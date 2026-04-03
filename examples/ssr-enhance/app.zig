const std = @import("std");
const nkl_wasm = @import("nkl_wasm");

const initial_count_request_id: u32 = 1;

var counter: usize = 0;
var booted = false;

export fn start() void {
    nkl_wasm.dom.setTextById("wasm-status", "Wasm booted. Reading server-provided state...");
    nkl_wasm.dom.getValueById(initial_count_request_id, "initial-count");
}

export fn onIncrementClick() void {
    counter += 1;
    render();
}

export fn bridgeReceiveString(kind: u32, request_id: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveString(kind, request_id, ptr, len) catch return;
    if (callback.kind != .input_value) return;
    if (callback.request_id != initial_count_request_id) return;

    counter = std.fmt.parseInt(usize, callback.text, 10) catch 0;
    booted = true;
    render();
}

fn render() void {
    var count_buffer: [64]u8 = undefined;
    const count_text = std.fmt.bufPrint(&count_buffer, "{d}", .{counter}) catch "0";
    nkl_wasm.dom.setTextById("count-value", count_text);

    var status_buffer: [160]u8 = undefined;
    const status = if (booted)
        std.fmt.bufPrint(
            &status_buffer,
            "Wasm active. Server rendered the initial HTML; Wasm now owns the counter from {d}.",
            .{counter},
        ) catch "Wasm active."
    else
        "Booting...";
    nkl_wasm.dom.setTextById("wasm-status", status);

    nkl_wasm.dom.setDisabledById("increment-button", false);
}

test "bridgeReceiveString ignores unrelated request ids" {
    bridgeReceiveString(@intFromEnum(nkl_wasm.StringKind.input_value), 99, 0, 0);
}

test "bridgeReceiveString ignores malformed initial state payloads" {
    bridgeReceiveString(@intFromEnum(nkl_wasm.StringKind.input_value), initial_count_request_id, 0, 2);
}
