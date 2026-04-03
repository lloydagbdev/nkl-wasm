# nkl-wasm

`nkl-wasm` is a reusable low-level Zig package for explicit Wasm host interop.

It extracts the proven Zig/Wasm browser-host boundary already exercised in
projects such as `nkl-filebrowser` and `nkl-playground-site`, while staying
small, explicit, and dependency-shaped.

In one sentence: `nkl-wasm` is for teams that want Zig-led Wasm application
logic with a thin host bridge, without adopting a client framework.

It is built for projects that want to stay explicit:

- Zig-owned client logic
- thin JS host bootstraps
- capability-oriented browser wrappers
- explicit callback handling
- freedom to choose SSR, CSR, SPA-like, or other project shapes

It is not trying to own:

- routing frameworks
- component systems
- reactive runtimes
- framework-owned state management
- required SSR or CSR structure
- product-specific DOM or request-id contracts

## Guarantees

What `nkl-wasm` is trying to guarantee today:

- a reusable Wasm host-boundary primitive layer rather than a framework shell
- exported alloc/free helpers for JS-to-Wasm string exchange
- explicit callback decoding for string and fetch payloads
- small capability-oriented Zig wrappers for common browser operations
- a reusable JS browser bridge that stays host-oriented rather than app-shaped
- dependency-style examples that exercise the current public surface

These are host-boundary guarantees, not application-framework guarantees.

## Non-Goals

What `nkl-wasm` is intentionally not trying to provide:

- routing abstractions
- virtual DOM or reactive view systems
- component composition models
- framework-owned lifecycle rules
- application state containers
- required SSR/Wasm handoff conventions
- product-specific flows such as filebrowser listing, preview, or upload logic

The intended contract is smaller: your app owns application structure,
`nkl-wasm` owns the Wasm and host interop mechanics.

## Positioning

`nkl-wasm` should be read the same way `nkl-http` is read inside the broader
`nkl` ecosystem: a low-level reusable boundary extracted from real applications,
not a top-level product and not an attempt to become a broad frontend platform.

SSR plus client-side Wasm enhancement with thin JS is one proven path.
CSR, SPA-like, and other Zig-led Wasm shapes should also remain valid
consumers.

## Start Here

If you are evaluating the package for the first time, read in this order:

1. This `README.md`
2. [`docs/usage.md`](/home/lloyd/dev/home-edge/prj/nkl-wasm/docs/usage.md)
3. [`docs/reference.md`](/home/lloyd/dev/home-edge/prj/nkl-wasm/docs/reference.md)
4. One of the shipped examples under [`examples/`](/home/lloyd/dev/home-edge/prj/nkl-wasm/examples)

## Using It In Another Zig Project

`nkl-wasm` is meant to be consumed as a normal Zig package dependency.

For a local checkout during development, the manifest shape is typically:

```zig
.dependencies = .{
    .nkl_wasm = .{
        .path = "../nkl-wasm",
    },
},
```

In `build.zig`, the usual pattern is:

```zig
const nkl_wasm_dep = b.dependency("nkl_wasm", .{
    .target = target,
    .optimize = optimize,
});

const wasm = b.addExecutable(.{
    .name = "my_app_wasm",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/app_wasm.zig"),
        .target = wasm_target,
        .optimize = .ReleaseSmall,
        .imports = &.{
            .{ .name = "nkl_wasm", .module = nkl_wasm_dep.module("nkl_wasm") },
        },
    }),
});
```

Then in application code:

```zig
const nkl_wasm = @import("nkl_wasm");
```

The JS side is expected to reuse
[`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js)
instead of rebuilding ad hoc string-bridging code in every app.

## What The Library Provides

Core boundary:

- `allocBytes(...)`
- `freeBytes(...)`
- pointer/length helpers
- callback decoding helpers
- shared enum and export-name constants

Capability wrappers:

- logging and timing
- DOM reads and writes
- storage reads and writes
- text fetch callbacks
- timeout scheduling
- history push and document-title updates
- focus and scroll helpers

JS runtime:

- Wasm instantiation
- import merging
- JS string <-> Wasm memory exchange
- browser API bridging into exported callbacks

## What To Read In Code

If you prefer code first, these are the main example entrypoints:

- [`app.zig`](/home/lloyd/dev/home-edge/prj/nkl-wasm/examples/echo/app.zig): smallest DOM/input callback example
- [`app.zig`](/home/lloyd/dev/home-edge/prj/nkl-wasm/examples/fetch/app.zig): minimal fetch callback example
- [`browser_bridge.js`](/home/lloyd/dev/home-edge/prj/nkl-wasm/src/js/browser_bridge.js): packaged JS host runtime

## Build And Run

Library verification:

```bash
zig build test
```

Examples:

```bash
zig build example-echo
zig build example-fetch
```

Example bundle verification:

```bash
zig build example-check
```

Served smoke check:

```bash
zig build example-smoke
```

Static serving helper:

```bash
zig build serve -- --directory zig-out/examples/echo
zig build serve -- --directory zig-out/examples/fetch
```
