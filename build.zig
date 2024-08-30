const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost = boostLibraries(b, .{
        .target = target,
        .optimize = optimize,
        .header_only = b.option(bool, "headers-only", "Build header-only libraries") orelse false,
    });
    b.installArtifact(boost);
}

const cxxFlags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wpedantic",
};

fn boostLibraries(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "boost",
        .target = config.target,
        .optimize = config.optimize,
    });

    const boostCore = b.dependency("core", .{}).path("");
    const boostAlg = b.dependency("algorithm", .{}).path("");
    const boostConfig = b.dependency("config", .{}).path("");
    const boostAssert = b.dependency("assert", .{}).path("");
    const boostTraits = b.dependency("type_traits", .{}).path("");
    const boostMP11 = b.dependency("mp11", .{}).path("");
    const boostRange = b.dependency("range", .{}).path("");
    const boostFunctional = b.dependency("functional", .{}).path("");
    const boostPreprocessor = b.dependency("preprocessor", .{}).path("");
    const boostHash = b.dependency("container_hash", .{}).path("");
    const boostDescribe = b.dependency("describe", .{}).path("");
    const boostMpl = b.dependency("mpl", .{}).path("");
    const boostIterator = b.dependency("iterator", .{}).path("");
    const boostStaticAssert = b.dependency("static_assert", .{}).path("");
    const boostMove = b.dependency("move", .{}).path("");
    const boostDetail = b.dependency("detail", .{}).path("");
    const boostThrow = b.dependency("throw_exception", .{}).path("");
    const boostTuple = b.dependency("tuple", .{}).path("");
    const boostPredef = b.dependency("predef", .{}).path("");
    const boostCCheck = b.dependency("concept_check", .{}).path("");
    const boostUtil = b.dependency("utility", .{}).path("");
    const boostEndian = b.dependency("endian", .{}).path("");
    const boostRegex = b.dependency("regex", .{}).path("");
    const boostAsio = b.dependency("asio", .{}).path("");
    const boostAlign = b.dependency("align", .{}).path("");
    const boostSystem = b.dependency("system", .{}).path("");
    const boostIntrusive = b.dependency("intrusive", .{}).path("");
    const boostHana = b.dependency("hana", .{}).path("");
    const boostOutcome = b.dependency("outcome", .{}).path("");
    const boostBind = b.dependency("bind", .{}).path("");
    const boostOptional = b.dependency("optional", .{}).path("");
    const boostDateTime = b.dependency("date_time", .{}).path("");
    const boostSmartPtr = b.dependency("smart_ptr", .{}).path("");
    const boostNumeric = b.dependency("numeric_conversion", .{}).path("");
    const boostLogic = b.dependency("logic", .{}).path("");
    const boostStaticStr = b.dependency("static_string", .{}).path("");
    const boostIO = b.dependency("io", .{}).path("");
    const boostJson = b.dependency("json", .{}).path("");
    const boostContainer = b.dependency("container", .{}).path("");
    const boostVariant2 = b.dependency("variant2", .{}).path("");
    const boostWinApi = b.dependency("winapi", .{}).path("");
    if (config.header_only) {
        // zig-pkg bypass (no header-only)
        const empty = b.addWriteFile("empty.cc", "// bypass");
        lib.step.dependOn(&empty.step);
        lib.addCSourceFiles(.{
            .root = empty.getDirectory(),
            .files = &.{"empty.cc"},
            .flags = cxxFlags,
        });
    } else {
        lib.addCSourceFiles(.{
            .root = boostContainer,
            .files = &.{
                "src/pool_resource.cpp",
                "src/monotonic_buffer_resource.cpp",
                "src/synchronized_pool_resource.cpp",
                "src/unsynchronized_pool_resource.cpp",
                "src/global_resource.cpp",
            },
            .flags = cxxFlags,
        });
        lib.addCSourceFiles(.{
            .root = boostJson,
            .files = &.{
                "src/src.cpp",
            },
            .flags = cxxFlags,
        });
        if (lib.rootModuleTarget().abi == .msvc)
            lib.linkLibC()
        else
            lib.linkLibCpp();
    }
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostCore.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostAlg.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostConfig.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostAssert.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostFunctional.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostMP11.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostTraits.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostRange.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostPreprocessor.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostHash.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostDescribe.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostMpl.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostStaticAssert.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostIterator.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostMove.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostDetail.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostThrow.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostTuple.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostPredef.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostCCheck.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostUtil.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostRegex.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostEndian.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostAsio.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostAlign.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostSystem.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostIntrusive.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostHana.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostOutcome.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostBind.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostOptional.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostDateTime.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostSmartPtr.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostNumeric.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostLogic.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostStaticStr.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostIO.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostJson.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostContainer.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostVariant2.getPath(b), "include" }) });
    lib.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ boostWinApi.getPath(b), "include" }) });

    return lib;
}

pub const Config = struct {
    header_only: bool,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};
