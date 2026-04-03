#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "tools" / "check_browser_bridge_negative.mjs"


def main() -> int:
    node = shutil.which("node")
    if node is None:
        print("browser bridge negative checks skipped: node not found")
        return 0

    completed = subprocess.run([node, str(SCRIPT)], cwd=ROOT, check=False)
    return int(completed.returncode)


if __name__ == "__main__":
    raise SystemExit(main())
