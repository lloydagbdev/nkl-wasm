const abi = @import("abi.zig");
const memory = @import("memory.zig");

pub const Error = error{
    UnknownStringKind,
};

pub const StringCallback = struct {
    kind: abi.StringKind,
    request_id: u32,
    text: []const u8,
};

pub const FetchCallback = struct {
    request_id: u32,
    ok: bool,
    status: u32,
    text: []const u8,
};

pub fn stringKindFromInt(value: u32) Error!abi.StringKind {
    return switch (value) {
        @intFromEnum(abi.StringKind.storage) => .storage,
        @intFromEnum(abi.StringKind.input_value) => .input_value,
        else => error.UnknownStringKind,
    };
}

pub fn receiveString(kind: u32, request_id: u32, ptr: usize, len: usize) Error!StringCallback {
    return .{
        .kind = try stringKindFromInt(kind),
        .request_id = request_id,
        .text = memory.sliceFromPtrLen(ptr, len),
    };
}

pub fn receiveFetch(request_id: u32, ok: u32, status: u32, ptr: usize, len: usize) FetchCallback {
    return .{
        .request_id = request_id,
        .ok = ok != 0,
        .status = status,
        .text = memory.sliceFromPtrLen(ptr, len),
    };
}

test "receiveString decodes the current string callback contract" {
    const text = "hello";
    const callback = try receiveString(@intFromEnum(abi.StringKind.input_value), 7, @intFromPtr(text.ptr), text.len);
    try @import("std").testing.expectEqual(abi.StringKind.input_value, callback.kind);
    try @import("std").testing.expectEqual(@as(u32, 7), callback.request_id);
    try @import("std").testing.expectEqualStrings(text, callback.text);
}

test "receiveString rejects unknown kinds" {
    try @import("std").testing.expectError(error.UnknownStringKind, receiveString(99, 1, 0, 0));
}

test "receiveFetch decodes success and payload text" {
    const text = "payload";
    const callback = receiveFetch(9, 1, 200, @intFromPtr(text.ptr), text.len);
    try @import("std").testing.expect(callback.ok);
    try @import("std").testing.expectEqual(@as(u32, 9), callback.request_id);
    try @import("std").testing.expectEqual(@as(u32, 200), callback.status);
    try @import("std").testing.expectEqualStrings(text, callback.text);
}
