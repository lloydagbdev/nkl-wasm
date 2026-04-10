const std = @import("std");

pub const Error = error{
    UnknownCapability,
    DuplicateBlock,
    MissingBlock,
    CyclicBlockDependency,
};

pub const Capability = enum {
    dom,
    storage,
    fetch,
    timer,
    history,
};

const BlockId = enum {
    module_start,
    callback_string,
    callback_fetch,
    callback_timer,
    dom_helpers,
    timer_state,
    imports_start,
    imports_core,
    imports_dom,
    imports_storage,
    imports_fetch,
    imports_timer,
    imports_history,
    module_end,
    helper_document,
    helper_storage,
    helper_validate,
    helper_merge,
};

const Block = struct {
    id: BlockId,
    deps: []const BlockId,
    source: []const u8,
};

pub const Selection = struct {
    dom: bool = false,
    storage: bool = false,
    fetch: bool = false,
    timer: bool = false,
    history: bool = false,

    pub fn full() Selection {
        return .{
            .dom = true,
            .storage = true,
            .fetch = true,
            .timer = true,
            .history = true,
        };
    }

    fn enable(self: *Selection, capability: Capability) void {
        switch (capability) {
            .dom => self.dom = true,
            .storage => self.storage = true,
            .fetch => self.fetch = true,
            .timer => self.timer = true,
            .history => self.history = true,
        }
    }
};

pub fn parseCapabilities(text: ?[]const u8) Error!Selection {
    const value = std.mem.trim(u8, text orelse "full", &std.ascii.whitespace);
    if (value.len == 0 or std.mem.eql(u8, value, "full")) {
        return Selection.full();
    }
    if (std.mem.eql(u8, value, "core") or std.mem.eql(u8, value, "minimal")) {
        return .{};
    }

    var selection: Selection = .{};
    var parts = std.mem.splitScalar(u8, value, ',');
    while (parts.next()) |raw_part| {
        const part = std.mem.trim(u8, raw_part, &std.ascii.whitespace);
        if (part.len == 0) continue;
        selection.enable(try capabilityFromName(part));
    }
    return selection;
}

pub fn render(allocator: std.mem.Allocator, selection: Selection) ![]const u8 {
    try validateBlocks();

    var visited = [_]bool{false} ** @typeInfo(BlockId).@"enum".fields.len;
    var visiting = [_]bool{false} ** @typeInfo(BlockId).@"enum".fields.len;
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();

    try appendBlock(&output, &visited, &visiting, .module_start);
    if (selection.timer) {
        try appendBlock(&output, &visited, &visiting, .timer_state);
    }
    if (selection.dom) {
        try appendBlock(&output, &visited, &visiting, .dom_helpers);
    }
    if (selection.dom or selection.storage) {
        try appendBlock(&output, &visited, &visiting, .callback_string);
    }
    if (selection.fetch) {
        try appendBlock(&output, &visited, &visiting, .callback_fetch);
    }
    if (selection.timer) {
        try appendBlock(&output, &visited, &visiting, .callback_timer);
    }

    try appendBlock(&output, &visited, &visiting, .imports_start);
    try appendBlock(&output, &visited, &visiting, .imports_core);
    if (selection.dom) {
        try appendBlock(&output, &visited, &visiting, .imports_dom);
    }
    if (selection.storage) {
        try appendBlock(&output, &visited, &visiting, .imports_storage);
    }
    if (selection.fetch) {
        try appendBlock(&output, &visited, &visiting, .imports_fetch);
    }
    if (selection.timer) {
        try appendBlock(&output, &visited, &visiting, .imports_timer);
    }
    if (selection.history) {
        try appendBlock(&output, &visited, &visiting, .imports_history);
    }

    try appendBlock(&output, &visited, &visiting, .module_end);
    try appendBlock(&output, &visited, &visiting, .helper_document);
    if (selection.storage) {
        try appendBlock(&output, &visited, &visiting, .helper_storage);
    }
    try appendBlock(&output, &visited, &visiting, .helper_validate);
    try appendBlock(&output, &visited, &visiting, .helper_merge);

    const result = try allocator.dupe(u8, output.written());
    output.deinit();
    return result;
}

pub fn renderAssetModule(allocator: std.mem.Allocator) ![]const u8 {
    return std.fmt.allocPrint(
        allocator,
        "const raw = @embedFile(\"browser_bridge.js\");\n" ++
            "pub const bytes = raw[0..raw.len];\n",
        .{},
    );
}

fn capabilityFromName(name: []const u8) Error!Capability {
    inline for (@typeInfo(Capability).@"enum".fields) |field| {
        if (std.mem.eql(u8, name, field.name)) {
            return @enumFromInt(field.value);
        }
    }
    return error.UnknownCapability;
}

fn appendBlock(
    output: *std.Io.Writer.Allocating,
    visited: *[@typeInfo(BlockId).@"enum".fields.len]bool,
    visiting: *[@typeInfo(BlockId).@"enum".fields.len]bool,
    id: BlockId,
) !void {
    const index = @intFromEnum(id);
    if (visited[index]) return;
    if (visiting[index]) return error.CyclicBlockDependency;

    const block = try blockById(id);
    visiting[index] = true;
    for (block.deps) |dep| {
        try appendBlock(output, visited, visiting, dep);
    }
    visiting[index] = false;

    try output.writer.writeAll(block.source);
    visited[index] = true;
}

fn blockById(id: BlockId) Error!Block {
    for (blocks) |block| {
        if (block.id == id) return block;
    }
    return error.MissingBlock;
}

fn validateBlocks() Error!void {
    var seen = [_]bool{false} ** @typeInfo(BlockId).@"enum".fields.len;
    for (blocks) |block| {
        const index = @intFromEnum(block.id);
        if (seen[index]) return error.DuplicateBlock;
        seen[index] = true;
        for (block.deps) |dep| {
            _ = try blockById(dep);
        }
    }
    for (seen) |is_seen| {
        if (!is_seen) return error.MissingBlock;
    }
}

const blocks = [_]Block{
    .{
        .id = .module_start,
        .deps = &.{},
        .source =
        \\// Copyright 2026 Lloyd Anthony Ganal Balisacan <lloyd.agb@pm.me>
        \\// Licensed under the Apache License, Version 2.0.
        \\// See the LICENSE file for details.
        \\
        \\// Reusable browser bridge for Zig Wasm projects.
        \\
        \\export function createBrowserBridge(options = {}) {
        \\  const config = {
        \\    logSelector: "#log",
        \\    wasmUrl: "./app.wasm",
        \\    imports: {},
        \\    ...options,
        \\  };
        \\
        \\  const encoder = new TextEncoder();
        \\  const decoder = new TextDecoder();
        \\  const logElement = resolveLogElement(config.logSelector);
        \\  let instance = null;
        \\
        \\  function append(message) {
        \\    if (logElement) {
        \\      logElement.textContent += `\n${message}`;
        \\    }
        \\  }
        \\
        \\  function warn(message, error) {
        \\    append(`bridge warning: ${message}`);
        \\    if (error !== undefined) {
        \\      console.warn(`bridge warning: ${message}`, error);
        \\      return;
        \\    }
        \\    console.warn(`bridge warning: ${message}`);
        \\  }
        \\
        \\  function u32(value) {
        \\    return Number(value) >>> 0;
        \\  }
        \\
        \\  function requireInstance() {
        \\    if (!instance) {
        \\      throw new Error("browser bridge is not instantiated yet");
        \\    }
        \\    return instance;
        \\  }
        \\
        \\  function getMemory() {
        \\    const activeInstance = requireInstance();
        \\    const memory = activeInstance.exports.memory;
        \\    if (!(memory instanceof WebAssembly.Memory)) {
        \\      throw new Error("wasm export 'memory' is missing or invalid");
        \\    }
        \\    return memory;
        \\  }
        \\
        \\  function getRequiredExport(name) {
        \\    const activeInstance = requireInstance();
        \\    const value = activeInstance.exports[name];
        \\    if (typeof value !== "function") {
        \\      throw new Error(`wasm export '${name}' is missing`);
        \\    }
        \\    return value;
        \\  }
        \\
        \\  function readString(ptr, len) {
        \\    const byteOffset = u32(ptr);
        \\    const byteLength = u32(len);
        \\    if (byteLength === 0) {
        \\      return "";
        \\    }
        \\
        \\    const bytes = new Uint8Array(getMemory().buffer, byteOffset, byteLength);
        \\    return decoder.decode(bytes);
        \\  }
        \\
        \\  function withWasmString(text, fn) {
        \\    const encoded = encoder.encode(text);
        \\    const allocBytes = getRequiredExport("allocBytes");
        \\    const freeBytes = getRequiredExport("freeBytes");
        \\    const ptr = u32(allocBytes(encoded.length));
        \\    if (!ptr && encoded.length !== 0) {
        \\      throw new Error("allocBytes returned 0");
        \\    }
        \\
        \\    try {
        \\      if (encoded.length !== 0) {
        \\        const bytes = new Uint8Array(getMemory().buffer, ptr, encoded.length);
        \\        bytes.set(encoded);
        \\      }
        \\      return fn(ptr, encoded.length);
        \\    } finally {
        \\      freeBytes(ptr, encoded.length);
        \\    }
        \\  }
        \\
        ,
    },
    .{
        .id = .timer_state,
        .deps = &.{},
        .source =
        \\  const timeoutHandles = new Map();
        \\
        ,
    },
    .{
        .id = .dom_helpers,
        .deps = &.{},
        .source =
        \\  function getElementById(id) {
        \\    const doc = getDocument();
        \\    if (!doc) {
        \\      warn(`document is unavailable while looking up #${id}`);
        \\      return null;
        \\    }
        \\
        \\    const element = doc.getElementById(id);
        \\    if (!element) {
        \\      warn(`missing element #${id}`);
        \\    }
        \\    return element;
        \\  }
        \\
        ,
    },
    .{
        .id = .callback_string,
        .deps = &.{},
        .source =
        \\  function deliverString(kind, requestId, text) {
        \\    const activeInstance = instance;
        \\    if (!activeInstance) {
        \\      warn("dropping string callback because wasm is not instantiated");
        \\      return;
        \\    }
        \\
        \\    if (typeof activeInstance.exports.bridgeReceiveString !== "function") {
        \\      warn("bridgeReceiveString export is missing");
        \\      return;
        \\    }
        \\
        \\    withWasmString(text, (ptr, len) => {
        \\      activeInstance.exports.bridgeReceiveString(kind, requestId, ptr, len);
        \\    });
        \\  }
        \\
        ,
    },
    .{
        .id = .callback_fetch,
        .deps = &.{},
        .source =
        \\  function deliverFetch(requestId, ok, status, text) {
        \\    const activeInstance = instance;
        \\    if (!activeInstance) {
        \\      warn("dropping fetch callback because wasm is not instantiated");
        \\      return;
        \\    }
        \\
        \\    if (typeof activeInstance.exports.bridgeReceiveFetch !== "function") {
        \\      warn("bridgeReceiveFetch export is missing");
        \\      return;
        \\    }
        \\
        \\    withWasmString(text, (ptr, len) => {
        \\      activeInstance.exports.bridgeReceiveFetch(requestId, ok ? 1 : 0, status, ptr, len);
        \\    });
        \\  }
        \\
        ,
    },
    .{
        .id = .callback_timer,
        .deps = &.{},
        .source =
        \\  function deliverTimer(timerId) {
        \\    const activeInstance = instance;
        \\    if (!activeInstance) {
        \\      warn(`dropping timer ${timerId} because wasm is not instantiated`);
        \\      return;
        \\    }
        \\
        \\    if (typeof activeInstance.exports.bridgeTimerFired !== "function") {
        \\      warn("bridgeTimerFired export is missing");
        \\      return;
        \\    }
        \\
        \\    activeInstance.exports.bridgeTimerFired(timerId);
        \\  }
        \\
        ,
    },
    .{
        .id = .imports_start,
        .deps = &.{},
        .source =
        \\  const baseImports = {
        \\    env: {
        ,
    },
    .{
        .id = .imports_core,
        .deps = &.{},
        .source =
        \\      js_log(ptr, len) {
        \\        const message = readString(ptr, len);
        \\        append(`zig -> js: ${message}`);
        \\        console.log(message);
        \\      },
        \\      js_error(ptr, len) {
        \\        const message = readString(ptr, len);
        \\        append(`zig error -> js: ${message}`);
        \\        console.error(message);
        \\      },
        \\      js_now_ms() {
        \\        if (typeof performance?.now === "function") {
        \\          return performance.now();
        \\        }
        \\        return Date.now();
        \\      },
        ,
    },
    .{
        .id = .imports_dom,
        .deps = &.{ .dom_helpers, .callback_string },
        .source =
        \\      js_set_text_by_id(idPtr, idLen, textPtr, textLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        if (element) {
        \\          element.textContent = readString(textPtr, textLen);
        \\        }
        \\      },
        \\      js_set_html_by_id(idPtr, idLen, htmlPtr, htmlLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        if (element) {
        \\          element.innerHTML = readString(htmlPtr, htmlLen);
        \\        }
        \\      },
        \\      js_set_value_by_id(idPtr, idLen, valuePtr, valueLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        if (element && "value" in element) {
        \\          element.value = readString(valuePtr, valueLen);
        \\        }
        \\      },
        \\      js_set_checked_by_id(idPtr, idLen, checked) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        if (element instanceof HTMLInputElement) {
        \\          element.checked = checked === 1;
        \\        }
        \\      },
        \\      js_set_attribute_by_id(idPtr, idLen, attrPtr, attrLen, valuePtr, valueLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const attr = readString(attrPtr, attrLen);
        \\        const value = readString(valuePtr, valueLen);
        \\        const element = getElementById(id);
        \\        if (element) {
        \\          element.setAttribute(attr, value);
        \\        }
        \\      },
        \\      js_set_disabled_by_id(idPtr, idLen, disabled) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        if (element && "disabled" in element) {
        \\          element.disabled = disabled === 1;
        \\        }
        \\      },
        \\      js_get_value_by_id(requestId, idPtr, idLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        const value = element && "value" in element ? String(element.value) : "";
        \\        deliverString(2, requestId, value);
        \\      },
        \\      js_get_checked_by_id(requestId, idPtr, idLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        const checked = element instanceof HTMLInputElement && element.checked ? "1" : "";
        \\        deliverString(2, requestId, checked);
        \\      },
        \\      js_toggle_class_by_id(idPtr, idLen, classPtr, classLen, present) {
        \\        const id = readString(idPtr, idLen);
        \\        const className = readString(classPtr, classLen);
        \\        const element = getElementById(id);
        \\        if (element) {
        \\          element.classList.toggle(className, present === 1);
        \\        }
        \\      },
        \\      js_toggle_class_on_selector(selectorPtr, selectorLen, classPtr, classLen, present) {
        \\        const doc = getDocument();
        \\        if (!doc) {
        \\          warn("document is unavailable while toggling selector classes");
        \\          return;
        \\        }
        \\
        \\        const selector = readString(selectorPtr, selectorLen);
        \\        const className = readString(classPtr, classLen);
        \\        for (const element of doc.querySelectorAll(selector)) {
        \\          element.classList.toggle(className, present === 1);
        \\        }
        \\      },
        \\      js_focus_by_id(idPtr, idLen) {
        \\        const id = readString(idPtr, idLen);
        \\        const element = getElementById(id);
        \\        if (element && "focus" in element) {
        \\          element.focus();
        \\        }
        \\      },
        \\      js_scroll_into_view_by_selector(selectorPtr, selectorLen) {
        \\        const doc = getDocument();
        \\        if (!doc) {
        \\          warn("document is unavailable while scrolling into view");
        \\          return;
        \\        }
        \\
        \\        const selector = readString(selectorPtr, selectorLen);
        \\        const element = doc.querySelector(selector);
        \\        if (element instanceof HTMLElement) {
        \\          element.scrollIntoView({ block: "nearest" });
        \\        }
        \\      },
        ,
    },
    .{
        .id = .imports_storage,
        .deps = &.{ .callback_string },
        .source =
        \\      js_storage_set(kind, keyPtr, keyLen, valuePtr, valueLen) {
        \\        const storage = getStorage(kind);
        \\        if (!storage) {
        \\          return;
        \\        }
        \\
        \\        try {
        \\          storage.setItem(readString(keyPtr, keyLen), readString(valuePtr, valueLen));
        \\        } catch (error) {
        \\          warn("storage set failed", error);
        \\        }
        \\      },
        \\      js_storage_get(kind, requestId, keyPtr, keyLen) {
        \\        const storage = getStorage(kind);
        \\        const key = readString(keyPtr, keyLen);
        \\        if (!storage) {
        \\          deliverString(1, requestId, "");
        \\          return;
        \\        }
        \\
        \\        try {
        \\          deliverString(1, requestId, storage.getItem(key) ?? "");
        \\        } catch (error) {
        \\          warn("storage get failed", error);
        \\          deliverString(1, requestId, "");
        \\        }
        \\      },
        \\      js_storage_remove(kind, keyPtr, keyLen) {
        \\        const storage = getStorage(kind);
        \\        if (!storage) {
        \\          return;
        \\        }
        \\
        \\        try {
        \\          storage.removeItem(readString(keyPtr, keyLen));
        \\        } catch (error) {
        \\          warn("storage remove failed", error);
        \\        }
        \\      },
        ,
    },
    .{
        .id = .imports_fetch,
        .deps = &.{ .callback_fetch },
        .source =
        \\      js_fetch_text(requestId, methodPtr, methodLen, urlPtr, urlLen, bodyPtr, bodyLen) {
        \\        const method = readString(methodPtr, methodLen);
        \\        const url = readString(urlPtr, urlLen);
        \\        const body = readString(bodyPtr, bodyLen);
        \\
        \\        if (typeof fetch !== "function") {
        \\          warn("fetch API is unavailable");
        \\          deliverFetch(requestId, false, 0, "fetch API is unavailable");
        \\          return;
        \\        }
        \\
        \\        fetch(url, {
        \\          method,
        \\          body: bodyLen === 0 ? undefined : body,
        \\        })
        \\          .then(async (response) => {
        \\            const text = await response.text();
        \\            deliverFetch(requestId, response.ok, response.status, text);
        \\          })
        \\          .catch((error) => {
        \\            console.error(error);
        \\            deliverFetch(requestId, false, 0, String(error));
        \\          });
        \\      },
        ,
    },
    .{
        .id = .imports_timer,
        .deps = &.{ .timer_state, .callback_timer },
        .source =
        \\      js_set_timeout(timerId, delayMs) {
        \\        const scheduler = globalThis?.setTimeout;
        \\        if (typeof scheduler !== "function") {
        \\          warn(`setTimeout is unavailable for timer ${timerId}`);
        \\          return;
        \\        }
        \\
        \\        const handle = scheduler(() => {
        \\          timeoutHandles.delete(timerId);
        \\          deliverTimer(timerId);
        \\        }, delayMs);
        \\        timeoutHandles.set(timerId, handle);
        \\      },
        \\      js_clear_timeout(timerId) {
        \\        const handle = timeoutHandles.get(timerId);
        \\        if (handle !== undefined) {
        \\          if (typeof globalThis?.clearTimeout === "function") {
        \\            globalThis.clearTimeout(handle);
        \\          }
        \\          timeoutHandles.delete(timerId);
        \\        }
        \\      },
        ,
    },
    .{
        .id = .imports_history,
        .deps = &.{},
        .source =
        \\      js_history_push(urlPtr, urlLen) {
        \\        const url = readString(urlPtr, urlLen);
        \\        if (typeof history?.pushState !== "function") {
        \\          warn(`history.pushState is unavailable for url ${url}`);
        \\          return;
        \\        }
        \\
        \\        try {
        \\          history.pushState({}, "", url);
        \\        } catch (error) {
        \\          warn(`history.pushState failed for url ${url}`, error);
        \\        }
        \\      },
        \\      js_set_document_title(titlePtr, titleLen) {
        \\        const doc = getDocument();
        \\        if (!doc) {
        \\          warn("document is unavailable while setting title");
        \\          return;
        \\        }
        \\        doc.title = readString(titlePtr, titleLen);
        \\      },
        ,
    },
    .{
        .id = .module_end,
        .deps = &.{ .imports_start, .imports_core },
        .source =
        \\    },
        \\  };
        \\
        \\  const imports = mergeImports(baseImports, config.imports);
        \\
        \\  async function instantiate() {
        \\    if (typeof fetch !== "function") {
        \\      throw new Error("fetch API is unavailable and the wasm module cannot be loaded");
        \\    }
        \\
        \\    const response = await fetch(config.wasmUrl);
        \\    if (!response.ok) {
        \\      throw new Error(`fetch failed: ${response.status} ${response.statusText}`);
        \\    }
        \\
        \\    const bytes = await response.arrayBuffer();
        \\    const wasmModule = await WebAssembly.instantiate(bytes, imports);
        \\    instance = wasmModule.instance;
        \\    validateRequiredExports(instance);
        \\    return instance;
        \\  }
        \\
        \\  return {
        \\    append,
        \\    get instance() {
        \\      return instance;
        \\    },
        \\    imports,
        \\    instantiate,
        \\    readString,
        \\    withWasmString,
        \\  };
        \\}
        \\
        ,
    },
    .{
        .id = .helper_document,
        .deps = &.{},
        .source =
        \\function getDocument() {
        \\  return typeof document === "object" ? document : null;
        \\}
        \\
        \\function resolveLogElement(logSelector) {
        \\  if (!logSelector) {
        \\    return null;
        \\  }
        \\
        \\  const doc = getDocument();
        \\  if (!doc) {
        \\    return null;
        \\  }
        \\
        \\  return typeof logSelector === "string"
        \\    ? doc.querySelector(logSelector)
        \\    : logSelector;
        \\}
        \\
        ,
    },
    .{
        .id = .helper_storage,
        .deps = &.{},
        .source =
        \\function getStorage(kind) {
        \\  try {
        \\    return kind === 0 ? globalThis.localStorage : globalThis.sessionStorage;
        \\  } catch (error) {
        \\    console.warn("bridge warning: storage access failed", error);
        \\    return null;
        \\  }
        \\}
        \\
        ,
    },
    .{
        .id = .helper_validate,
        .deps = &.{},
        .source =
        \\function validateRequiredExports(instance) {
        \\  const { exports } = instance;
        \\  if (!(exports.memory instanceof WebAssembly.Memory)) {
        \\    throw new Error("wasm export 'memory' is missing or invalid");
        \\  }
        \\  if (typeof exports.allocBytes !== "function") {
        \\    throw new Error("wasm export 'allocBytes' is missing");
        \\  }
        \\  if (typeof exports.freeBytes !== "function") {
        \\    throw new Error("wasm export 'freeBytes' is missing");
        \\  }
        \\}
        \\
        ,
    },
    .{
        .id = .helper_merge,
        .deps = &.{},
        .source =
        \\function mergeImports(baseImports, extraImports) {
        \\  const result = { ...baseImports };
        \\
        \\  for (const [namespace, value] of Object.entries(extraImports)) {
        \\    result[namespace] = {
        \\      ...(result[namespace] ?? {}),
        \\      ...value,
        \\    };
        \\  }
        \\
        \\  return result;
        \\}
        ,
    },
};

test "parseCapabilities handles full and explicit groups" {
    try std.testing.expectEqual(Selection.full(), try parseCapabilities(null));
    try std.testing.expectEqual(Selection.full(), try parseCapabilities("full"));
    try std.testing.expectEqual(Selection{}, try parseCapabilities("core"));

    const selection = try parseCapabilities("dom, fetch");
    try std.testing.expect(selection.dom);
    try std.testing.expect(selection.fetch);
    try std.testing.expect(!selection.storage);
    try std.testing.expect(!selection.timer);
    try std.testing.expect(!selection.history);
}

test "parseCapabilities rejects unknown names" {
    try std.testing.expectError(error.UnknownCapability, parseCapabilities("dom,routing"));
}

test "render core bridge omits optional capability imports" {
    const output = try render(std.testing.allocator, .{});
    defer std.testing.allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "createBrowserBridge") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_now_ms") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_fetch_text") == null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_storage_get") == null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_set_timeout") == null);
}

test "render expands capability dependencies" {
    const output = try render(std.testing.allocator, .{ .storage = true });
    defer std.testing.allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "js_storage_get") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "function deliverString") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "function getStorage") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_fetch_text") == null);
}

test "render is deterministic" {
    const a = try render(std.testing.allocator, .{ .history = true, .dom = true });
    defer std.testing.allocator.free(a);
    const b = try render(std.testing.allocator, .{ .dom = true, .history = true });
    defer std.testing.allocator.free(b);

    try std.testing.expectEqualStrings(a, b);
}

test "render full profile includes all import groups" {
    const output = try render(std.testing.allocator, Selection.full());
    defer std.testing.allocator.free(output);

    try std.testing.expect(std.mem.indexOf(u8, output, "js_set_text_by_id") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_storage_get") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_fetch_text") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_set_timeout") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "js_history_push") != null);
}
