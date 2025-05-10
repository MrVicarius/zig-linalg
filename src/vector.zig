const std = @import("std");
const expect = @import("std").testing.expect;

pub fn Vec(comptime n: u8, comptime T: type) type {
    return struct {
        raw: @Vector(n, T),

        const This = @This();

        // ---------------
        // initialization
        // ---------------
        pub fn init(data: @Vector(n, T)) This {
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

        // -----------------
        // logic operations 
        // -----------------
        pub fn equal(this: This, other: This) bool {
            for (0..n) |i| {
                if (this.raw[i] != other.raw[i]) {
                    return false;
                }
            }

            return true;
        }

        // ----------------
        // math operations 
        // ----------------
        pub fn dprod(this: This, other: This) T {
            return @reduce(.Add, this.raw * other.raw);
        }

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
    }; 
}

test "init" {
    const v = Vec(3, u32).init(.{1, 2, 3});
    try expect(v.raw[0] == 1);
    try expect(v.raw[1] == 2);
    try expect(v.raw[2] == 3);
}

test "full" {
    const v = Vec(2, u32).full(1);
    try expect(v.raw[0] == 1);
    try expect(v.raw[1] == 1);
}

test "zeros" {
    const v = Vec(2, u32).zeros();
    try expect(v.raw[0] == 0);
    try expect(v.raw[1] == 0);
}

test "ones" {
    const v = Vec(2, u32).ones();
    try expect(v.raw[0] == 1);
    try expect(v.raw[1] == 1);
}

test "equal" {
    const v1 = Vec(3, f32).full(1);
    const v2 = Vec(3, f32).ones();
    const v3 = Vec(3, f32).zeros();

    try expect(v1.equal(v2));
    try expect(!v1.equal(v3));
}

test "dot product" {
    const v1 = Vec(3, u32).init(.{1, 2, 3});
    const v2 = Vec(3, u32).init(.{1, 2, 3});
    const res = v1.dprod(v2);
    try expect(res == 1 + 4 + 9);
}

test "add" {
    const v1 = Vec(3, u32).init(.{1, 2, 3});
    const v2 = Vec(3, u32).init(.{1, 2, 3});
    try expect(v1.add(v2).equal(Vec(3, u32).init(.{2, 4, 6})));
}

