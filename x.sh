#!/usr/bin/env bash
set -euo pipefail

# X base

if [[ ! -x /usr/bin/x ]] || ! grep -q 'exec sudo "$@"' /usr/bin/x 2>/dev/null; then
  sudo sh -c 'cat > /usr/bin/x << "EOF"
#!/usr/bin/env bash
exec sudo "$@"
EOF'
  sudo chmod 755 /usr/bin/x
fi
alias x &>/dev/null && unalias x || true
if [[ -n "${RCFILE:-}" ]] && [[ -f "$RCFILE" ]]; then
  sed -i '/^[[:space:]]*alias[[:space:]]*x=.*$/d' "$RCFILE" || true
fi
if [[ -f "$HOME/.zshrc" ]]; then
  sed -i '/^[[:space:]]*alias[[:space:]]*x=.*$/d' "$HOME/.zshrc" || true
fi
if [[ -f /etc/bash.bashrc ]]; then
  x sed -i '/^[[:space:]]*alias[[:space:]]*x=.*$/d' /etc/bash.bashrc || true
fi
if [[ -f /etc/zsh/zshrc ]]; then
  x sed -i '/^[[:space:]]*alias[[:space:]]*x=.*$/d' /etc/zsh/zshrc || true
fi

ALIASES="
# ───── Xscriptor Aliases ─────
alias xs='sudo su'
alias xi='sudo -i'
alias xsh='sudo -s'
alias xzdev='zellij --layout x'
"

shopt -s expand_aliases
alias xs='sudo su'
alias xi='sudo -i'
alias xsh='sudo -s'
alias xzdev='zellij --layout x'

if ! command -v zsh &>/dev/null; then
  if command -v pacman &>/dev/null; then
    x pacman -Sy --noconfirm zsh
  elif command -v apt &>/dev/null; then
    x apt update -y
    x apt install -y zsh
  elif command -v dnf &>/dev/null; then
    x dnf install -y zsh
  fi
fi

# Install yay only if Arch-based
if command -v pacman &>/dev/null; then
  if ! command -v yay &>/dev/null; then
    echo "[+] Installing yay (AUR helper)..."
    x pacman -Sy --noconfirm --needed git base-devel

    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir"
    (cd "$tmpdir" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  else
    echo "[=] yay already installed"
  fi
fi

if [ "$SHELL" != "$(which zsh)" ] && command -v zsh &>/dev/null; then
  chsh -s "$(which zsh)"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

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

ZSHRC="$HOME/.zshrc"

sed -i 's/^ZSH_THEME=.*/ZSH_THEME="random"/' "$ZSHRC" || echo 'ZSH_THEME="random"' >> "$ZSHRC"

if grep -q "^plugins=" "$ZSHRC"; then
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)/' "$ZSHRC"
else
  echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-autocomplete)' >> "$ZSHRC"
fi

GIT_ALIASES=$(cat <<'EOF'
# ===== XCustom Git Aliases =====
alias gc="git clone"
alias ga="git add ."
alias gcom="git commit -m"
alias gp="git push"
alias gpuom="git push -u origin main"
alias gpuod="git push -u origin dev"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gd="git diff"
alias gpl="git pull"
alias gf="git fetch"
# ===== End =====
EOF
)

NAVIGATION_ALIASES=$(cat <<'EOF'
# ===== XCustom Navigation Aliases =====
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias c="clear"
alias ll="ls -lh"
alias la="ls -A"
alias l="ls -CF"
# ===== End =====
EOF
)

# Detect shell rc file
RCFILE=""
case "$(basename "$SHELL")" in
  bash) RCFILE="$HOME/.bashrc" ;;
  zsh)  RCFILE="$HOME/.zshrc" ;;
esac

# Add to user shell rc
if [[ -n "$RCFILE" ]]; then
  if ! grep -q "Xscriptor Aliases" "$RCFILE" 2>/dev/null; then
    echo "$ALIASES" >> "$RCFILE"
    echo "[+] Aliases added to $RCFILE"
  else
    echo "[=] Aliases already exist in $RCFILE"
  fi
else
  echo "[!] Unsupported shell. Add manually."
fi

if [[ -n "$RCFILE" ]]; then
  if ! grep -q "XCustom Git Aliases" "$RCFILE" 2>/dev/null; then
    echo "$GIT_ALIASES" >> "$RCFILE"
  fi
  if ! grep -q "XCustom Navigation Aliases" "$RCFILE" 2>/dev/null; then
    echo "$NAVIGATION_ALIASES" >> "$RCFILE"
  fi
fi

if [[ -f /etc/bash.bashrc ]]; then
  if ! grep -q "Xscriptor Aliases" /etc/bash.bashrc 2>/dev/null; then
    echo "$ALIASES" | x tee -a /etc/bash.bashrc >/dev/null
  fi
  if ! grep -q "XCustom Git Aliases" /etc/bash.bashrc 2>/dev/null; then
    echo "$GIT_ALIASES" | x tee -a /etc/bash.bashrc >/dev/null
  fi
  if ! grep -q "XCustom Navigation Aliases" /etc/bash.bashrc 2>/dev/null; then
    echo "$NAVIGATION_ALIASES" | x tee -a /etc/bash.bashrc >/dev/null
  fi
fi

if [[ -f /etc/zsh/zshrc ]]; then
  if ! grep -q "Xscriptor Aliases" /etc/zsh/zshrc 2>/dev/null; then
    echo "$ALIASES" | x tee -a /etc/zsh/zshrc >/dev/null
  fi
  if ! grep -q "XCustom Git Aliases" /etc/zsh/zshrc 2>/dev/null; then
    echo "$GIT_ALIASES" | x tee -a /etc/zsh/zshrc >/dev/null
  fi
  if ! grep -q "XCustom Navigation Aliases" /etc/zsh/zshrc 2>/dev/null; then
    echo "$NAVIGATION_ALIASES" | x tee -a /etc/zsh/zshrc >/dev/null
  fi
fi

if ! grep -q "Xscriptor Aliases" "$HOME/.zshrc" 2>/dev/null; then
  echo "$ALIASES" >> "$HOME/.zshrc"
fi

if ! grep -q "XCustom Git Aliases" "$HOME/.zshrc" 2>/dev/null; then
  echo "$GIT_ALIASES" >> "$HOME/.zshrc"
fi
if ! grep -q "XCustom Navigation Aliases" "$HOME/.zshrc" 2>/dev/null; then
  echo "$NAVIGATION_ALIASES" >> "$HOME/.zshrc"
fi

if command -v code &>/dev/null; then
  code --install-extension xscriptor.x-dark-colors || echo "[!] Failed to install xscriptor.x-dark-colors"
  code --install-extension xscriptor.xscriptor-themes || echo "[!] Failed to install xscriptor.xscriptor-themes"
  code --install-extension xscriptor.xglass || echo "[!] Failed to install xscriptor.xglass"
fi

echo " Done. Reload your shell:"
echo "   source ~/.bashrc  or  source ~/.zshrc"
