const std = @import("std");
const nkl_wasm = @import("nkl_wasm");

const list_request_id: u32 = 1;
const filter_request_id: u32 = 2;

var items = std.ArrayList([]u8).empty;
var filter_text: []u8 = &.{};

export fn start() void {
    nkl_wasm.dom.setTextById("status", "Booting client-rendered view...");
    nkl_wasm.dom.setDisabledById("filter-input", true);
    nkl_wasm.fetch.fetchText(list_request_id, "GET", "./data.txt", null);
}

export fn onFilterInput() void {
    nkl_wasm.dom.getValueById(filter_request_id, "filter-input");
}

export fn bridgeReceiveFetch(request_id: u32, ok: u32, status: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveFetch(request_id, ok, status, ptr, len) catch return;
    if (callback.request_id != list_request_id) return;

    if (!callback.ok()) {
        var buffer: [128]u8 = undefined;
        const message = std.fmt.bufPrint(&buffer, "Client fetch failed with status {d}.", .{callback.status}) catch "Client fetch failed.";
        nkl_wasm.dom.setTextById("status", message);
        return;
    }

    resetItems();

    var iterator = std.mem.splitScalar(u8, callback.text, '\n');
    while (iterator.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        const owned = nkl_wasm.allocator().dupe(u8, trimmed) catch return;
        items.append(nkl_wasm.allocator(), owned) catch {
            nkl_wasm.allocator().free(owned);
            return;
        };
    }

    nkl_wasm.dom.setDisabledById("filter-input", false);
    render();
}

export fn bridgeReceiveString(kind: u32, request_id: u32, ptr: u32, len: u32) void {
    const callback = nkl_wasm.callback.receiveString(kind, request_id, ptr, len) catch return;
    if (callback.kind != .input_value) return;
    if (callback.request_id != filter_request_id) return;

    if (filter_text.len != 0) {
        nkl_wasm.allocator().free(filter_text);
    }
    filter_text = nkl_wasm.allocator().dupe(u8, callback.text) catch return;
    render();
}

fn render() void {
    var html = std.ArrayList(u8).empty;
    defer html.deinit(nkl_wasm.allocator());

    html.appendSlice(nkl_wasm.allocator(), "<ul>") catch return;

    var visible_count: usize = 0;
    for (items.items) |item| {
        if (!matchesFilter(item, filter_text)) continue;
        html.appendSlice(nkl_wasm.allocator(), "<li>") catch return;
        appendEscaped(&html, item) catch return;
        html.appendSlice(nkl_wasm.allocator(), "</li>") catch return;
        visible_count += 1;
    }

    html.appendSlice(nkl_wasm.allocator(), "</ul>") catch return;

    nkl_wasm.dom.setHtmlById("items", html.items);

    var status_buffer: [160]u8 = undefined;
    const status = std.fmt.bufPrint(
        &status_buffer,
        "Client-rendered content loaded from Wasm. Showing {d} of {d} items.",
        .{ visible_count, items.items.len },
    ) catch "Client-rendered content loaded from Wasm.";
    nkl_wasm.dom.setTextById("status", status);
}

fn resetItems() void {
    for (items.items) |item| {
        nkl_wasm.allocator().free(item);
    }
    items.clearRetainingCapacity();
}

fn matchesFilter(text: []const u8, filter: []const u8) bool {
    if (filter.len == 0) return true;
    if (filter.len > text.len) return false;

    var cursor: usize = 0;
    while (cursor + filter.len <= text.len) : (cursor += 1) {
        var matched = true;
        var index: usize = 0;
        while (index < filter.len) : (index += 1) {
            if (std.ascii.toLower(text[cursor + index]) != std.ascii.toLower(filter[index])) {
                matched = false;
                break;
            }
        }
        if (matched) return true;
    }
    return false;
}

fn appendEscaped(buffer: *std.ArrayList(u8), text: []const u8) !void {
    for (text) |byte| {
        switch (byte) {
            '&' => try buffer.appendSlice(nkl_wasm.allocator(), "&amp;"),
            '<' => try buffer.appendSlice(nkl_wasm.allocator(), "&lt;"),
            '>' => try buffer.appendSlice(nkl_wasm.allocator(), "&gt;"),
            '"' => try buffer.appendSlice(nkl_wasm.allocator(), "&quot;"),
            '\'' => try buffer.appendSlice(nkl_wasm.allocator(), "&#39;"),
            else => try buffer.append(nkl_wasm.allocator(), byte),
        }
    }
}

test "bridgeReceiveFetch ignores unrelated request ids" {
    bridgeReceiveFetch(99, 1, 200, 0, 0);
}

test "bridgeReceiveFetch ignores malformed list payloads" {
    bridgeReceiveFetch(list_request_id, 1, 200, 0, 5);
}

test "bridgeReceiveFetch ignores unknown fetch status kinds" {
    bridgeReceiveFetch(list_request_id, 9, 200, 0, 0);
}

test "bridgeReceiveString ignores malformed filter payloads" {
    bridgeReceiveString(@intFromEnum(nkl_wasm.StringKind.input_value), filter_request_id, 0, 3);
}

test "matchesFilter is case-insensitive" {
    try std.testing.expect(matchesFilter("Alpha item", "alp"));
    try std.testing.expect(matchesFilter("Gamma item", "ITEM"));
    try std.testing.expect(!matchesFilter("Beta item", "zig"));
}
