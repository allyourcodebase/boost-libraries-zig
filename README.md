# boost-libraries-zig

Boost Libraries using `build.zig`

### Requirements

- [zig](https://ziglang.org/download) v0.13.0 or master

## How to use

Make directory and init

```bash
$ zig init
## add zon file boost-libraries-zig
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
        .@"headers-only" = true,
    });
    const boost_artifact = boost_dep.artifact("boost");

    for(boost_artifact.root_module.include_dirs.items) |include_dir| {
        try exe.root_module.include_dirs.append(b.allocator, include_dir);
    }
    exe.linklibrary(boost_artifact);
}
```

## License

see: [LICENSE](LICENSE)