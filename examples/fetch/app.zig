const std = @import("std");
const nkl_wasm = @import("nkl_wasm");

const fetch_request_id: u32 = 1;

export fn start() void {
    nkl_wasm.dom.setTextById("status", "Ready to fetch.");
}

export fn onFetchClick() void {
    nkl_wasm.dom.setTextById("status", "Loading ./data.txt ...");
    nkl_wasm.fetch.fetchText(fetch_request_id, "GET", "./data.txt", null);
}

export fn onClearClick() void {
    nkl_wasm.dom.setTextById("fetch-output", "");
    nkl_wasm.dom.setTextById("status", "Cleared.");
}

export fn bridgeReceiveFetch(request_id: u32, ok: u32, status: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveFetch(request_id, ok, status, ptr, len) catch return;
    if (callback.request_id != fetch_request_id) return;

    if (!callback.ok()) {
        var buffer: [128]u8 = undefined;
        const message = std.fmt.bufPrint(&buffer, "Fetch failed with status {d}.", .{callback.status}) catch "Fetch failed.";
        nkl_wasm.dom.setTextById("status", message);
        nkl_wasm.dom.setTextById("fetch-output", callback.text);
        return;
    }

    nkl_wasm.dom.setTextById("fetch-output", callback.text);

    var buffer: [128]u8 = undefined;
    const message = std.fmt.bufPrint(&buffer, "Fetched {d} bytes with status {d}.", .{ callback.text.len, callback.status }) catch "Fetch succeeded.";
    nkl_wasm.dom.setTextById("status", message);
}

test "bridgeReceiveFetch ignores unrelated request ids" {
    bridgeReceiveFetch(99, 1, 200, 0, 0);
}

test "bridgeReceiveFetch ignores malformed payload pointers" {
    bridgeReceiveFetch(fetch_request_id, 1, 200, 0, 4);
}

test "bridgeReceiveFetch ignores unknown fetch status kinds" {
    bridgeReceiveFetch(fetch_request_id, 9, 200, 0, 0);
}
