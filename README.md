# RPI-HID Setup

One-command installer to configure a **Raspberry Pi Zero / Zero 2 W** as a **USB HID keyboard** and install the **rpi-hid** Python library inside a dedicated virtual environment.

This repository handles:
- USB gadget (HID) configuration
- Required kernel and boot settings
- Creation of `/dev/hidg0`
- Installation of `rpi-hid` in an isolated Python environment

---

## Supported Hardware

- Raspberry Pi Zero
- Raspberry Pi Zero 2 W

> ⚠️ Raspberry Pi 3 / 4 / 5 do **not** support USB gadget mode.

---

## Requirements

- Raspberry Pi OS (Lite recommended)
- Internet connection
- Root access

---

## Clone the Repository

```bash
git clone https://github.com/AbhirupRudra/RPI-HID.git
cd RPI-HID
```

---

## Installation

Run the installer **once**:

```bash
sudo bash install.sh
```

When installation completes, reboot:

```bash
sudo reboot
```

---

## Verify Installation

After reboot, plug the Pi into the **USB DATA (OTG) port**.

Verify that the HID device exists:

```bash
ls /dev/hidg0
```

If the file exists, the HID gadget is active.

---

## Python Environment

The installer creates a dedicated virtual environment at:

```
/opt/rpi-hid/venv
```

The `rpi-hid` library is installed **only inside this environment**.

---

## Running HID Scripts

All HID scripts **must be run using the venv Python** and **with sudo**:

```bash
sudo /opt/rpi-hid/venv/bin/python your_script.py
```

Example:

```bash
sudo /opt/rpi-hid/venv/bin/python test.py
```

---

## Installing the Python Library Manually (Optional)

If you only want the Python library:

```bash
pip install rpi-hid
```

(Requires HID gadget setup to already be configured.)

---

## Uninstall

To remove the HID gadget and Python environment:

```bash
sudo bash uninstall.sh
```

---

## Notes

* Use the **USB DATA (OTG)** port, not the power-only port.
* HID access requires root privileges.
* The installer is safe to re-run.
* No system Python packages are modified.

---

## License

MIT License

---

## Author

**Abhirup Rudra**

---

## Disclaimer

This project is intended for:

* USB HID experimentation
* Automation on owned or authorized systems
* Educational and research use

Users are responsible for complying with applicable laws and policies.

```