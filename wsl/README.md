# XScriptor WSL Setup

This script automates the bootstrapping of a fresh WSL (Windows Subsystem for Linux) instance.

## What it does
- **User Setup**: Creates a new user `xscriptor` and prompts you to set a password.
- **Boot Configuration**: Configures `/etc/wsl.conf` to make `xscriptor` the default user and enable systemd.
- **Sudo Wrapper**: Installs the `x` wrapper (`x pacman` -> `sudo pacman`).
- **Environment**: Installs `zsh`, `oh-my-zsh` + plugins, git aliases, and common tools (`yay` on Arch).
- **Optimized**: Skips GUI applications and VS Code extensions to keep the layer thin.

## Usage

### Method 1: Download and Run (Recommended)
This is the most reliable method.

1.  **Download the script**:
    ```bash
    wget https://raw.githubusercontent.com/xscriptordev/x/main/wsl/install.sh
    ```
2.  **Make it executable**:
    ```bash
    chmod +x install.sh
    ```
3.  **Run as root**:
    ```bash
    sudo ./install.sh
    ```

### Method 2: Remote Execution
If you prefer a one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/xscriptordev/x/main/wsl/install.sh | sudo bash
```

> **Important:** After installation, you **MUST** restart your WSL instance for the user change to take effect.
>
> In Windows PowerShell/CMD:
> ```powershell
> wsl --shutdown
> ```
> Then open your WSL terminal again. You should be logged in as `xscriptor`.
