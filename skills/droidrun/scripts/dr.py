#!/opt/droidrun/bin/python3
"""Droidrun wrapper — always uses Gibson's primary device (20429563B4043064)"""
import sys, subprocess

DEVICE = "20429563B4043064"

if __name__ == "__main__":
    cmd = [sys.executable, "-m", "droidrun"] + sys.argv[1:]
    # Inject device if not already specified
    if "-d" not in " ".join(sys.argv[1:]) and "--device" not in " ".join(sys.argv[1:]):
        cmd.extend(["-d", DEVICE])
    result = subprocess.run(cmd)
    sys.exit(result.returncode)
