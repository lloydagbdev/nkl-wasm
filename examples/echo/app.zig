const std = @import("std");
const nkl_wasm = @import("nkl_wasm");

const input_request_id: u32 = 1;

var message_count: usize = 0;

export fn start() void {
    nkl_wasm.dom.setTextById("status", "Ready.");
    nkl_wasm.dom.focusById("echo-input");
}

export fn onEchoSubmit() void {
    nkl_wasm.dom.getValueById(input_request_id, "echo-input");
}

export fn onClearLog() void {
    message_count = 0;
    nkl_wasm.dom.setValueById("echo-input", "");
    nkl_wasm.dom.setTextById("echo-output", "");
    nkl_wasm.dom.setTextById("status", "Cleared.");
    nkl_wasm.dom.focusById("echo-input");
}

export fn bridgeReceiveString(kind: u32, request_id: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveString(kind, request_id, ptr, len) catch return;
    if (callback.kind != .input_value) return;
    if (callback.request_id != input_request_id) return;

    const value = std.mem.trim(u8, callback.text, &std.ascii.whitespace);
    if (value.len == 0) {
        nkl_wasm.dom.setTextById("status", "Type a message before echoing.");
        nkl_wasm.dom.focusById("echo-input");
        return;
    }

    message_count += 1;

    var output_buffer: [512]u8 = undefined;
    const output = std.fmt.bufPrint(&output_buffer, "echo {d}: {s}", .{ message_count, value }) catch "echo";
    nkl_wasm.dom.setTextById("echo-output", output);
    nkl_wasm.dom.setValueById("echo-input", "");

    var status_buffer: [96]u8 = undefined;
    const status = std.fmt.bufPrint(&status_buffer, "Last message length: {d}", .{value.len}) catch "Updated.";
    nkl_wasm.dom.setTextById("status", status);
    nkl_wasm.dom.focusById("echo-input");
}

test "bridgeReceiveString ignores unknown request ids" {
    bridgeReceiveString(@intFromEnum(nkl_wasm.StringKind.input_value), 99, 0, 0);
}
