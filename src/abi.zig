pub const StorageKind = enum(u32) {
    local = 0,
    session = 1,
};

pub const StringKind = enum(u32) {
    storage = 1,
    input_value = 2,
};

pub const FetchStatus = enum(u32) {
    failed = 0,
    ok = 1,
};

pub const exports = struct {
    pub const alloc_bytes = "allocBytes";
    pub const free_bytes = "freeBytes";
    pub const receive_string = "bridgeReceiveString";
    pub const receive_fetch = "bridgeReceiveFetch";
    pub const timer_fired = "bridgeTimerFired";
};

test "enum values match the proven bridge contract" {
    try @import("std").testing.expectEqual(@as(u32, 0), @intFromEnum(StorageKind.local));
    try @import("std").testing.expectEqual(@as(u32, 1), @intFromEnum(StorageKind.session));
    try @import("std").testing.expectEqual(@as(u32, 1), @intFromEnum(StringKind.storage));
    try @import("std").testing.expectEqual(@as(u32, 2), @intFromEnum(StringKind.input_value));
}
