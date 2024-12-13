const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AuthHashMap = std.AutoHashMap;
const BlockType = enum { file, free };

pub fn run(alloc: Allocator) !void {
    const disk = try std.fs.cwd().readFileAlloc(alloc, "input/day9.txt", std.math.maxInt(usize));
    defer alloc.free(disk);

    // fixme: weird trailing whitespace in the input file
    const pointer_r_start = disk.len - 2;

    var output = ArrayList(usize).init(alloc);
    defer output.deinit();

    var moves = AuthHashMap(usize, u1).init(alloc);
    defer moves.deinit();

    for (0..disk.len) |idx| {
        if (idx >= pointer_r_start) {
            break;
        }

        const t = if (@mod(idx, 2) == 0) BlockType.file else BlockType.free;

        const block = disk[idx];
        var block_len = try std.fmt.parseInt(usize, &[1]u8{block}, 10);
        if (t == .file) {
            const id = idx / 2;
            const check = moves.get(idx);
            for (0..block_len) |_| {
                if (check == null) {
                    try output.append(id + 1);
                } else {
                    try output.append(0);
                }
            }
        } else {
            var pointer_r = pointer_r_start;
            while (block_len > 0 and pointer_r > idx) {
                defer pointer_r -= 2;

                if (moves.get(pointer_r) != null) {
                    continue;
                }
                const candidate_size_s = disk[pointer_r];
                const candidate_size = try std.fmt.parseInt(usize, &[1]u8{candidate_size_s}, 10);

                if (candidate_size <= block_len) {
                    for (0..candidate_size) |_| {
                        const id = pointer_r / 2;
                        try output.append(id + 1);
                        block_len -= 1;
                    }

                    try moves.put(pointer_r, 1);
                }
            }

            for (0..block_len) |_| {
                try output.append(0);
            }
        }
    }

    const ret = try output.toOwnedSlice();
    defer alloc.free(ret);

    var sum: usize = 0;

    // we store ids as 1-based so we can use zeros for free space
    for (0.., ret) |idx, d| {
        if (d > 0) {
            const file_id = d - 1;
            sum += file_id * idx;
        }
    }

    std.debug.print("day 9, sum: {d}\n", .{sum});
}
