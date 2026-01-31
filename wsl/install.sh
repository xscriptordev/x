#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------------
# XScriptor WSL Bootstrap Script (Root)
# -------------------------------------------------------------------------
# This script prepares the system, creates the user, and configures WSL/DNS.
# It does NOT install user-specific tools (Oh-My-Zsh, Aliases).
# Run this as ROOT.

echo "[XOs] Starting WSL Bootstrap..."

# Ensure we are root
if [ "$EUID" -ne 0 ]; then
  echo "[!] This script must be run as root (or via sudo bash ...)"
  exit 1
fi

USER_NAME="xscriptor"

# 1. Prompt for Password
echo "Enter password for new user '$USER_NAME':"
# Force read from /dev/tty
read -s USER_PASS < /dev/tty
echo
if [ -z "$USER_PASS" ]; then
    echo "[!] Password cannot be empty."
    exit 1
fi

# 2. Create User
if id "$USER_NAME" &>/dev/null; then
    echo "[=] User $USER_NAME already exists"
else
    echo "[+] Creating user $USER_NAME..."
    useradd -m -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$USER_PASS" | chpasswd
    echo "[+] Password set for $USER_NAME"
fi

# 3. Grant Sudo
echo "[+] Granting sudo privileges..."
if command -v pacman &>/dev/null; then
    # Arch
    if [ ! -d "/etc/sudoers.d" ]; then mkdir -p /etc/sudoers.d; fi
    echo "$USER_NAME ALL=(ALL) ALL" > "/etc/sudoers.d/$USER_NAME"
elif command -v apt &>/dev/null; then
    # Debian/Ubuntu
    usermod -aG sudo "$USER_NAME" || usermod -aG wheel "$USER_NAME"
    echo "$USER_NAME ALL=(ALL) ALL" > "/etc/sudoers.d/$USER_NAME"
fi
chmod 0440 "/etc/sudoers.d/$USER_NAME"

# 4. Configure /etc/wsl.conf (User Default + DNS)
echo "[+] Configuring /etc/wsl.conf..."
if [ -f /etc/wsl.conf ]; then
    cp /etc/wsl.conf /etc/wsl.conf.bak
fi

# We enable systemd and ensure network generation is ON (standard behavior).
# If DNS issues persist, one might set generateResolvConf=false and manually set DNS,
# but usually ensuring systemd-resolved doesn't conflict is better.
# For a clean bootstrap, we stick to standard but explicit configuration.
cat > /etc/wsl.conf <<EOF
[user]
default=$USER_NAME

[boot]
systemd=true

[network]
generateResolvConf=true
EOF

# 5. Install Base Dependencies (for user setup later)
echo "[XOs] Installing base dependencies..."
if command -v pacman &>/dev/null; then
    # Arch: git, base-devel, zsh, curl, wget, go (needed for yay/others later)
    # We update first to avoid 404s
    pacman -Syu --noconfirm git base-devel zsh curl wget go
    # Set zsh as default shell for user
    chsh -s /usr/bin/zsh "$USER_NAME"
elif command -v apt &>/dev/null; then
    # Debian/Ubuntu
    apt update -y
    apt install -y git build-essential zsh curl wget
    # Set zsh as default shell for user if installed
    chsh -s $(which zsh) "$USER_NAME"
fi

echo "[XOs] Bootstrap Complete!"
echo "[XOs] Please restart your WSL instance: wsl --shutdown"
echo "[XOs] After restart, log in as '$USER_NAME' and run the setup script."
