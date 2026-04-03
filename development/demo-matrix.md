# Demo Matrix

This file records the intended set of self-contained `nkl-wasm` reference demos.

These demos are meant to show how the package can fit into different webapp
shapes. They are reference paths, not framework laws.

## Goals

- make the package easier to understand in context
- show that `nkl-wasm` is not tied to one app structure
- keep each demo small and architecture-focused
- avoid inventing a shared framework layer across demos

## Planned Demo Set

### 1. `echo/`

Purpose:

- smallest possible host-boundary demo
- DOM reads and writes
- string callback decoding

Status:

- implemented

### 2. `fetch/`

Purpose:

- async host call demo
- fetch callback decoding
- static serving path

Status:

- implemented

### 3. `ssr-enhance/`

Purpose:

- reference path for server-rendered HTML plus Wasm enhancement
- demonstrate SSR handoff without baking in a framework lifecycle
- closest small-scale shape to the path currently proven in `nkl-filebrowser`

Status:

- in progress

### 4. `csr/`

Purpose:

- reference path for client-rendered content after boot
- demonstrate that SSR is optional

Status:

- in progress

### 5. `spa-like/`

Purpose:

- reference path for history-driven view switching in one page
- demonstrate that SPA-like behavior can still stay explicit and Zig-led

Status:

- in progress

## Constraints

- no shared hidden runtime across demos
- no demo should define a mandatory app structure
- demos may reuse the packaged `browser_bridge.js`
- app-specific patterns should stay inside each demo until a reusable shape is
  proven independently
