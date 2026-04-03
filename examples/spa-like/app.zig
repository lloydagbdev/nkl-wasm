const std = @import("std");
const nkl_wasm = @import("nkl_wasm");

const View = enum {
    home,
    about,
    notes,
};

var current_view: View = .home;

export fn start() void {
    nkl_wasm.dom.setTextById("status", "Booting SPA-like reference...");
}

export fn onNavigateHome() void {
    navigate(.home, true);
}

export fn onNavigateAbout() void {
    navigate(.about, true);
}

export fn onNavigateNotes() void {
    navigate(.notes, true);
}

export fn onLocationChange(ptr: u32, len: u32) void {
    const location = nkl_wasm.sliceFromPtrLen(ptr, len);
    navigate(viewFromLocation(location), false);
}

fn navigate(view: View, push_history: bool) void {
    current_view = view;
    if (push_history) {
        nkl_wasm.history.push(locationForView(view));
    }
    render();
}

fn render() void {
    nkl_wasm.history.setDocumentTitle(titleForView(current_view));
    nkl_wasm.dom.toggleClassById("nav-home", "is-active", current_view == .home);
    nkl_wasm.dom.toggleClassById("nav-about", "is-active", current_view == .about);
    nkl_wasm.dom.toggleClassById("nav-notes", "is-active", current_view == .notes);
    nkl_wasm.dom.setHtmlById("view-content", htmlForView(current_view));

    var buffer: [160]u8 = undefined;
    const status = std.fmt.bufPrint(
        &buffer,
        "SPA-like view active: {s}. URL updates are explicit and routed through Wasm.",
        .{viewLabel(current_view)},
    ) catch "SPA-like view active.";
    nkl_wasm.dom.setTextById("status", status);
}

fn viewFromLocation(location: []const u8) View {
    if (std.mem.indexOf(u8, location, "view=about") != null) return .about;
    if (std.mem.indexOf(u8, location, "view=notes") != null) return .notes;
    return .home;
}

fn locationForView(view: View) []const u8 {
    return switch (view) {
        .home => "?view=home",
        .about => "?view=about",
        .notes => "?view=notes",
    };
}

fn titleForView(view: View) []const u8 {
    return switch (view) {
        .home => "nkl-wasm SPA-like demo: Home",
        .about => "nkl-wasm SPA-like demo: About",
        .notes => "nkl-wasm SPA-like demo: Notes",
    };
}

fn viewLabel(view: View) []const u8 {
    return switch (view) {
        .home => "home",
        .about => "about",
        .notes => "notes",
    };
}

fn htmlForView(view: View) []const u8 {
    return switch (view) {
        .home =>
        \\<section><h2>Home</h2><p>This is a single-page style view switch driven by Wasm-owned state.</p></section>
        ,
        .about =>
        \\<section><h2>About</h2><p>The URL query string changes through <code>history.push</code>, but the app stays on one page.</p></section>
        ,
        .notes =>
        \\<section><h2>Notes</h2><ul><li>No framework router</li><li>No hidden lifecycle</li><li>Thin JS event wiring only</li></ul></section>
        ,
    };
}

test "viewFromLocation maps known query strings" {
    try std.testing.expectEqual(View.home, viewFromLocation(""));
    try std.testing.expectEqual(View.about, viewFromLocation("?view=about"));
    try std.testing.expectEqual(View.notes, viewFromLocation("?view=notes"));
}
