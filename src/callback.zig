const abi = @import("abi.zig");
const memory = @import("memory.zig");

pub const Error = error{
    UnknownStringKind,
    UnknownFetchStatus,
    InvalidPtrLen,
};

pub const StringCallback = struct {
    kind: abi.StringKind,
    request_id: u32,
    text: []const u8,
};

pub const FetchCallback = struct {
    request_id: u32,
    status_kind: abi.FetchStatus,
    status: u32,
    text: []const u8,

    pub fn ok(self: FetchCallback) bool {
        return self.status_kind == .ok;
    }
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
        .text = try memory.checkedSliceFromPtrLen(ptr, len),
    };
}

pub fn fetchStatusFromInt(value: u32) Error!abi.FetchStatus {
    return switch (value) {
        @intFromEnum(abi.FetchStatus.failed) => .failed,
        @intFromEnum(abi.FetchStatus.ok) => .ok,
        else => error.UnknownFetchStatus,
    };
}

pub fn receiveFetch(request_id: u32, ok: u32, status: u32, ptr: usize, len: usize) Error!FetchCallback {
    return .{
        .request_id = request_id,
        .status_kind = try fetchStatusFromInt(ok),
        .status = status,
        .text = try memory.checkedSliceFromPtrLen(ptr, len),
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

test "receiveString rejects non-zero length with null pointer" {
    try @import("std").testing.expectError(
        error.InvalidPtrLen,
        receiveString(@intFromEnum(abi.StringKind.input_value), 1, 0, 2),
    );
}

test "receiveFetch decodes success and payload text" {
    const text = "payload";
    const callback = try receiveFetch(9, 1, 200, @intFromPtr(text.ptr), text.len);
    try @import("std").testing.expect(callback.ok());
    try @import("std").testing.expectEqual(@as(u32, 9), callback.request_id);
    try @import("std").testing.expectEqual(abi.FetchStatus.ok, callback.status_kind);
    try @import("std").testing.expectEqual(@as(u32, 200), callback.status);
    try @import("std").testing.expectEqualStrings(text, callback.text);
}

test "receiveFetch rejects unknown status kinds" {
    try @import("std").testing.expectError(error.UnknownFetchStatus, receiveFetch(1, 9, 200, 0, 0));
}

test "receiveFetch rejects non-zero length with null pointer" {
    try @import("std").testing.expectError(error.InvalidPtrLen, receiveFetch(1, 1, 200, 0, 2));
}
