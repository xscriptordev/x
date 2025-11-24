# X Scripts

This repository contains system scripts for XOS. The primary entrypoint is `x.sh`, which configures and refreshes the environment after a reboot. An in-progress `scripts` directory will host optional add-ons and extra configurations.

## x.sh (Base Script)

- Purpose: Apply the latest required configurations for XOS after a reboot.
- Responsibilities:
  - Ensure the `x` wrapper command is installed to `/usr/bin/x` so `x <cmd>` runs with elevated privileges.
  - Install and configure Zsh and Oh My Zsh, including useful plugins.
  - Add shell aliases and Git/navigation helpers to user and system rc files when missing.
  - Perform distro-aware package setup (e.g., Arch `pacman`, Debian/Ubuntu `apt`, Fedora `dnf`).
- Usage:
  - Run `bash x.sh` after system startup or reboot.
  - After execution, reload your shell: `source ~/.bashrc` or `source ~/.zshrc`.

## /scripts (Optional Add-ons)

- Status: Under active development.
- Location: `/scripts` (to be populated).
- Purpose: Host optional and modular configurations that can be added to XOS on demand, without being part of the base setup.
- Expected Contents:
  - Feature-specific setup scripts.
  - Integration helpers for additional tools and workflows.
  - Experimental or in-progress modules that can be enabled selectively.

As this directory is under construction, interfaces and available scripts are subject to change. Contributions and iterations are ongoing as we develop these optional components.