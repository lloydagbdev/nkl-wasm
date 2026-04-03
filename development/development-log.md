# Development Log

## 2026-04-02

- Initialized `nkl-wasm` as the extraction target for the reusable Zig/Wasm host-boundary code currently proven in `nkl-filebrowser` and `nkl-playground-site`.
- Initialized a dedicated Git repository at the start of the package work so extraction, scaffolding, and public-surface decisions have a clean local history from the first package-shaped commit onward.
- Chose to keep a dedicated development log from the start because it already proved useful in both `nkl-filebrowser` and `nkl-http` for recording extraction constraints, failed paths, and architecture decisions before the codebase gets larger.
- Carried forward the most important positioning constraint from the current source projects:
  - `nkl-wasm` should extract the proven low-level Wasm and host boundary
  - it should not become an application skeleton, framework, or opinionated frontend architecture
- Kept the package direction explicitly broader than one rendering model:
  - SSR plus client-side Wasm enhancement with thin JS is one proven path
  - CSR, SPA-like, or other Zig-led Wasm app shapes should also be valid consumers
  - the package should own host interop primitives, not product structure
- Recorded the current extraction source material as the reference baseline:
  - `nkl-filebrowser/src/frontend/browser_bridge.zig`
  - `nkl-filebrowser/src/frontend/assets/browser_bridge.js`
  - `nkl-filebrowser/src/frontend/app_wasm.zig`
  - `nkl-playground-site/src/frontend/browser_bridge.zig`
  - `nkl-playground-site/src/frontend/assets/browser_bridge.js`
  - `nkl-playground-site/src/frontend/app_wasm.zig`
- Carried forward the most important extraction principle already used in `nkl-http`:
  - preserve the proven runtime boundary first
  - generalize names and module seams carefully
  - keep app-specific logic in apps until another consumer proves a reusable shape
- Recorded the currently proven primitive areas that `nkl-wasm` is expected to own:
  - Wasm alloc/free helpers and pointer-plus-length utilities
  - string exchange across the host boundary
  - request-id-based callback delivery
  - thin capability-oriented Zig wrappers over browser host calls
  - a thin JS runtime that instantiates Wasm and bridges browser APIs back into exported callbacks
- Recorded the strongest current non-goals:
  - client framework
  - routing framework
  - reactive runtime
  - state management layer
  - component model
  - required project layout tied to SSR, CSR, or SPA assumptions
- Deferred package scaffolding and code extraction until after the initial direction documents were consolidated into local `development/` notes so implementation can start from a stable package brief instead of repeated conversational restatement.

## 2026-04-02 - package scaffold plan and first repo scaffold

- Recorded the first implementation sequence before writing package code:
  - scaffold the package as a library
  - extract the stable memory and ABI core first
  - extract the thin Zig bridge surface next
  - extract the reusable JS host runtime after the Zig side is shaped
  - add tiny examples and focused tests early
  - leave medium-confidence helpers for later review
- Kept this plan intentionally aligned with the extraction discipline used in
  `nkl-http`:
  - library shape first
  - proven primitive first
  - app-specific behavior left behind
- Started step 1 by scaffolding the repository with:
  - `build.zig`
  - `build.zig.zon`
  - `src/root.zig`
  - `README.md`
  - `examples/README.md`
  - `docs/README.md`
- Kept the first scaffold deliberately minimal:
  - one package module named `nkl_wasm`
  - one library test step
  - no extracted bridge code yet
  - no example binaries yet
- Chose to establish the package directories now even where content is still
  placeholder-only so the eventual extraction can land into an already
  library-shaped layout rather than growing ad hoc from a single source file.
- Ran the first scaffold verification with `zig build test`.
- Corrected the initial `build.zig.zon` fingerprint to the value required by the
  local Zig toolchain for this fresh package scaffold before rerunning
  verification.
- Verified the scaffold successfully with `zig build test` after the fingerprint
  correction.

## 2026-04-02 - first extracted memory and ABI core

- Started step 2 by extracting the most stable low-level core first:
  - `src/memory.zig`
  - `src/abi.zig`
- Moved the allocator-selection and exported allocation boundary into
  `src/memory.zig`:
  - `allocator()`
  - `allocBytes(...)`
  - `freeBytes(...)`
- Added pointer-plus-length helpers in `src/memory.zig` so future callback and
  host-wrapper code can stop reimplementing local pointer reconstruction:
  - `sliceFromPtrLen(...)`
  - `bytesFromPtrLen(...)`
  - `PtrLen`
  - `ptrLen(...)`
- Kept the memory helper surface intentionally small and close to the already
  proven bridge code from `nkl-filebrowser` and `nkl-playground-site`.
- Added `src/abi.zig` as the first shared contract module for stable enum and
  export-name definitions:
  - `StorageKind`
  - `StringKind`
  - `FetchStatus`
  - exported callback/allocation symbol names
- Wired the new modules through `src/root.zig` so the package now exposes an
  intentional first public surface instead of only a placeholder root symbol.
- Added focused unit coverage for:
  - alloc/free round-trip behavior
  - zero-length pointer/slice behavior
  - pointer-plus-length reconstruction
  - enum values matching the current proven bridge contract
- Added `.codex/` to `.gitignore` so it is never tracked by this repository,
  alongside the standard Zig build-output paths.

## 2026-04-03 - first thin Zig bridge module split

- Continued the extraction by splitting the first capability-oriented Zig host
  wrapper surface into explicit modules instead of keeping the whole boundary in
  one future app-local bridge file.
- Added `src/bridge.zig` as the central raw host-import layer for the currently
  proven generic browser operations:
  - logging
  - error logging
  - timing
  - DOM mutation and reads
  - storage
  - text fetch
  - timers
  - history and document title
  - focus / scroll helpers
- Kept the non-wasm stub behavior from the proven bridge shape so package tests
  can continue to compile and exercise the public surface on native targets.
- Added the first capability-oriented wrapper modules on top of `src/bridge.zig`:
  - `src/dom.zig`
  - `src/storage.zig`
  - `src/fetch.zig`
  - `src/history.zig`
  - `src/timer.zig`
- Wired those modules through `src/root.zig` and promoted the common bridge
  helpers:
  - `log(...)`
  - `logError(...)`
  - `logFmt(...)`
  - `nowMs()`
- Kept file-input and upload helpers deferred even though they exist in
  `nkl-filebrowser`, because they are not yet proven by a second consumer and
  still need a clearer package-fit review.
- Added lightweight compile-and-call unit coverage for each wrapper module on
  non-wasm targets so the extraction keeps package shape validation tight while
  the real browser-facing integration tests are still pending.

## 2026-04-03 - first reusable JS host runtime extraction

- Added `src/js/browser_bridge.js` as the first package-owned reusable JS host
  runtime instead of leaving the browser bridge buried in app asset trees.
- Extracted the JS runtime from the shared shape already present in
  `nkl-filebrowser` and `nkl-playground-site`, keeping the public runtime
  intentionally generic:
  - Wasm instantiation
  - import merging
  - string reads from Wasm memory
  - temporary string writes into Wasm memory
  - callback delivery for string and fetch responses
  - DOM, storage, fetch, timer, history, title, focus, scroll, checked-state,
    and attribute helpers
- Kept the JS side aligned with the current Zig package surface rather than with
  every feature present in `nkl-filebrowser`.
- Deferred file-input and upload helpers on the JS side for the same reason they
  were deferred on the Zig side:
  - they are only proven in one app path today
  - they still need a clearer review as package-level capabilities
- Updated the placeholder docs and example notes so the package now explicitly
  points future consumers toward `src/js/browser_bridge.js` as the intended
  reusable host bootstrap.

## 2026-04-03 - callback helper extraction

- Added `src/callback.zig` as the first package-owned helper layer for
  host-to-Wasm callback decoding.
- The immediate goal was to stop leaving callback payload interpretation as
  repeated app-local logic once the package already owns the callback contract.
- Added explicit helper shapes for the currently proven callback paths:
  - `StringCallback`
  - `FetchCallback`
- Added small decoding helpers for the current contract:
  - `stringKindFromInt(...)`
  - `receiveString(...)`
  - `receiveFetch(...)`
- Kept this module intentionally narrow:
  - decode the already-proven callback boundary
  - do not impose app state machines or callback dispatch policy
- Wired the callback module through `src/root.zig`.
- Added focused tests around:
  - valid string callback decoding
  - rejection of unknown string kinds
  - fetch callback decoding of success, status, and payload text

## 2026-04-03 - first tiny consumer example

- Added the first real dependency-style consumer under `examples/echo/`.
- The example is intentionally small and proves the current package surface
  end to end:
  - Wasm build wiring through `build.zig`
  - import of `nkl_wasm` from another Zig module
  - DOM reads through `getValueById(...)`
  - string callback decoding through `callback.receiveString(...)`
  - DOM writes and focus control through the package wrappers
  - browser bootstrap through the package-owned `browser_bridge.js`
- Added `zig build example-echo` as a build step that installs a self-contained
  static example directory under `zig-out/examples/echo/` with:
  - `index.html`
  - `app.js`
  - `browser_bridge.js`
  - `app.wasm`
- Kept the example intentionally static-file-friendly rather than introducing a
  dedicated example HTTP server too early, because the main point is dependency
  usage and bridge shape, not server packaging.

## 2026-04-03 - static serving helper step

- Added `zig build serve` as a convenience build step that wraps
  `python3 -m http.server`.
- Kept the step intentionally generic and argument-driven so callers can pass
  through the normal Python server flags, including:
  - `zig build serve -- --directory zig-out/examples/echo`
- Chose this small wrapper instead of adding a custom example server because the
  package still only needs a simple local static-serving helper for Wasm
  examples at this stage.

## 2026-04-03 - second tiny example for fetch callbacks

- Added a second dependency-style consumer under `examples/fetch/`.
- This example is intentionally static-file-friendly so it can run through the
  current `zig build serve` workflow without needing a custom backend:
  - the page fetches `./data.txt`
  - the package bridge delivers the response through `bridgeReceiveFetch(...)`
- The fetch example proves the current package surface end to end for:
  - `fetch.fetchText(...)`
  - fetch callback decoding through `callback.receiveFetch(...)`
  - DOM updates through the extracted wrappers
  - reuse of the packaged `src/js/browser_bridge.js`
- Added `zig build example-fetch` as a build step that installs a self-contained
  static example directory under `zig-out/examples/fetch/` with:
  - `index.html`
  - `app.js`
  - `browser_bridge.js`
  - `app.wasm`
  - `data.txt`

## 2026-04-03 - package documentation pass

- Rewrote the top-level `README.md` from scaffold/planning language into a real
  package README that describes the current extracted surface.
- Added focused package docs:
  - `docs/usage.md`
  - `docs/reference.md`
- Kept the docs aligned with the actual current package surface rather than the
  broader future extraction plan.
- Documented:
  - current positioning and non-goals
  - dependency wiring
  - memory and callback usage
  - capability wrapper modules
  - packaged JS runtime usage
  - shipped examples and local serving flow

## 2026-04-03 - bridge stub hardening cleanup

- Performed a narrow internal hardening pass on `src/bridge.zig`.
- Kept the public package surface unchanged while reducing repetitive native
  no-op stub boilerplate for non-wasm builds.
- Consolidated repeated stub implementations into shared helper functions for:
  - pointer/length no-ops
  - request-id plus pointer/length no-ops
  - id/value and id/bool no-ops
  - storage no-ops
  - fetch no-op
  - selector/class no-op
  - timer and scalar no-ops
- The goal of this pass was maintainability rather than feature growth:
  future bridge additions now have a smaller amount of internal repetition to
  match when keeping native package tests compilable.

## 2026-04-03 - internal bridge import split

- Continued the hardening pass by splitting the raw browser import declarations
  and non-wasm stub-selection logic out of `src/bridge.zig`.
- Added `src/internal/browser_imports.zig` as the internal owner of:
  - raw `extern "env"` declarations
  - native no-op fallback helpers
  - current import-selection constants for wasm vs native builds
- Reduced `src/bridge.zig` to a smaller wrapper layer over that internal module.
- Kept the public package surface unchanged:
  - no root export changes
  - no wrapper module changes
  - no JS runtime changes
- The goal of this pass was to make the bridge easier to extend without letting
  one public-facing file keep growing as the raw host surface expands.

## 2026-04-03 - example bundle verification step

- Added `tools/check_example_assets.py` as the first black-box verification path
  for the shipped examples.
- Kept the check intentionally small and static-asset-oriented:
  - verify the installed example directories exist under `zig-out/examples/`
  - verify the expected files exist
  - verify files are non-empty
  - verify a few identifying content strings in the text assets
- Added `zig build example-check` as the build entrypoint for this verification
  pass.
- Kept the first black-box verification scope intentionally narrow:
  - no browser automation yet
  - no HTTP request harness yet
  - just enough end-to-end coverage to ensure the current example-install
    workflow keeps producing complete static bundles

## 2026-04-03 - served example smoke harness

- Added `tools/run_example_smoke.py` as the first served-example smoke harness.
- Kept the smoke scope pragmatic and HTTP-level:
  - serve `zig-out/examples/` on loopback with Python's standard library HTTP server
  - fetch the installed example assets over real HTTP URLs
  - verify status codes
  - verify basic content types
  - verify a few identifying response-body strings for text assets
  - verify a missing file returns `404`
- Added `zig build example-smoke` as the build entrypoint for this pass.
- Kept browser automation out of scope for now; the current goal is to verify
  that the installed example bundles are not only present on disk but also
  servable and coherent through a minimal static hosting path.

## 2026-04-03 - stricter smoke harness and aggregate verify step

- Tightened `tools/run_example_smoke.py` in a few small but useful ways:
  - silenced the temporary HTTP server request logs so smoke output stays clean
  - accepted either `text/javascript` or `application/javascript` for JS assets
  - added `HEAD` checks alongside `GET` checks for the served example assets
- Added `zig build verify` as a higher-signal aggregate package command that
  runs:
  - library tests
  - example smoke verification
- Kept this aggregation deliberately small; the goal is one obvious command for
  package verification without introducing a large CI-specific abstraction.

## 2026-04-03 - docs rewrite for faster onboarding and clearer reference

- Reworked `docs/usage.md` into a more productive top-down structure:
  - quick start first
  - shortest path to something working near the top
  - deeper explanation and workflow details in later sections
- Reworked `docs/reference.md` into a more explicit package map that does not
  assume the reader already knows what each library element is.
- The main documentation goals of this pass were:
  - help a new reader get productive quickly
  - make the package layers clearer
  - explain what each module is for before listing its functions

## 2026-04-03 - demo matrix and first architecture-reference demo

- Added `development/demo-matrix.md` to define the intended self-contained demo
  set and to keep the “reference paths, not framework laws” positioning explicit.
- Added `examples/ssr-enhance/` as the first architecture-reference demo beyond
  the primitive `echo/` and `fetch/` examples.
- Kept the SSR-plus-Wasm demo intentionally small:
  - HTML starts in a server-rendered-looking state
  - a hidden input carries initial state
  - Wasm reads that initial state through the normal host boundary
  - Wasm then owns the interactive counter behavior
- Updated build, example verification, smoke verification, and docs so the new
  demo is treated as a first-class reference path alongside the smaller demos.

## 2026-04-03 - second architecture-reference demo for CSR

- Added `examples/csr/` as the client-rendered reference path.
- Kept the CSR demo intentionally small and clearly different from the SSR demo:
  - the HTML starts as a static shell only
  - the item list is not rendered in the initial HTML
  - Wasm fetches `data.txt` after boot
  - Wasm renders the content into the page after the fetch callback arrives
- Updated build wiring, asset verification, smoke verification, and docs so the
  CSR demo is treated as another first-class reference path rather than a side
  experiment.

## 2026-04-03 - third architecture-reference demo for SPA-like navigation

- Added `examples/spa-like/` as the SPA-like reference path.
- Kept the demo intentionally narrow and explicit:
  - Wasm owns the current view state
  - Wasm pushes query-string URLs through `history.push(...)`
  - JS only forwards button clicks and `popstate` back into Wasm
  - view rendering stays explicit rather than being hidden behind a router or
    framework lifecycle
- Updated build wiring, asset verification, smoke verification, docs, and the
  demo matrix so the SPA-like path now sits alongside the SSR and CSR reference
  demos.
