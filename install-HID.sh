#!/bin/bash
set -e

echo "[*] Installing USB Keyboard HID gadget"

# ---------- ROOT CHECK ----------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------- LOAD MODULE ----------
modprobe libcomposite

# ---------- ENSURE CONFIGFS ----------
if ! mountpoint -q /sys/kernel/config; then
  mount -t configfs none /sys/kernel/config
fi

cd /sys/kernel/config/usb_gadget || {
  echo "[-] usb_gadget not available (reboot required?)"
  exit 1
}

# ---------- CREATE GADGET ----------
if [ ! -d hidkbd ]; then
  mkdir hidkbd
fi
cd hidkbd

# ---------- USB IDS ----------
echo 0x1d6b > idVendor
echo 0x0104 > idProduct

# ---------- STRINGS ----------
mkdir -p strings/0x409
echo "0001" > strings/0x409/serialnumber
echo "RaspberryPi" > strings/0x409/manufacturer
echo "Pi Keyboard HID" > strings/0x409/product

# ---------- CONFIG + FUNCTION ----------
mkdir -p configs/c.1
mkdir -p functions/hid.usb0

# ---------- HID PARAMETERS ----------
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length

# ---------- HID REPORT DESCRIPTOR ----------
echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' \
> functions/hid.usb0/report_desc

# ---------- LINK FUNCTION ----------
if [ ! -L configs/c.1/hid.usb0 ]; then
  ln -s functions/hid.usb0 configs/c.1/
fi

# ---------- BIND UDC ----------
UDC=$(ls /sys/class/udc | head -n1)
if [ -z "$UDC" ]; then
  echo "[-] No UDC found"
  exit 1
fi

if [ ! -s UDC ]; then
  echo "$UDC" > UDC
fi

echo "[✓] USB Keyboard HID installed"
echo "[✓] Device node: /dev/hidg0"
