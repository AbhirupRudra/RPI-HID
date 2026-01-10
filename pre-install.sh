#!/bin/bash
set -e

echo "[*] RPI-ZERO PRE-INSTALL STARTING"

# ---------- ROOT CHECK ----------
if [ "$EUID" -ne 0 ]; then
  echo "[-] Run as root"
  exit 1
fi

# ---------- FILE PATHS ----------
CONFIG="/boot/firmware/config.txt"
CMDLINE="/boot/firmware/cmdline.txt"

# ---------- MODEL CHECK ----------
MODEL=$(tr -d '\0' < /proc/device-tree/model)
if [[ "$MODEL" != *"Pi Zero"* ]]; then
  echo "[-] Unsupported model: $MODEL"
  exit 1
fi
echo "[+] Model OK: $MODEL"

# ---------- CONFIG.TXT ----------
if ! grep -q "^dtoverlay=dwc2$" "$CONFIG"; then
  echo "dtoverlay=dwc2" >> "$CONFIG"
  echo "[+] Added dtoverlay=dwc2 to config.txt"
else
  echo "[*] dtoverlay=dwc2 already present"
fi

# ---------- CMDLINE.TXT ----------
# MUST stay single-line
if ! grep -q "modules-load=dwc2" "$CMDLINE"; then
  sed -i 's/rootwait/rootwait modules-load=dwc2/' "$CMDLINE"
  echo "[+] Added modules-load=dwc2 to cmdline.txt"
else
  echo "[*] modules-load=dwc2 already present"
fi

# ---------- FINAL ----------
echo ""
echo "[✓] PRE-INSTALL COMPLETE"
echo "[!] REBOOT REQUIRED for USB gadget support"
echo ""
echo "Run:"
echo "  sudo reboot"
