const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost_dep = b.dependency("boost", .{
        .target = target,
        .optimize = optimize,
    });

    buildTests(b, .{
        .target = target,
        .optimize = optimize,
        .files = &.{
            "include_all.cc",
        },
        .name = "include_tests",
        .dependency = boost_dep,
    });
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
        .target = options.target,
        .optimize = options.optimize,
    });

    if (options.dependency) |dep| {
        const artifact = dep.artifact("boost");
        for (artifact.root_module.include_dirs.items) |include_dir| {
            exe.root_module.include_dirs.append(b.allocator, include_dir) catch unreachable;
        }
        // exe.linkLibrary(artifact);
    }

    for (options.files) |file| {
        exe.addCSourceFile(.{
            .file = b.path(file),
        });
    }
    if (exe.rootModuleTarget().abi != .msvc) {
        exe.linkLibCpp();
    } else {
        exe.linkLibC();
    }

    b.installArtifact(exe);
}
