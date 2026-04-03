# nkl-wasm

`nkl-wasm` is intended to become the reusable low-level Zig/Wasm host-boundary
library for the broader `nkl` ecosystem.

## Core Constraints

- preserve the proven Zig/Wasm host-boundary shape from `nkl-filebrowser`
  and `nkl-playground-site`
- keep the package low-level, explicit, and dependency-shaped rather than
  framework-shaped
- prefer capability-oriented host wrappers over app-oriented APIs
- preserve thin-JS, Zig-led client logic as a proven reference pattern without
  making it a required application architecture
- support multiple consumer shapes, including SSR plus Wasm enhancement, CSR,
  and SPA-like projects, as long as they want an explicit Zig-led Wasm host
  boundary

## Current Extraction Posture

- `nkl-filebrowser` remains the main proving ground for the browser-host bridge
- `nkl-playground-site` confirms that the current bridge shape already has reuse
  pressure outside one app
- `nkl-wasm` starts as a fresh package scaffold rather than a blind app code
  dump
- the package should temporarily include the browser-host layer because there is
  no separate `nkl-web` package yet
- any future split between host-agnostic Wasm ABI and browser-specific wrappers
  should happen only after another real consumer proves the seam

## Near-Term Goal

Stabilize a reusable core around:

- Wasm alloc/free helpers
- pointer and slice reconstruction helpers
- host callback naming and request-id conventions
- host string exchange
- thin Zig wrappers for logging, timing, DOM mutation, storage, fetch, history,
  timers, and related browser capabilities
- a thin reusable JS browser bridge that instantiates Wasm and wires browser
  APIs into exported callbacks

## Current Scope Boundary

`nkl-wasm` should provide primitives for host interop, not application policy.

That means the package should own:

- memory and ABI helpers
- callback delivery conventions
- browser capability wrappers that remain generic
- a small JS runtime with import merging, string read/write helpers, and async
  callback delivery
- examples that demonstrate dependency usage from another Zig project

That means the package should not own:

- routing policy
- page lifecycle policy
- framework-owned state management
- app-specific DOM contracts
- product-specific request ids
- preview, listing, upload, or other product flows taken directly from
  `nkl-filebrowser`

## Emerging Helper Surface

The current reference bridge surface already suggests a first package-worthy
primitive set:

- logging and error logging
- `nowMs()`
- DOM setters like text, HTML, value, disabled state, checked state, attribute
  writes, class toggles, focus, and scroll helpers
- DOM reads delivered back through callback exports
- storage read/write/remove helpers
- text fetch with callback delivery
- timeout scheduling and callback delivery
- history push and document-title updates
- optional file-input and upload helpers only if they remain truly generic

The main hardening priorities once extraction begins are:

- make the top-level public surface intentional
- split the package into explicit low-level modules
- ship a reusable JS bridge under the package rather than buried in an app
- add tiny example consumers that prove the public API from a dependency
  perspective
- add tests around alloc/free helpers, callback round-trips, and shared utility
  behavior before broadening the surface
