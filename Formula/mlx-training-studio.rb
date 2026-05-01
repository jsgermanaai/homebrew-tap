# Formula for the MLX Training Studio installer CLI.
#
# This formula installs the `mlx-training-studio` CLI, which is a wrapper that
# clones, builds, and installs the upstream Swift app (stevenatkin/mlx-lm-gui)
# on the user's machine. The formula itself does NOT build the Swift app —
# that happens when the user runs `mlx-training-studio install`.
#
# SHA256 NOTE: The sha256 below is a placeholder. After creating the v0.1.0
# GitHub release and uploading/tagging the tarball, compute the real value:
#
#   curl -fsSL https://github.com/jsgermanaai/mlx-training-studio-installer/archive/refs/tags/v0.1.0.tar.gz \
#     | shasum -a 256
#
# Then replace __FILL_ME_IN__ with the resulting hash.

class MlxTrainingStudio < Formula
  desc "Installer for MLX Training Studio (Swift macOS GUI for mlx-lm-lora fine-tuning)"
  homepage "https://github.com/jsgermanaai/mlx-training-studio-installer"
  url "https://github.com/jsgermanaai/mlx-training-studio-installer/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "4f60cffa33e59c16bbf4c90aff98052a83bda60d0f644aed7030e021659fdede"
  version "0.1.0"
  license "Apache-2.0"

  # Allow installing from the latest HEAD for development / pre-release use.
  head "https://github.com/jsgermanaai/mlx-training-studio-installer.git",
       branch: "main"

  # Require macOS — this is a macOS-only tool (Apple Silicon Swift app).
  depends_on :macos
  depends_on macos: :ventura # macOS 13.0+

  def install
    # Strategy: install the real script into libexec so Homebrew's `brew audit`
    # is happy (scripts in libexec are not on PATH by default). Then write a
    # small shim into bin/ that:
    #   1. Exports MLX_TS_LIB_DIR so the main script finds lib/ next to itself
    #      inside libexec, regardless of where Homebrew symlinks things.
    #   2. Execs the real script in libexec.
    #
    # This pattern is common in Homebrew formulae that ship shell scripts with
    # relative sourcing of sibling files (e.g., git-extras, hub, etc.).

    # Install the main script and all lib/ modules into libexec.
    libexec.install "bin/mlx-training-studio"
    (libexec / "lib").install Dir["lib/*"]

    # Write the bin shim.
    (bin / "mlx-training-studio").write <<~SH
      #!/usr/bin/env bash
      export MLX_TS_LIB_DIR="#{libexec}/lib"
      exec "#{libexec}/mlx-training-studio" "$@"
    SH
  end

  def caveats
    <<~EOS
      The `mlx-training-studio` CLI has been installed, but the app has NOT
      yet been built or copied to /Applications.

      To build and install MLX Training Studio, run:

        mlx-training-studio install

      Requirements for the install step:
        - Full Xcode 15+ (not just Command Line Tools)
        - Python 3.12+ (not the /usr/bin/python3 stub)
        - Apple Silicon Mac
        - ~5 GB of free disk space

      Run `mlx-training-studio doctor` first to check your environment.
    EOS
  end

  test do
    # The `doctor` subcommand runs all preflight checks and exits non-zero if
    # any hard requirement is missing (e.g., Xcode not installed on CI).
    # We only verify that the binary is reachable and can parse its own args.
    # `help` always exits 0.
    system bin / "mlx-training-studio", "help"
  end
end
