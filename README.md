# RPI-HID — Raspberry Pi Zero USB Keyboard HID with Web Control

Turn a **Raspberry Pi Zero / Zero 2 W** into a **USB Keyboard HID device** that can inject keystrokes into a connected computer, with an optional **web interface** for live control.

This project uses the **Linux USB Gadget framework** and is designed to be:
- modular
- reproducible
- cleanly installable / uninstallable

---

## 🚀 What This Project Does

After installation, your Raspberry Pi Zero / Zero 2 W:

- Appears to a host PC as a **standard USB keyboard**
- Creates `/dev/hidg0` for HID report injection
- Can be controlled via:
  - Python scripts
  - Web UI (Flask)
- Survives reboot (when installed correctly)

---

## 🧩 Outcome Device Behavior

| Property | Result |
|-------|-------|
| USB Class | HID (Keyboard) |
| Host OS Detection | Generic USB Keyboard |
| Driver Needed | ❌ None |
| Keystroke Injection | ✅ |
| Mouse Support | ❌ (keyboard only, by default) |
| Bluetooth | ❌ |
| Persistence | ✅ (after reboot) |

---

## 🖥 Supported Hardware

- ✅ Raspberry Pi Zero
- ✅ Raspberry Pi Zero 2 W
- ❌ Pi 3 / Pi 4 / Pi 5 (not USB-OTG device mode)

⚠️ **Use the USB (OTG) port**, not the PWR IN port.

---

## 🧠 How It Works (High Level)

```

Python / Web UI
↓
/dev/hidg0
↓
USB Gadget (libcomposite + configfs)
↓
Target PC sees: USB Keyboard

```

---

## 📦 Repository Structure

```

.
├── pre-install.sh        # Enables dwc2 (USB gadget support)
├── install-HID.sh        # Creates USB HID keyboard gadget
├── install-python.sh     # Python venv + web server
├── uninstall.sh          # Full cleanup / rollback
├── README.md

````

---

## ⚙️ Installation (Correct Order)

### 1️⃣ Pre-install (ONE TIME)
Enables USB gadget support at boot.

```bash
sudo chmod +x pre-install.sh
sudo ./pre-install.sh
sudo reboot
````

---

### 2️⃣ Install USB Keyboard HID

Creates the HID gadget and binds it to the USB controller.

```bash
sudo chmod +x install-HID.sh
sudo ./install-HID.sh
```

Verify:

```bash
ls /dev/hidg0
```

---

### 3️⃣ Install Python + Web Interface

Creates a virtual environment and starts the web server.

```bash
sudo chmod +x install-python.sh
sudo ./install-python.sh
```

---

## 🌐 Web Interface

After installation, access from another device:

```
http://<PI-IP>:5000/python
http://<PI-IP>:5000/ducky
```

Features:

* Live keystroke injection
* Script-based input
* Remote control over LAN

---

## ⌨️ Manual HID Test

Send a single key (`A`) to the host PC:

```bash
sudo bash -c 'echo -ne "\x00\x00\x04\x00\x00\x00\x00\x00" > /dev/hidg0'
sudo bash -c 'echo -ne "\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/hidg0'
```

---

## 🧹 Uninstall / Full Cleanup

Removes:

* USB gadget
* systemd services
* Python environment
* dwc2 boot config

```bash
sudo chmod +x uninstall.sh
sudo ./uninstall.sh
sudo reboot
```

After reboot:

```bash
ls /dev/hidg*
# should show nothing
```

---

## ⚠️ Important Notes

* This project **does NOT** use Bluetooth HID
* `libcomposite` is a **kernel module**, not an apt package
* `configfs` must be mounted for gadget inspection
* Re-running HID creation without uninstalling can cause kernel errors

---

## 🔒 Legal & Ethical Notice

This tool **injects keystrokes** into a connected system.

Use **ONLY** on:

* your own machines
* test environments
* devices you have explicit permission to control

Unauthorized use may be illegal.

---

## 🛠 Future Extensions

Planned / possible additions:

* Keyboard + Mouse combo
* DuckyScript engine
* HTTPS + authentication
* Payload auto-execution
* Multi-profile HID modes

---

## ✅ Status

* ✔ Stable on Raspberry Pi Zero 2 W
* ✔ Clean install / uninstall
* ✔ Reboot-safe
* ✔ No external drivers required

---

## 📄 License

MIT License — use responsibly.
