const bridge = @import("bridge.zig");

pub fn fetchText(request_id: u32, method: []const u8, url: []const u8, body: ?[]const u8) void {
    const payload = body orelse "";
    bridge.rawFetchText(request_id, method, url, payload);
}

test "fetchText wrapper compiles on non-wasm targets" {
    fetchText(1, "GET", "/api/health", null);
    fetchText(2, "POST", "/api/echo", "hello");
}
