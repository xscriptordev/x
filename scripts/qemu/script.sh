#!/usr/bin/env bash
set -euo pipefail

echo "[XOs] Installing QEMU + libvirt + virt-manager stack…"

# ─── Base package list ────────────────────────────────
pkgs=(
  qemu-full libvirt virt-manager virt-viewer edk2-ovmf dnsmasq swtpm
  guestfs-tools libosinfo bridge-utils vde2 openbsd-netcat ebtables
)

# ─── Detect iptables backend ───────────────────────────
HAS_IPTABLES=0
HAS_NFT=0

pacman -Qi iptables &>/dev/null      && HAS_IPTABLES=1
pacman -Qi iptables-nft &>/dev/null  && HAS_NFT=1

# If neither backend exists → install iptables-nft
if [[ "$HAS_IPTABLES" -eq 0 && "$HAS_NFT" -eq 0 ]]; then
  pkgs+=(iptables-nft)
fi

# If legacy iptables exists → remove iptables-nft from list
if [[ "$HAS_IPTABLES" -eq 1 ]]; then
  echo "[XOs] Legacy iptables detected. Removing iptables-nft from package list."
  new_pkgs=()
  for p in "${pkgs[@]}"; do
    [[ "$p" == "iptables-nft" ]] && continue
    new_pkgs+=("$p")
  done
  pkgs=("${new_pkgs[@]}")
fi

# ─── Install with noconfirm (required for curl|bash) ───
x pacman -Syu --needed --noconfirm "${pkgs[@]}"

# ─── Services ──────────────────────────────────────────
echo "[XOs] Enabling services..."
x systemctl enable --now libvirtd.service
x systemctl enable --now virtlogd.socket virtlockd.socket

echo "[XOs] Adding user to libvirt/kvm groups..."
x usermod -aG libvirt,kvm "$(whoami)"

echo "[XOs] Restarting libvirt service..."
x systemctl restart libvirtd.service

# ─── Default network ───────────────────────────────────
echo "[XOs] Defining and starting default network..."
x virsh net-define /usr/share/libvirt/networks/default.xml 2>/dev/null || true
x virsh net-autostart default || true
x virsh net-start default || true

echo "[XOs] Virtualization stack installed."
echo "[XOs] Please log out or reboot to apply group changes."
echo "[XOs] After reboot, run virt-manager to start using QEMU/KVM."
