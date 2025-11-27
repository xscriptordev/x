#!/usr/bin/env bash
set -e

echo "Installing Next.js + TypeScript environment on Arch Linux..."

# --- System update ---
x pacman -Syu --noconfirm

# --- Base dependencies ---
x pacman -S --needed --noconfirm git curl wget base-devel ca-certificates lsb-release gnupg || true

# --- Install NVM (Node Version Manager) ---
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi

# --- Load NVM into the current shell session ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# --- Install Node.js (latest LTS) ---
echo "Installing Node.js LTS..."
nvm install --lts
nvm use --lts

# --- Check versions ---
node -v
npm -v

# --- Update npm to the latest version ---
echo "Updating npm..."
npm install -g npm@latest

# --- Install TypeScript globally ---
echo "Installing TypeScript..."
npm install -g typescript ts-node @types/node

# --- Install common web dev tools ---
npm install -g yarn pnpm

