# nkl-wasm Package Direction

## Position

`nkl-wasm` is the extraction target for the Wasm-side runtime boundary proven in
`nkl-filebrowser`.

For now, there is no separate `nkl-web` package.

Like `nkl-http` and `nkl-html`, `nkl-wasm` is meant to be consumed as a
dependency from other Zig projects.

It is not meant to be:

- an application skeleton
- a project template
- a generated starter
- a client framework
- a top-level product

Higher-level projects should depend on `nkl-wasm` for the Wasm and host
boundary, then compose their own application logic, SSR handoff, UI behavior,
routing, and domain state on top of it.

That means `nkl-wasm` should own the full low-level Zig/Wasm host boundary that
has already been exercised in a real app:

- Wasm memory allocation and release helpers
- string and byte exchange across the host boundary
- import/export callback conventions
- a thin browser host bridge
- minimal browser capability wrappers used directly by Zig app code

The key constraint is the same one already used for `nkl-http` and `nkl-html`:
extract the proven primitive, not a framework.

`nkl-wasm` should remain low-level, explicit, and small. It should make Zig-led
Wasm apps easier to build without trying to own application structure, state, or
rendering.

## Dependency Role

`nkl-wasm` should be packaged and documented primarily as a reusable dependency.

The intended usage model is:

- `nkl-wasm` provides the low-level Wasm and host bridge
- another Zig project imports it as a dependency
- that project defines its own app behavior and higher-level contracts

In other words:

- `nkl-wasm` should do for Zig/Wasm host interop what `nkl-http` does for HTTP
  transport
- it should provide a stable primitive layer, not the whole application model

The package should therefore be shaped around:

- a clean import surface
- small examples that demonstrate dependency usage
- docs that explain how another Zig project wires it into its own build

It should not be shaped around:

- one canonical app layout
- framework-owned page lifecycle
- required project conventions beyond the host ABI contract

## Why Extract It

`nkl-filebrowser` has already proven this shape in a real app path:

- Zig owns the client logic
- JS stays a thin host bridge
- browser capabilities are exposed through explicit calls
- fetch, storage, timers, history, and DOM mutation can stay outside of a JS
  app framework
- a server-rendered HTML page can hand off state and interactivity to Wasm
  cleanly

This is enough proof to extract the boundary as a reusable package.

## Extraction Principle

Preserve the runtime boundary that already worked in `nkl-filebrowser`, then
generalize names and module boundaries carefully.

Do not redesign the model around a hypothetical future client framework.

## What nkl-wasm Should Be

`nkl-wasm` should be a low-level package for Zig code that runs in `wasm32` and
needs an explicit host bridge.

It should let another small Zig/Wasm app:

- allocate and free temporary host-exchange buffers
- receive string or fetch callbacks from the host
- call thin host wrappers for common browser capabilities
- keep most client logic in Zig
- keep JavaScript small and host-oriented

It should feel similar in spirit to `nkl-http`:

- small public surface
- explicit contracts
- reusable primitives
- no hidden application model

## Proven Source Material

These are the main reference sources to extract from.

### nkl-filebrowser

- `src/frontend/browser_bridge.zig`
- `src/frontend/assets/browser_bridge.js`
- `src/frontend/app_wasm.zig`
- `development/extraction/04-nkl-wasm.md`
- `development/extraction/01-consolidation.md`
- `development/development-log.md`

What these proved:

- the Zig bridge API shape is workable
- the JS bridge can remain thin
- request id / callback style is workable for async host operations
- Wasm can own filter, navigation, preview, and upload client behavior without
  turning JS into the app

### nkl-playground-site

- `src/frontend/browser_bridge.zig`
- `src/frontend/assets/browser_bridge.js`
- `src/frontend/app_wasm.zig`

What this proved:

- the bridge is already duplicated outside of `nkl-filebrowser`
- the current shape has real reuse pressure
- not all consumers need the larger filebrowser-specific host surface

### nkl-html

- `docs/architecture.md`
- `docs/nkl-html-dx.md`
- `docs/use-cases/fullstack-development.md`

What this contributes:

- strong precedent for staying low-level
- clear separation between primitive layer and app-layer composition
- support for the SSR plus Wasm enhancement model without introducing a client
  framework

### nkl-http

- `README.md`
- `development/extraction/01-initial-direction.md`
- `development/development-log.md`

What this contributes:

- extraction style reference
- preserve proven runtime shape first
- document non-goals explicitly
- package structure should be library-shaped, not app-dump-shaped

## Recommended Scope

`nkl-wasm` should include these areas.

### 1. ABI / Memory Boundary

- allocator selection for Wasm use
- `allocBytes(len)`
- `freeBytes(ptr, len)`
- pointer plus length helpers
- slice reconstruction helpers
- small tests around alloc/free and slice round-trips

This is the most stable and reusable base.

### 2. Host Callback Conventions

- host-to-wasm callback naming conventions
- request id based callback delivery
- string payload delivery
- fetch-result delivery
- timer delivery
- optional byte payload delivery if needed later

This is where the async contract should become stable.

The important thing is not cleverness. The important thing is having a small,
predictable contract that both Zig and JS can implement.

### 3. Thin Zig Host Wrappers

The Zig side should provide small wrappers over host imports for:

- logging
- timing
- DOM mutation by id or selector
- input value reads
- storage read/write/remove
- fetch text
- history push
- document title update
- timers
- focus / scroll helpers
- optional file-input and upload helpers

These should stay capability-oriented, not app-oriented.

Good:

- `setTextById(...)`
- `storageGet(...)`
- `fetchText(...)`
- `setTimeout(...)`

Bad:

- `navigateToRoute(...)`
- `updateListingPanel(...)`
- `loadPreviewAndRender(...)`

### 4. Thin JS Host Runtime

The JS side should:

- instantiate the Wasm module
- expose the expected host imports
- read strings from Wasm memory
- write temporary strings into Wasm memory for callbacks
- bridge browser APIs to exported Wasm callbacks

It should remain operational and generic.

It should not become:

- a state container
- a UI controller
- a routing layer
- a rendering system

### 5. Small Example Consumers

The package should ship at least one or two tiny examples:

- basic DOM echo / form interaction
- fetch plus callback example

These should play the same role as the shipped examples in `nkl-http`: small,
real consumers of the public API.

## Recommended Non-Goals

`nkl-wasm` should not become:

- a client-side framework
- a reactive runtime
- a virtual DOM layer
- a component model
- a routing framework
- a state management library
- a browser-only application architecture
- a general frontend toolkit with product-level abstractions

Also avoid extracting these from `nkl-filebrowser` for now:

- listing state machines
- preview rendering policy
- syntax highlighters
- upload UX flow
- page-specific request ids
- page-specific DOM contracts

Those belong in apps until another app proves a shared shape.

## Boundary Clarification

There is one design tension to keep explicit:

- the original seed says `nkl-wasm` should not know about the browser
- the currently proven extraction path is a Zig/Wasm plus browser-host bridge

Since `nkl-web` is deferred for now, `nkl-wasm` should temporarily own the thin
browser host boundary as well.

That should be treated as a practical packaging decision, not a philosophical
claim that browser concerns and Wasm concerns are identical.

If a future non-browser host appears and the shared ABI surface is clearly large
enough, the package can later be split into:

- `nkl-wasm`: host-agnostic ABI and callback boundary
- browser-specific bridge package layered on top

But that split should only happen after another real consumer proves it.

## Public Surface Shape

The package should be shaped like a library, with a small root and explicit
submodules.

Suggested direction:

```text
src/
  root.zig
  abi.zig
  memory.zig
  callback.zig
  bridge.zig
  dom.zig
  storage.zig
  fetch.zig
  history.zig
  timer.zig
  upload.zig
  js/
    browser_bridge.js
examples/
  echo/
  fetch_demo/
docs/
development/
```

Suggested role of each area:

- `abi.zig`: import/export names, callback ids, enums, shared contract details
- `memory.zig`: alloc/free helpers and pointer utilities
- `callback.zig`: host callback receiving helpers
- `bridge.zig`: common low-level wrappers and allocator selection
- `dom.zig`: DOM-specific wrappers
- `storage.zig`: local/session storage wrappers
- `fetch.zig`: fetch helpers and fetch callback types
- `history.zig`: history/title helpers
- `timer.zig`: timeout helpers
- `upload.zig`: optional generic file-input/upload bridge if kept generic enough

This is a direction, not a frozen requirement.

If the final package is smaller, that is fine.

## Recommended Extraction Sequence

### 1. Establish package scaffold

- `build.zig`
- `build.zig.zon`
- `src/root.zig`
- initial docs
- one minimal example

### 2. Extract the stable core first

- alloc/free helpers
- pointer and slice helpers
- request id callback pattern
- basic logging and timing imports

### 3. Extract the duplicated browser bridge

Start from the common subset shared by:

- `nkl-filebrowser`
- `nkl-playground-site`

Then add the extra operations only if they stay generic.

### 4. Keep app-specific logic out

Do not move any of this into `nkl-wasm`:

- filebrowser page behavior
- preview-specific UI rendering
- listing-specific navigation logic
- page-specific DOM conventions

### 5. Add examples and tests

- bridge instantiation example
- DOM mutation example
- fetch example
- alloc/free unit test
- callback round-trip tests where practical

## Extraction Candidates By Confidence

### High confidence

These already look package-worthy.

- `allocBytes(...)`
- `freeBytes(...)`
- host string exchange helpers
- `log(...)`
- `logError(...)`
- `nowMs(...)`
- `setTextById(...)`
- `setHtmlById(...)`
- `setValueById(...)`
- `setDisabledById(...)`
- `storageSet/Get/Remove(...)`
- `fetchText(...)`
- `setTimeout(...)`
- `clearTimeout(...)`
- `historyPush(...)`
- `setDocumentTitle(...)`
- JS module instantiation and import merging

### Medium confidence

These are probably reusable, but should be reviewed carefully for package fit.

- `setCheckedById(...)`
- `setAttributeById(...)`
- `toggleClassById(...)`
- `toggleClassOnSelector(...)`
- `focusById(...)`
- `scrollIntoViewBySelector(...)`
- `getValueById(...)`

### Lower confidence

These may stay in app code unless a second consumer clearly wants them.

- `getFileNameById(...)`
- `getCheckedById(...)`
- `uploadFileFromInput(...)`

They are still plausible package features, but they are closer to a specific
browser interaction seam and should not be included automatically if they make
the package feel too product-shaped.

## Naming Guidance

Prefer names that describe the low-level operation directly.

Good:

- `fetchText`
- `storageGet`
- `setTextById`
- `bridgeReceiveFetch`

Avoid names that imply framework semantics.

Bad:

- `dispatchAction`
- `bindView`
- `mountComponent`
- `syncState`
- `navigateApp`

## Documentation Expectations

The package should eventually document:

- the import/export contract
- required Wasm exports
- optional callback exports
- the JS host runtime expectations
- minimal build wiring in Zig
- minimal browser bootstrap wiring
- a tiny SSR plus Wasm handoff example

The docs should explain the model in plain terms:

- Zig owns client logic
- JS hosts browser APIs
- callbacks cross the boundary explicitly

## Immediate Guidance For The Next Session

When continuing this extraction later, start with:

1. package scaffold
2. common subset diff between the two existing browser bridges
3. alloc/free and callback contract extraction
4. smallest possible example app

Do not start by extracting `app_wasm.zig`.

That file is useful mainly as a reference consumer, not as package code.

## Summary

`nkl-wasm` should become the reusable low-level Zig/Wasm host bridge package
proven by `nkl-filebrowser`.

For now it should include the thin browser boundary because that is the only
host shape already proven and duplicated.

The package should extract:

- the ABI boundary
- the callback conventions
- the thin Zig bridge
- the thin JS browser host runtime

It should not extract:

- app logic
- client architecture
- framework semantics
- product-specific UI behavior

The right standard is the same one already applied elsewhere in the stack:
small primitive, explicit contract, no framework drift.
