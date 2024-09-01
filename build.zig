const std = @import("std");

const boost_libs = [_][]const u8{
    "core",
    "algorithm",
    "config",
    "assert",
    "type_traits",
    "mp11",
    "range",
    "functional",
    "preprocessor",
    "container_hash",
    "describe",
    "mpl",
    "iterator",
    "static_assert",
    "move",
    "detail",
    "throw_exception",
    "tuple",
    "predef",
    "concept_check",
    "utility",
    "endian",
    "regex",
    "asio",
    "align",
    "system",
    "intrusive",
    "hana",
    "outcome",
    "bind",
    "pfr",
    "array",
    "multi_array",
    "integer",
    "graph",
    "optional",
    "date_time",
    "mysql",
    "compute",
    "safe_numerics",
    "smart_ptr",
    "math",
    "beast",
    "numeric_conversion",
    "logic",
    "lexical_cast",
    "unordered",
    "static_string",
    "io",
    "json",
    "type_index",
    "timer",
    "stacktrace",
    "sort",
    "filesystem",
    "context",
    "signals2",
    "interprocess",
    "container",
    "variant",
    "variant2",
    "winapi",
    "chrono",
    "any",
    "url",
    "wave",
    "atomic",
    "scope",
    "process",
    "fusion",
    "function",
    "spirit",
    "cobalt",
    "phoenix",
    "nowide",
    "locale",
    "circular_buffer",
    "uuid",
    "leaf",
    "redis",
    "lockfree",
    "parameter",
    "tokenizer",
    "geometry",
    "crc",
    "compat",
    "bimap",
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost = boostLibraries(b, .{
        .target = target,
        .optimize = optimize,
        .header_only = b.option(bool, "headers-only", "Build header-only libraries") orelse true,
    });
    b.installArtifact(boost);
}

const cxxFlags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    "-std=c++17",
};

const boost_version: std.SemanticVersion = .{ .major = 0, .minor = 86, .patch = 0 };

pub fn boostLibraries(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "boost",
        .target = config.target,
        .optimize = config.optimize,
        .version = boost_version,
    });

    inline for (boost_libs) |name| {
        const boostLib = b.dependency(name, .{}).path("include");
        lib.addIncludePath(boostLib);
    }

    if (config.header_only) {
        // zig-pkg bypass (artifact need source file)
        const empty = b.addWriteFile("empty.cc",
            \\ #include <boost/config.hpp>
        );
        lib.step.dependOn(&empty.step);
        lib.addCSourceFiles(.{
            .root = empty.getDirectory(),
            .files = &.{"empty.cc"},
            .flags = cxxFlags,
        });
    } else {
        const boostJson = b.dependency("json", .{}).path("");
        const boostContainer = b.dependency("container", .{}).path("");
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
    }
    if (lib.rootModuleTarget().abi == .msvc)
        lib.linkLibC()
    else
        lib.linkLibCpp();
    return lib;
}

pub const Config = struct {
    header_only: bool,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};
