# Examples

This directory will hold small dependency-style examples for `nkl-wasm`.

The initial target examples are:

- a small DOM echo/form interaction example
- a fetch-plus-callback example

These examples are meant to exercise the public package surface from another
Zig project shape, not to define a required application architecture.

The JS side of those examples is expected to reuse
`src/js/browser_bridge.js` directly rather than re-creating ad hoc host
bootstraps inside each example.

Current example:

- `echo/`
  Build with `zig build example-echo`, then serve `zig-out/examples/echo/`
  through any static file server.
- `fetch/`
  Build with `zig build example-fetch`, then serve `zig-out/examples/fetch/`
  through any static file server.

Convenience command:

```bash
zig build example-echo
zig build serve -- --directory zig-out/examples/echo
```

```bash
zig build example-fetch
zig build serve -- --directory zig-out/examples/fetch
```
