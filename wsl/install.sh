#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------------
# XScriptor WSL Installation Script
# -------------------------------------------------------------------------

echo "[XOs] Starting WSL Setup..."

# Ensure we are root
if [ "$EUID" -ne 0 ]; then
  echo "[!] This script must be run as root (or via sudo bash ...)"
  exit 1
fi

USER_NAME="xscriptor"

# 1. Prompt for Password
echo "Enter password for new user '$USER_NAME':"
read -s USER_PASS
echo
if [ -z "$USER_PASS" ]; then
    echo "[!] Password cannot be empty."
    exit 1
fi

# 2. Create 'x' Wrapper for Sudo
echo "[XOs] Installing 'x' wrapper for sudo..."
if [[ ! -x /usr/bin/x ]] || ! grep -q 'exec sudo "$@"' /usr/bin/x 2>/dev/null; then
  cat > /usr/bin/x << "EOF"
#!/usr/bin/env bash
exec sudo "$@"
EOF
  chmod 755 /usr/bin/x
  echo "[+] Installed /usr/bin/x"
else
  echo "[=] /usr/bin/x already exists and is correct"
fi

# 3. Create User
if id "$USER_NAME" &>/dev/null; then
    echo "[=] User $USER_NAME already exists"
else
    echo "[+] Creating user $USER_NAME..."
    useradd -m -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$USER_PASS" | chpasswd
    echo "[+] Password set for $USER_NAME"
fi

# 4. Grant Sudo
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

# 5. Set as Default User for WSL
echo "[+] Configuring /etc/wsl.conf to set $USER_NAME as default..."
if [ -f /etc/wsl.conf ]; then
    # Back up if exists
    cp /etc/wsl.conf /etc/wsl.conf.bak
fi

cat > /etc/wsl.conf <<EOF
[user]
default=$USER_NAME

[boot]
systemd=true
EOF

# -------------------------------------------------------------------------
# 6. ENVIRONMENT SETUP (As User)
# -------------------------------------------------------------------------

echo "[XOs] Installing base dependencies..."
if command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm git base-devel zsh curl wget
elif command -v apt &>/dev/null; then
    apt update -y
    apt install -y git build-essential zsh curl wget
    chsh -s $(which zsh) "$USER_NAME"
fi

# Switch to user to run user-level setup
echo "[XOs] Switching to $USER_NAME to complete setup..."

# Helper script to run as user
cat > "/home/$USER_NAME/x_wsl_setup_inner.sh" << "EOS"
#!/usr/bin/env bash
set -e

# Define aliases content
ALIASES="
# ───── Xscriptor Aliases ─────
alias xs='sudo su'
alias xi='sudo -i'
alias xsh='sudo -s'
alias xzdev='zellij --layout x'
"

GIT_ALIASES="
# ===== XCustom Git Aliases =====
alias gc='git clone'
alias ga='git add .'
alias gcom='git commit -m'
alias gp='git push'
alias gpuom='git push -u origin main'
alias gpuod='git push -u origin dev'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gpl='git pull'
alias gf='git fetch'
"

NAVIGATION_ALIASES="
# ===== XCustom Navigation Aliases =====
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
"

echo "[User] Setting up Environment..."

# Install Yay (Arch only)
if command -v pacman &>/dev/null && ! command -v yay &>/dev/null; then
    echo "[User] Installing yay..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
fi

# Install Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[User] Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install OYZ Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
declare -A plugins=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
  ["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete"
)

for name in "${!plugins[@]}"; do
  dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    git clone --depth=1 "${plugins[$name]}" "$dest"
  fi
done

# Configure .zshrc
ZSHRC="$HOME/.zshrc"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="random"/' "$ZSHRC" || echo 'ZSH_THEME="random"' >> "$ZSHRC"

if grep -q "^plugins=" "$ZSHRC"; then
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)/' "$ZSHRC"
else
  echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)' >> "$ZSHRC"
fi

# Add Aliases
echo "$ALIASES" >> "$ZSHRC"
echo "$GIT_ALIASES" >> "$ZSHRC"
echo "$NAVIGATION_ALIASES" >> "$ZSHRC"

# Install Extras (Fetch/Top)
echo "[User] Installing extras..."
curl -fsSL https://raw.githubusercontent.com/xscriptordev/xfetch/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/xscriptordev/xtop/main/install.sh | bash

EOS

# Fix permissions and run
chmod +x "/home/$USER_NAME/x_wsl_setup_inner.sh"
chown "$USER_NAME:$USER_NAME" "/home/$USER_NAME/x_wsl_setup_inner.sh"

# Run as user
su - "$USER_NAME" -c "/home/$USER_NAME/x_wsl_setup_inner.sh"

# Cleanup
rm "/home/$USER_NAME/x_wsl_setup_inner.sh"

echo "[XOs] WSL Setup Complete!"
echo "[XOs] Please restart your WSL instance: wsl --shutdown"
