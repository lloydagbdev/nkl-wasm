const std = @import("std");
const bridge_assets = @import("src/js/bridge_assets.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const bridge_caps = b.option(
        []const u8,
        "browser_bridge_caps",
        "Comma-separated browser bridge capability groups: full, core, dom, storage, fetch, timer, history",
    ) orelse "full";
    const selected_bridge = bridgeAsset(b, bridge_caps);
    b.addNamedLazyPath("browser_bridge_js", selected_bridge.js);
    b.addNamedLazyPath("browser_bridge_asset_zig", selected_bridge.module);

    const mod = b.addModule("nkl_wasm", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const bridge_asset_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/js/bridge_assets.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_bridge_asset_tests = b.addRunArtifact(bridge_asset_tests);

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
        bridgeAsset(b, "dom").js,
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
        bridgeAsset(b, "dom,fetch").js,
        "examples/fetch/browser_bridge.js",
    );
    const ssr_enhance_wasm = b.addExecutable(.{
        .name = "nkl_wasm_ssr_enhance",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/ssr-enhance/app.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "nkl_wasm", .module = mod },
            },
        }),
    });
    ssr_enhance_wasm.entry = .disabled;
    ssr_enhance_wasm.rdynamic = true;
    ssr_enhance_wasm.import_symbols = true;
    ssr_enhance_wasm.export_memory = true;

    const install_ssr_enhance_wasm = b.addInstallFile(ssr_enhance_wasm.getEmittedBin(), "examples/ssr-enhance/app.wasm");
    const install_ssr_enhance_index = b.addInstallFile(b.path("examples/ssr-enhance/index.html"), "examples/ssr-enhance/index.html");
    const install_ssr_enhance_app_js = b.addInstallFile(b.path("examples/ssr-enhance/app.js"), "examples/ssr-enhance/app.js");
    const install_ssr_enhance_bridge_js = b.addInstallFile(
        bridgeAsset(b, "dom").js,
        "examples/ssr-enhance/browser_bridge.js",
    );
    const csr_wasm = b.addExecutable(.{
        .name = "nkl_wasm_csr",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/csr/app.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "nkl_wasm", .module = mod },
            },
        }),
    });
    csr_wasm.entry = .disabled;
    csr_wasm.rdynamic = true;
    csr_wasm.import_symbols = true;
    csr_wasm.export_memory = true;

    const install_csr_wasm = b.addInstallFile(csr_wasm.getEmittedBin(), "examples/csr/app.wasm");
    const install_csr_index = b.addInstallFile(b.path("examples/csr/index.html"), "examples/csr/index.html");
    const install_csr_app_js = b.addInstallFile(b.path("examples/csr/app.js"), "examples/csr/app.js");
    const install_csr_data = b.addInstallFile(b.path("examples/csr/data.txt"), "examples/csr/data.txt");
    const install_csr_bridge_js = b.addInstallFile(
        bridgeAsset(b, "dom,fetch").js,
        "examples/csr/browser_bridge.js",
    );
    const spa_like_wasm = b.addExecutable(.{
        .name = "nkl_wasm_spa_like",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/spa-like/app.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .imports = &.{
                .{ .name = "nkl_wasm", .module = mod },
            },
        }),
    });
    spa_like_wasm.entry = .disabled;
    spa_like_wasm.rdynamic = true;
    spa_like_wasm.import_symbols = true;
    spa_like_wasm.export_memory = true;

    const install_spa_like_wasm = b.addInstallFile(spa_like_wasm.getEmittedBin(), "examples/spa-like/app.wasm");
    const install_spa_like_index = b.addInstallFile(b.path("examples/spa-like/index.html"), "examples/spa-like/index.html");
    const install_spa_like_app_js = b.addInstallFile(b.path("examples/spa-like/app.js"), "examples/spa-like/app.js");
    const install_spa_like_bridge_js = b.addInstallFile(
        bridgeAsset(b, "dom,history").js,
        "examples/spa-like/browser_bridge.js",
    );

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_bridge_asset_tests.step);

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

    const example_ssr_enhance_step = b.step("example-ssr-enhance", "Install the SSR plus Wasm enhancement example assets");
    example_ssr_enhance_step.dependOn(&install_ssr_enhance_wasm.step);
    example_ssr_enhance_step.dependOn(&install_ssr_enhance_index.step);
    example_ssr_enhance_step.dependOn(&install_ssr_enhance_app_js.step);
    example_ssr_enhance_step.dependOn(&install_ssr_enhance_bridge_js.step);

    const example_csr_step = b.step("example-csr", "Install the client-rendered Wasm example assets");
    example_csr_step.dependOn(&install_csr_wasm.step);
    example_csr_step.dependOn(&install_csr_index.step);
    example_csr_step.dependOn(&install_csr_app_js.step);
    example_csr_step.dependOn(&install_csr_data.step);
    example_csr_step.dependOn(&install_csr_bridge_js.step);

    const example_spa_like_step = b.step("example-spa-like", "Install the SPA-like Wasm example assets");
    example_spa_like_step.dependOn(&install_spa_like_wasm.step);
    example_spa_like_step.dependOn(&install_spa_like_index.step);
    example_spa_like_step.dependOn(&install_spa_like_app_js.step);
    example_spa_like_step.dependOn(&install_spa_like_bridge_js.step);

    const serve_cmd = b.addSystemCommand(&.{ "python3", "-m", "http.server" });
    if (b.args) |args| {
        serve_cmd.addArgs(args);
    }

    const serve_step = b.step("serve", "Serve a static directory via python3 -m http.server");
    serve_step.dependOn(&serve_cmd.step);

    const example_check_cmd = b.addSystemCommand(&.{ "python3", "tools/check_example_assets.py" });
    example_check_cmd.setCwd(b.path("."));
    example_check_cmd.step.dependOn(&install_echo_wasm.step);
    example_check_cmd.step.dependOn(&install_echo_index.step);
    example_check_cmd.step.dependOn(&install_echo_app_js.step);
    example_check_cmd.step.dependOn(&install_echo_bridge_js.step);
    example_check_cmd.step.dependOn(&install_fetch_wasm.step);
    example_check_cmd.step.dependOn(&install_fetch_index.step);
    example_check_cmd.step.dependOn(&install_fetch_app_js.step);
    example_check_cmd.step.dependOn(&install_fetch_data.step);
    example_check_cmd.step.dependOn(&install_fetch_bridge_js.step);
    example_check_cmd.step.dependOn(&install_ssr_enhance_wasm.step);
    example_check_cmd.step.dependOn(&install_ssr_enhance_index.step);
    example_check_cmd.step.dependOn(&install_ssr_enhance_app_js.step);
    example_check_cmd.step.dependOn(&install_ssr_enhance_bridge_js.step);
    example_check_cmd.step.dependOn(&install_csr_wasm.step);
    example_check_cmd.step.dependOn(&install_csr_index.step);
    example_check_cmd.step.dependOn(&install_csr_app_js.step);
    example_check_cmd.step.dependOn(&install_csr_data.step);
    example_check_cmd.step.dependOn(&install_csr_bridge_js.step);
    example_check_cmd.step.dependOn(&install_spa_like_wasm.step);
    example_check_cmd.step.dependOn(&install_spa_like_index.step);
    example_check_cmd.step.dependOn(&install_spa_like_app_js.step);
    example_check_cmd.step.dependOn(&install_spa_like_bridge_js.step);

    const example_check_step = b.step("example-check", "Verify installed example asset bundles");
    example_check_step.dependOn(&example_check_cmd.step);

    const example_smoke_cmd = b.addSystemCommand(&.{ "python3", "tools/run_example_smoke.py" });
    example_smoke_cmd.setCwd(b.path("."));
    example_smoke_cmd.step.dependOn(&example_check_cmd.step);

    const example_smoke_step = b.step("example-smoke", "Serve and smoke-test installed example bundles");
    example_smoke_step.dependOn(&example_smoke_cmd.step);

    const bridge_js_check_cmd = b.addSystemCommand(&.{ "python3", "tools/check_browser_bridge_negative.py" });
    bridge_js_check_cmd.setCwd(b.path("."));

    const bridge_js_check_step = b.step("bridge-js-check", "Run negative-path checks for the packaged JS browser bridge");
    bridge_js_check_step.dependOn(&bridge_js_check_cmd.step);

    const selected_bridge_check_cmd = b.addSystemCommand(&.{ "python3", "tools/check_selected_bridge_assets.py" });
    selected_bridge_check_cmd.setCwd(b.path("."));
    selected_bridge_check_cmd.addFileArg(bridgeAsset(b, "core").js);
    selected_bridge_check_cmd.addFileArg(bridgeAsset(b, "storage,timer").js);
    selected_bridge_check_cmd.addFileArg(bridgeAsset(b, "dom,fetch").js);

    const selected_bridge_check_step = b.step("selected-bridge-check", "Run checks for selected JS browser bridge assets");
    selected_bridge_check_step.dependOn(&selected_bridge_check_cmd.step);

    const example_interaction_cmd = b.addSystemCommand(&.{ "python3", "tools/check_example_interactions.py" });
    example_interaction_cmd.setCwd(b.path("."));
    example_interaction_cmd.step.dependOn(&example_check_cmd.step);

    const example_interaction_step = b.step("example-interaction", "Run interaction checks for shipped examples under a minimal DOM harness");
    example_interaction_step.dependOn(&example_interaction_cmd.step);

    const verify_step = b.step("verify", "Run library tests and example smoke verification");
    verify_step.dependOn(&run_mod_tests.step);
    verify_step.dependOn(&run_bridge_asset_tests.step);
    verify_step.dependOn(&example_interaction_cmd.step);
    verify_step.dependOn(&example_smoke_cmd.step);
    verify_step.dependOn(&bridge_js_check_cmd.step);
    verify_step.dependOn(&selected_bridge_check_cmd.step);
}

const BridgeAsset = struct {
    js: std.Build.LazyPath,
    module: std.Build.LazyPath,
};

fn bridgeAsset(b: *std.Build, caps: []const u8) BridgeAsset {
    const selection = bridge_assets.parseCapabilities(caps) catch |err| {
        std.debug.panic("invalid browser_bridge_caps '{s}': {s}", .{ caps, @errorName(err) });
    };
    const source = bridge_assets.render(b.allocator, selection) catch @panic("failed to render browser bridge asset");
    const module_source = bridge_assets.renderAssetModule(b.allocator) catch @panic("failed to render browser bridge asset module");
    const files = b.addWriteFiles();
    return .{
        .js = files.add("browser_bridge.js", source),
        .module = files.add("browser_bridge_asset.zig", module_source),
    };
}
