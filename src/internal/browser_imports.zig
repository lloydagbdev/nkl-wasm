const builtin = @import("builtin");

fn noopVoid1U32(_: u32) void {}
fn noopVoid2U32(_: u32, _: u32) void {}
fn noopF64() f64 {
    return 0;
}
fn noopPtrLen(ptr: [*]const u8, len: usize) void {
    _ = ptr;
    _ = len;
}
fn noopReqIdPtrLen(request_id: u32, ptr: [*]const u8, len: usize) void {
    _ = request_id;
    _ = ptr;
    _ = len;
}
fn noopIdValue(id_ptr: [*]const u8, id_len: usize, value_ptr: [*]const u8, value_len: usize) void {
    _ = id_ptr;
    _ = id_len;
    _ = value_ptr;
    _ = value_len;
}
fn noopIdBool(id_ptr: [*]const u8, id_len: usize, value: u32) void {
    _ = id_ptr;
    _ = id_len;
    _ = value;
}
fn noopIdAttrValue(
    id_ptr: [*]const u8,
    id_len: usize,
    attr_ptr: [*]const u8,
    attr_len: usize,
    value_ptr: [*]const u8,
    value_len: usize,
) void {
    _ = id_ptr;
    _ = id_len;
    _ = attr_ptr;
    _ = attr_len;
    _ = value_ptr;
    _ = value_len;
}
fn noopKindKeyValue(
    kind: u32,
    key_ptr: [*]const u8,
    key_len: usize,
    value_ptr: [*]const u8,
    value_len: usize,
) void {
    _ = kind;
    _ = key_ptr;
    _ = key_len;
    _ = value_ptr;
    _ = value_len;
}
fn noopKindReqIdKey(kind: u32, request_id: u32, key_ptr: [*]const u8, key_len: usize) void {
    _ = kind;
    _ = request_id;
    _ = key_ptr;
    _ = key_len;
}
fn noopKindKey(kind: u32, key_ptr: [*]const u8, key_len: usize) void {
    _ = kind;
    _ = key_ptr;
    _ = key_len;
}
fn noopFetch(
    request_id: u32,
    method_ptr: [*]const u8,
    method_len: usize,
    url_ptr: [*]const u8,
    url_len: usize,
    body_ptr: [*]const u8,
    body_len: usize,
) void {
    _ = request_id;
    _ = method_ptr;
    _ = method_len;
    _ = url_ptr;
    _ = url_len;
    _ = body_ptr;
    _ = body_len;
}
fn noopSelectorClass(
    selector_ptr: [*]const u8,
    selector_len: usize,
    class_ptr: [*]const u8,
    class_len: usize,
    present: u32,
) void {
    _ = selector_ptr;
    _ = selector_len;
    _ = class_ptr;
    _ = class_len;
    _ = present;
}

extern "env" fn @"js_log"(ptr: [*]const u8, len: usize) void;
extern "env" fn @"js_error"(ptr: [*]const u8, len: usize) void;
extern "env" fn @"js_now_ms"() f64;
extern "env" fn @"js_set_text_by_id"(id_ptr: [*]const u8, id_len: usize, text_ptr: [*]const u8, text_len: usize) void;
extern "env" fn @"js_set_html_by_id"(id_ptr: [*]const u8, id_len: usize, html_ptr: [*]const u8, html_len: usize) void;
extern "env" fn @"js_set_value_by_id"(id_ptr: [*]const u8, id_len: usize, value_ptr: [*]const u8, value_len: usize) void;
extern "env" fn @"js_set_checked_by_id"(id_ptr: [*]const u8, id_len: usize, checked: u32) void;
extern "env" fn @"js_set_attribute_by_id"(
    id_ptr: [*]const u8,
    id_len: usize,
    attr_ptr: [*]const u8,
    attr_len: usize,
    value_ptr: [*]const u8,
    value_len: usize,
) void;
extern "env" fn @"js_set_disabled_by_id"(id_ptr: [*]const u8, id_len: usize, disabled: u32) void;
extern "env" fn @"js_get_value_by_id"(request_id: u32, id_ptr: [*]const u8, id_len: usize) void;
extern "env" fn @"js_get_checked_by_id"(request_id: u32, id_ptr: [*]const u8, id_len: usize) void;
extern "env" fn @"js_storage_set"(kind: u32, key_ptr: [*]const u8, key_len: usize, value_ptr: [*]const u8, value_len: usize) void;
extern "env" fn @"js_storage_get"(kind: u32, request_id: u32, key_ptr: [*]const u8, key_len: usize) void;
extern "env" fn @"js_storage_remove"(kind: u32, key_ptr: [*]const u8, key_len: usize) void;
extern "env" fn @"js_fetch_text"(
    request_id: u32,
    method_ptr: [*]const u8,
    method_len: usize,
    url_ptr: [*]const u8,
    url_len: usize,
    body_ptr: [*]const u8,
    body_len: usize,
) void;
extern "env" fn @"js_set_timeout"(timer_id: u32, delay_ms: u32) void;
extern "env" fn @"js_clear_timeout"(timer_id: u32) void;
extern "env" fn @"js_history_push"(url_ptr: [*]const u8, url_len: usize) void;
extern "env" fn @"js_set_document_title"(title_ptr: [*]const u8, title_len: usize) void;
extern "env" fn @"js_toggle_class_by_id"(
    id_ptr: [*]const u8,
    id_len: usize,
    class_ptr: [*]const u8,
    class_len: usize,
    present: u32,
) void;
extern "env" fn @"js_toggle_class_on_selector"(
    selector_ptr: [*]const u8,
    selector_len: usize,
    class_ptr: [*]const u8,
    class_len: usize,
    present: u32,
) void;
extern "env" fn @"js_focus_by_id"(id_ptr: [*]const u8, id_len: usize) void;
extern "env" fn @"js_scroll_into_view_by_selector"(selector_ptr: [*]const u8, selector_len: usize) void;

pub const log_fn = if (builtin.target.cpu.arch == .wasm32) @"js_log" else noopPtrLen;
pub const error_fn = if (builtin.target.cpu.arch == .wasm32) @"js_error" else noopPtrLen;
pub const now_ms_fn = if (builtin.target.cpu.arch == .wasm32) @"js_now_ms" else noopF64;
pub const set_text_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_text_by_id" else noopIdValue;
pub const set_html_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_html_by_id" else noopIdValue;
pub const set_value_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_value_by_id" else noopIdValue;
pub const set_checked_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_checked_by_id" else noopIdBool;
pub const set_attribute_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_attribute_by_id" else noopIdAttrValue;
pub const set_disabled_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_disabled_by_id" else noopIdBool;
pub const get_value_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_get_value_by_id" else noopReqIdPtrLen;
pub const get_checked_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_get_checked_by_id" else noopReqIdPtrLen;
pub const storage_set_fn = if (builtin.target.cpu.arch == .wasm32) @"js_storage_set" else noopKindKeyValue;
pub const storage_get_fn = if (builtin.target.cpu.arch == .wasm32) @"js_storage_get" else noopKindReqIdKey;
pub const storage_remove_fn = if (builtin.target.cpu.arch == .wasm32) @"js_storage_remove" else noopKindKey;
pub const fetch_text_fn = if (builtin.target.cpu.arch == .wasm32) @"js_fetch_text" else noopFetch;
pub const set_timeout_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_timeout" else noopVoid2U32;
pub const clear_timeout_fn = if (builtin.target.cpu.arch == .wasm32) @"js_clear_timeout" else noopVoid1U32;
pub const history_push_fn = if (builtin.target.cpu.arch == .wasm32) @"js_history_push" else noopPtrLen;
pub const set_document_title_fn = if (builtin.target.cpu.arch == .wasm32) @"js_set_document_title" else noopPtrLen;
pub const toggle_class_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_toggle_class_by_id" else noopSelectorClass;
pub const toggle_class_on_selector_fn = if (builtin.target.cpu.arch == .wasm32) @"js_toggle_class_on_selector" else noopSelectorClass;
pub const focus_by_id_fn = if (builtin.target.cpu.arch == .wasm32) @"js_focus_by_id" else noopPtrLen;
pub const scroll_into_view_by_selector_fn = if (builtin.target.cpu.arch == .wasm32) @"js_scroll_into_view_by_selector" else noopPtrLen;
