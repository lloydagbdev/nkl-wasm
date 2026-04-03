#!/usr/bin/env python3

from __future__ import annotations

from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError
import contextlib
import functools
import socket
import threading
import sys


ROOT = Path(__file__).resolve().parent.parent
SERVE_ROOT = ROOT / "zig-out" / "examples"

EXPECTED = {
    "/echo/index.html": ({"text/html"}, "nkl-wasm echo"),
    "/echo/app.js": ({"text/javascript", "application/javascript"}, "createBrowserBridge"),
    "/echo/browser_bridge.js": ({"text/javascript", "application/javascript"}, "createBrowserBridge"),
    "/echo/app.wasm": ("application/wasm", None),
    "/fetch/index.html": ({"text/html"}, "nkl-wasm fetch"),
    "/fetch/app.js": ({"text/javascript", "application/javascript"}, "createBrowserBridge"),
    "/fetch/browser_bridge.js": ({"text/javascript", "application/javascript"}, "createBrowserBridge"),
    "/fetch/data.txt": ({"text/plain"}, "nkl-wasm fetch example payload"),
    "/fetch/app.wasm": ("application/wasm", None),
}


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args: object) -> None:
        _ = format
        _ = args


def find_free_port() -> int:
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def fetch(url: str, method: str = "GET") -> tuple[int, str, bytes]:
    request = Request(url, method=method)
    with urlopen(request, timeout=5) as response:
        status = int(response.status)
        content_type = response.headers.get_content_type()
        body = response.read()
        return status, content_type, body


def main() -> int:
    if not SERVE_ROOT.is_dir():
        print(f"ERROR: missing serve root: {SERVE_ROOT}", file=sys.stderr)
        return 1

    handler = functools.partial(QuietHandler, directory=str(SERVE_ROOT))
    port = find_free_port()
    server = ThreadingHTTPServer(("127.0.0.1", port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    failures: list[str] = []

    try:
        base_url = f"http://127.0.0.1:{port}"
        for path, (expected_types, expected_text) in EXPECTED.items():
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

            if isinstance(expected_types, str):
                expected_types = {expected_types}
            if content_type not in expected_types:
                failures.append(f"{path}: expected content type in {sorted(expected_types)!r}, got {content_type!r}")

            if expected_text is not None:
                text = body.decode("utf-8")
                if expected_text not in text:
                    failures.append(f"{path}: expected text not found: {expected_text!r}")

            try:
                head_status, head_content_type, head_body = fetch(url, method="HEAD")
            except HTTPError as err:
                failures.append(f"{path}: unexpected HEAD HTTP error {err.code}")
                continue
            except Exception as err:  # noqa: BLE001
                failures.append(f"{path}: HEAD request failed: {err}")
                continue

            if head_status != 200:
                failures.append(f"{path}: expected HEAD 200, got {head_status}")
            if head_content_type not in expected_types:
                failures.append(f"{path}: expected HEAD content type in {sorted(expected_types)!r}, got {head_content_type!r}")
            if head_body not in (b"",):
                failures.append(f"{path}: expected empty HEAD body")

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
