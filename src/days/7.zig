const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const OPS = "*+|";

pub fn generateOperationCombinations(allocator: std.mem.Allocator, operations: []const u8, len: usize, cache: *std.AutoHashMap(usize, [][]u8)) ![][]u8 {
    const cache_result = cache.getPtr(len);
    if (cache_result != null) {
        return cache_result.?.*;
    }

    var result = std.ArrayList([]u8).init(allocator);

    const generateCombination = struct {
        fn generate(
            alloc: std.mem.Allocator,
            ops: []const u8,
            current: []const u8,
            target: usize,
            results: *std.ArrayList([]u8),
        ) !void {
            if (current.len == target) {
                const combination = try alloc.dupe(u8, current);
                try results.append(combination);
                return;
            }

            for (ops) |op| {
                var new_current = try alloc.alloc(u8, current.len + 1);
                @memcpy(new_current[0..current.len], current);
                new_current[current.len] = op;

                try generate(alloc, ops, new_current, target, results);
                alloc.free(new_current);
            }
        }
    }.generate;

    try generateCombination(allocator, operations, &.{}, len, &result);
    const ret = try result.toOwnedSlice();
    try cache.put(len, ret);
    return ret;
}

pub fn run(alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("input/day7.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var sum: usize = 0;
    var combo_cache = std.AutoHashMap(usize, [][]u8).init(alloc);
    defer {
        var combo_cache_it = combo_cache.iterator();
        while (combo_cache_it.next()) |v| {
            const combo = v.value_ptr.*;
            for (combo) |c| {
                alloc.free(c);
            }
            alloc.free(combo);
        }
        combo_cache.deinit();
    }

    outer: while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var part_it = std.mem.split(u8, line, ": ");

        const expected_s = part_it.next() orelse return error.InvalidInput;
        const expected = try std.fmt.parseInt(usize, expected_s, 10);

        const inputs_s = part_it.next() orelse return error.InvalidInput;
        var inputs_it = std.mem.split(u8, inputs_s, " ");

        var inputs = ArrayList(usize).init(alloc);
        defer inputs.deinit();

        while (inputs_it.next()) |i| {
            const input = try std.fmt.parseInt(usize, i, 10);
            try inputs.append(input);
        }

        const input_slice = try inputs.toOwnedSlice();
        defer alloc.free(input_slice);

        const combos = try generateOperationCombinations(alloc, "+*|", input_slice.len - 1, &combo_cache);

        combos: for (combos) |c| {
            var result = input_slice[0];

            for (1..input_slice.len) |i| {
                const op = c[i - 1];
                const n = input_slice[i];

                if (op == '*') {
                    result *= n;
                } else if (op == '+') {
                    result += n;
                } else {
                    const concat_s = try std.fmt.allocPrint(alloc, "{d}{d}", .{ result, n });
                    const concat = try std.fmt.parseInt(usize, concat_s, 10);
                    alloc.free(concat_s);
                    result = concat;
                }

                if (result > expected) {
                    continue :combos;
                }
            }

            if (result == expected) {
                sum += expected;
                continue :outer;
            }
        }
    }

    std.debug.print("day 7, sum: {d}\n", .{sum});
}
