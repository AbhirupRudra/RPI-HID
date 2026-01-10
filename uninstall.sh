#!/bin/bash
set -e

echo "[*] RPI-HID FULL UNINSTALL STARTING"

# ---------- ROOT CHECK ----------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------- VARIABLES ----------
GADGET_NAME="hidkbd"
GADGET_PATH="/sys/kernel/config/usb_gadget/$GADGET_NAME"
INSTALL_DIR="/opt/rpi-hid"
BOOT_CONFIG="/boot/firmware/config.txt"
CMDLINE="/boot/firmware/cmdline.txt"

# ---------- STOP & REMOVE SERVICES ----------
systemctl stop rpi-hid-web.service 2>/dev/null || true
systemctl disable rpi-hid-web.service 2>/dev/null || true
rm -f /etc/systemd/system/rpi-hid-web.service

systemctl daemon-reexec
systemctl daemon-reload

echo "[+] systemd services removed"

# ---------- MOUNT CONFIGFS IF NEEDED ----------
if ! mountpoint -q /sys/kernel/config; then
  mount -t configfs none /sys/kernel/config || true
fi

# ---------- REMOVE USB HID GADGET (CORRECT ORDER) ----------
if [ -d "$GADGET_PATH" ]; then
  echo "[*] Removing USB HID gadget"

  cd "$GADGET_PATH"

  # 1. Unbind UDC (ignore harmless errors)
  if [ -f UDC ]; then
    echo "" > UDC 2>/dev/null || true
  fi

  # 2. Remove function symlinks
  find configs -type l -delete 2>/dev/null || true

  # 3. Remove functions
  rm -rf functions 2>/dev/null || true

  # 4. Remove configs
  rm -rf configs 2>/dev/null || true

  # 5. Remove strings
  rm -rf strings 2>/dev/null || true

  # 6. Remove gadget directory
  cd ..
  rmdir "$GADGET_NAME" 2>/dev/null || true
fi

echo "[+] USB gadget removed"

# ---------- REMOVE DEVICE NODES ----------
rm -f /dev/hidg* 2>/dev/null || true
echo "[+] /dev/hidg* removed"

# ---------- REMOVE PROJECT FILES ----------
rm -rf "$INSTALL_DIR"
rm -f /usr/local/bin/hid-gadget.sh 2>/dev/null || true
echo "[+] Project files removed"

# ---------- REMOVE PYTHON PACKAGES (OPTIONAL HARD CLEAN) ----------
pip3 uninstall -y rpi-hid flask 2>/dev/null || true
echo "[+] Python packages removed"

# ---------- REVERT BOOT CONFIG (dwc2) ----------
sed -i '/^dtoverlay=dwc2$/d' "$BOOT_CONFIG" 2>/dev/null || true
sed -i 's/ modules-load=dwc2//g' "$CMDLINE" 2>/dev/null || true
echo "[+] Boot configuration reverted"

# ---------- UNLOAD KERNEL MODULES ----------
modprobe -r libcomposite 2>/dev/null || true
modprobe -r dwc2 2>/dev/null || true
echo "[+] Kernel modules unloaded"

# ---------- FINAL ----------
echo ""
echo "[✓] RPI-HID FULLY UNINSTALLED"
echo "[✓] USB HID REMOVED"
echo "[✓] SYSTEM CLEAN"
echo ""
echo "REBOOT REQUIRED:"
echo "  sudo reboot"
