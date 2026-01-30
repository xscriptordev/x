# XScriptor WSL Setup

This script automates the bootstrapping of a fresh WSL (Windows Subsystem for Linux) instance.

## What it does
- **User Setup**: Creates a new user `xscriptor` and prompts you to set a password.
- **Boot Configuration**: Configures `/etc/wsl.conf` to make `xscriptor` the default user and enable systemd.
- **Sudo Wrapper**: Installs the `x` wrapper (`x pacman` -> `sudo pacman`).
- **Environment**: Installs `zsh`, `oh-my-zsh` + plugins, git aliases, and common tools (`yay` on Arch).
- **Optimized**: Skips GUI applications and VS Code extensions to keep the layer thin.

## Usage

### Remote Execution (One-Liner)
Run this as root/sudo on your fresh WSL installation:

```bash
# Using curl (Recommended)
curl -fsSL https://raw.githubusercontent.com/xscriptordev/x/main/wsl/install.sh | sudo bash

# Using wget
wget -qO- https://raw.githubusercontent.com/xscriptordev/x/main/wsl/install.sh | sudo bash
```

### Manual Execution
1. Clone or download the file.
2. Make it executable and run as root:
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

> **Note:** After installation, you must restart WSL (`wsl --shutdown` in PowerShell) for the default user change to take effect.
