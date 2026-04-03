const std = @import("std");
const builtin = @import("builtin");

pub const PtrLen = extern struct {
    ptr: usize,
    len: usize,
};

pub fn allocator() std.mem.Allocator {
    return if (builtin.target.cpu.arch == .wasm32)
        std.heap.wasm_allocator
    else
        std.heap.page_allocator;
}

pub export fn allocBytes(len: usize) usize {
    const bytes = allocator().alloc(u8, len) catch return 0;
    return @intFromPtr(bytes.ptr);
}

pub export fn freeBytes(ptr: usize, len: usize) void {
    if (ptr == 0 or len == 0) return;
    allocator().free(bytesFromPtrLen(ptr, len));
}

pub fn sliceFromPtrLen(ptr: usize, len: usize) []const u8 {
    if (len == 0) return "";
    return @as([*]const u8, @ptrFromInt(ptr))[0..len];
}

pub fn bytesFromPtrLen(ptr: usize, len: usize) []u8 {
    if (len == 0) return &.{};
    return @as([*]u8, @ptrFromInt(ptr))[0..len];
}

pub fn ptrLen(bytes: []const u8) PtrLen {
    return .{
        .ptr = @intFromPtr(bytes.ptr),
        .len = bytes.len,
    };
}

test "alloc/free roundtrip" {
    const ptr = allocBytes(16);
    defer freeBytes(ptr, 16);
    try std.testing.expect(ptr != 0);
}

test "sliceFromPtrLen returns empty slice for zero length" {
    try std.testing.expectEqualStrings("", sliceFromPtrLen(0, 0));
}

test "bytesFromPtrLen returns empty slice for zero length" {
    try std.testing.expectEqual(@as(usize, 0), bytesFromPtrLen(0, 0).len);
}

test "ptrLen preserves pointer and length" {
    const text = "hello";
    const span = ptrLen(text);
    try std.testing.expectEqual(text.len, span.len);
    try std.testing.expectEqualStrings(text, sliceFromPtrLen(span.ptr, span.len));
}
