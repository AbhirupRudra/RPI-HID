from .device import HIDDevice
from .keycodes import KEY, MOD, SHIFTED
from .utils import pause

class Keyboard:
    def __init__(self, delay=0.02):
        self.dev = HIDDevice(delay)

    # 1️⃣ type("string")
    def type(self, text, pause_after=0.1):
        for ch in text:
            if ch.isupper():
                self.dev.send(MOD["SHIFT"], KEY[ch.lower()])
            elif ch in KEY:
                self.dev.send(0, KEY[ch])
            elif ch in SHIFTED:
                mod, base = SHIFTED[ch]
                self.dev.send(MOD[mod], KEY[base])
        pause(pause_after)

    # 2️⃣ press("CTRL","ALT","DEL")
    def press(self, *keys):
        if not keys:
            raise ValueError("At least one key required")

        modifier = 0
        main_key = None

        for k in keys:
            k = k.strip()

            # Modifier keys
            if k.upper() in MOD:
                modifier |= MOD[k.upper()]

            # Single letter (r, a, z, etc.)
            elif len(k) == 1 and k.lower() in KEY:
                main_key = KEY[k.lower()]

            # Named keys (ENTER, TAB, etc.)
            elif k.upper() in KEY:
                main_key = KEY[k.upper()]

        if main_key is None:
            raise ValueError("No valid key provided")

        self.dev.send(modifier, main_key)


    # 3️⃣ spamText(n, "string")
    def spamText(self, text, n=10):
        for _ in range(n):
            self.type(text)

    # Extra useful functions
    def enter(self):
        self.dev.send(0, KEY["ENTER"])

    def winRun(self, command):
        self.press("GUI", "r")
        pause(0.3)
        self.type(command)
        self.enter()

    def close(self):
        self.dev.close()
