const std = @import("std");
const imports = @import("internal/browser_imports.zig");

pub fn log(message: []const u8) void {
    imports.log_fn(message.ptr, message.len);
}

pub fn logError(message: []const u8) void {
    imports.error_fn(message.ptr, message.len);
}

pub fn logFmt(comptime format: []const u8, args: anytype) void {
    var buffer: [256]u8 = undefined;
    const rendered = std.fmt.bufPrint(&buffer, format, args) catch "logFmt overflow";
    log(rendered);
}

pub fn nowMs() f64 {
    return imports.now_ms_fn();
}

pub fn rawSetTextById(id: []const u8, text: []const u8) void {
    imports.set_text_by_id_fn(id.ptr, id.len, text.ptr, text.len);
}

pub fn rawSetHtmlById(id: []const u8, html: []const u8) void {
    imports.set_html_by_id_fn(id.ptr, id.len, html.ptr, html.len);
}

pub fn rawSetValueById(id: []const u8, value: []const u8) void {
    imports.set_value_by_id_fn(id.ptr, id.len, value.ptr, value.len);
}

pub fn rawSetCheckedById(id: []const u8, checked: bool) void {
    imports.set_checked_by_id_fn(id.ptr, id.len, if (checked) 1 else 0);
}

pub fn rawSetAttributeById(id: []const u8, attr: []const u8, value: []const u8) void {
    imports.set_attribute_by_id_fn(id.ptr, id.len, attr.ptr, attr.len, value.ptr, value.len);
}

pub fn rawSetDisabledById(id: []const u8, disabled: bool) void {
    imports.set_disabled_by_id_fn(id.ptr, id.len, if (disabled) 1 else 0);
}

pub fn rawGetValueById(request_id: u32, id: []const u8) void {
    imports.get_value_by_id_fn(request_id, id.ptr, id.len);
}

pub fn rawGetCheckedById(request_id: u32, id: []const u8) void {
    imports.get_checked_by_id_fn(request_id, id.ptr, id.len);
}

pub fn rawToggleClassById(id: []const u8, class_name: []const u8, present: bool) void {
    imports.toggle_class_by_id_fn(id.ptr, id.len, class_name.ptr, class_name.len, if (present) 1 else 0);
}

pub fn rawToggleClassOnSelector(selector: []const u8, class_name: []const u8, present: bool) void {
    imports.toggle_class_on_selector_fn(selector.ptr, selector.len, class_name.ptr, class_name.len, if (present) 1 else 0);
}

pub fn rawFocusById(id: []const u8) void {
    imports.focus_by_id_fn(id.ptr, id.len);
}

pub fn rawScrollIntoViewBySelector(selector: []const u8) void {
    imports.scroll_into_view_by_selector_fn(selector.ptr, selector.len);
}

pub fn rawStorageSet(kind: u32, key: []const u8, value: []const u8) void {
    imports.storage_set_fn(kind, key.ptr, key.len, value.ptr, value.len);
}

pub fn rawStorageGet(kind: u32, request_id: u32, key: []const u8) void {
    imports.storage_get_fn(kind, request_id, key.ptr, key.len);
}

pub fn rawStorageRemove(kind: u32, key: []const u8) void {
    imports.storage_remove_fn(kind, key.ptr, key.len);
}

pub fn rawFetchText(request_id: u32, method: []const u8, url: []const u8, body: []const u8) void {
    imports.fetch_text_fn(
        request_id,
        method.ptr,
        method.len,
        url.ptr,
        url.len,
        body.ptr,
        body.len,
    );
}

pub fn rawSetTimeout(timer_id: u32, delay_ms: u32) void {
    imports.set_timeout_fn(timer_id, delay_ms);
}

pub fn rawClearTimeout(timer_id: u32) void {
    imports.clear_timeout_fn(timer_id);
}

pub fn rawHistoryPush(url: []const u8) void {
    imports.history_push_fn(url.ptr, url.len);
}

pub fn rawSetDocumentTitle(title: []const u8) void {
    imports.set_document_title_fn(title.ptr, title.len);
}

test "logFmt compiles and remains callable on non-wasm targets" {
    logFmt("bridge test {d}", .{1});
}
