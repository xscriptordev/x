#!/usr/bin/env bash
set -e

# -------------------------------------------------------------------------
# XScriptor User Setup Script
# -------------------------------------------------------------------------
# This script configures the user environment (Zsh, Aliases, Wrapper).
# Run this AFTER logging in as the 'xscriptor' user.

echo "[Setup] Starting User Environment Setup..."

# Ensure we are NOT root
if [ "$EUID" -eq 0 ]; then
  echo "[!] This script should be run as your normal user (xscriptor), NOT root."
  exit 1
fi

# 0. Install Essential Dependencies
# We sudo install these to ensure they exist for the rest of the script.
echo "[Setup] Checking and installing dependencies..."
if command -v pacman &>/dev/null; then
    echo "[Setup] Detected Arch Linux (pacman). Updating and installing..."
    sudo pacman -Syu --noconfirm git zsh curl wget
elif command -v apt &>/dev/null; then
    echo "[Setup] Detected Debian/Ubuntu (apt). Updating and installing..."
    sudo apt update -y
    sudo apt install -y git zsh curl wget
fi

# 1. Install 'x' Wrapper
# We install it to ~/.local/bin to avoid sudo if possible, or use sudo for /usr/bin if preferred.
# The user requested "wrapper for x in place of sudo".
# Let's put it in ~/.local/bin and ensure PATH includes it.
echo "[Setup] Installing 'x' wrapper..."
if [ ! -d "$HOME/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
fi

cat > "$HOME/.local/bin/x" << "EOF"
#!/usr/bin/env bash
exec sudo "$@"
EOF
chmod 755 "$HOME/.local/bin/x"

# Ensure ~/.local/bin is in PATH in .bashrc/.zshrc (handled later)
echo "[+] Installed 'x' wrapper to ~/.local/bin/x"

# 2. Install Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "[Setup] Installing Oh-My-Zsh..."
    # We use --unattended to keep it non-interactive
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "[=] Oh-My-Zsh already installed."
fi

# 3. Install OYZ Plugins
echo "[Setup] Installing Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
declare -A plugins=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
  ["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete"
)

# Check for git
if ! command -v git &>/dev/null; then
    echo "[!] Git is not installed. Please install git."
    exit 1
fi

for name in "${!plugins[@]}"; do
  dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    echo "    Cloning $name..."
    git clone --depth=1 "${plugins[$name]}" "$dest" || echo "[!] Failed to clone $name"
  else
    echo "    $name already installed."
  fi
done

# 4. Configure .zshrc
echo "[Setup] Configuring .zshrc..."
ZSHRC="$HOME/.zshrc"

# Set Theme to random
if grep -q "^ZSH_THEME=" "$ZSHRC"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="random"/' "$ZSHRC"
else
    echo 'ZSH_THEME="random"' >> "$ZSHRC"
fi

# Set Plugins
if grep -q "^plugins=" "$ZSHRC"; then
    sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)/' "$ZSHRC"
else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)' >> "$ZSHRC"
fi

# 5. Add Aliases and Path
# We append them if not present. Using a marker to avoid duplication.
if ! grep -q "# ───── Xscriptor Config ─────" "$ZSHRC"; then
    cat >> "$ZSHRC" << "EOF"

# ───── Xscriptor Config ─────

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# ───── Aliases ─────
alias xs='sudo su'
alias xi='sudo -i'
alias xsh='sudo -s'
alias xzdev='zellij --layout x'

# ===== Git Aliases =====
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

# ===== Navigation Aliases =====
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
EOF
    echo "[+] Added aliases and PATH to .zshrc"
else
    echo "[=] Aliases already present in .zshrc"
fi

echo "[Setup] Configuration Complete!"
echo "Please restart your shell or run: source ~/.zshrc"
