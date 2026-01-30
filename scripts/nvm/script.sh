#!/usr/bin/env bash
set -e

# -------------------------------------------------------------------------
# FNM (Fast Node Manager) Installation Script
# -------------------------------------------------------------------------

echo "[XOs] Installing FNM (Fast Node Manager) + Node.js Environment..."

# Helper to log
log() {
    echo -e "\033[1;32m[XOs]\033[0m $1"
}

# -------------------------------------------------------------------------
# 1. INSTALL FNM
# -------------------------------------------------------------------------

if ! command -v fnm &>/dev/null; then
    log "Downloading and installing fnm..."
    # Install to default location ($HOME/.local/share/fnm) and skip shell setup
    # We will handle shell setup manually to ensure it's correct for Arch users
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
else
    log "fnm is already installed."
fi

# -------------------------------------------------------------------------
# 2. CONFIGURE SHELL ENVIRONMENT
# -------------------------------------------------------------------------

FNM_PATH="$HOME/.local/share/fnm"
SHELL_CONFIG=""

case "$SHELL" in
    */zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    */bash)
        SHELL_CONFIG="$HOME/.bashrc"
        ;;
    */fish)
        SHELL_CONFIG="$HOME/.config/fish/config.fish"
        ;;
    *)
        log "Unknown shell: $SHELL. Please configure fnm manually."
        ;;
esac

if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
    log "Configuring $SHELL_CONFIG..."
    
    # Check if already configured
    if ! grep -q "fnm env" "$SHELL_CONFIG"; then
        log "Adding fnm to $SHELL_CONFIG..."
        echo "" >> "$SHELL_CONFIG"
        echo "# fnm" >> "$SHELL_CONFIG"
        
        if [[ "$SHELL" == */fish ]]; then
            echo "fnm env --use-on-cd | source" >> "$SHELL_CONFIG"
        else
            echo 'export PATH="'"$FNM_PATH"':$PATH"' >> "$SHELL_CONFIG"
            echo 'eval "$(fnm env --use-on-cd)"' >> "$SHELL_CONFIG"
        fi
    else
        log "fnm already configured in $SHELL_CONFIG."
    fi
fi

# -------------------------------------------------------------------------
# 3. INSTALL NODE.JS & GLOBALS
# -------------------------------------------------------------------------

# Temporarily add fnm to current path to use it immediately
export PATH="$FNM_PATH:$PATH"
eval "$(fnm env --use-on-cd)"

log "Installing Node.js LTS..."
fnm install --lts
fnm use --lts

log "Installing global packages (npm, yarn, pnpm)..."
npm install -g npm@latest
npm install -g yarn pnpm typescript ts-node

# -------------------------------------------------------------------------
# FINISH
# -------------------------------------------------------------------------

log "Installation complete!"
log "Node version: $(node -v)"
log "NPM version: $(npm -v)"
log "Please restart your shell to apply changes."
