const abi = @import("abi.zig");
const bridge = @import("bridge.zig");

pub fn set(kind: abi.StorageKind, key: []const u8, value: []const u8) void {
    bridge.rawStorageSet(@intFromEnum(kind), key, value);
}

pub fn get(kind: abi.StorageKind, request_id: u32, key: []const u8) void {
    bridge.rawStorageGet(@intFromEnum(kind), request_id, key);
}

pub fn remove(kind: abi.StorageKind, key: []const u8) void {
    bridge.rawStorageRemove(@intFromEnum(kind), key);
}

test "storage wrappers compile on non-wasm targets" {
    set(.local, "theme", "dark");
    get(.session, 3, "theme");
    remove(.local, "theme");
}
