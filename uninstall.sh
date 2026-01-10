#!/bin/bash
set -e

echo "[*] RPI-ZERO HID FULL UNINSTALL STARTING"

# ---------- ROOT CHECK ----------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------- STOP SERVICES ----------
systemctl stop hid-gadget.service 2>/dev/null || true
systemctl stop rpi-hid-web.service 2>/dev/null || true
systemctl disable hid-gadget.service 2>/dev/null || true
systemctl disable rpi-hid-web.service 2>/dev/null || true

rm -f /etc/systemd/system/hid-gadget.service
rm -f /etc/systemd/system/rpi-hid-web.service

systemctl daemon-reexec
systemctl daemon-reload

echo "[+] systemd services removed"

# ---------- USB GADGET CLEAN ----------
CONFIGFS=/sys/kernel/config/usb_gadget
GADGET=$CONFIGFS/rpi_hid

if [ -d "$GADGET" ]; then
  echo "[*] Removing active USB gadget"

  # 1. Unbind UDC FIRST
  if [ -f "$GADGET/UDC" ]; then
    echo "" > "$GADGET/UDC"
  fi

  # 2. Remove function symlinks
  find "$GADGET/configs" -type l -delete || true

  # 3. Remove functions
  rm -rf "$GADGET/functions" || true

  # 4. Remove configs
  rm -rf "$GADGET/configs" || true

  # 5. Remove strings
  rm -rf "$GADGET/strings" || true

  # 6. Remove gadget
  rmdir "$GADGET" || true
fi

echo "[+] USB gadget removed cleanly"

# ---------- REMOVE DEVICE NODES ----------
rm -f /dev/hidg* || true

# ---------- REMOVE FILES ----------
rm -f /usr/local/bin/hid-gadget.sh
rm -rf /opt/rpi-hid

echo "[+] Installed files removed"

# ---------- PYTHON CLEAN ----------
pip3 uninstall -y rpi-hid flask 2>/dev/null || true

# ---------- REVERT BOOT CONFIG ----------
BOOT_CONFIG="/boot/firmware/config.txt"
CMDLINE="/boot/firmware/cmdline.txt"

sed -i '/^dtoverlay=dwc2$/d' "$BOOT_CONFIG"
sed -i 's/ modules-load=dwc2//g' "$CMDLINE"

echo "[+] Boot config reverted"

# ---------- UNLOAD MODULES ----------
modprobe -r libcomposite 2>/dev/null || true
modprobe -r dwc2 2>/dev/null || true

echo ""
echo "[✓] HID COMPLETELY REMOVED"
echo "[✓] KERNEL CLEAN"
echo "[✓] CONFIGFS CLEAN"
echo ""
echo "REBOOT REQUIRED:"
echo "  sudo reboot"
