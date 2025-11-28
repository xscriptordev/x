#!/usr/bin/env bash
set -euo pipefail

echo "[XOs] Installing proprietary NVIDIA drivers with GNOME power modes..."

# ────────────────────────────────────────────────
# 1. Remove open-source drivers (nouveau)
# ────────────────────────────────────────────────
if pacman -Q vulkan-nouveau xf86-video-nouveau &>/dev/null; then
  echo "[XOs] Removing nouveau..."
  x pacman -Rns --noconfirm vulkan-nouveau xf86-video-nouveau || true
fi

# ────────────────────────────────────────────────
# 2. Install NVIDIA packages
# ────────────────────────────────────────────────
echo "[XOs] Installing NVIDIA packages..."
x pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings opencl-nvidia egl-wayland libva-nvidia-driver

# ────────────────────────────────────────────────
# 3. Blacklist nouveau
# ────────────────────────────────────────────────
echo "[XOs] Blacklisting nouveau..."
cat << 'EOF' | x tee /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

# ────────────────────────────────────────────────
# 4. Enable Early KMS for NVIDIA (required for GNOME power modes)
# ────────────────────────────────────────────────
echo "[XOs] Enabling early KMS..."
cat << 'EOF' | x tee /etc/modprobe.d/nvidia-earlykms.conf
options nvidia_drm modeset=1
EOF

# Ensure MODULES are set correctly in mkinitcpio
x sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

# ────────────────────────────────────────────────
# 5. Enable NVIDIA Dynamic Power Management
# ────────────────────────────────────────────────
echo "[XOs] Enabling Dynamic Power Management..."
cat << 'EOF' | x tee /etc/modprobe.d/nvidia-power.conf
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

# ────────────────────────────────────────────────
# 6. Create udev rule so GNOME can use nvidia-powerd
# ────────────────────────────────────────────────
echo "[XOs] Adding udev rule for power modes..."
cat << 'EOF' | x tee /etc/udev/rules.d/80-nvidia-power-modes.rules
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", RUN+="/usr/bin/nvidia-powerd"
EOF

# ────────────────────────────────────────────────
# 7. Rebuild initramfs
# ────────────────────────────────────────────────
echo "[XOs] Rebuilding initramfs..."
x mkinitcpio -P

# ────────────────────────────────────────────────
# 8. Regenerate GRUB
# ────────────────────────────────────────────────
echo "[XOs] Updating GRUB..."
x sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub || true
x grub-mkconfig -o /boot/grub/grub.cfg

# ────────────────────────────────────────────────
# 9. Enable NVIDIA power daemon
# ────────────────────────────────────────────────
echo "[XOs] Enabling nvidia-powerd service..."
x systemctl enable --now nvidia-powerd.service

# ────────────────────────────────────────────────
# 10. Done
# ────────────────────────────────────────────────
echo "[XOs] NVIDIA installation complete. Rebooting in 5 seconds..."
sleep 5
x reboot
