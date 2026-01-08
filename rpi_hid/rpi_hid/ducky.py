import time
from .keyboard import Keyboard
from .utils import pause

class DuckyInterpreter:
    def __init__(self, delay=0.02):
        self.kbd = Keyboard(delay)
        self.last_command = None

    def run_line(self, line):
        line = line.strip()

        if not line or line.startswith("REM"):
            return

        parts = line.split()
        cmd = parts[0].upper()
        args = parts[1:]

        # STRING
        if cmd == "STRING":
            text = line[len("STRING "):]
            self.kbd.type(text)
            self.last_command = ("STRING", text)

        # DELAY (milliseconds)
        elif cmd == "DELAY":
            ms = int(args[0])
            time.sleep(ms / 1000)

        # SINGLE KEYS
        elif cmd in ("ENTER", "TAB", "SPACE"):
            self.kbd.press(cmd)
            self.last_command = ("PRESS", cmd)

        # KEY COMBINATIONS
        elif cmd in ("CTRL", "ALT", "SHIFT", "GUI"):
            combo = [cmd] + [a.upper() for a in args]
            self.kbd.press(*combo)
            self.last_command = ("PRESS", combo)

        # REPEAT
        elif cmd == "REPEAT":
            count = int(args[0])
            if self.last_command:
                for _ in range(count):
                    if self.last_command[0] == "STRING":
                        self.kbd.type(self.last_command[1])
                    elif self.last_command[0] == "PRESS":
                        if isinstance(self.last_command[1], list):
                            self.kbd.press(*self.last_command[1])
                        else:
                            self.kbd.press(self.last_command[1])

        else:
            raise ValueError(f"Unsupported DuckyScript command: {cmd}")

    def run_script(self, script_text):
        for line in script_text.splitlines():
            self.run_line(line)

    def run_file(self, filepath):
        with open(filepath, "r") as f:
            for line in f:
                self.run_line(line)

    def close(self):
        self.kbd.close()
