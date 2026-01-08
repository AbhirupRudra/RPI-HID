#!/bin/bash
set -e

echo "[*] RPI-HID Installer (venv-based) starting..."

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
BOOT_CONFIG="/boot/config.txt"
CMDLINE="/boot/cmdline.txt"

grep -q "dtoverlay=dwc2" $BOOT_CONFIG || echo "dtoverlay=dwc2" >> $BOOT_CONFIG

if ! grep -q "modules-load=dwc2" $CMDLINE; then
  sed -i 's/rootwait/rootwait modules-load=dwc2/' $CMDLINE
fi

echo "[+] USB gadget support configured"

# --- Install system dependencies ---
apt update
apt install -y python3 python3-venv python3-pip

# --- Create install directory ---
INSTALL_DIR="/opt/rpi-hid"
VENV_DIR="$INSTALL_DIR/venv"

mkdir -p $INSTALL_DIR

# --- Create venv if not exists ---
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv $VENV_DIR
  echo "[+] Virtual environment created at $VENV_DIR"
else
  echo "[*] Virtual environment already exists"
fi

# --- Upgrade pip inside venv ---
$VENV_DIR/bin/pip install --upgrade pip

# --- Install rpi-hid inside venv ---
$VENV_DIR/bin/pip install rpi-hid

echo "[+] rpi-hid installed inside venv"

# --- Install HID gadget script ---
install -m 755 scripts/hid-gadget.sh /usr/local/bin/hid-gadget.sh

# --- systemd service for HID gadget ---
cat <<EOF >/etc/systemd/system/hid-gadget.service
[Unit]
Description=USB HID Gadget
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hid-gadget.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hid-gadget.service

echo "[✓] Installation complete"
echo "→ Reboot required"
echo ""
echo "Run HID scripts using:"
echo "sudo $VENV_DIR/bin/python your_script.py"
