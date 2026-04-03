const bridge = @import("bridge.zig");

pub fn setTextById(id: []const u8, text: []const u8) void {
    bridge.rawSetTextById(id, text);
}

pub fn setHtmlById(id: []const u8, html: []const u8) void {
    bridge.rawSetHtmlById(id, html);
}

pub fn setValueById(id: []const u8, value: []const u8) void {
    bridge.rawSetValueById(id, value);
}

pub fn setCheckedById(id: []const u8, checked: bool) void {
    bridge.rawSetCheckedById(id, checked);
}

pub fn setAttributeById(id: []const u8, attr: []const u8, value: []const u8) void {
    bridge.rawSetAttributeById(id, attr, value);
}

pub fn setDisabledById(id: []const u8, disabled: bool) void {
    bridge.rawSetDisabledById(id, disabled);
}

pub fn getValueById(request_id: u32, id: []const u8) void {
    bridge.rawGetValueById(request_id, id);
}

pub fn getCheckedById(request_id: u32, id: []const u8) void {
    bridge.rawGetCheckedById(request_id, id);
}

pub fn toggleClassById(id: []const u8, class_name: []const u8, present: bool) void {
    bridge.rawToggleClassById(id, class_name, present);
}

pub fn toggleClassOnSelector(selector: []const u8, class_name: []const u8, present: bool) void {
    bridge.rawToggleClassOnSelector(selector, class_name, present);
}

pub fn focusById(id: []const u8) void {
    bridge.rawFocusById(id);
}

pub fn scrollIntoViewBySelector(selector: []const u8) void {
    bridge.rawScrollIntoViewBySelector(selector);
}

test "dom wrappers compile on non-wasm targets" {
    setTextById("status", "ok");
    setHtmlById("status", "<strong>ok</strong>");
    setValueById("field", "value");
    setCheckedById("toggle", true);
    setAttributeById("status", "data-state", "ready");
    setDisabledById("submit", false);
    getValueById(1, "field");
    getCheckedById(2, "toggle");
    toggleClassById("status", "is-ready", true);
    toggleClassOnSelector(".row", "is-ready", true);
    focusById("field");
    scrollIntoViewBySelector(".current");
}
