#!/bin/bash
set -e

echo "[*] RPI-ZERO USB HID INSTALLER STARTING"

# ---------------- ROOT CHECK ----------------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------------- MODEL CHECK ----------------
MODEL=$(tr -d '\0' < /proc/device-tree/model)
if [[ "$MODEL" != *"Pi Zero"* ]]; then
  echo "[-] Unsupported model: $MODEL"
  exit 1
fi
echo "[+] Model OK: $MODEL"

# ---------------- ENABLE DWC2 ----------------
BOOT_CONFIG="/boot/firmware/config.txt"
CMDLINE="/boot/firmware/cmdline.txt"

grep -q "^dtoverlay=dwc2" "$BOOT_CONFIG" || echo "dtoverlay=dwc2" >> "$BOOT_CONFIG"

if ! grep -q "modules-load=dwc2" "$CMDLINE"; then
  sed -i 's/rootwait/rootwait modules-load=dwc2/' "$CMDLINE"
fi

echo "[+] USB gadget kernel support enabled"

# ---------------- SYSTEM PACKAGES ----------------
apt update
apt install -y \
  python3 python3-venv python3-pip \
  libcomposite bluez pulseaudio

# ---------------- HID GADGET SCRIPT ----------------
cat <<'EOF' >/usr/local/bin/hid-gadget.sh
#!/bin/bash
set -e

modprobe libcomposite

CONFIGFS=/sys/kernel/config
GADGET=$CONFIGFS/usb_gadget/hidkbd

if [ -d "$GADGET" ]; then
  exit 0
fi

mkdir -p $GADGET
cd $GADGET

echo 0x1d6b > idVendor
echo 0x0104 > idProduct

mkdir -p strings/0x409
echo "0001" > strings/0x409/serialnumber
echo "RaspberryPi" > strings/0x409/manufacturer
echo "Pi USB Keyboard" > strings/0x409/product

mkdir -p configs/c.1
mkdir -p functions/hid.usb0

echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length

echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' \
> functions/hid.usb0/report_desc

ln -s functions/hid.usb0 configs/c.1/

UDC=$(ls /sys/class/udc | head -n1)
echo "$UDC" > UDC
EOF

chmod +x /usr/local/bin/hid-gadget.sh
echo "[+] HID gadget script installed"

# ---------------- SYSTEMD SERVICE (HID) ----------------
cat <<EOF >/etc/systemd/system/hid-gadget.service
[Unit]
Description=USB HID Gadget
After=systemd-modules-load.service
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hid-gadget.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# ---------------- PYTHON ENV ----------------
INSTALL_DIR="/opt/rpi-hid"
VENV="$INSTALL_DIR/venv"

mkdir -p "$INSTALL_DIR"

if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi

"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install flask rpi-hid

echo "[+] Python environment ready"

# ---------------- WEB SERVICE ----------------
cat <<EOF >/etc/systemd/system/rpi-hid-web.service
[Unit]
Description=RPI HID Web UI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rpi-hid
ExecStart=/opt/rpi-hid/venv/bin/python -m rpi_hid.web.app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ---------------- ENABLE SERVICES ----------------
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable hid-gadget.service
systemctl enable rpi-hid-web.service
systemctl start rpi-hid-web.service

echo ""
echo "[✓] INSTALL COMPLETE"
echo "[✓] USB HID Keyboard ENABLED"
echo "[✓] Web UI RUNNING"
echo ""
echo "REBOOT REQUIRED:"
echo "  sudo reboot"
