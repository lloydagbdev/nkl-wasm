const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("nkl_wasm", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const echo_wasm = b.addExecutable(.{
        .name = "nkl_wasm_echo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/echo/app.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "nkl_wasm", .module = mod },
            },
        }),
    });
    echo_wasm.entry = .disabled;
    echo_wasm.rdynamic = true;
    echo_wasm.import_symbols = true;
    echo_wasm.export_memory = true;

    const install_echo_wasm = b.addInstallFile(echo_wasm.getEmittedBin(), "examples/echo/app.wasm");
    const install_echo_index = b.addInstallFile(b.path("examples/echo/index.html"), "examples/echo/index.html");
    const install_echo_app_js = b.addInstallFile(b.path("examples/echo/app.js"), "examples/echo/app.js");
    const install_echo_bridge_js = b.addInstallFile(
        b.path("src/js/browser_bridge.js"),
        "examples/echo/browser_bridge.js",
    );
    const fetch_wasm = b.addExecutable(.{
        .name = "nkl_wasm_fetch",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/fetch/app.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "nkl_wasm", .module = mod },
            },
        }),
    });
    fetch_wasm.entry = .disabled;
    fetch_wasm.rdynamic = true;
    fetch_wasm.import_symbols = true;
    fetch_wasm.export_memory = true;

    const install_fetch_wasm = b.addInstallFile(fetch_wasm.getEmittedBin(), "examples/fetch/app.wasm");
    const install_fetch_index = b.addInstallFile(b.path("examples/fetch/index.html"), "examples/fetch/index.html");
    const install_fetch_app_js = b.addInstallFile(b.path("examples/fetch/app.js"), "examples/fetch/app.js");
    const install_fetch_data = b.addInstallFile(b.path("examples/fetch/data.txt"), "examples/fetch/data.txt");
    const install_fetch_bridge_js = b.addInstallFile(
        b.path("src/js/browser_bridge.js"),
        "examples/fetch/browser_bridge.js",
    );

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_mod_tests.step);

    const example_echo_step = b.step("example-echo", "Install the echo Wasm example assets");
    example_echo_step.dependOn(&install_echo_wasm.step);
    example_echo_step.dependOn(&install_echo_index.step);
    example_echo_step.dependOn(&install_echo_app_js.step);
    example_echo_step.dependOn(&install_echo_bridge_js.step);

    const example_fetch_step = b.step("example-fetch", "Install the fetch Wasm example assets");
    example_fetch_step.dependOn(&install_fetch_wasm.step);
    example_fetch_step.dependOn(&install_fetch_index.step);
    example_fetch_step.dependOn(&install_fetch_app_js.step);
    example_fetch_step.dependOn(&install_fetch_data.step);
    example_fetch_step.dependOn(&install_fetch_bridge_js.step);

    const serve_cmd = b.addSystemCommand(&.{ "python3", "-m", "http.server" });
    if (b.args) |args| {
        serve_cmd.addArgs(args);
    }

    const serve_step = b.step("serve", "Serve a static directory via python3 -m http.server");
    serve_step.dependOn(&serve_cmd.step);
}
