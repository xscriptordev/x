#!/usr/bin/env bash
set -euo pipefail

echo "[XOs] Installing QEMU + libvirt + virt-manager stack…"

# ─── Detect iptables backend ───
pkgs=(
  qemu-full libvirt virt-manager virt-viewer edk2-ovmf dnsmasq swtpm
  guestfs-tools libosinfo bridge-utils vde2 openbsd-netcat ebtables
)

if pacman -Qi iptables-nft &>/dev/null; then
  echo "[XOs] Using iptables-nft backend."
elif pacman -Qi iptables &>/dev/null; then
  echo "[XOs] Using legacy iptables backend."
else
  echo "[XOs] No iptables backend found. Installing iptables-nft."
  pkgs+=(iptables-nft)
fi

x pacman -Syu --needed "${pkgs[@]}"

echo "[XOs] Enabling services..."
x systemctl enable --now libvirtd.service
x systemctl enable --now virtlogd.socket virtlockd.socket

echo "[XOs] Adding user to libvirt/kvm groups..."
x usermod -aG libvirt,kvm "$(whoami)"

echo "[XOs] Restarting libvirt service..."
x systemctl restart libvirtd.service

echo "[XOs] Defining and starting default network..."
x virsh net-define /usr/share/libvirt/networks/default.xml 2>/dev/null || true
x virsh net-autostart default || true
x virsh net-start default || true

echo "[XOs] Virtualization stack installed."
echo "[XOs] Please log out or reboot to apply group changes."
echo "[XOs] After reboot, run virt-manager to start using QEMU/KVM."