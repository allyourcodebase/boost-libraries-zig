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
    "local_function",
    "format",
    "pool",
    "proto",
    "property_tree",
    "exception",
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
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost = boostLibraries(b, .{
        .target = target,
        .optimize = optimize,
        .module = .{
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
            .process = b.option(bool, "process", "Build boost.process library (default: false)") orelse false,
            .random = b.option(bool, "random", "Build boost.random library (default: false)") orelse false,
            .serialization = b.option(bool, "serialization", "Build boost.serialization library (default: false)") orelse false,
            .system = b.option(bool, "system", "Build boost.system library (default: false)") orelse false,
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
    const shared = b.option(bool, "shared", "Build as shared library (default: false)") orelse false;

    const lib = if (shared) b.addSharedLibrary(.{
        .name = "boost",
        .target = config.target,
        .optimize = config.optimize,
        .version = boost_version,
    }) else b.addStaticLibrary(.{
        .name = "boost",
        .target = config.target,
        .optimize = config.optimize,
        .version = boost_version,
    });

    inline for (boost_libs) |name| {
        const boostLib = b.dependency(name, .{}).path("include");
        lib.addIncludePath(boostLib);
    }

    // zig-pkg bypass (artifact need generate object file)
    const empty = b.addWriteFile("empty.cc",
        \\ #include <boost/config.hpp>
    );
    lib.step.dependOn(&empty.step);
    lib.addCSourceFiles(.{
        .root = empty.getDirectory(),
        .files = &.{"empty.cc"},
        .flags = cxxFlags,
    });
    if (config.module) |module| {
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
        if (module.system) {
            buildSystem(b, lib);
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
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    module: ?boostLibrariesModules = null,
};

// No header-only libraries
const boostLibrariesModules = struct {
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
    process: bool = false,
    random: bool = false,
    serialization: bool = false,
    system: bool = false,
};

fn buildCobalt(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const cobaltPath = b.dependency("cobalt", .{}).path("src");
    obj.defineCMacro("BOOST_COBALT_SOURCE", null);
    obj.addCSourceFiles(.{
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
    obj.addCSourceFiles(.{
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
    obj.addCSourceFiles(.{
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

    obj.addCSourceFiles(.{
        .root = jsonPath,
        .files = &.{
            "src.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildProcess(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const processPath = b.dependency("process", .{}).path("src");

    obj.addCSourceFiles(.{
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

    obj.addCSourceFiles(.{
        .root = systemPath,
        .files = &.{
            "error_code.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildFileSystem(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const fsPath = b.dependency("filesystem", .{}).path("src");

    if (obj.rootModuleTarget().os.tag == .windows) {
        obj.addCSourceFiles(.{
            .root = fsPath,
            .files = &.{"windows_file_codecvt.cpp"},
            .flags = cxxFlags,
        });
        obj.defineCMacro("BOOST_USE_WINDOWS_H", null);
        obj.defineCMacro("NOMINMAX", null);
    }
    obj.defineCMacro("BOOST_FILESYSTEM_NO_CXX20_ATOMIC_REF", null);
    obj.addIncludePath(fsPath);
    obj.addCSourceFiles(.{
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
        obj.defineCMacro("_SCL_SECURE_NO_WARNINGS", null);
        obj.defineCMacro("_SCL_SECURE_NO_DEPRECATE", null);
        obj.defineCMacro("_CRT_SECURE_NO_WARNINGS", null);
        obj.defineCMacro("_CRT_SECURE_NO_DEPRECATE", null);
    }
}

fn buildContext(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const contextPath = b.dependency("context", .{}).path("src");
    const ctxPath = contextPath.getPath(b);
    obj.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ ctxPath, "asm" }),
    }); // common.h
    obj.addCSourceFiles(.{
        .root = contextPath,
        .files = &.{
            "continuation.cpp",
            "fiber.cpp",
        },
        .flags = cxxFlags,
    });

    obj.addCSourceFile(.{
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
        obj.defineCMacro("BOOST_USE_WINFIB", null);
        obj.want_lto = false;
    } else {
        obj.defineCMacro("BOOST_USE_UCONTEXT", null);
    }
    switch (obj.rootModuleTarget().cpu.arch) {
        .arm => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                if (obj.rootModuleTarget().abi == .msvc) {
                    obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm_aapcs_pe_armasm.asm" }) });
                    obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm_aapcs_pe_armasm.asm" }) });
                    obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm_aapcs_pe_armasm.asm" }) });
                }
            },
            .macos => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm_aapcs_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm_aapcs_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm_aapcs_macho_gas.S" }) });
            },
            else => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm_aapcs_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm_aapcs_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm_aapcs_elf_gas.S" }) });
            },
        },
        .aarch64 => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                if (obj.rootModuleTarget().abi == .msvc) {
                    obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm64_aapcs_pe_armasm.asm" }) });
                    obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm64_aapcs_pe_armasm.asm" }) });
                    obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm64_aapcs_pe_armasm.asm" }) });
                }
            },
            .macos => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm64_aapcs_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm64_aapcs_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm64_aapcs_macho_gas.S" }) });
            },
            else => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_arm64_aapcs_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_arm64_aapcs_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_arm64_aapcs_elf_gas.S" }) });
            },
        },
        .riscv64 => {
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_riscv64_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_riscv64_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_riscv64_sysv_elf_gas.S" }) });
        },
        .x86 => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                // @panic("undefined symbol:{j/m/o}-fcontext");
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_ms_pe_clang_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_ms_pe_clang_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_ms_pe_clang_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_ms_pe_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_ms_pe_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_ms_pe_gas.S" }) });
            },
            .macos => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_x86_64_sysv_macho_gas.S" }) });
            },
            else => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_sysv_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_sysv_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_sysv_elf_gas.S" }) });
            },
        },
        .x86_64 => switch (obj.rootModuleTarget().os.tag) {
            .windows => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_x86_64_ms_pe_clang_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_x86_64_ms_pe_clang_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_x86_64_ms_pe_clang_gas.S" }) });
            },
            .macos => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_i386_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_i386_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_x86_64_sysv_macho_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_i386_x86_64_sysv_macho_gas.S" }) });
            },
            else => {
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_x86_64_sysv_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_x86_64_sysv_elf_gas.S" }) });
                obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_x86_64_sysv_elf_gas.S" }) });
            },
        },
        .s390x => {
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_s390x_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_s390x_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_s390x_sysv_elf_gas.S" }) });
        },
        .mips, .mipsel => {
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_mips32_o32_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_mips32_o32_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_mips32_o32_elf_gas.S" }) });
        },
        .mips64, .mips64el => {
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_mips64_n64_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_mips64_n64_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_mips64_n64_elf_gas.S" }) });
        },
        .loongarch64 => {
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_loongarch64_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_loongarch64_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_loongarch64_sysv_elf_gas.S" }) });
        },
        .powerpc => {
            obj.addCSourceFile(.{
                .file = .{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/tail_ontop_ppc32_sysv.cpp" }) },
                .flags = cxxFlags,
            });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_ppc32_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_ppc32_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_ppc32_sysv_elf_gas.S" }) });
        },
        .powerpc64 => {
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/jump_ppc64_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/make_ppc64_sysv_elf_gas.S" }) });
            obj.addAssemblyFile(.{ .cwd_relative = b.pathJoin(&.{ ctxPath, "asm/ontop_ppc64_sysv_elf_gas.S" }) });
        },
        else => @panic("Invalid arch"),
    }
}

fn buildSerialization(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const serialPath = b.dependency("serialization", .{}).path("src");

    obj.addCSourceFiles(.{
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

    obj.addCSourceFiles(.{
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

    obj.addCSourceFiles(.{
        .root = rndPath,
        .files = &.{
            "random_device.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildException(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const exceptPath = b.dependency("exception", .{}).path("src");

    obj.addCSourceFiles(.{
        .root = exceptPath,
        .files = &.{
            "clone_current_exception_non_intrusive.cpp",
        },
        .flags = cxxFlags,
    });
}

fn buildIOStreams(b: *std.Build, obj: *std.Build.Step.Compile) void {
    const iostreamPath = b.dependency("iostreams", .{}).path("src");

    obj.addCSourceFiles(.{
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
    obj.defineCMacro("BOOST_LOG_NO_THREADS", null);
    obj.addIncludePath(logPath);
    obj.addCSourceFiles(.{
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
    obj.addCSourceFiles(.{
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
