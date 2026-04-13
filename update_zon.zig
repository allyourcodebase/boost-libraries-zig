const std = @import("std");
const process = std.process;
const fmt = std.fmt;

const boost_version = "boost-1.90.0";

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    for (git_urls) |git_url| {
        // Extract package name from URL
        const pkg_name = blk: {
            var iter = std.mem.splitSequence(u8, git_url, "/");
            while (iter.next()) |part| {
                if (std.mem.indexOf(u8, part, "#") != null) {
                    break :blk part[0..std.mem.indexOf(u8, part, "#").?];
                }
            }
            unreachable;
        };

        const saved_pkg = try fmt.allocPrint(allocator, "--save={s}", .{pkg_name});
        defer allocator.free(saved_pkg);

        // zig fetch command
        const args = [_][]const u8{
            "zig",
            "fetch",
            saved_pkg,
            git_url,
        };

        // Execute command
        const result = try process.run(allocator, init.io, .{
            .argv = &args,
        });
        defer allocator.free(result.stderr);

        if (result.stderr.len > 0) {
            std.debug.print("Fetching {s}: {s}", .{
                pkg_name,
                result.stderr,
            });
        }
    }
}

const git_urls = [_][]const u8{
    "git+https://github.com/boostorg/algorithm#" ++ boost_version,
    "git+https://github.com/boostorg/asio#" ++ boost_version,
    "git+https://github.com/boostorg/assert#" ++ boost_version,
    "git+https://github.com/boostorg/bind#" ++ boost_version,
    "git+https://github.com/boostorg/config#" ++ boost_version,
    "git+https://github.com/boostorg/container#" ++ boost_version,
    "git+https://github.com/boostorg/core#" ++ boost_version,
    "git+https://github.com/boostorg/detail#" ++ boost_version,
    "git+https://github.com/boostorg/describe#" ++ boost_version,
    "git+https://github.com/boostorg/endian#" ++ boost_version,
    "git+https://github.com/boostorg/container_hash#" ++ boost_version,
    "git+https://github.com/boostorg/iterator#" ++ boost_version,
    "git+https://github.com/boostorg/intrusive#" ++ boost_version,
    "git+https://github.com/boostorg/logic#" ++ boost_version,
    "git+https://github.com/boostorg/mp11#" ++ boost_version,
    "git+https://github.com/boostorg/mpl#" ++ boost_version,
    "git+https://github.com/boostorg/optional#" ++ boost_version,
    "git+https://github.com/boostorg/smart_ptr#" ++ boost_version,
    "git+https://github.com/boostorg/move#" ++ boost_version,
    "git+https://github.com/boostorg/static_assert#" ++ boost_version,
    "git+https://github.com/boostorg/static_string#" ++ boost_version,
    "git+https://github.com/boostorg/system#" ++ boost_version,
    "git+https://github.com/boostorg/throw_exception#" ++ boost_version,
    "git+https://github.com/boostorg/tuple#" ++ boost_version,
    "git+https://github.com/boostorg/type_traits#" ++ boost_version,
    "git+https://github.com/boostorg/utility#" ++ boost_version,
    "git+https://github.com/boostorg/winapi#" ++ boost_version,
    "git+https://github.com/boostorg/functional#" ++ boost_version,
    "git+https://github.com/boostorg/json#" ++ boost_version,
    "git+https://github.com/boostorg/io#" ++ boost_version,
    "git+https://github.com/boostorg/range#" ++ boost_version,
    "git+https://github.com/boostorg/regex#" ++ boost_version,
    "git+https://github.com/boostorg/variant#" ++ boost_version,
    "git+https://github.com/boostorg/variant2#" ++ boost_version,
    "git+https://github.com/boostorg/date_time#" ++ boost_version,
    "git+https://github.com/boostorg/outcome#" ++ boost_version,
    "git+https://github.com/boostorg/hana#" ++ boost_version,
    "git+https://github.com/boostorg/numeric_conversion#" ++ boost_version,
    "git+https://github.com/boostorg/concept_check#" ++ boost_version,
    "git+https://github.com/boostorg/predef#" ++ boost_version,
    "git+https://github.com/boostorg/preprocessor#" ++ boost_version,
    "git+https://github.com/boostorg/align#" ++ boost_version,
    "git+https://github.com/boostorg/graph#" ++ boost_version,
    "git+https://github.com/boostorg/pfr#" ++ boost_version,
    "git+https://github.com/boostorg/math#" ++ boost_version,
    "git+https://github.com/boostorg/lexical_cast#" ++ boost_version,
    "git+https://github.com/boostorg/type_index#" ++ boost_version,
    "git+https://github.com/boostorg/beast#" ++ boost_version,
    "git+https://github.com/boostorg/chrono#" ++ boost_version,
    "git+https://github.com/boostorg/unordered#" ++ boost_version,
    "git+https://github.com/boostorg/any#" ++ boost_version,
    "git+https://github.com/boostorg/url#" ++ boost_version,
    "git+https://github.com/boostorg/multi_array#" ++ boost_version,
    "git+https://github.com/boostorg/integer#" ++ boost_version,
    "git+https://github.com/boostorg/array#" ++ boost_version,
    "git+https://github.com/boostorg/safe_numerics#" ++ boost_version,
    "git+https://github.com/boostorg/filesystem#" ++ boost_version,
    "git+https://github.com/boostorg/compute#" ++ boost_version,
    "git+https://github.com/boostorg/mysql#" ++ boost_version,
    "git+https://github.com/boostorg/sort#" ++ boost_version,
    "git+https://github.com/boostorg/stacktrace#" ++ boost_version,
    "git+https://github.com/boostorg/signals2#" ++ boost_version,
    "git+https://github.com/boostorg/interprocess#" ++ boost_version,
    "git+https://github.com/boostorg/context#" ++ boost_version,
    "git+https://github.com/boostorg/timer#" ++ boost_version,
    "git+https://github.com/boostorg/wave#" ++ boost_version,
    "git+https://github.com/boostorg/atomic#" ++ boost_version,
    "git+https://github.com/boostorg/scope#" ++ boost_version,
    "git+https://github.com/boostorg/process#" ++ boost_version,
    "git+https://github.com/boostorg/fusion#" ++ boost_version,
    "git+https://github.com/boostorg/function#" ++ boost_version,
    "git+https://github.com/boostorg/spirit#" ++ boost_version,
    "git+https://github.com/boostorg/cobalt#" ++ boost_version,
    "git+https://github.com/boostorg/phoenix#" ++ boost_version,
    "git+https://github.com/boostorg/locale#" ++ boost_version,
    "git+https://github.com/boostorg/uuid#" ++ boost_version,
    "git+https://github.com/boostorg/nowide#" ++ boost_version,
    "git+https://github.com/boostorg/circular_buffer#" ++ boost_version,
    "git+https://github.com/boostorg/leaf#" ++ boost_version,
    "git+https://github.com/boostorg/lockfree#" ++ boost_version,
    "git+https://github.com/boostorg/redis#" ++ boost_version,
    "git+https://github.com/boostorg/geometry#" ++ boost_version,
    "git+https://github.com/boostorg/crc#" ++ boost_version,
    "git+https://github.com/boostorg/compat#" ++ boost_version,
    "git+https://github.com/boostorg/bimap#" ++ boost_version,
    "git+https://github.com/boostorg/tokenizer#" ++ boost_version,
    "git+https://github.com/boostorg/parameter#" ++ boost_version,
    "git+https://github.com/boostorg/callable_traits#" ++ boost_version,
    "git+https://github.com/boostorg/odeint#" ++ boost_version,
    "git+https://github.com/boostorg/ublas#" ++ boost_version,
    "git+https://github.com/boostorg/serialization#" ++ boost_version,
    "git+https://github.com/boostorg/iostreams#" ++ boost_version,
    "git+https://github.com/boostorg/type_erasure#" ++ boost_version,
    "git+https://github.com/boostorg/typeof#" ++ boost_version,
    "git+https://github.com/boostorg/units#" ++ boost_version,
    "git+https://github.com/boostorg/hash2#" ++ boost_version,
    "git+https://github.com/boostorg/parser#" ++ boost_version,
    "git+https://github.com/boostorg/mqtt5#" ++ boost_version,
    "git+https://github.com/boostorg/function_types#" ++ boost_version,
    "git+https://github.com/boostorg/hof#" ++ boost_version,
    "git+https://github.com/boostorg/interval#" ++ boost_version,
    "git+https://github.com/boostorg/icl#" ++ boost_version,
    "git+https://github.com/boostorg/local_function#" ++ boost_version,
    "git+https://github.com/boostorg/log#" ++ boost_version,
    "git+https://github.com/boostorg/charconv#" ++ boost_version,
    "git+https://github.com/boostorg/conversion#" ++ boost_version,
    "git+https://github.com/boostorg/heap#" ++ boost_version,
    "git+https://github.com/boostorg/msm#" ++ boost_version,
    "git+https://github.com/boostorg/coroutine2#" ++ boost_version,
    "git+https://github.com/boostorg/pool#" ++ boost_version,
    "git+https://github.com/boostorg/format#" ++ boost_version,
    "git+https://github.com/boostorg/fiber#" ++ boost_version,
    "git+https://github.com/boostorg/proto#" ++ boost_version,
    "git+https://github.com/boostorg/property_tree#" ++ boost_version,
    "git+https://github.com/boostorg/exception#" ++ boost_version,
    "git+https://github.com/boostorg/multi_index#" ++ boost_version,
    "git+https://github.com/boostorg/random#" ++ boost_version,
    "git+https://github.com/boostorg/dll#" ++ boost_version,
    "git+https://github.com/boostorg/multiprecision#" ++ boost_version,
    "git+https://github.com/boostorg/gil#" ++ boost_version,
    "git+https://github.com/boostorg/python#" ++ boost_version,
    "git+https://github.com/boostorg/property_map#" ++ boost_version,
    "git+https://github.com/boostorg/property_map_parallel#" ++ boost_version,
    "git+https://github.com/boostorg/tti#" ++ boost_version,
    "git+https://github.com/boostorg/bloom#" ++ boost_version,
    "git+https://github.com/boostorg/openmethod#" ++ boost_version,
};
