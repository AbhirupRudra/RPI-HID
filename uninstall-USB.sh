#!/bin/bash
set -e

echo "[*] Removing HID + USB gadget setup..."

# --- Stop & disable service ---
systemctl stop "hid-gadget-USB.service" 2>/dev/null || true
systemctl disable "hid-gadget-USB.service" 2>/dev/null || true

# --- Remove service file ---
rm -f /etc/systemd/system/hid-gadget-USB.service
systemctl daemon-reload

# --- Remove gadget script ---
rm -f /usr/local/bin/hid-gadget-USB.sh

# --- Remove USB gadget from configfs (if exists) ---
if [ -d /sys/kernel/config/usb_gadget/rpi_composite ]; then
  echo "" > /sys/kernel/config/usb_gadget/rpi_composite/UDC 2>/dev/null || true
  rm -rf /sys/kernel/config/usb_gadget/rpi_composite
fi

# --- Remove install directories ---
rm -rf /opt/rpi-hid
rm -rf /opt/usb-storage

echo "[✓] HID + USB gadget completely removed"
echo "→ Reboot recommended"
