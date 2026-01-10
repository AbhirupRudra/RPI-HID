#!/bin/bash
set -e

echo "[*] Installing Python environment for RPI-HID"

# ---------- ROOT CHECK ----------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------- VARIABLES ----------
INSTALL_DIR="/opt/rpi-hid"
VENV_DIR="$INSTALL_DIR/venv"
SERVICE_FILE="/etc/systemd/system/rpi-hid-web.service"

# ---------- SYSTEM PACKAGES ----------
apt update
apt install -y python3 python3-venv python3-pip

# ---------- CREATE INSTALL DIR ----------
mkdir -p "$INSTALL_DIR"
chown -R root:root "$INSTALL_DIR"

# ---------- CREATE VENV ----------
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
  echo "[+] Virtual environment created"
else
  echo "[*] Virtual environment already exists"
fi

# ---------- PIP SETUP ----------
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install rpi-hid flask

echo "[+] Python packages installed (rpi-hid, flask)"

# ---------- SYSTEMD SERVICE ----------
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=RPI HID Web Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$VENV_DIR/bin/python -m rpi_hid.web.app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ---------- ENABLE SERVICE ----------
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable rpi-hid-web.service
systemctl start rpi-hid-web.service

echo ""
echo "[✓] Python HID environment installed"
echo "[✓] Web server running"
echo ""
echo "Web UI:"
echo "  http://<PI-IP>:5000/python"
echo "  http://<PI-IP>:5000/ducky"
