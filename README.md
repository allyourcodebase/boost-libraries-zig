# boost-libraries-zig

[Boost Libraries](https://boost.io) using `build.zig`.

Replacing the [CMake](https://cmake.org/) and [B2](https://www.bfgroup.xyz/b2/) build system.

### Requirements

- [zig](https://ziglang.org/download) v0.13.0 or master

## How to use

Build libraries

```bash
# Build no-header-only libraries
$ zig build -Doptimize=<Debug|ReleaseSafe|ReleaseFast|ReleaseSmall> -Dtarget=<triple-target> --summary <all|new> -Dcontext -Djson -Dsystem -Dcontainer -Dcobalt -Dfilesystem -Dheaders-only=false
```

#### Helper

```bash
Project-Specific Options:
  -Dtarget=[string]            The CPU architecture, OS, and ABI to build for
  -Dcpu=[string]               Target CPU features to add or subtract
  -Ddynamic-linker=[string]    Path to interpreter on the target system
  -Doptimize=[enum]            Prioritize performance, safety, or binary size
                                 Supported Values:
                                   Debug
                                   ReleaseSafe
                                   ReleaseFast
                                   ReleaseSmall
  -Dheaders-only=[bool]        Use headers-only libraries (default: true)
  -Dcobalt=[bool]              Build cobalt library (default: false)
  -Dcontext=[bool]             Build context library (default: false)
  -Djson=[bool]                Build json library (default: false)
  -Dcontainer=[bool]           Build container library (default: false)
  -Dfilesystem=[bool]          Build filesystem library (default: false)
  -Dcoroutine2=[bool]          Build coroutine2 library (default: false)
  -Dsystem=[bool]              Build system library (default: false)
  -Dshared=[bool]              Build as shared library (default: false)
```


### or use in new zig project

Make directory and init

```bash
$ zig init
## add in 'build.zig.zon' boost-libraries-zig package
$ zig fetch --save=boost git+https://github.com/allyourcodebase/boost-libraries-zig
```
Add in **build.zig**
```zig
const std = @import("std");
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const boost_dep = b.dependency("boost", .{
        .target = target,
        .optimize = optimize,
        // default is true (recommended)
        // .@"headers-only" = false,
    });
    const boost_artifact = boost_dep.artifact("boost");

    for(boost_artifact.root_module.include_dirs.items) |include_dir| {
        try exe.root_module.include_dirs.append(b.allocator, include_dir);
    }
}
```

## License

see: [LICENSE](LICENSE)