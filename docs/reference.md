# nkl-wasm Reference

This document is the reference for the current public package surface.

## Scope Of This Reference

This is the reference for the current usable package surface, not a promise of
a fully frozen long-term frontend framework API. The package is already usable,
but it should still be treated as an early low-level interop library rather
than a mature high-level platform.

## Top-Level Exports

The root module currently exposes:

- `abi`
- `bridge`
- `callback`
- `dom`
- `fetch`
- `history`
- `memory`
- `storage`
- `timer`

Convenience re-exports:

- `StorageKind`
- `StringKind`
- `FetchStatus`
- `PtrLen`
- `allocator`
- `allocBytes`
- `freeBytes`
- `sliceFromPtrLen`
- `bytesFromPtrLen`
- `ptrLen`
- `log`
- `logError`
- `logFmt`
- `nowMs`

## ABI Module

Module: `abi`

Current enums:

- `StorageKind`
  - `.local = 0`
  - `.session = 1`
- `StringKind`
  - `.storage = 1`
  - `.input_value = 2`
- `FetchStatus`
  - `.failed = 0`
  - `.ok = 1`

Export-name constants live under `abi.exports`:

- `alloc_bytes`
- `free_bytes`
- `receive_string`
- `receive_fetch`
- `timer_fired`

## Memory Module

Module: `memory`

Types:

- `PtrLen`

Functions:

- `allocator()`
- `allocBytes(len)`
- `freeBytes(ptr, len)`
- `sliceFromPtrLen(ptr, len)`
- `bytesFromPtrLen(ptr, len)`
- `ptrLen(bytes)`

Behavior notes:

- `allocator()` uses `std.heap.wasm_allocator` on `wasm32`
- native tests fall back to `std.heap.page_allocator`
- zero-length pointer/length inputs return empty slices

## Callback Module

Module: `callback`

Types:

- `StringCallback`
- `FetchCallback`

Functions:

- `stringKindFromInt(value)`
- `receiveString(kind, request_id, ptr, len)`
- `receiveFetch(request_id, ok, status, ptr, len)`

Important error:

- `error.UnknownStringKind`

This module decodes the current callback contract but does not impose app-level
dispatch logic.

## Bridge Module

Module: `bridge`

Primary helpers:

- `log(message)`
- `logError(message)`
- `logFmt(format, args)`
- `nowMs()`

It also owns the raw imported browser capability functions used internally by
the higher-level wrapper modules.

The bridge keeps non-wasm stubs so native package tests can compile and execute
without requiring a browser runtime.

## DOM Module

Module: `dom`

Functions:

- `setTextById(id, text)`
- `setHtmlById(id, html)`
- `setValueById(id, value)`
- `setCheckedById(id, checked)`
- `setAttributeById(id, attr, value)`
- `setDisabledById(id, disabled)`
- `getValueById(request_id, id)`
- `getCheckedById(request_id, id)`
- `toggleClassById(id, class_name, present)`
- `toggleClassOnSelector(selector, class_name, present)`
- `focusById(id)`
- `scrollIntoViewBySelector(selector)`

## Storage Module

Module: `storage`

Functions:

- `set(kind, key, value)`
- `get(kind, request_id, key)`
- `remove(kind, key)`

Storage kind uses `abi.StorageKind`.

## Fetch Module

Module: `fetch`

Functions:

- `fetchText(request_id, method, url, body)`

Current scope:

- text-oriented fetch callback delivery
- request body is optional
- callback result decoding is handled by `callback.receiveFetch(...)`

## History Module

Module: `history`

Functions:

- `push(url)`
- `setDocumentTitle(title)`

## Timer Module

Module: `timer`

Functions:

- `setTimeout(timer_id, delay_ms)`
- `clearTimeout(timer_id)`

## JS Runtime

File:

- [`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js)

Main entrypoint:

- `createBrowserBridge(options = {})`

Returned object:

- `append(message)`
- `instance`
- `imports`
- `instantiate()`
- `readString(ptr, len)`
- `withWasmString(text, fn)`

Current JS-side host imports include:

- log/error
- timing
- DOM writes and reads
- checked-state and attribute helpers
- storage
- text fetch
- timers
- history/title
- focus/scroll helpers

Deferred for now:

- file-input helpers
- upload helpers

Those remain intentionally outside the package until their generic fit is
better proven.
