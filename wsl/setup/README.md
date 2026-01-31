# XScriptor Setup

This directory contains the user-level setup script.

## Usage

After running the bootstrap script (`wsl/install.sh`) as root and restarting WSL, you will be logged in as `xscriptor`.

Run the setup script to configure your environment:

```bash
# Download and run directly
wget https://raw.githubusercontent.com/xscriptordev/x/main/wsl/setup/install.sh
chmod +x install.sh
./install.sh
```

## What it does

- Installs `x` wrapper in `~/.local/bin/x` (to use `x` instead of `sudo`).
- Installs Oh-My-Zsh.
- Installs Zsh plugins (autosuggestions, syntax-highlighting, completions, autocomplete).
- Configures `.zshrc` with a random theme and XScriptor aliases.
- Sets up PATH to include `~/.local/bin`.
