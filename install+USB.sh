#!/bin/bash
set -e

echo "[*] RPI-HID + USB Storage Installer (venv-based) starting..."

# --- Root check ---
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# --- Check Pi model ---
MODEL=$(tr -d '\0' < /proc/device-tree/model)
if [[ "$MODEL" != *"Pi Zero"* ]]; then
  echo "[-] Unsupported model: $MODEL"
  echo "    Only Raspberry Pi Zero / Zero 2 W supported"
  exit 1
fi

echo "[+] Detected: $MODEL"

# --- Enable dwc2 overlay ---
BOOT_CONFIG="/boot/firmware/config.txt"
CMDLINE="/boot/firmware/cmdline.txt"

grep -q "dtoverlay=dwc2" $BOOT_CONFIG || echo "dtoverlay=dwc2" >> $BOOT_CONFIG

if ! grep -q "modules-load=dwc2" $CMDLINE; then
  sed -i 's/rootwait/rootwait modules-load=dwc2/' $CMDLINE
fi

echo "[+] USB gadget support configured"

# --- System dependencies ---
apt update
apt install -y python3 python3-venv python3-pip dosfstools

# --- Install directory ---
INSTALL_DIR="/opt/rpi-hid"
VENV_DIR="$INSTALL_DIR/venv"
STORAGE_DIR="/opt/usb-storage"
STORAGE_IMG="$STORAGE_DIR/storage.img"

mkdir -p "$INSTALL_DIR" "$STORAGE_DIR"

# --- Create storage backing file (only once) ---
if [ ! -f "$STORAGE_IMG" ]; then
  echo "[*] Creating USB storage image (256MB)"
  dd if=/dev/zero of="$STORAGE_IMG" bs=1M count=256
  mkfs.vfat "$STORAGE_IMG"
else
  echo "[*] USB storage image already exists"
fi

# --- Create venv ---
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
  echo "[+] Virtual environment created at $VENV_DIR"
else
  echo "[*] Virtual environment already exists"
fi

# --- Upgrade pip ---
"$VENV_DIR/bin/pip" install --upgrade pip

# --- Install rpi-hid ---
"$VENV_DIR/bin/pip" install rpi-hid

echo "[+] rpi-hid installed inside venv"

# --- Install composite HID + Storage gadget script ---
install -m 755 scripts/hid-gadget+USB.sh /usr/local/bin/hid-gadget+USB.sh

# --- systemd service ---
cat <<EOF >/etc/systemd/system/hid-gadget+USB.service
[Unit]
Description=USB HID + Mass Storage Gadget
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hid-gadget+USB.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hid-gadget+USB.service

echo "[✓] Installation complete"
echo "→ Reboot required"
echo ""
echo "After reboot, device will appear as:"
echo " • USB Keyboard"
echo " • USB Flash Drive"
echo ""
echo "Run HID scripts using:"
echo "sudo $VENV_DIR/bin/python your_script.py"
