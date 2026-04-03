# nkl-wasm Usage

This document is the practical guide to building on `nkl-wasm`.

## What The Package Assumes

`nkl-wasm` assumes that your application wants to stay close to the Wasm host
boundary.

That means:

- your app owns structure and state
- your app owns event wiring above the basic host bridge
- your app owns callback dispatch policy
- your app chooses SSR, CSR, SPA-like, or any other shape

If your primary goal is framework ergonomics, components, reactivity, or hidden
lifecycle management, `nkl-wasm` is the wrong layer to compare against those
tools. It is intentionally closer to the Wasm/host boundary.

## Mental Model

`nkl-wasm` is a host-boundary library.

Your application owns:

- UI structure
- routing
- state
- product-specific request ids
- page lifecycle
- higher-level event semantics

`nkl-wasm` owns:

- Wasm alloc/free exports
- pointer/length reconstruction helpers
- callback decoding helpers
- thin Zig wrappers for host capabilities
- a reusable JS runtime for browser-side host bridging

## Typical Zig Setup

The smallest Wasm-side setup looks like this:

```zig
const std = @import("std");
const nkl_wasm = @import("nkl_wasm");

const input_request_id: u32 = 1;

export fn start() void {
    nkl_wasm.dom.setTextById("status", "Ready.");
}

export fn onSubmit() void {
    nkl_wasm.dom.getValueById(input_request_id, "message-input");
}

export fn bridgeReceiveString(kind: u32, request_id: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveString(kind, request_id, ptr, len) catch return;
    if (callback.kind != .input_value) return;
    if (callback.request_id != input_request_id) return;

    nkl_wasm.dom.setTextById("status", callback.text);
}
```

The key point is that your exports stay explicit. `nkl-wasm` does not invent a
hidden runtime above them.

## Memory Boundary

The JS runtime expects your Wasm module to export:

- `memory`
- `allocBytes(len)`
- `freeBytes(ptr, len)`

Those are already provided by the package:

- `nkl_wasm.allocBytes`
- `nkl_wasm.freeBytes`

Pointer/length helpers also live in the package:

- `nkl_wasm.sliceFromPtrLen(...)`
- `nkl_wasm.bytesFromPtrLen(...)`
- `nkl_wasm.ptrLen(...)`

## Callback Handling

The main callback helpers live under `nkl_wasm.callback`.

For string callbacks:

```zig
const callback = nkl_wasm.callback.receiveString(kind, request_id, ptr, len) catch return;
```

For fetch callbacks:

```zig
const callback = nkl_wasm.callback.receiveFetch(request_id, ok, status, ptr, len);
```

These helpers decode the current shared contract without imposing any app-level
dispatch model.

## Browser Capability Wrappers

The package currently provides small wrapper modules for:

- `nkl_wasm.dom`
- `nkl_wasm.storage`
- `nkl_wasm.fetch`
- `nkl_wasm.history`
- `nkl_wasm.timer`
- `nkl_wasm.bridge`

Common examples:

```zig
nkl_wasm.dom.setTextById("status", "Loading...");
nkl_wasm.dom.getValueById(1, "search-input");
nkl_wasm.fetch.fetchText(2, "GET", "/api/data", null);
nkl_wasm.history.push("/docs");
nkl_wasm.timer.setTimeout(1, 60);
```

These are capability wrappers, not app abstractions.

## JS Runtime Setup

The packaged browser bridge lives at
[`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js).

Typical setup:

```js
import { createBrowserBridge } from "./browser_bridge.js";

const bridge = createBrowserBridge({
  wasmUrl: "./app.wasm",
  logSelector: null,
});

const instance = await bridge.instantiate();
if (typeof instance.exports.start === "function") {
  instance.exports.start();
}
```

The JS runtime currently covers:

- Wasm instantiation
- import merging
- string exchange
- DOM operations
- storage operations
- text fetch
- timers
- history/title
- focus/scroll helpers

## Examples

Two shipped examples currently exercise the package:

- [`echo/`](/home/lloyd/dev/home-edge/prj/nkl-wasm/examples/echo)
- [`fetch/`](/home/lloyd/dev/home-edge/prj/nkl-wasm/examples/fetch)

Build and serve them like this:

```bash
zig build example-echo
zig build serve -- --directory zig-out/examples/echo
```

```bash
zig build example-fetch
zig build serve -- --directory zig-out/examples/fetch
```
