#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent.parent
ZIG_OUT = ROOT / "zig-out" / "examples"


EXPECTED = {
    "echo": {
        "app.js": "createBrowserBridge",
        "app.wasm": None,
        "browser_bridge.js": "createBrowserBridge",
        "index.html": "nkl-wasm echo",
    },
    "fetch": {
        "app.js": "createBrowserBridge",
        "app.wasm": None,
        "browser_bridge.js": "createBrowserBridge",
        "data.txt": "nkl-wasm fetch example payload",
        "index.html": "nkl-wasm fetch",
    },
}


def main() -> int:
    failures: list[str] = []

    for example_name, files in EXPECTED.items():
        example_dir = ZIG_OUT / example_name
        if not example_dir.is_dir():
            failures.append(f"missing example directory: {example_dir}")
            continue

        for filename, required_text in files.items():
            path = example_dir / filename
            if not path.is_file():
                failures.append(f"missing file: {path}")
                continue

            if path.stat().st_size == 0:
                failures.append(f"empty file: {path}")
                continue

            if required_text is not None:
                text = path.read_text(encoding="utf-8")
                if required_text not in text:
                    failures.append(f"expected text not found in {path}: {required_text!r}")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    print("example asset bundles verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
