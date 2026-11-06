const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost_dep = b.dependency("boost", .{
        .target = target,
        .optimize = optimize,
        .cobalt = true,
    });

    inline for (&.{
        "http_server.cc",
        "include_all.cc",
    }) |file| {
        buildTests(b, .{
            .target = target,
            .optimize = optimize,
            .files = &.{file},
            .name = b.fmt("test_{s}", .{file[0 .. file.len - 3]}),
            .dependency = boost_dep,
        });
    }
}
fn buildTests(b: *std.Build, options: struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    files: []const []const u8,
    name: []const u8,
    dependency: ?*std.Build.Dependency = null,
}) void {
    const exe = b.addExecutable(.{
        .name = options.name,
        .root_module = b.createModule(.{
            .target = options.target,
            .optimize = options.optimize,
        }),
    });

    if (options.dependency) |dep| {
        const artifact = dep.artifact("boost");
        for (artifact.root_module.include_dirs.items) |include_dir| {
            exe.root_module.include_dirs.append(b.allocator, include_dir) catch unreachable;
        }
        // if not header-only, link library
        if (std.mem.endsWith(u8, exe.name, "server"))
            exe.root_module.linkLibrary(artifact);
    }

    for (options.files) |file| {
        exe.root_module.addCSourceFile(.{
            .file = b.path(file),
            .flags = &.{
                "-std=c++20",
                "-Wall",
                "-Wextra",
                "-Wpedantic",
                "-Wformat",
            },
        });
    }
    if (exe.rootModuleTarget().abi != .msvc) {
        exe.root_module.link_libcpp = true;
        exe.root_module.addCMacro("_GNU_SOURCE", "");
    } else {
        exe.root_module.link_libc = true;
        // Disable auto-linking.
        exe.root_module.addCMacro("BOOST_ALL_NO_LIB", "");
    }

    // for boost::asio/boost::beast/boost::cobalt
    if (std.mem.endsWith(u8, exe.name, "server")) {
        if (exe.rootModuleTarget().os.tag == .windows) {
            exe.root_module.linkSystemLibrary("ws2_32", .{});
            exe.root_module.linkSystemLibrary("mswsock", .{});
        }
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step(exe.name, b.fmt("Run the {s}", .{exe.name}));
    run_step.dependOn(&run_cmd.step);
}
