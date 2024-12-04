const std = @import("std");
const day1 = @import("./days/1.zig");
const day2 = @import("./days/2.zig");

const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try day1.run(allocator);
    try day2.run(allocator);
}
