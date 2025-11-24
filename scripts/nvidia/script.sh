#!/usr/bin/env bash
set -euo pipefail

echo "[XOs] Installing proprietary NVIDIA drivers..."

# ────────────────────────────────────────────────
# 1. Remove open-source drivers (nouveau)
# ────────────────────────────────────────────────
if pacman -Q vulkan-nouveau xf86-video-nouveau &>/dev/null; then
  echo "[XOs] Removing open-source drivers (nouveau)..."
  sudo pacman -Rns --noconfirm vulkan-nouveau xf86-video-nouveau || true
fi

# ────────────────────────────────────────────────
# 2. Install proprietary NVIDIA drivers
# ────────────────────────────────────────────────
echo "[XOs] Installing NVIDIA packages..."
sudo pacman -S --noconfirm --needed nvidia nvidia-utils nvidia-settings opencl-nvidia egl-wayland

# ────────────────────────────────────────────────
# 3. Blacklist nouveau
# ────────────────────────────────────────────────
echo "[XOs] Blacklisting nouveau..."
sudo bash -c 'echo -e "blacklist nouveau\noptions nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf'

# ────────────────────────────────────────────────
# 4. Ensure NVIDIA modules are added to initramfs
# ────────────────────────────────────────────────
echo "[XOs] Updating /etc/mkinitcpio.conf..."
sudo sed -i 's/^MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

# ────────────────────────────────────────────────
# 5. Rebuild initramfs
# ────────────────────────────────────────────────
echo "[XOs] Rebuilding initramfs..."
sudo mkinitcpio -P

# ────────────────────────────────────────────────
# 6. Configure DRM and regenerate GRUB
# ────────────────────────────────────────────────
echo "[XOs] Configuring DRM and regenerating GRUB..."
sudo bash -c 'echo "options nvidia_drm modeset=1" > /etc/modprobe.d/nvidia.conf'

if grep -q 'GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg

# ────────────────────────────────────────────────
# 7. Enable NVIDIA power modes (performance / balanced / powersave)
# ────────────────────────────────────────────────
echo "[XOs] Enabling NVIDIA Power Management..."
sudo systemctl enable --now nvidia-powerd.service


# ────────────────────────────────────────────────
# 8. Finish
# ────────────────────────────────────────────────
echo "[XOs] Installation complete. The system will reboot in 5 seconds..."
sleep 5
sudo reboot
