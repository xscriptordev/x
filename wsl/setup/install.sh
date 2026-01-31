#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# XScriptor User Setup (WSL-safe)
# Must be run as NORMAL user
# --------------------------------------------------

echo "[Setup] Starting user environment setup..."

if [[ $EUID -eq 0 ]]; then
  echo "[ERROR] Do NOT run this script as root."
  exit 1
fi

# --------------------------------------------------
# 1. Install dependencies
# --------------------------------------------------
echo "[Setup] Installing dependencies..."

if command -v pacman &>/dev/null; then
  sudo pacman -Sy --noconfirm git zsh curl wget base-devel
elif command -v apt &>/dev/null; then
  sudo apt update -y
  sudo apt install -y git zsh curl wget build-essential
else
  echo "[ERROR] Unsupported distro."
  exit 1
fi

# --------------------------------------------------
# 2. Ensure ~/.local/bin exists and PATH works NOW
# --------------------------------------------------
mkdir -p "$HOME/.local/bin"

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# --------------------------------------------------
# 3. Install x wrapper
# --------------------------------------------------
echo "[Setup] Installing x wrapper..."

cat > "$HOME/.local/bin/x" <<'EOF'
#!/usr/bin/env bash
exec sudo "$@"
EOF
chmod 755 "$HOME/.local/bin/x"

command -v x >/dev/null && echo "[OK] Wrapper x installed."

# --------------------------------------------------
# 4. Install Oh My Zsh
# --------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "[Setup] Installing Oh-My-Zsh..."
  RUNZSH=no CHSH=no \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Ensure .zshrc exists
[[ -f "$HOME/.zshrc" ]] || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

# --------------------------------------------------
# 5. Install Zsh plugins
# --------------------------------------------------
echo "[Setup] Installing Zsh plugins..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

plugins=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
  "https://github.com/zsh-users/zsh-completions"
  "https://github.com/marlonrichert/zsh-autocomplete"
)

for repo in "${plugins[@]}"; do
  name="$(basename "$repo")"
  dest="$ZSH_CUSTOM/plugins/$name"
  [[ -d "$dest" ]] || git clone --depth=1 "$repo" "$dest"
done

# --------------------------------------------------
# 6. Configure .zshrc safely
# --------------------------------------------------
echo "[Setup] Configuring .zshrc..."

sed -i 's/^ZSH_THEME=.*/ZSH_THEME="random"/' "$HOME/.zshrc"

sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)/' "$HOME/.zshrc"

if ! grep -q "Xscriptor Config" "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'EOF'

# ───── Xscriptor Config ─────
export PATH="$HOME/.local/bin:$PATH"

alias xs='sudo su'
alias xi='sudo -i'
alias xsh='sudo -s'

# Git
alias ga='git add .'
alias gcom='git commit -m'
alias gs='git status'
alias gp='git push'

# Nav
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lh'
alias la='ls -A'
alias c='clear'
EOF
fi

# --------------------------------------------------
# 7. Force zsh as default shell (CRITICAL)
# --------------------------------------------------
if [[ "$SHELL" != "/bin/zsh" ]]; then
  echo "[Setup] Setting zsh as default shell..."
  chsh -s /bin/zsh
fi

# --------------------------------------------------
echo "----------------------------------------------"
echo "[OK] Setup completed successfully."
echo "Exit WSL and re-enter the distro."
echo "----------------------------------------------"
