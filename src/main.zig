const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const InputArrays = struct {
    a: []u64,
    b: []u64,
};

const InputMaps = struct {
    a: std.AutoHashMap(u64, u64),
    b: std.AutoHashMap(u64, u64),
};

fn readInputAsSortedArrays(path: []const u8, alloc: Allocator) !InputArrays {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list_one = ArrayList(u64).init(alloc);
    var list_two = ArrayList(u64).init(alloc);
    defer list_one.deinit();
    defer list_two.deinit();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");
        const one_s = it.first();
        const two_s = it.next();

        if (two_s) |val| {
            const one = try std.fmt.parseInt(u64, one_s, 10);
            const two = try std.fmt.parseInt(u64, val, 10);

            try list_one.append(one);
            try list_two.append(two);
        }
    }

    const one_arr = try list_one.toOwnedSlice();
    const two_arr = try list_two.toOwnedSlice();

    std.mem.sort(u64, one_arr, {}, std.sort.asc(u64));
    std.mem.sort(u64, two_arr, {}, std.sort.asc(u64));

    return .{
        .a = one_arr,
        .b = two_arr,
    };
}

fn calcDistance(input: InputArrays) u64 {
    var distance: u64 = 0;

    for (0.., input.a) |i, a_val| {
        const b_val = input.b[i];

        if (b_val == a_val) {
            continue;
        }

        if (b_val > a_val) {
            distance += b_val - a_val;
        } else {
            distance += a_val - b_val;
        }
    }

    return distance;
}

fn day1part1(alloc: Allocator) !void {
    const input = try readInputAsSortedArrays("day1.txt", alloc);
    const distance = calcDistance(input);

    std.debug.print("day 1, part 1 (distance): {d}\n", .{distance});
}

fn readInputAsCountMap(path: []const u8, alloc: Allocator) !InputMaps {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var map_one = std.AutoHashMap(u64, u64).init(
        alloc,
    );
    var map_two = std.AutoHashMap(u64, u64).init(
        alloc,
    );

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");
        const one_s = it.first();
        const two_s = it.next();

        if (two_s) |val| {
            const one = try std.fmt.parseInt(u64, one_s, 10);
            const two = try std.fmt.parseInt(u64, val, 10);

            const one_count = map_one.get(one) orelse 0;
            const two_count = map_two.get(two) orelse 0;

            try map_one.put(one, one_count + 1);
            try map_two.put(two, two_count + 1);
        }
    }

    return InputMaps{
        .a = map_one,
        .b = map_two,
    };
}

fn day1part2(alloc: Allocator) !void {
    const input = try readInputAsCountMap("day1.txt", alloc);
    var it = input.a.keyIterator();

    var similarity: u64 = 0;

    while (it.next()) |key| {
        const key_deref = key.*;
        const a_count = input.a.get(key_deref) orelse 0;
        const b_count = input.b.get(key_deref) orelse 0;

        similarity += a_count * b_count * key_deref;
    }

    std.debug.print("day 1, part 2 (similarity): {d}\n", .{similarity});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try day1part1(allocator);
    try day1part2(allocator);
}
