#!/usr/bin/env bash
set -euo pipefail

echo "[XOs] Installing proprietary NVIDIA drivers..."

# ────────────────────────────────────────────────
# 1. Remove open-source drivers (nouveau)
# ────────────────────────────────────────────────
if pacman -Q vulkan-nouveau xf86-video-nouveau &>/dev/null; then
  echo "[XOs] Removing open-source drivers (nouveau)..."
  x pacman -Rns --noconfirm vulkan-nouveau xf86-video-nouveau || true
fi

# ────────────────────────────────────────────────
# 2. Install proprietary NVIDIA drivers
# ────────────────────────────────────────────────
echo "[XOs] Installing NVIDIA packages..."
x pacman -S --noconfirm --needed nvidia nvidia-utils nvidia-settings opencl-nvidia egl-wayland

# ────────────────────────────────────────────────
# 3. Blacklist nouveau
# ────────────────────────────────────────────────
echo "[XOs] Blacklisting nouveau..."
x bash -c 'echo -e "blacklist nouveau\noptions nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf'

# ────────────────────────────────────────────────
# 4. Ensure NVIDIA modules are added to initramfs
# ────────────────────────────────────────────────
echo "[XOs] Updating /etc/mkinitcpio.conf..."
x sed -i 's/^MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

# ────────────────────────────────────────────────
# 5. Rebuild initramfs
# ────────────────────────────────────────────────
echo "[XOs] Rebuilding initramfs..."
x mkinitcpio -P

# ────────────────────────────────────────────────
# 6. Configure DRM and update bootloader entries
# ────────────────────────────────────────────────
echo "[XOs] Configuring DRM kernel mode setting..."
x bash -c 'echo "options nvidia_drm modeset=1" > /etc/modprobe.d/nvidia.conf'

BOOTLOADER=""
if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
  BOOTLOADER="systemd-boot"
elif [[ -f /boot/loader/loader.conf ]] || [[ -d /boot/loader/entries ]]; then
  BOOTLOADER="systemd-boot"
elif [[ -f /etc/default/grub ]] || command -v grub-mkconfig &>/dev/null; then
  BOOTLOADER="grub"
fi

if [[ "$BOOTLOADER" == "systemd-boot" ]]; then
  echo "[XOs] Updating systemd-boot entries with nvidia_drm.modeset=1..."
  entries_dir="/boot/loader/entries"
  if [[ -d "$entries_dir" ]]; then
    for entry in "$entries_dir"/*.conf; do
      [[ -f "$entry" ]] || continue
      if ! grep -qE '(^|[[:space:]])nvidia_drm\.modeset=1([[:space:]]|$)' "$entry"; then
        x sed -i '/^options/s/$/ nvidia_drm.modeset=1/' "$entry"
      fi
    done
  fi
else
  echo "[XOs] Regenerating GRUB with nvidia_drm.modeset=1..."
  if ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub 2>/dev/null; then
    x sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 nvidia_drm.modeset=1\"/' /etc/default/grub
  fi
  x grub-mkconfig -o /boot/grub/grub.cfg
fi

# ────────────────────────────────────────────────
# 7. Enable NVIDIA power modes (performance / balanced / powersave)
# ────────────────────────────────────────────────
echo "[XOs] Enabling NVIDIA Power Management..."
x systemctl enable --now nvidia-powerd.service


# ────────────────────────────────────────────────
# 8. Finish
# ────────────────────────────────────────────────
echo "[XOs] Installation complete. The system will reboot in 5 seconds..."
sleep 5
x reboot
