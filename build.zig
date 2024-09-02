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
    "compute", // need OpenCL
    "odeint",
    "ublas",
    "serialization",
    "iostreams",
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
    "json", // (no header-only)
    "type_index",
    "type_erasure",
    "typeof",
    "units",
    "timer",
    "stacktrace",
    "sort",
    "filesystem", // no header-only
    "context", // cpp + asm (no header-only)
    "signals2",
    "interprocess",
    "container", // no header-only
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
    "function_types",
    "cobalt", // need boost.context & boost.asio (no header-only)
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
    "hof",
    "interval",
    "local_function",
    "callable_traits",
    "compat",
    "bimap",
    "conversion",
    "charconv",
    "log",
    "heap",
    "msm",
    "coroutine2", // need boost.context (no header-only)
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost = boostLibraries(b, .{
        .target = target,
        .optimize = optimize,
        .header_only = b.option(bool, "headers-only", "Build headers-only libraries (default: true)") orelse true,
        .module = .{
            .cobalt = b.option(bool, "cobalt", "Build cobalt library (default: false)") orelse false,
            .context = b.option(bool, "context", "Build context library (default: false)") orelse false,
            .json = b.option(bool, "json", "Build json library (default: false)") orelse false,
            .container = b.option(bool, "container", "Build container library (default: false)") orelse false,
            .filesystem = b.option(bool, "filesystem", "Build filesystem library (default: false)") orelse false,
            .coroutine2 = b.option(bool, "coroutine2", "Build coroutine2 library (default: false)") orelse false,
        },
    });
    b.installArtifact(boost);
}

const cxxFlags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    "-Wformat",
};

const boost_version: std.SemanticVersion = .{ .major = 1, .minor = 86, .patch = 0 };

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
        if (config.module) |module| {
            if (module.cobalt) {
                const boostCobalt = buildCobalt(b, .{
                    .header_only = config.header_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostCobalt);
            }
            if (module.container) {
                const boostContainer = buildContainer(b, .{
                    .header_only = config.header_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostContainer);
            }
            if (module.json) {
                const boostJson = buildJson(b, .{
                    .header_only = config.header_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostJson);
            }
        }
    }
    if (lib.rootModuleTarget().abi == .msvc)
        lib.linkLibC()
    else {
        lib.defineCMacro("_GNU_SOURCE", null);
        lib.linkLibCpp();
    }
    return lib;
}

pub const Config = struct {
    header_only: bool,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    module: ?boostLibrariesModules = null,
    include_dirs: ?std.ArrayListUnmanaged(std.Build.Module.IncludeDir) = null,
};

// No header-only libraries
const boostLibrariesModules = struct {
    coroutine2: bool = false,
    context: bool = false,
    json: bool = false,
    container: bool = false,
    filesystem: bool = false,
    cobalt: bool = false,
};

fn buildCobalt(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const cobaltPath = b.dependency("cobalt", .{}).path("");
    const obj = b.addObject(.{
        .name = "cobalt",
        .target = config.target,
        .optimize = config.optimize,
    });

    if (config.include_dirs) |include_dirs| {
        for (include_dirs.items) |include| {
            obj.root_module.include_dirs.append(b.allocator, include) catch unreachable;
        }
    }
    obj.defineCMacro("BOOST_COBALT_SOURCE", null);
    obj.defineCMacro("BOOST_COBALT_USE_BOOST_CONTAINER_PMR", null);
    obj.addCSourceFiles(.{
        .root = cobaltPath,
        .files = &.{
            "src/channel.cpp",
            "src/detail/exception.cpp",
            "src/detail/util.cpp",
            "src/error.cpp",
            "src/main.cpp",
            "src/this_thread.cpp",
            "src/thread.cpp",
        },
        .flags = cxxFlags ++ &[_][]const u8{"-std=c++20"},
    });
    if (obj.rootModuleTarget().abi == .msvc)
        obj.linkLibC()
    else {
        obj.defineCMacro("_GNU_SOURCE", null);
        obj.linkLibCpp();
    }

    return obj;
}

fn buildContainer(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const containerPath = b.dependency("container", .{}).path("");
    const obj = b.addObject(.{
        .name = "container",
        .target = config.target,
        .optimize = config.optimize,
    });

    if (config.include_dirs) |include_dirs| {
        for (include_dirs.items) |include| {
            obj.root_module.include_dirs.append(b.allocator, include) catch unreachable;
        }
    }
    obj.addCSourceFiles(.{
        .root = containerPath,
        .files = &.{
            "src/pool_resource.cpp",
            "src/monotonic_buffer_resource.cpp",
            "src/synchronized_pool_resource.cpp",
            "src/unsynchronized_pool_resource.cpp",
            "src/global_resource.cpp",
        },
        .flags = cxxFlags,
    });
    if (obj.rootModuleTarget().abi == .msvc)
        obj.linkLibC()
    else {
        obj.defineCMacro("_GNU_SOURCE", null);
        obj.linkLibCpp();
    }

    return obj;
}

fn buildJson(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const jsonPath = b.dependency("json", .{}).path("");
    const obj = b.addObject(.{
        .name = "json",
        .target = config.target,
        .optimize = config.optimize,
    });

    if (config.include_dirs) |include_dirs| {
        for (include_dirs.items) |include| {
            obj.root_module.include_dirs.append(b.allocator, include) catch unreachable;
        }
    }
    obj.addCSourceFiles(.{
        .root = jsonPath,
        .files = &.{
            "src/src.cpp",
        },
        .flags = cxxFlags,
    });
    if (obj.rootModuleTarget().abi == .msvc)
        obj.linkLibC()
    else {
        obj.defineCMacro("_GNU_SOURCE", null);
        obj.linkLibCpp();
    }

    return obj;
}
