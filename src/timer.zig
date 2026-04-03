const bridge = @import("bridge.zig");

pub fn setTimeout(timer_id: u32, delay_ms: u32) void {
    bridge.rawSetTimeout(timer_id, delay_ms);
}

pub fn clearTimeout(timer_id: u32) void {
    bridge.rawClearTimeout(timer_id);
}

test "timer wrappers compile on non-wasm targets" {
    setTimeout(1, 60);
    clearTimeout(1);
}
