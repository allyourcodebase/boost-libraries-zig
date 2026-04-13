const std = @import("std");
const zon = @import("build.zig.zon");

const boost_libs = [_][]const u8{
    "core",
    "algorithm",
    "config",
    "assert",
    "type_traits",
    "mp11",
    "range",
    "functional",
    "random",
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
    "asio", // stackless coroutine (stl) and stackful coroutine (need boost.context)
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
    "serialization", // no header-only
    "iostreams",
    "safe_numerics",
    "smart_ptr",
    "math",
    "beast", // need boost.asio
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
    "cobalt", // need boost.asio (no header-only)
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
    "icl",
    "local_function",
    "format",
    "pool",
    "gil",
    "python",
    "proto",
    "property_tree",
    "exception",
    "property_map",
    "property_map_parallel",
    "multi_index",
    "callable_traits",
    "compat",
    "bimap",
    "conversion",
    "charconv",
    "fiber", // need boost.context (no header-only)
    "log",
    "heap",
    "msm",
    "coroutine2", // need boost.context
    "parser",
    "mqtt5", // need boost.asio
    "hash2",
    "tti",
    "bloom",
    "openmethod",
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version = try std.SemanticVersion.parse(zon.version);

    const boost = boostLibraries(b, .{
        .target = target,
        .optimize = optimize,
        .boost_version = version,
        .module = .{
            .atomic = b.option(bool, "atomic", "Build boost.atomic library (default: false)") orelse false,
            .charconv = b.option(bool, "charconv", "Build boost.charconv library (default: false)") orelse false,
            .cobalt = b.option(bool, "cobalt", "Build boost.cobalt library (default: false)") orelse false,
            .container = b.option(bool, "container", "Build boost.container library (default: false)") orelse false,
            .context = b.option(bool, "context", "Build boost.context library (default: false)") orelse false,
            .exception = b.option(bool, "exception", "Build boost.exception library (default: false)") orelse false,
            .fiber = b.option(bool, "fiber", "Build boost.fiber library (default: false)") orelse false,
            .filesystem = b.option(bool, "filesystem", "Build boost.filesystem library (default: false)") orelse false,
            .iostreams = b.option(bool, "iostreams", "Build boost.iostreams library (default: false)") orelse false,
            .json = b.option(bool, "json", "Build boost.json library (default: false)") orelse false,
            .log = b.option(bool, "log", "Build boost.log library (default: false)") orelse false,
            .nowide = b.option(bool, "nowide", "Build boost.nowide library (default: false)") orelse false,
            .process = b.option(bool, "process", "Build boost.process library (default: false)") orelse false,
            .python = b.option(bool, "python", "Build boost.python library (default: false)") orelse false,
            .random = b.option(bool, "random", "Build boost.random library (default: false)") orelse false,
            .regex = b.option(bool, "regex", "Build boost.regex library (default: false)") orelse false,
            .serialization = b.option(bool, "serialization", "Build boost.serialization library (default: false)") orelse false,
            .stacktrace = b.option(bool, "stacktrace", "Build boost.stacktrace library (default: false)") orelse false,
            .system = b.option(bool, "system", "Build boost.system library (default: false)") orelse false,
            .url = b.option(bool, "url", "Build boost.url library (default: false)") orelse false,
            .wave = b.option(bool, "wave", "Build boost.wave library (default: false)") orelse false,
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

pub fn boostLibraries(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const shared = b.option(bool, "shared", "Build as shared library (default: false)") orelse false;

    const lib = b.addLibrary(.{
        .name = "boost",
        .root_module = b.createModule(.{
            .target = config.target,
            .optimize = config.optimize,
        }),
        .linkage = if (shared) .dynamic else .static,
        .version = config.boost_version,
    });

    inline for (boost_libs) |name| {
        const boostLib = b.dependency(name, .{}).path("include");
        lib.root_module.addIncludePath(boostLib);
    }

    // zig-pkg bypass (artifact need generate object file)
    const empty = b.addWriteFile("empty.cc",
        \\ #include <boost/config.hpp>
    );
    lib.step.dependOn(&empty.step);
    lib.root_module.addCSourceFiles(.{
        .root = empty.getDirectory(),
        .files = &.{"empty.cc"},
        .flags = cxxFlags,
    });
    if (config.module) |module| {
        if (module.atomic) {
            buildAtomic(b, lib);
        }
        if (module.cobalt) {
            buildCobalt(b, lib);
        }
        if (module.container) {
            buildContainer(b, lib);
        }
        if (module.exception) {
            buildException(b, lib);
        }
        if (module.random) {
            buildRandom(b, lib);
        }
        if (module.context) {
            buildContext(b, lib);
        }
        if (module.charconv) {
            buildCharConv(b, lib);
        }
        if (module.process) {
            buildProcess(b, lib);
        }
        if (module.iostreams) {
            buildIOStreams(b, lib);
        }
        if (module.json) {
            buildJson(b, lib);
        }
        if (module.log) {
            buildLog(b, lib);
        }
        if (module.fiber) {
            buildFiber(b, lib);
        }
        if (module.filesystem) {
            buildFileSystem(b, lib);
        }
        if (module.serialization) {
            buildSerialization(b, lib);
        }
        if (module.nowide) {
            buildNoWide(b, lib);
        }
        if (module.system) {
            buildSystem(b, lib);
        }
        if (module.python) {
            buildPython(b, lib);
        }
        if (module.stacktrace) {
            buildStacktrace(b, lib);
        }
        if (module.regex) {
            buildRegex(b, lib);
        }
        if (module.url) {
            buildURL(b, lib);
        }
        if (module.wave) {
            buildWave(b, lib);
        }
    }
    if (lib.rootModuleTarget().abi == .msvc)
        lib.root_module.link_libc = true
    else {
        lib.root_module.addCMacro("_GNU_SOURCE", "");
        lib.root_module.link_libcpp = true;
    }
    return lib;
}

pub const Config = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    module: ?boostLibrariesModules = null,
    boost_version: ?std.SemanticVersion = null,
};

// No header-only libraries
const boostLibrariesModules = struct {
    atomic: bool = false,
    charconv: bool = false,
    cobalt: bool = false,
    container: bool = false,
    context: bool = false,
    exception: bool = false,
    fiber: bool = false,
    filesystem: bool = false,
    iostreams: bool = false,
    json: bool = false,
    log: bool = false,
    nowide: bool = false,
    process: bool = false,
    python: bool = false,
    random: bool = false,
    regex: bool = false,
    stacktrace: bool = false,
    serialization: bool = false,
    system: bool = false,
    url: bool = false,
    wave: bool = false,
};

fn buildCobalt(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const cobaltPath = b.dependency("cobalt", .{}).path("src");
    obj.root_module.addCMacro("BOOST_COBALT_SOURCE", "");
    obj.root_module.addCSourceFiles(.{
        .root = cobaltPath,
        .files = &.{
            "channel.cpp",
            "detail/exception.cpp",
            "detail/util.cpp",
            "error.cpp",
            "main.cpp",
            "this_thread.cpp",
            "thread.cpp",
        },
        .flags = cxxFlags ++ &[_][]const u8{"-std=c++20"},
    });
}

fn buildContainer(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const containerPath = b.dependency("container", .{}).path("src");
    obj.root_module.addCSourceFiles(.{
        .root = containerPath,
        .files = &.{
            "pool_resource.cpp",
            "monotonic_buffer_resource.cpp",
            "synchronized_pool_resource.cpp",
            "unsynchronized_pool_resource.cpp",
            "global_resource.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildFiber(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const fiberPath = b.dependency("fiber", .{}).path("src");
    obj.root_module.addCSourceFiles(.{
        .root = fiberPath,
        .files = &.{
            "algo/algorithm.cpp",
            "algo/round_robin.cpp",
            "algo/shared_work.cpp",
            "algo/work_stealing.cpp",
            "barrier.cpp",
            "condition_variable.cpp",
            "context.cpp",
            "fiber.cpp",
            "future.cpp",
            "mutex.cpp",
            "numa/algo/work_stealing.cpp",
            "properties.cpp",
            "recursive_mutex.cpp",
            "recursive_timed_mutex.cpp",
            "scheduler.cpp",
            "timed_mutex.cpp",
            "waker.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildJson(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const jsonPath = b.dependency("json", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = jsonPath,
        .files = &.{
            "src.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildProcess(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const processPath = b.dependency("process", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = processPath,
        .files = &.{
            "detail/environment_posix.cpp",
            "detail/environment_win.cpp",
            "detail/last_error.cpp",
            "detail/process_handle_windows.cpp",
            "detail/throw_error.cpp",
            "detail/utf8.cpp",
            "environment.cpp",
            "error.cpp",
            "ext/cmd.cpp",
            "ext/cwd.cpp",
            "ext/env.cpp",
            "ext/exe.cpp",
            "ext/proc_info.cpp",
            "pid.cpp",
            "shell.cpp",
            switch (obj.rootModuleTarget().os.tag) {
                .windows => "windows/default_launcher.cpp",
                else => "posix/close_handles.cpp",
            },
        },
        .flags = cxxFlags,
    });
}

fn buildSystem(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const systemPath = b.dependency("system", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = systemPath,
        .files = &.{
            "error_code.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildAtomic(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const atomicPath = b.dependency("atomic", .{}).path("src");

    obj.root_module.addIncludePath(atomicPath);
    obj.root_module.addCSourceFiles(.{
        .root = atomicPath,
        .files = &.{
            "lock_pool.cpp",
        },
        .flags = cxxFlags,
    });
    if (obj.rootModuleTarget().os.tag == .windows)
        obj.root_module.addCSourceFiles(.{
            .root = atomicPath,
            .files = &.{
                "wait_on_address.cpp",
            },
            .flags = cxxFlags,
        });
    if (std.Target.x86.featureSetHas(obj.rootModuleTarget().cpu.features, .sse2)) {
        obj.root_module.addCSourceFiles(.{
            .root = atomicPath,
            .files = &.{
                "find_address_sse2.cpp",
            },
            .flags = cxxFlags,
        });
    }
    if (std.Target.x86.featureSetHas(obj.rootModuleTarget().cpu.features, .sse4_1)) {
        obj.root_module.addCSourceFiles(.{
            .root = atomicPath,
            .files = &.{
                "find_address_sse41.cpp",
            },
            .flags = cxxFlags,
        });
    }
}

fn buildRegex(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const regPath = b.dependency("regex", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = regPath,
        .files = &.{
            "posix_api.cpp",
            "wide_posix_api.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildFileSystem(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const fsPath = b.dependency("filesystem", .{}).path("src");

    if (obj.rootModuleTarget().os.tag == .windows) {
        obj.root_module.addCSourceFiles(.{
            .root = fsPath,
            .files = &.{"windows_file_codecvt.cpp"},
            .flags = cxxFlags,
        });
        obj.root_module.addCMacro("BOOST_USE_WINDOWS_H", "");
        obj.root_module.addCMacro("NOMINMAX", "");
    }
    obj.root_module.addCMacro("BOOST_FILESYSTEM_NO_CXX20_ATOMIC_REF", "");
    obj.root_module.addIncludePath(fsPath);
    obj.root_module.addCSourceFiles(.{
        .root = fsPath,
        .files = &.{
            "codecvt_error_category.cpp",
            "directory.cpp",
            "exception.cpp",
            "path.cpp",
            "path_traits.cpp",
            "portability.cpp",
            "operations.cpp",
            "unique_path.cpp",
            "utf8_codecvt_facet.cpp",
        },
        .flags = cxxFlags,
    });
    if (obj.rootModuleTarget().abi == .msvc) {
        obj.root_module.addCMacro("_SCL_SECURE_NO_WARNINGS", "");
        obj.root_module.addCMacro("_SCL_SECURE_NO_DEPRECATE", "");
        obj.root_module.addCMacro("_CRT_SECURE_NO_WARNINGS", "");
        obj.root_module.addCMacro("_CRT_SECURE_NO_DEPRECATE", "");
    }
}

fn buildContext(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const contextPath = b.dependency("context", .{}).path("src");
    const ctxPath = contextPath.getPath(b);
    obj.root_module.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ ctxPath, "asm" }),
    }); // common.h
    obj.root_module.addCSourceFiles(.{
        .root = contextPath,
        .files = &.{
            "continuation.cpp",
            "fiber.cpp",
        },
        .flags = cxxFlags,
    });

    obj.root_module.addCSourceFile(.{
        .file = switch (obj.rootModuleTarget().os.tag) {
            .windows => .{
                .cwd_relative = b.pathJoin(&.{ ctxPath, "windows/stack_traits.cpp" }),
            },
            else => .{
                .cwd_relative = b.pathJoin(&.{ ctxPath, "posix/stack_traits.cpp" }),
            },
        },
        .flags = cxxFlags,
    });
    if (obj.rootModuleTarget().os.tag == .windows) {
        obj.root_module.addCMacro("BOOST_USE_WINFIB", "");
        obj.lto = .thin;
    } else {
        obj.root_module.addCMacro("BOOST_USE_UCONTEXT", "");
    }
    switch (obj.rootModuleTarget().cpu.arch) {
        .arm => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                if (obj.rootModuleTarget().abi == .msvc) {
                    obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm_aapcs_pe_armasm.asm" }) });
                    obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm_aapcs_pe_armasm.asm" }) });
                    obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm_aapcs_pe_armasm.asm" }) });
                }
            },
            .macos => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm_aapcs_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm_aapcs_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm_aapcs_macho_gas.S" }) });
            },
            else => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm_aapcs_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm_aapcs_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm_aapcs_elf_gas.S" }) });
            },
        },
        .aarch64 => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                if (obj.rootModuleTarget().abi == .msvc) {
                    obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm64_aapcs_pe_armasm.asm" }) });
                    obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm64_aapcs_pe_armasm.asm" }) });
                    obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm64_aapcs_pe_armasm.asm" }) });
                }
            },
            .macos => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm64_aapcs_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm64_aapcs_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm64_aapcs_macho_gas.S" }) });
            },
            else => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm64_aapcs_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm64_aapcs_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm64_aapcs_elf_gas.S" }) });
            },
        },
        .riscv64 => {
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_riscv64_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_riscv64_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_riscv64_sysv_elf_gas.S" }) });
        },
        .x86 => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                // @panic("undefined symbol:{j/m/o}-fcontext");
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_ms_pe_clang_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_ms_pe_clang_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_ms_pe_clang_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_ms_pe_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_ms_pe_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_ms_pe_gas.S" }) });
            },
            .macos => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_x86_64_sysv_macho_gas.S" }) });
            },
            else => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_sysv_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_sysv_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_sysv_elf_gas.S" }) });
            },
        },
        .x86_64 => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_x86_64_ms_pe_clang_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_x86_64_ms_pe_clang_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_x86_64_ms_pe_clang_gas.S" }) });
            },
            .macos => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_x86_64_sysv_macho_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_x86_64_sysv_macho_gas.S" }) });
            },
            else => {
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_x86_64_sysv_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_x86_64_sysv_elf_gas.S" }) });
                obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_x86_64_sysv_elf_gas.S" }) });
            },
        },
        .s390x => {
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_s390x_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_s390x_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_s390x_sysv_elf_gas.S" }) });
        },
        .mips, .mipsel => {
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_mips32_o32_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_mips32_o32_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_mips32_o32_elf_gas.S" }) });
        },
        .mips64, .mips64el => {
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_mips64_n64_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_mips64_n64_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_mips64_n64_elf_gas.S" }) });
        },
        .loongarch64 => {
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_loongarch64_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_loongarch64_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_loongarch64_sysv_elf_gas.S" }) });
        },
        .powerpc => {
            obj.root_module.addCSourceFile(.{
                .file = .{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/tail_ontop_ppc32_sysv.cpp" }) },
                .flags = cxxFlags,
            });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_ppc32_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_ppc32_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_ppc32_sysv_elf_gas.S" }) });
        },
        .powerpc64 => {
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_ppc64_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_ppc64_sysv_elf_gas.S" }) });
            obj.root_module.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_ppc64_sysv_elf_gas.S" }) });
        },
        else => @panic("Invalid arch"),
    }
}

fn buildSerialization(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const serialPath = b.dependency("serialization", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = serialPath,
        .files = &.{
            "archive_exception.cpp",
            "basic_archive.cpp",
            "basic_iarchive.cpp",
            "basic_iserializer.cpp",
            "basic_oarchive.cpp",
            "basic_oserializer.cpp",
            "basic_pointer_iserializer.cpp",
            "basic_pointer_oserializer.cpp",
            "basic_serializer_map.cpp",
            "basic_text_iprimitive.cpp",
            "basic_text_oprimitive.cpp",
            "basic_text_wiprimitive.cpp",
            "basic_text_woprimitive.cpp",
            "basic_xml_archive.cpp",
            "binary_iarchive.cpp",
            "binary_oarchive.cpp",
            "binary_wiarchive.cpp",
            "binary_woarchive.cpp",
            "codecvt_null.cpp",
            "extended_type_info.cpp",
            "extended_type_info_no_rtti.cpp",
            "extended_type_info_typeid.cpp",
            "polymorphic_binary_iarchive.cpp",
            "polymorphic_binary_oarchive.cpp",
            "polymorphic_iarchive.cpp",
            "polymorphic_oarchive.cpp",
            "polymorphic_text_iarchive.cpp",
            "polymorphic_text_oarchive.cpp",
            "polymorphic_text_wiarchive.cpp",
            "polymorphic_text_woarchive.cpp",
            "polymorphic_xml_iarchive.cpp",
            "polymorphic_xml_oarchive.cpp",
            "polymorphic_xml_wiarchive.cpp",
            "polymorphic_xml_woarchive.cpp",
            "stl_port.cpp",
            "text_iarchive.cpp",
            "text_oarchive.cpp",
            "text_wiarchive.cpp",
            "text_woarchive.cpp",
            "utf8_codecvt_facet.cpp",
            "void_cast.cpp",
            "xml_archive_exception.cpp",
            "xml_grammar.cpp",
            "xml_iarchive.cpp",
            "xml_oarchive.cpp",
            "xml_wgrammar.cpp",
            "xml_wiarchive.cpp",
            "xml_woarchive.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildCharConv(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const cconvPath = b.dependency("charconv", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = cconvPath,
        .files = &.{
            "from_chars.cpp",
            "to_chars.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildRandom(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const rndPath = b.dependency("random", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = rndPath,
        .files = &.{
            "random_device.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildException(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const exceptPath = b.dependency("exception", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = exceptPath,
        .files = &.{
            "clone_current_exception_non_intrusive.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildStacktrace(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const stackPath = b.dependency("stacktrace", .{}).path("src");

    obj.root_module.addIncludePath(stackPath);
    obj.root_module.addCSourceFiles(.{
        .root = stackPath,
        .files = &.{
            "addr2line.cpp",
            "basic.cpp",
            "from_exception.cpp",
            "noop.cpp",
        },
        .flags = cxxFlags,
    });
    // TODO: fix https://github.com/ziglang/zig/issues/21308
    if (checkSystemLibrary(obj, "backtrace")) {
        obj.root_module.addCSourceFiles(.{
            .root = stackPath,
            .files = &.{
                "backtrace.cpp",
            },
            .flags = cxxFlags,
        });
        obj.root_module.linkSystemLibrary("backtrace", .{});
    }

    if (obj.rootModuleTarget().abi == .msvc) {
        obj.root_module.addCSourceFiles(.{
            .root = stackPath,
            .files = &.{
                "windbg.cpp",
                "windbg_cached.cpp",
            },
            .flags = cxxFlags,
        });

        obj.root_module.linkSystemLibrary("dbgeng", .{});
        obj.root_module.linkSystemLibrary("ole32", .{});
    }
}

fn buildURL(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const urlPath = b.dependency("url", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = urlPath,
        .files = &.{
            "authority_view.cpp",
            "decode_view.cpp",
            "detail/any_params_iter.cpp",
            "detail/any_segments_iter.cpp",
            "detail/decode.cpp",
            "detail/except.cpp",
            "detail/format_args.cpp",
            "detail/normalize.cpp",
            "detail/params_iter_impl.cpp",
            "detail/pattern.cpp",
            "detail/pct_format.cpp",
            "detail/replacement_field_rule.cpp",
            "detail/segments_iter_impl.cpp",
            "detail/url_impl.cpp",
            "detail/vformat.cpp",
            "encoding_opts.cpp",
            "error.cpp",
            "grammar/ci_string.cpp",
            "grammar/dec_octet_rule.cpp",
            "grammar/delim_rule.cpp",
            "grammar/detail/recycled.cpp",
            "grammar/error.cpp",
            "grammar/literal_rule.cpp",
            "grammar/string_view_base.cpp",
            "ipv4_address.cpp",
            "ipv6_address.cpp",
            "params_base.cpp",
            "params_encoded_base.cpp",
            "params_encoded_ref.cpp",
            "params_encoded_view.cpp",
            "params_ref.cpp",
            "params_view.cpp",
            "parse.cpp",
            "parse_path.cpp",
            "parse_query.cpp",
            "pct_string_view.cpp",
            "rfc/absolute_uri_rule.cpp",
            "rfc/authority_rule.cpp",
            "rfc/detail/h16_rule.cpp",
            "rfc/detail/hier_part_rule.cpp",
            "rfc/detail/host_rule.cpp",
            "rfc/detail/ip_literal_rule.cpp",
            "rfc/detail/ipv6_addrz_rule.cpp",
            "rfc/detail/ipvfuture_rule.cpp",
            "rfc/detail/port_rule.cpp",
            "rfc/detail/relative_part_rule.cpp",
            "rfc/detail/scheme_rule.cpp",
            "rfc/detail/userinfo_rule.cpp",
            "rfc/ipv4_address_rule.cpp",
            "rfc/ipv6_address_rule.cpp",
            "rfc/origin_form_rule.cpp",
            "rfc/query_rule.cpp",
            "rfc/relative_ref_rule.cpp",
            "rfc/uri_reference_rule.cpp",
            "rfc/uri_rule.cpp",
            "scheme.cpp",
            "segments_base.cpp",
            "segments_encoded_base.cpp",
            "segments_encoded_ref.cpp",
            "segments_encoded_view.cpp",
            "segments_ref.cpp",
            "segments_view.cpp",
            "static_url.cpp",
            "url.cpp",
            "url_base.cpp",
            "url_view.cpp",
            "url_view_base.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildIOStreams(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const iostreamPath = b.dependency("iostreams", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = iostreamPath,
        .files = &.{
            "bzip2.cpp",
            "file_descriptor.cpp",
            "gzip.cpp",
            "mapped_file.cpp",
            "zlib.cpp",
            "zstd.cpp",
            "lzma.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildLog(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const logPath = b.dependency("log", .{}).path("src");
    obj.root_module.addCMacro("BOOST_LOG_NO_THREADS", "");
    obj.root_module.addIncludePath(logPath);
    obj.root_module.addCSourceFiles(.{
        .root = logPath,
        .files = &.{
            "attribute_name.cpp",
            "attribute_set.cpp",
            "attribute_value_set.cpp",
            "code_conversion.cpp",
            "core.cpp",
            "date_time_format_parser.cpp",
            "default_attribute_names.cpp",
            "default_sink.cpp",
            "dump.cpp",
            "dump_avx2.cpp",
            "dump_ssse3.cpp",
            "event.cpp",
            "exceptions.cpp",
            "format_parser.cpp",
            "global_logger_storage.cpp",
            "named_scope.cpp",
            "named_scope_format_parser.cpp",
            "once_block.cpp",
            "permissions.cpp",
            "process_id.cpp",
            "process_name.cpp",
            "record_ostream.cpp",
            "setup/default_filter_factory.cpp",
            "setup/default_formatter_factory.cpp",
            "setup/filter_parser.cpp",
            "setup/formatter_parser.cpp",
            "setup/init_from_settings.cpp",
            "setup/init_from_stream.cpp",
            "setup/matches_relation_factory.cpp",
            "setup/parser_utils.cpp",
            "setup/settings_parser.cpp",
            "severity_level.cpp",
            "spirit_encoding.cpp",
            "syslog_backend.cpp",
            "text_file_backend.cpp",
            "text_multifile_backend.cpp",
            "text_ostream_backend.cpp",
            "thread_id.cpp",
            "thread_specific.cpp",
            "threadsafe_queue.cpp",
            "timer.cpp",
            "timestamp.cpp",
            "trivial.cpp",
        },
        .flags = cxxFlags,
    });
    obj.root_module.addCSourceFiles(.{
        .root = logPath,
        .files = switch (obj.rootModuleTarget().os.tag) {
            .windows => &.{
                "windows/debug_output_backend.cpp",
                "windows/event_log_backend.cpp",
                "windows/ipc_reliable_message_queue.cpp",
                "windows/ipc_sync_wrappers.cpp",
                "windows/is_debugger_present.cpp",
                "windows/light_rw_mutex.cpp",
                "windows/mapped_shared_memory.cpp",
                "windows/object_name.cpp",
            },
            else => &.{
                "posix/ipc_reliable_message_queue.cpp",
                "posix/object_name.cpp",
            },
        },
        .flags = cxxFlags,
    });
}

fn buildNoWide(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const nwPath = b.dependency("nowide", .{}).path("src");

    obj.root_module.addIncludePath(nwPath);
    obj.root_module.addCSourceFiles(.{
        .root = nwPath,
        .files = &.{
            "console_buffer.cpp",
            "cstdio.cpp",
            "cstdlib.cpp",
            "filebuf.cpp",
            "iostream.cpp",
            "stat.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildPython(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const pyPath = b.dependency("python", .{}).path("src");

    obj.root_module.linkSystemLibrary("python3", .{});
    obj.root_module.addCSourceFiles(.{
        .root = pyPath,
        .files = &.{
            "converter/arg_to_python_base.cpp",
            "converter/builtin_converters.cpp",
            "converter/from_python.cpp",
            "converter/registry.cpp",
            "converter/type_id.cpp",
            "dict.cpp",
            "errors.cpp",
            "exec.cpp",
            "import.cpp",
            "list.cpp",
            "long.cpp",
            "module.cpp",
            "object/class.cpp",
            "object/enum.cpp",
            "object/function.cpp",
            "object/function_doc_signature.cpp",
            "object/inheritance.cpp",
            "object/iterator.cpp",
            "object/life_support.cpp",
            "object/pickle_support.cpp",
            "object/stl_iterator.cpp",
            "object_operators.cpp",
            "object_protocol.cpp",
            "slice.cpp",
            "str.cpp",
            "tuple.cpp",
            "wrapper.cpp",
        },
        .flags = cxxFlags,
    });

    if (checkSystemLibrary(obj, "npymath")) {
        obj.root_module.linkSystemLibrary("npymath", .{});
        obj.root_module.addCSourceFiles(.{
            .root = pyPath,
            .files = &.{
                "numpy/dtype.cpp",
                "numpy/matrix.cpp",
                "numpy/ndarray.cpp",
                "numpy/numpy.cpp",
                "numpy/scalars.cpp",
                "numpy/ufunc.cpp",
            },
            .flags = cxxFlags,
        });
    }
}

fn buildWave(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const wavePath = b.dependency("wave", .{}).path("src");

    obj.root_module.addCSourceFiles(.{
        .root = wavePath,
        .files = &.{
            "cpplexer/re2clex/aq.cpp",
            "cpplexer/re2clex/cpp_re.cpp",
            "instantiate_cpp_exprgrammar.cpp",
            "instantiate_cpp_grammar.cpp",
            "instantiate_cpp_literalgrs.cpp",
            "instantiate_defined_grammar.cpp",
            "instantiate_has_include_grammar.cpp",
            "instantiate_predef_macros.cpp",
            "instantiate_re2c_lexer.cpp",
            "instantiate_re2c_lexer_str.cpp",
            "token_ids.cpp",
            "wave_config_constant.cpp",
        },
        .flags = cxxFlags,
    });
}

// temporary workaround for https://github.com/ziglang/zig/issues/21308
fn checkSystemLibrary(compile: *std.Build.Step.Compile, name: []const u8) bool {
    var is_linking_libc = false;
    var is_linking_libcpp = false;

    for (compile.getCompileDependencies(true)) |some_compile| {
        for (some_compile.root_module.getGraph().modules) |mod| {
            for (mod.link_objects.items) |lo| {
                switch (lo) {
                    .system_lib => |lib| if (std.mem.eql(u8, lib.name, name)) return true,
                    else => {},
                }
            }
            if (mod.link_libc != null) is_linking_libc = true;
            if (mod.link_libcpp != null) is_linking_libcpp = true;
        }
    }

    const target = &compile.rootModuleTarget();

    if (std.zig.target.isLibCLibName(target, name)) {
        return is_linking_libc;
    }

    if (std.zig.target.isLibCxxLibName(target, name)) {
        return is_linking_libcpp;
    }

    return false;
}
