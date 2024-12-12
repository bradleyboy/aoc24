const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const BlockType = enum { file, free };

pub fn run(alloc: Allocator) !void {
    const disk = try std.fs.cwd().readFileAlloc(alloc, "input/day9.txt", std.math.maxInt(usize));
    defer alloc.free(disk);

    // fixme: weird trailing whitespace in the input file
    var pointer_r = disk.len - 2;
    const pointer_r_remaining_s = disk[pointer_r];
    var pointer_r_remaining = try std.fmt.parseInt(usize, &[1]u8{pointer_r_remaining_s}, 10);

    var output = ArrayList(usize).init(alloc);
    defer output.deinit();

    for (0.., disk) |idx, block| {
        if (idx >= pointer_r) {
            while (pointer_r_remaining > 0) {
                const id = pointer_r / 2;
                pointer_r_remaining -= 1;
                try output.append(id + 1);
            }

            break;
        }

        const t = if (@mod(idx, 2) == 0) BlockType.file else BlockType.free;

        const block_len = try std.fmt.parseInt(usize, &[1]u8{block}, 10);
        if (t == .file) {
            const id = idx / 2;
            for (0..block_len) |_| {
                try output.append(id + 1);
            }
        } else {
            for (0..block_len) |_| {
                if (pointer_r_remaining == 0) {
                    // skip over free space to the next file block
                    pointer_r -= 2;
                    const next_pointer_r_remaining_s = disk[pointer_r];
                    pointer_r_remaining = try std.fmt.parseInt(usize, &[1]u8{next_pointer_r_remaining_s}, 10);
                }

                if (pointer_r_remaining > 0) {
                    const id = pointer_r / 2;
                    pointer_r_remaining -= 1;
                    try output.append(id + 1);
                }
            }
        }
    }

    const ret = try output.toOwnedSlice();
    defer alloc.free(ret);

    var sum: usize = 0;

    // we store ids as 1-based so we can use zeros for free space
    for (0.., ret) |idx, d| {
        const file_id = d - 1;
        sum += file_id * idx;
    }

    std.debug.print("day 9, sum: {d}\n", .{sum});
}
