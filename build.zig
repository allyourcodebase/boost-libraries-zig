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
        .headers_only = b.option(bool, "headers-only", "Use headers-only libraries (default: true)") orelse true,
        .module = .{
            .cobalt = b.option(bool, "cobalt", "Build cobalt library (default: false)") orelse false,
            .context = b.option(bool, "context", "Build context library (default: false)") orelse false,
            .json = b.option(bool, "json", "Build json library (default: false)") orelse false,
            .container = b.option(bool, "container", "Build container library (default: false)") orelse false,
            .filesystem = b.option(bool, "filesystem", "Build filesystem library (default: false)") orelse false,
            .coroutine2 = b.option(bool, "coroutine2", "Build coroutine2 library (default: false)") orelse false,
            .system = b.option(bool, "system", "Build system library (default: false)") orelse false,
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

    if (config.headers_only) {
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
                    .headers_only = config.headers_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostCobalt);
            }
            if (module.container) {
                const boostContainer = buildContainer(b, .{
                    .headers_only = config.headers_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostContainer);
            }
            if (module.context) {
                const boostContext = buildContext(b, .{
                    .headers_only = config.headers_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostContext);
            }
            if (module.json) {
                const boostJson = buildJson(b, .{
                    .headers_only = config.headers_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostJson);
            }
            if (module.filesystem) {
                const boostFileSystem = buildFileSystem(b, .{
                    .headers_only = config.headers_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostFileSystem);
            }
            if (module.system) {
                const boostSystem = buildSystem(b, .{
                    .headers_only = config.headers_only,
                    .target = config.target,
                    .optimize = config.optimize,
                    .include_dirs = lib.root_module.include_dirs,
                });
                lib.addObject(boostSystem);
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
    headers_only: bool = false,
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
    system: bool = false,
};

fn buildCobalt(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const cobaltPath = b.dependency("cobalt", .{}).path("src");
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
    if (obj.rootModuleTarget().abi == .msvc)
        obj.linkLibC()
    else {
        obj.defineCMacro("_GNU_SOURCE", null);
        obj.linkLibCpp();
    }

    return obj;
}

fn buildContainer(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const containerPath = b.dependency("container", .{}).path("src");
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
            "pool_resource.cpp",
            "monotonic_buffer_resource.cpp",
            "synchronized_pool_resource.cpp",
            "unsynchronized_pool_resource.cpp",
            "global_resource.cpp",
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
    const jsonPath = b.dependency("json", .{}).path("src");
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
            "src.cpp",
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

fn buildSystem(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const systemPath = b.dependency("system", .{}).path("src");
    const obj = b.addObject(.{
        .name = "system",
        .target = config.target,
        .optimize = config.optimize,
    });

    if (config.include_dirs) |include_dirs| {
        for (include_dirs.items) |include| {
            obj.root_module.include_dirs.append(b.allocator, include) catch unreachable;
        }
    }
    obj.addCSourceFiles(.{
        .root = systemPath,
        .files = &.{
            "error_code.cpp",
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

fn buildFileSystem(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const fsPath = b.dependency("filesystem", .{}).path("src");
    const obj = b.addObject(.{
        .name = "filesystem",
        .target = config.target,
        .optimize = config.optimize,
    });

    if (config.include_dirs) |include_dirs| {
        for (include_dirs.items) |include| {
            obj.root_module.include_dirs.append(b.allocator, include) catch unreachable;
        }
    }
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
        obj.linkLibC();
        obj.defineCMacro("_SCL_SECURE_NO_WARNINGS", null);
        obj.defineCMacro("_SCL_SECURE_NO_DEPRECATE", null);
        obj.defineCMacro("_CRT_SECURE_NO_WARNINGS", null);
        obj.defineCMacro("_CRT_SECURE_NO_DEPRECATE", null);
    } else {
        obj.defineCMacro("_GNU_SOURCE", null);
        obj.linkLibCpp();
    }

    return obj;
}

fn buildContext(b: *std.Build, config: Config) *std.Build.Step.Compile {
    const contextPath = b.dependency("context", .{}).path("src");
    const obj = b.addObject(.{
        .name = "context",
        .target = config.target,
        .optimize = config.optimize,
    });

    if (config.include_dirs) |include_dirs| {
        for (include_dirs.items) |include| {
            obj.root_module.include_dirs.append(b.allocator, include) catch unreachable;
        }
    }
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

    if (obj.rootModuleTarget().abi == .msvc)
        obj.linkLibC()
    else {
        obj.defineCMacro("_GNU_SOURCE", null);
        obj.linkLibCpp();
    }

    return obj;
}
