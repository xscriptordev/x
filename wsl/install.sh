#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# XScriptor - Create user securely in WSL (X)
# --------------------------------------------------

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

USER_NAME="xscriptor"

# --- 1. Read password securely ---
if [[ -t 0 ]]; then
  echo "Enter password for $USER_NAME:"
  read -s USER_PASS
  echo
  echo "Repeat password:"
  read -s USER_PASS_CONFIRM
  echo

  if [[ "$USER_PASS" != "$USER_PASS_CONFIRM" ]]; then
    echo "Passwords do not match."
    exit 1
  fi
else
  echo "Interactive terminal required."
  exit 1
fi

# --- 2. Crear usuario si no existe ---
if ! id "$USER_NAME" &>/dev/null; then
  useradd -m -s /bin/bash "$USER_NAME"
  echo "$USER_NAME:$USER_PASS" | chpasswd
  echo "[OK] User created."
else
  echo "[INFO] User already exists."
fi

unset USER_PASS USER_PASS_CONFIRM

# --- 3. Configurar sudo (Arch) ---
if command -v pacman &>/dev/null; then
  usermod -aG wheel "$USER_NAME"

  if [[ ! -f /etc/sudoers.d/wheel ]]; then
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
    chmod 0440 /etc/sudoers.d/wheel
  fi
else
  echo "[WARN] No parece Arch. Sudo no configurado."
fi

# --- 4. Usuario por defecto en WSL (SEGURO) ---
if grep -qi microsoft /proc/version; then
  if [[ ! -f /etc/wsl.conf ]]; then
    cat > /etc/wsl.conf <<EOF
[user]
default=$USER_NAME
EOF
    echo "[OK] User default configured in WSL."
  else
    echo "[INFO] /etc/wsl.conf already exists. Not modified."
  fi
fi

echo "----------------------------------------------"
echo "User '$USER_NAME' ready."
echo "No systemd or network have been modified."
echo "Close the distro or run: wsl --terminate x"
echo "----------------------------------------------"
