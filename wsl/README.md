# XScriptor WSL Bootstrap

This script automates the initial bootstrapping of a fresh WSL (Windows Subsystem for Linux) instance.

## Overview

This process is split into two stages:
1.  **Bootstrap (Root)**: Creates the user, configures WSL/DNS, and installs base packages.
2.  **Setup (User)**: Configures the shell, aliases, and tools for the `xscriptor` user.

## Stage 1: Bootstrap (Run as Root)

This script must be run as `root` on a fresh WSL instance.

### Usage

```bash
# Download and run as root
curl -fsSL https://raw.githubusercontent.com/xscriptordev/x/main/wsl/install.sh | sudo bash
```

### What it does
- **User Creation**: Creates `xscriptor` and sets password.
- **Privileges**: Grants sudo access.
- **WSL Config**: Updates `/etc/wsl.conf` to:
    - Set `xscriptor` as the default user on boot.
    - Enable `systemd`.
    - Ensure DNS generation is enabled (`generateResolvConf=true`).
- **Base Deps**: Installs minimal dependencies (git, curl, wget, zsh, go).

> **Important:** After this stage, restart WSL (`wsl --shutdown`) and reopen the terminal. You should be logged in as `xscriptor`.

## Stage 2: User Setup (Run as xscriptor)

After restarting, run the setup script to finish configuring your environment.

See [setup/README.md](../setup/README.md) for details.

```bash
curl -fsSL https://raw.githubusercontent.com/xscriptordev/x/main/setup/install.sh | bash
```
