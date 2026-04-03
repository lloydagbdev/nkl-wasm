const bridge = @import("bridge.zig");

pub fn push(url: []const u8) void {
    bridge.rawHistoryPush(url);
}

pub fn setDocumentTitle(title: []const u8) void {
    bridge.rawSetDocumentTitle(title);
}

test "history wrappers compile on non-wasm targets" {
    push("/docs");
    setDocumentTitle("Docs");
}
