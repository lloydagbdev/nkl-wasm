# nkl-wasm Reference

This document is the package reference for the current public surface.

The goal of this file is not only to list names. It is to make clear what each
library element actually is, what role it plays in the package, and when you
would reach for it.

## Scope Of This Reference

This is the reference for the current usable package surface, not a promise of
a fully frozen long-term frontend framework API. The package is already usable,
but it should still be treated as an early low-level interop library rather
than a mature high-level platform.

## Package Map

At a high level, the package is split into five conceptual layers.

### 1. Shared contract layer

This is where the package describes the boundary itself.

- `abi`
  Shared enums and exported symbol-name constants.

### 2. Raw memory boundary layer

This is where the package handles the low-level Wasm memory exchange.

- `memory`
  Alloc/free helpers and pointer/length reconstruction utilities.

### 3. Callback decoding layer

This is where the package turns raw callback arguments into structured values.

- `callback`
  Decode string and fetch callback payloads.

### 4. Raw host bridge layer

This is the thin Zig wrapper directly over host imports.

- `bridge`
  Logging, timing, and internal raw host-call wrappers.

### 5. Capability wrapper layer

These are the modules that group host operations by purpose.

- `dom`
- `storage`
- `fetch`
- `history`
- `timer`

If you are starting from scratch, the modules you will most often use directly
are usually:

- `dom`
- `fetch`
- `storage`
- `timer`
- `callback`

## Top-Level Exports

The root module currently exposes these module namespaces:

- `abi`
- `bridge`
- `callback`
- `dom`
- `fetch`
- `history`
- `memory`
- `storage`
- `timer`

It also re-exports a few convenience names:

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

Those re-exports exist so common boundary helpers can be accessed directly from
`nkl_wasm` without always qualifying through the deeper module names.

## ABI Module

Module: `abi`

What it is:

- the package's shared contract vocabulary

What it is for:

- naming the meaning of callback and storage kinds
- centralizing the current exported callback/allocation symbol names

### Enums

`StorageKind`

- `.local = 0`
- `.session = 1`

Use it when calling storage wrappers and when interpreting storage-related
callback semantics.

`StringKind`

- `.storage = 1`
- `.input_value = 2`

Use it when decoding `bridgeReceiveString(...)` traffic.

`FetchStatus`

- `.failed = 0`
- `.ok = 1`

This is a small current status enum representing the fetch callback contract.

### Export-name constants

Under `abi.exports`:

- `alloc_bytes`
- `free_bytes`
- `receive_string`
- `receive_fetch`
- `timer_fired`

These are string constants for the current Wasm export names expected by the JS
runtime.

## Memory Module

Module: `memory`

What it is:

- the low-level Wasm memory boundary helper layer

What it is for:

- allocating JS-exchange buffers in Wasm memory
- freeing those buffers after the host is done with them
- reconstructing slices from raw pointer/length values

### Types

`PtrLen`

An `extern struct` with:

- `ptr: usize`
- `len: usize`

Use it when you want to carry pointer-plus-length information as one explicit
value instead of two separate integers.

### Functions

`allocator()`

- returns `std.heap.wasm_allocator` on `wasm32`
- returns `std.heap.page_allocator` on native targets for testing

`allocBytes(len)`

- allocates `len` bytes
- returns the pointer as `usize`
- returns `0` on allocation failure

`freeBytes(ptr, len)`

- frees a buffer previously allocated for host exchange
- does nothing for zero pointer or zero length

`sliceFromPtrLen(ptr, len)`

- reconstructs a `[]const u8` from a pointer and length
- returns `""` for zero-length input

`checkedSliceFromPtrLen(ptr, len)`

- like `sliceFromPtrLen(...)`, but rejects non-zero lengths paired with a null
  pointer

`bytesFromPtrLen(ptr, len)`

- reconstructs a mutable `[]u8`
- returns an empty slice for zero-length input

`checkedBytesFromPtrLen(ptr, len)`

- like `bytesFromPtrLen(...)`, but rejects non-zero lengths paired with a null
  pointer

`ptrLen(bytes)`

- turns a slice into a `PtrLen` value

## Callback Module

Module: `callback`

What it is:

- the callback decoding layer for host-to-Wasm payload delivery

What it is for:

- turning raw callback arguments into typed values
- centralizing the current callback interpretation rules

This module intentionally does not decide what your app should do with a
callback. It only decodes the boundary.

### Types

`StringCallback`

Fields:

- `kind: abi.StringKind`
- `request_id: u32`
- `text: []const u8`

`FetchCallback`

Fields:

- `request_id: u32`
- `status_kind: abi.FetchStatus`
- `status: u32`
- `text: []const u8`

Methods:

- `ok()`
  Returns true when `status_kind == .ok`.

### Functions

`stringKindFromInt(value)`

- converts a raw integer into `abi.StringKind`
- returns `error.UnknownStringKind` for unknown values

`receiveString(kind, request_id, ptr, len)`

- decodes a string callback into `StringCallback`

`receiveFetch(request_id, ok, status, ptr, len)`

- decodes a fetch callback into `FetchCallback`
- rejects unknown fetch status-kind integers
- rejects non-zero lengths paired with a null pointer

### Error

- `error.UnknownStringKind`
- `error.UnknownFetchStatus`
- `error.InvalidPtrLen`

## Bridge Module

Module: `bridge`

What it is:

- the lowest-level public Zig-side host bridge layer

What it is for:

- common logging and timing helpers
- internal raw wrappers used by the more focused capability modules

Most application code should prefer `dom`, `fetch`, `storage`, `history`, and
`timer` rather than using the lower-level raw helpers directly.

### Main helpers

`log(message)`

- sends a message to the host log path

`logError(message)`

- sends a message to the host error log path

`logFmt(format, args)`

- small formatted logging helper built on top of `log(...)`

`nowMs()`

- returns the host monotonic-ish millisecond time source currently exposed by
  the browser bridge

### Important note

The bridge keeps native no-op fallbacks so the package can still compile and
run unit tests on non-Wasm targets.

## DOM Module

Module: `dom`

What it is:

- a capability-oriented wrapper for DOM-related host operations

What it is for:

- updating elements
- reading input values
- toggling classes
- focusing elements
- scrolling elements into view

### Functions

Write-oriented:

- `setTextById(id, text)`
- `setHtmlById(id, html)`
- `setValueById(id, value)`
- `setCheckedById(id, checked)`
- `setAttributeById(id, attr, value)`
- `setDisabledById(id, disabled)`

Read-oriented:

- `getValueById(request_id, id)`
- `getCheckedById(request_id, id)`

Class and focus helpers:

- `toggleClassById(id, class_name, present)`
- `toggleClassOnSelector(selector, class_name, present)`
- `focusById(id)`
- `scrollIntoViewBySelector(selector)`

### Behavior model

Read helpers do not return values synchronously. They trigger host work and
deliver the result later through your callback exports.

## Storage Module

Module: `storage`

What it is:

- a capability-oriented wrapper for browser storage access

What it is for:

- localStorage/sessionStorage reads and writes

### Functions

- `set(kind, key, value)`
- `get(kind, request_id, key)`
- `remove(kind, key)`

### Notes

- `kind` uses `abi.StorageKind`
- reads come back through `bridgeReceiveString(...)`

## Fetch Module

Module: `fetch`

What it is:

- a capability-oriented wrapper for text fetch requests

What it is for:

- starting fetches whose results are delivered back through
  `bridgeReceiveFetch(...)`

### Functions

- `fetchText(request_id, method, url, body)`

### Current scope

- text-oriented fetch callback delivery
- optional request body
- no higher-level JSON/object abstraction

If you want JSON, fetch text and parse it in Zig yourself.

## History Module

Module: `history`

What it is:

- a small wrapper for history/title browser operations

### Functions

- `push(url)`
- `setDocumentTitle(title)`

## Timer Module

Module: `timer`

What it is:

- a small wrapper for timeout scheduling

### Functions

- `setTimeout(timer_id, delay_ms)`
- `clearTimeout(timer_id)`

### Notes

Timer delivery returns to your Wasm module through `bridgeTimerFired(...)` if
you export it.

## JS Runtime

File:

- [`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js)

What it is:

- the packaged browser-side host runtime for this library

What it is for:

- instantiating the Wasm module
- exposing the expected host imports
- exchanging strings with Wasm memory
- bridging generic browser APIs back into exported Wasm callbacks

### Main entrypoint

- `createBrowserBridge(options = {})`

### Main options

- `wasmUrl`
  URL of the `.wasm` file to load
- `logSelector`
  optional selector or element for visible log output
- `imports`
  extra imports to merge into the base import object

### Returned object

- `append(message)`
- `instance`
- `imports`
- `instantiate()`
- `readString(ptr, len)`
- `withWasmString(text, fn)`

### Required Wasm contract

The runtime validates these exports during `instantiate()`:

- `memory`
- `allocBytes`
- `freeBytes`

If one is missing or invalid, instantiation throws immediately.

### Optional Wasm callback exports

The runtime can call these if you provide them:

- `bridgeReceiveString(...)`
- `bridgeReceiveFetch(...)`
- `bridgeTimerFired(...)`

If one is missing, the bridge warns and drops only that callback path.

### Current JS-side host imports

- log/error
- timing
- DOM writes and reads
- checked-state and attribute helpers
- storage
- text fetch
- timers
- history/title
- focus/scroll helpers

### Graceful-failure behavior

The runtime tries to fail gracefully when the browser environment is only
partially available.

Current behavior:

- missing DOM elements produce warnings instead of exceptions
- missing optional callback exports produce warnings instead of exceptions
- unavailable storage returns empty reads and no-op writes/removes
- unavailable `history.pushState(...)` becomes a warning plus no-op
- unavailable `setTimeout(...)` becomes a warning plus no-op
- missing `performance.now()` falls back to `Date.now()`

The runtime still throws for unrecoverable boot problems such as:

- missing required Wasm exports
- failure to fetch the `.wasm` file
- failure to instantiate the Wasm module
- calling `readString(...)` or `withWasmString(...)` before instantiation

### Deferred for now

- file-input helpers
- upload helpers

Those remain intentionally outside the package until their generic fit is
better proven.
