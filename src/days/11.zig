const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const CacheKey = struct {
    val: u64,
    seq: u64,
};
const Cache = AutoHashMap(CacheKey, u64);

// iterate through a given val, returning the number of
// values will be produced by this "blink"
fn blinkVal(val: u64, seq: u64, cache: *Cache) !u64 {
    // if we are here, we are at the end of the sequence
    // (no more blinks), so return a count of 1;
    if (seq == 0) {
        return 1;
    }

    const key = CacheKey{ .val = val, .seq = seq };
    if (cache.get(key)) |cached_result| {
        return cached_result;
    }

    if (val == 0) {
        const result = try blinkVal(1, seq - 1, cache);
        try cache.put(key, result);
        return result;
    }

    // fun math to bypass string back and forths
    const digit_count = std.math.log10(val) + 1;
    if (@rem(digit_count, 2) == 0) {
        const divisor = std.math.pow(u64, 10, digit_count / 2);
        const one = val / divisor;
        const two = @rem(val, divisor);

        const result = try blinkVal(one, seq - 1, cache) + try blinkVal(two, seq - 1, cache);
        try cache.put(key, result);
        return result;
    }

    const result = try blinkVal(val * 2024, seq - 1, cache);
    try cache.put(key, result);
    return result;
}

pub fn run(alloc: Allocator) !void {
    const input_s = try std.fs.cwd().readFileAlloc(alloc, "input/day11.txt", std.math.maxInt(usize));
    defer alloc.free(input_s);

    const blinks = 75;
    var stones: usize = 0;
    var cache = Cache.init(alloc);
    defer cache.deinit();

    var input_it = std.mem.split(u8, input_s[0 .. input_s.len - 1], " ");
    while (input_it.next()) |val_s| {
        const val = try std.fmt.parseInt(u64, val_s, 10);
        stones += try blinkVal(val, blinks, &cache);
    }

    std.debug.print("day 11, stones: {d}\n", .{stones});
}
