# nkl-wasm Usage

This document is the practical guide to becoming productive with `nkl-wasm`
quickly.

The short version is:

1. build a `wasm32-freestanding` Zig executable that imports `nkl_wasm`
2. export a small set of explicit functions such as `start()` and one or more
   callback receivers
3. use the package wrappers for DOM, storage, fetch, timers, and history
4. bootstrap the Wasm module in the browser with
   [`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js)

If you read only one section first, read **Quick Start**.

## Quick Start

### 1. Add the dependency

For a local checkout during development:

```zig
.dependencies = .{
    .nkl_wasm = .{
        .path = "../nkl-wasm",
    },
},
```

### 2. Wire the Wasm build in `build.zig`

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nkl_wasm_dep = b.dependency("nkl_wasm", .{
        .target = target,
        .optimize = optimize,
    });

    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/app_wasm.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "nkl_wasm", .module = nkl_wasm_dep.module("nkl_wasm") },
            },
        }),
    });
    wasm.entry = .disabled;
    wasm.rdynamic = true;
    wasm.import_symbols = true;
    wasm.export_memory = true;
}
```

### 3. Write the smallest possible Wasm-side app

```zig
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

### 4. Bootstrap it in the browser

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

At that point you already have a usable path:

- Zig owns the Wasm app logic
- JS stays a thin host bridge
- browser interactions cross the boundary through explicit exports/imports

## Fastest Path To Something Working

If you want a working baseline immediately, use one of the shipped examples:

```bash
zig build example-echo
zig build serve -- --directory zig-out/examples/echo
```

```bash
zig build example-fetch
zig build serve -- --directory zig-out/examples/fetch
```

```bash
zig build example-ssr-enhance
zig build serve -- --directory zig-out/examples/ssr-enhance
```

```bash
zig build example-csr
zig build serve -- --directory zig-out/examples/csr
```

```bash
zig build example-spa-like
zig build serve -- --directory zig-out/examples/spa-like
```

Use these examples as dependency-style references, not as framework templates.

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
- pointer/length helpers
- callback decoding helpers
- thin capability wrappers for host operations
- a reusable browser bridge for JS-side host bootstrapping

The package reduces repeated host-boundary work. It does not take ownership of
your application architecture.

## The Minimum Runtime Contract

The packaged JS bridge expects these Wasm exports:

- `memory`
- `allocBytes(len)`
- `freeBytes(ptr, len)`

Those three exports are required. If one is missing, bridge instantiation fails
early with a direct error instead of continuing in a partially broken state.

The package already provides:

- `nkl_wasm.allocBytes`
- `nkl_wasm.freeBytes`

Optional callback exports that the JS bridge can call if you define them:

- `bridgeReceiveString(kind, request_id, ptr, len)`
- `bridgeReceiveFetch(request_id, ok, status, ptr, len)`
- `bridgeTimerFired(timer_id)`

You are not required to implement every callback path. Implement only the ones
your app uses.

If an optional callback export is missing, the JS bridge warns and drops that
specific callback path instead of crashing the whole runtime.

## Failure Model

`nkl-wasm` is strict about hard contract errors and forgiving about optional
browser capability gaps.

It fails fast for:

- missing required Wasm exports like `memory`, `allocBytes`, or `freeBytes`
- failure to fetch or instantiate the Wasm module
- calling low-level helpers like `withWasmString(...)` before instantiation

It degrades gracefully where possible for:

- missing optional callback exports such as `bridgeReceiveFetch(...)`
- unavailable storage in restricted browser contexts
- unavailable `history.pushState(...)`
- unavailable `setTimeout(...)`
- missing DOM targets on the current page

In those graceful-failure cases, the bridge prefers warning plus no-op or empty
fallback behavior instead of taking the whole app down.

## Common Workflows

### Reading input values

Request a value:

```zig
nkl_wasm.dom.getValueById(1, "search-input");
```

Receive it later:

```zig
export fn bridgeReceiveString(kind: u32, request_id: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveString(kind, request_id, ptr, len) catch return;
    if (callback.kind != .input_value) return;
    if (callback.request_id != 1) return;

    // callback.text is your input value
}
```

### Updating the DOM

```zig
nkl_wasm.dom.setTextById("status", "Loading...");
nkl_wasm.dom.setHtmlById("preview", "<strong>ok</strong>");
nkl_wasm.dom.setValueById("search-input", "");
nkl_wasm.dom.focusById("search-input");
```

### Fetching text

Start a fetch:

```zig
nkl_wasm.fetch.fetchText(2, "GET", "/api/data", null);
```

Receive the result:

```zig
export fn bridgeReceiveFetch(request_id: u32, ok: u32, status: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveFetch(request_id, ok, status, ptr, len) catch return;
    if (callback.request_id != 2) return;

    if (!callback.ok()) {
        nkl_wasm.dom.setTextById("status", "Fetch failed.");
        return;
    }

    nkl_wasm.dom.setTextById("status", callback.text);
}
```

Like `receiveString(...)`, `receiveFetch(...)` now rejects malformed host
payloads such as invalid status-kind values or non-zero lengths paired with a
null pointer.

### Using storage

```zig
nkl_wasm.storage.set(.local, "theme", "dark");
nkl_wasm.storage.get(.local, 3, "theme");
nkl_wasm.storage.remove(.session, "draft");
```

Storage reads come back through `bridgeReceiveString(...)` with
`callback.kind == .storage`.

### Using timers

```zig
nkl_wasm.timer.setTimeout(1, 60);
```

Then:

```zig
export fn bridgeTimerFired(timer_id: u32) void {
    if (timer_id != 1) return;
    // do work
}
```

## What Each Module Is For

- `nkl_wasm.memory`
  Low-level pointer/length and alloc/free helpers.
- `nkl_wasm.abi`
  Shared enums and export-name constants used at the boundary.
- `nkl_wasm.callback`
  Helpers for decoding host-to-Wasm callback payloads.
- `nkl_wasm.bridge`
  The lowest-level Zig-side host bridge layer.
- `nkl_wasm.dom`
  Thin wrappers for DOM-oriented host operations.
- `nkl_wasm.storage`
  Thin wrappers for local/session storage operations.
- `nkl_wasm.fetch`
  Thin wrappers for fetch-driven text callbacks.
- `nkl_wasm.history`
  Thin wrappers for history push and document title updates.
- `nkl_wasm.timer`
  Thin wrappers for timeout scheduling and clearing.

If you need the exact exported names or function list, use
[`reference.md`](/home/lloyd/dev/home-edge/prj/nkl-wasm/docs/reference.md).

## JS Runtime Details

The packaged browser bridge lives at
[`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js).

It currently handles:

- Wasm instantiation
- import merging
- string exchange
- DOM operations
- storage operations
- text fetch
- timers
- history/title
- focus/scroll helpers

It also owns the package's current host-side robustness policy:

- validate required Wasm exports during instantiation
- warn and continue when optional browser features are unavailable
- return empty results or drop optional callbacks when there is no safe
  stronger fallback

It intentionally does not try to become your app runtime.

## Verification

Useful commands:

```bash
zig build test
```

```bash
zig build example-check
```

```bash
zig build example-smoke
```

```bash
zig build bridge-js-check
```

```bash
zig build example-interaction
```

```bash
zig build verify
```

`zig build verify` is the current highest-signal package verification command.
It currently covers:

- Zig unit tests
- installed example bundle verification
- JS bridge negative-path checks
- example interaction checks under a minimal DOM harness
- served example smoke checks
