const std = @import("std");
const builtin = @import("builtin");

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

const js_log_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_log"
else
    struct {
        fn call(ptr: [*]const u8, len: usize) void {
            _ = ptr;
            _ = len;
        }
    }.call;
const js_error_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_error"
else
    struct {
        fn call(ptr: [*]const u8, len: usize) void {
            _ = ptr;
            _ = len;
        }
    }.call;
const js_now_ms_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_now_ms"
else
    struct {
        fn call() f64 {
            return 0;
        }
    }.call;
const js_set_text_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_text_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, text_ptr: [*]const u8, text_len: usize) void {
            _ = id_ptr;
            _ = id_len;
            _ = text_ptr;
            _ = text_len;
        }
    }.call;
const js_set_html_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_html_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, html_ptr: [*]const u8, html_len: usize) void {
            _ = id_ptr;
            _ = id_len;
            _ = html_ptr;
            _ = html_len;
        }
    }.call;
const js_set_value_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_value_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, value_ptr: [*]const u8, value_len: usize) void {
            _ = id_ptr;
            _ = id_len;
            _ = value_ptr;
            _ = value_len;
        }
    }.call;
const js_set_checked_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_checked_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, checked: u32) void {
            _ = id_ptr;
            _ = id_len;
            _ = checked;
        }
    }.call;
const js_set_attribute_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_attribute_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, attr_ptr: [*]const u8, attr_len: usize, value_ptr: [*]const u8, value_len: usize) void {
            _ = id_ptr;
            _ = id_len;
            _ = attr_ptr;
            _ = attr_len;
            _ = value_ptr;
            _ = value_len;
        }
    }.call;
const js_set_disabled_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_disabled_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, disabled: u32) void {
            _ = id_ptr;
            _ = id_len;
            _ = disabled;
        }
    }.call;
const js_get_value_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_get_value_by_id"
else
    struct {
        fn call(request_id: u32, id_ptr: [*]const u8, id_len: usize) void {
            _ = request_id;
            _ = id_ptr;
            _ = id_len;
        }
    }.call;
const js_get_checked_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_get_checked_by_id"
else
    struct {
        fn call(request_id: u32, id_ptr: [*]const u8, id_len: usize) void {
            _ = request_id;
            _ = id_ptr;
            _ = id_len;
        }
    }.call;
const js_storage_set_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_storage_set"
else
    struct {
        fn call(kind: u32, key_ptr: [*]const u8, key_len: usize, value_ptr: [*]const u8, value_len: usize) void {
            _ = kind;
            _ = key_ptr;
            _ = key_len;
            _ = value_ptr;
            _ = value_len;
        }
    }.call;
const js_storage_get_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_storage_get"
else
    struct {
        fn call(kind: u32, request_id: u32, key_ptr: [*]const u8, key_len: usize) void {
            _ = kind;
            _ = request_id;
            _ = key_ptr;
            _ = key_len;
        }
    }.call;
const js_storage_remove_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_storage_remove"
else
    struct {
        fn call(kind: u32, key_ptr: [*]const u8, key_len: usize) void {
            _ = kind;
            _ = key_ptr;
            _ = key_len;
        }
    }.call;
const js_fetch_text_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_fetch_text"
else
    struct {
        fn call(
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
    }.call;
const js_set_timeout_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_timeout"
else
    struct {
        fn call(timer_id: u32, delay_ms: u32) void {
            _ = timer_id;
            _ = delay_ms;
        }
    }.call;
const js_clear_timeout_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_clear_timeout"
else
    struct {
        fn call(timer_id: u32) void {
            _ = timer_id;
        }
    }.call;
const js_history_push_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_history_push"
else
    struct {
        fn call(url_ptr: [*]const u8, url_len: usize) void {
            _ = url_ptr;
            _ = url_len;
        }
    }.call;
const js_set_document_title_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_set_document_title"
else
    struct {
        fn call(title_ptr: [*]const u8, title_len: usize) void {
            _ = title_ptr;
            _ = title_len;
        }
    }.call;
const js_toggle_class_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_toggle_class_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize, class_ptr: [*]const u8, class_len: usize, present: u32) void {
            _ = id_ptr;
            _ = id_len;
            _ = class_ptr;
            _ = class_len;
            _ = present;
        }
    }.call;
const js_toggle_class_on_selector_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_toggle_class_on_selector"
else
    struct {
        fn call(selector_ptr: [*]const u8, selector_len: usize, class_ptr: [*]const u8, class_len: usize, present: u32) void {
            _ = selector_ptr;
            _ = selector_len;
            _ = class_ptr;
            _ = class_len;
            _ = present;
        }
    }.call;
const js_focus_by_id_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_focus_by_id"
else
    struct {
        fn call(id_ptr: [*]const u8, id_len: usize) void {
            _ = id_ptr;
            _ = id_len;
        }
    }.call;
const js_scroll_into_view_by_selector_fn = if (builtin.target.cpu.arch == .wasm32)
    @"js_scroll_into_view_by_selector"
else
    struct {
        fn call(selector_ptr: [*]const u8, selector_len: usize) void {
            _ = selector_ptr;
            _ = selector_len;
        }
    }.call;

pub fn log(message: []const u8) void {
    js_log_fn(message.ptr, message.len);
}

pub fn logError(message: []const u8) void {
    js_error_fn(message.ptr, message.len);
}

pub fn logFmt(comptime format: []const u8, args: anytype) void {
    var buffer: [256]u8 = undefined;
    const rendered = std.fmt.bufPrint(&buffer, format, args) catch "logFmt overflow";
    log(rendered);
}

pub fn nowMs() f64 {
    return js_now_ms_fn();
}

pub fn rawSetTextById(id: []const u8, text: []const u8) void {
    js_set_text_by_id_fn(id.ptr, id.len, text.ptr, text.len);
}

pub fn rawSetHtmlById(id: []const u8, html: []const u8) void {
    js_set_html_by_id_fn(id.ptr, id.len, html.ptr, html.len);
}

pub fn rawSetValueById(id: []const u8, value: []const u8) void {
    js_set_value_by_id_fn(id.ptr, id.len, value.ptr, value.len);
}

pub fn rawSetCheckedById(id: []const u8, checked: bool) void {
    js_set_checked_by_id_fn(id.ptr, id.len, if (checked) 1 else 0);
}

pub fn rawSetAttributeById(id: []const u8, attr: []const u8, value: []const u8) void {
    js_set_attribute_by_id_fn(id.ptr, id.len, attr.ptr, attr.len, value.ptr, value.len);
}

pub fn rawSetDisabledById(id: []const u8, disabled: bool) void {
    js_set_disabled_by_id_fn(id.ptr, id.len, if (disabled) 1 else 0);
}

pub fn rawGetValueById(request_id: u32, id: []const u8) void {
    js_get_value_by_id_fn(request_id, id.ptr, id.len);
}

pub fn rawGetCheckedById(request_id: u32, id: []const u8) void {
    js_get_checked_by_id_fn(request_id, id.ptr, id.len);
}

pub fn rawToggleClassById(id: []const u8, class_name: []const u8, present: bool) void {
    js_toggle_class_by_id_fn(id.ptr, id.len, class_name.ptr, class_name.len, if (present) 1 else 0);
}

pub fn rawToggleClassOnSelector(selector: []const u8, class_name: []const u8, present: bool) void {
    js_toggle_class_on_selector_fn(selector.ptr, selector.len, class_name.ptr, class_name.len, if (present) 1 else 0);
}

pub fn rawFocusById(id: []const u8) void {
    js_focus_by_id_fn(id.ptr, id.len);
}

pub fn rawScrollIntoViewBySelector(selector: []const u8) void {
    js_scroll_into_view_by_selector_fn(selector.ptr, selector.len);
}

pub fn rawStorageSet(kind: u32, key: []const u8, value: []const u8) void {
    js_storage_set_fn(kind, key.ptr, key.len, value.ptr, value.len);
}

pub fn rawStorageGet(kind: u32, request_id: u32, key: []const u8) void {
    js_storage_get_fn(kind, request_id, key.ptr, key.len);
}

pub fn rawStorageRemove(kind: u32, key: []const u8) void {
    js_storage_remove_fn(kind, key.ptr, key.len);
}

pub fn rawFetchText(request_id: u32, method: []const u8, url: []const u8, body: []const u8) void {
    js_fetch_text_fn(
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
    js_set_timeout_fn(timer_id, delay_ms);
}

pub fn rawClearTimeout(timer_id: u32) void {
    js_clear_timeout_fn(timer_id);
}

pub fn rawHistoryPush(url: []const u8) void {
    js_history_push_fn(url.ptr, url.len);
}

pub fn rawSetDocumentTitle(title: []const u8) void {
    js_set_document_title_fn(title.ptr, title.len);
}

test "logFmt compiles and remains callable on non-wasm targets" {
    logFmt("bridge test {d}", .{1});
}
