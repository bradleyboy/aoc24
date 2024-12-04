const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const NextToken = enum(u8) { m = 'm', u = 'u', l = 'l', open_parens = '(', a = 'a', comma = ',', b = 'b', close_parens = ')' };
const NextInstructionToken = enum(u8) { d = 'd', o = 'o', n = 'n', apos = '\'', t = 't', open_parens = '(', close_parens = ')' };

fn advanceToken(current: NextToken) NextToken {
    switch (current) {
        NextToken.m => return NextToken.u,
        NextToken.u => return NextToken.l,
        NextToken.l => return NextToken.open_parens,
        NextToken.open_parens => return NextToken.a,
        NextToken.a => return NextToken.comma,
        NextToken.comma => return NextToken.b,
        NextToken.b => return NextToken.close_parens,
        NextToken.close_parens => return NextToken.m,
    }
}

fn advanceInstructionToken(current: NextInstructionToken) NextInstructionToken {
    switch (current) {
        NextInstructionToken.d => return NextInstructionToken.o,
        NextInstructionToken.o => return NextInstructionToken.n,
        NextInstructionToken.n => return NextInstructionToken.apos,
        NextInstructionToken.apos => return NextInstructionToken.t,
        NextInstructionToken.t => return NextInstructionToken.open_parens,
        NextInstructionToken.open_parens => return NextInstructionToken.close_parens,
        NextInstructionToken.close_parens => return NextInstructionToken.d,
    }
}

pub fn run(alloc: Allocator) !void {
    // const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    // const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    //
    const input = try std.fs.cwd().readFileAlloc(alloc, "input/day3.txt", std.math.maxInt(usize));
    defer alloc.free(input);

    var expected_next = NextToken.m;
    var expected_next_instruction = NextInstructionToken.d;

    var enabled = true;
    var reading_instruction = false;
    var instruction_is_enabling = false;
    var reading_mul = false;

    var a: u64 = 0;
    var b: u64 = 0;
    var total: u64 = 0;

    for (0.., input) |i, _| {
        const c = input[i];

        if (reading_instruction) {
            if (c == @intFromEnum(expected_next_instruction)) {
                if (c == ')') {
                    enabled = instruction_is_enabling;
                    reading_instruction = false;
                    instruction_is_enabling = false;
                }
                expected_next_instruction = advanceInstructionToken(expected_next_instruction);
                continue;
            }

            if (expected_next_instruction == NextInstructionToken.n and c == @intFromEnum(NextInstructionToken.open_parens)) {
                instruction_is_enabling = true;
                expected_next_instruction = NextInstructionToken.close_parens;
                continue;
            }
        }

        if (reading_mul and enabled) {
            const is_digit = std.ascii.isDigit(c);

            if (is_digit) {
                const as_int = c - '0';

                if (expected_next == NextToken.a) {
                    a = as_int;
                    expected_next = advanceToken(expected_next);
                    continue;
                }

                if (expected_next == NextToken.b) {
                    b = as_int;
                    expected_next = advanceToken(expected_next);
                    continue;
                }

                if (expected_next == NextToken.comma and a < 100) {
                    a = (a * 10) + as_int;
                    continue;
                }

                if (expected_next == NextToken.close_parens and b < 100) {
                    b = (b * 10) + as_int;
                    continue;
                }
            }

            if (c == @intFromEnum(expected_next)) {
                if (c == ')') {
                    total += (a * b);
                }
                expected_next = advanceToken(expected_next);
                continue;
            }
        }

        if (c == @intFromEnum(NextToken.m)) {
            reading_mul = true;
            expected_next = advanceToken(NextToken.m);
        } else if (c == @intFromEnum(NextInstructionToken.d)) {
            reading_instruction = true;
            expected_next_instruction = advanceInstructionToken(NextInstructionToken.d);
        } else {
            a = 0;
            b = 0;
            expected_next = NextToken.m;
            expected_next_instruction = NextInstructionToken.d;
            reading_instruction = false;
            reading_mul = false;
        }
    }

    std.debug.print("day 3, total: {d}\n", .{total});
}
