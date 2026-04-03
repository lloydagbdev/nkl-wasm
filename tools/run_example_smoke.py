#!/usr/bin/env python3

from __future__ import annotations

from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.request import urlopen
from urllib.error import HTTPError
import contextlib
import functools
import socket
import threading
import sys


ROOT = Path(__file__).resolve().parent.parent
SERVE_ROOT = ROOT / "zig-out" / "examples"

EXPECTED = {
    "/echo/index.html": ("text/html", "nkl-wasm echo"),
    "/echo/app.js": ("text/javascript", "createBrowserBridge"),
    "/echo/browser_bridge.js": ("text/javascript", "createBrowserBridge"),
    "/echo/app.wasm": ("application/wasm", None),
    "/fetch/index.html": ("text/html", "nkl-wasm fetch"),
    "/fetch/app.js": ("text/javascript", "createBrowserBridge"),
    "/fetch/browser_bridge.js": ("text/javascript", "createBrowserBridge"),
    "/fetch/data.txt": ("text/plain", "nkl-wasm fetch example payload"),
    "/fetch/app.wasm": ("application/wasm", None),
}


def find_free_port() -> int:
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def fetch(url: str) -> tuple[int, str, bytes]:
    with urlopen(url, timeout=5) as response:
        status = int(response.status)
        content_type = response.headers.get_content_type()
        body = response.read()
        return status, content_type, body


def main() -> int:
    if not SERVE_ROOT.is_dir():
        print(f"ERROR: missing serve root: {SERVE_ROOT}", file=sys.stderr)
        return 1

    handler = functools.partial(SimpleHTTPRequestHandler, directory=str(SERVE_ROOT))
    port = find_free_port()
    server = ThreadingHTTPServer(("127.0.0.1", port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    failures: list[str] = []

    try:
        base_url = f"http://127.0.0.1:{port}"
        for path, (expected_type, expected_text) in EXPECTED.items():
            url = f"{base_url}{path}"
            try:
                status, content_type, body = fetch(url)
            except HTTPError as err:
                failures.append(f"{path}: unexpected HTTP error {err.code}")
                continue
            except Exception as err:  # noqa: BLE001
                failures.append(f"{path}: request failed: {err}")
                continue

            if status != 200:
                failures.append(f"{path}: expected 200, got {status}")
                continue

            if content_type != expected_type:
                failures.append(f"{path}: expected content type {expected_type!r}, got {content_type!r}")

            if expected_text is not None:
                text = body.decode("utf-8")
                if expected_text not in text:
                    failures.append(f"{path}: expected text not found: {expected_text!r}")

        missing_path = f"{base_url}/fetch/does-not-exist.txt"
        try:
            fetch(missing_path)
            failures.append("/fetch/does-not-exist.txt: expected 404")
        except HTTPError as err:
            if err.code != 404:
                failures.append(f"/fetch/does-not-exist.txt: expected 404, got {err.code}")
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    print("example smoke checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
