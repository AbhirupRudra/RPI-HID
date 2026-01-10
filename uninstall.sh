#!/bin/bash
set -e

echo "[*] RPI-ZERO HID FULL UNINSTALL STARTING"

# ---------------- ROOT CHECK ----------------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------------- STOP & DISABLE SERVICES ----------------
systemctl stop hid-gadget.service 2>/dev/null || true
systemctl stop rpi-hid-web.service 2>/dev/null || true

systemctl disable hid-gadget.service 2>/dev/null || true
systemctl disable rpi-hid-web.service 2>/dev/null || true

rm -f /etc/systemd/system/hid-gadget.service
rm -f /etc/systemd/system/rpi-hid-web.service

systemctl daemon-reexec
systemctl daemon-reload

echo "[+] systemd services removed"

# ---------------- REMOVE USB GADGETS SAFELY ----------------
CONFIGFS="/sys/kernel/config/usb_gadget"

if mount | grep -q configfs; then
  for G in "$CONFIGFS"/*; do
    [ -d "$G" ] || continue

    if [ -f "$G/UDC" ]; then
      echo "" > "$G/UDC" || true
    fi

    find "$G" -type l -delete || true
    rm -rf "$G"
  done
fi

echo "[+] USB gadget configfs cleaned"

# ---------------- REMOVE HID DEVICE NODES ----------------
rm -f /dev/hidg* || true
echo "[+] /dev/hidg* removed"

# ---------------- REMOVE INSTALLED FILES ----------------
rm -f /usr/local/bin/hid-gadget.sh
rm -rf /opt/rpi-hid

echo "[+] Installed HID files removed"

# ---------------- REMOVE PYTHON PACKAGES (OPTIONAL HARD WIPE) ----------------
pip3 uninstall -y rpi-hid flask 2>/dev/null || true

echo "[+] Python HID packages removed"

# ---------------- REVERT BOOT CONFIG ----------------
BOOT_CONFIG="/boot/firmware/config.txt"
CMDLINE="/boot/firmware/cmdline.txt"

# Remove dtoverlay=dwc2
sed -i '/^dtoverlay=dwc2$/d' "$BOOT_CONFIG"

# Remove modules-load=dwc2 from cmdline
sed -i 's/ modules-load=dwc2//g' "$CMDLINE"

echo "[+] Boot configuration reverted"

# ---------------- UNLOAD MODULES ----------------
modprobe -r libcomposite 2>/dev/null || true
modprobe -r dwc2 2>/dev/null || true

echo "[+] Kernel modules unloaded"

# ---------------- FINAL ----------------
echo ""
echo "[✓] HID FULLY REMOVED FROM SYSTEM"
echo "[✓] NO USB GADGETS REMAIN"
echo "[✓] BOOT CONFIG RESTORED"
echo ""
echo "REBOOT REQUIRED:"
echo "  sudo reboot"
