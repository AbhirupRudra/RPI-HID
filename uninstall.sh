#!/bin/bash
set -e

systemctl disable hid-gadget.service || true
rm -f /etc/systemd/system/hid-gadget.service
systemctl daemon-reload

rm -f /usr/local/bin/hid-gadget.sh
rm -rf /sys/kernel/config/usb_gadget/rpi_hid
rm -rf /opt/rpi-hid

echo "[✓] HID gadget removed"
