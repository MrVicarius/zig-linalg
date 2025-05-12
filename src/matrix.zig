const std = @import("std");
const assert = @import("std").debug.assert;
const expect = @import("std").testing.expect;

pub fn Mat(comptime n: u8, comptime T: type) type {
    return struct {
        raw: @Vector(n * n, T),

        const This = @This();

        // ---------------
        // initialization
        // ---------------
        pub fn init(data: @Vector(n * n, T)) This {
            return .{.raw = data};
        }

        pub fn full(value: T) This {
            return .{.raw = @splat(value)};
        }

        pub fn zeros() This {
            return .{.raw = @splat(0)};
        }

        pub fn ones() This {
            return .{.raw = @splat(1)};
        }

        pub fn identity() This {
            var m = This.zeros();
            
            for (0..n) |i| {
                m.set(i, i, 1);
            }

            return m;
        }

        pub fn set(this: *This, row: usize, col: usize, value: T) void {
            this.raw[row * n + col] = value;
        }

        // ------------
        // data access
        // ------------
        pub fn get(this: This, row: usize, col: usize) T {
            return this.raw[row * n + col];
        }

        // -----------------
        // logic operations 
        // -----------------
        pub fn equal(this: This, other: This) bool {
            return @reduce(.And, this.raw == other.raw);
        }

        // ----------------
        // math operations 
        // ----------------
        pub fn add(this: This, other: This) This { 
            return .{.raw = this.raw + other.raw};
        }

        pub fn sub(this: This, other: This) This { 
            return .{.raw = this.raw - other.raw};
        }

        pub fn mul(this: This, other: This) This { 
            return .{.raw = this.raw * other.raw};
        }

        pub fn div(this: This, other: This) This { 
            return .{.raw = this.raw / other.raw};
        }

        pub fn bias(this: This, value: T) This {
            return this.add(This.full(value));
        }

        pub fn scale(this: This, value: T) This {
            return this.mul(This.full(value));
        }

        pub fn transpose(this: This) This {
            return switch(n) {
                1 => this,
                2 => This.init(
                    @shuffle(T, this.raw, undefined, [4]u32{ 0, 2, 1, 3 })
                ),
                3 => This.init(
                    @shuffle(T, this.raw, undefined, [9]u32{ 0, 3, 6, 1, 4, 7, 2, 5, 8 })
                ),
                4 => This.init(
                    @shuffle(
                        T, 
                        this.raw, 
                        undefined, 
                        [16]u32{ 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15 },
                    )
                ),
                else => blk: {
                    var m = This.zeros();

                    for (0..n) |i| {
                        for (0..n) |j| {
                            m.set(j, i, this.get(i, j));
                        }
                    }

                    break :blk m;
                },
            };
        }

        pub fn t(this: This) This {
            return this.transpose();
        }
    };
}

test "init" {
    const m = Mat(2, u32).init(.{
        1, 2,
        3, 4,
    });

    try expect(m.raw[0] == 1);
    try expect(m.raw[1] == 2);
    try expect(m.raw[2] == 3);
    try expect(m.raw[3] == 4);
}

test "full" {
    const m = Mat(2, u32).full(2);

    try expect(m.raw[0] == 2);
    try expect(m.raw[1] == 2);
    try expect(m.raw[2] == 2);
    try expect(m.raw[3] == 2);
}

test "zeros" {
    const m = Mat(2, u32).zeros();

    try expect(m.raw[0] == 0);
    try expect(m.raw[1] == 0);
    try expect(m.raw[2] == 0);
    try expect(m.raw[3] == 0);
}

test "ones" {
    const m = Mat(2, u32).ones();

    try expect(m.raw[0] == 1);
    try expect(m.raw[1] == 1);
    try expect(m.raw[2] == 1);
    try expect(m.raw[3] == 1);
}

test "identity" {
    const m = Mat(2, u32).identity();

    try expect(m.raw[0] == 1);
    try expect(m.raw[1] == 0);
    try expect(m.raw[2] == 0);
    try expect(m.raw[3] == 1);
}

test "get values" {
    const m = Mat(2, u32).init(.{
        1, 2,
        3, 4,
    });

    try expect(m.get(0, 0) == 1);
    try expect(m.get(0, 1) == 2);
    try expect(m.get(1, 0) == 3);
    try expect(m.get(1, 1) == 4);
}

test "equal" {
    const m1 = Mat(3, f32).full(1);
    const m2 = Mat(3, f32).ones();
    const m3 = Mat(3, f32).zeros();

    try expect(m1.equal(m2));
    try expect(!m1.equal(m3));
}

test "add" {
    const m1 = Mat(2, f32).init(.{1, 2, 3, 4});
    const m2 = Mat(2, f32).init(.{1, 2, 3, 4});
    try expect(m1.add(m2).equal(Mat(2, f32).init(.{2, 4, 6, 8})));
}

test "subtract" {
    const m1 = Mat(3, f32).ones();
    const m2 = Mat(3, f32).ones();
    try expect(m1.sub(m2).equal(Mat(3, f32).zeros()));
}

test "multiplication" {
    const m1 = Mat(2, f32).init(.{1, 2, 3, 4});
    const m2 = Mat(2, f32).init(.{1, 2, 3, 4});
    try expect(m1.mul(m2).equal(Mat(2, f32).init(.{1, 4, 9, 16})));
}

test "division" {
    const m1 = Mat(2, f32).init(.{1, 2, 3, 4});
    const m2 = Mat(2, f32).init(.{1, 2, 3, 4});
    try expect(m1.div(m2).equal(Mat(2, f32).ones()));
}

test "bias" {
    const m = Mat(2, f32).ones();
    try expect(m.bias(4).equal(Mat(2, f32).full(5))); 
}

test "scale" {
    const m = Mat(2, f32).full(2);
    try expect(m.scale(0.5).equal(Mat(2, f32).ones())); 
}

test "transpose" {
    const m1_2 = Mat(2, u32).init(.{
        1, 2,
        3, 4,
    });
    const m2_2 = Mat(2, u32).init(.{
        1, 3,
        2, 4,
    });

    try expect(m1_2.transpose().equal(m2_2));

    const m1_3 = Mat(3, u32).init(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });
    const m2_3 = Mat(3, u32).init(.{
        1, 4, 7,
        2, 5, 8,
        3, 6, 9,
    });

    try expect(m1_3.t().equal(m2_3));

    const m1_4 = Mat(4, u32).init(.{
        1, 2, 3, 4,
        5, 6, 7, 8,
        9, 10, 11, 12,
        13, 14, 15, 16,
    });
    const m2_4 = Mat(4, u32).init(.{
        1, 5, 9, 13,
        2, 6, 10, 14,
        3, 7, 11, 15,
        4, 8, 12, 16,
    });

    try expect(m1_4.t().equal(m2_4));

    const m1_5 = Mat(5, u32).init(.{
        1, 2, 3, 4, 5,
        6, 7, 8, 9, 10,
        11, 12, 13, 14, 15,
        16, 17, 18, 19, 20,
        21, 22, 23, 24, 25,
    });
    const m2_5 = Mat(5, u32).init(.{
        1, 6, 11, 16, 21,
        2, 7, 12, 17, 22,
        3, 8, 13, 18, 23,
        4, 9, 14, 19, 24,
        5, 10, 15, 20, 25,
    });

    try expect(m1_5.t().equal(m2_5));
}

