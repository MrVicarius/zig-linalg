const expect = @import("std").testing.expect;

pub fn Vec(comptime n: u8, comptime T: type) type {
    return struct {
        raw: @Vector(n, T),

        const This = @This();

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

        pub fn dprod(this: This, other: This) T {
            return @reduce(.Add, this.raw * other.raw);
        }

        pub fn add(this: This, other: This) This { 
            return .{.raw = this.raw + other.raw};
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

test "dot product" {
    const v1 = Vec(3, u32).init(.{1, 2, 3});
    const v2 = Vec(3, u32).init(.{1, 2, 3});
    const res = v1.dprod(v2);
    try expect(res == 1 + 4 + 9);
}

test "add" {
    const v1 = Vec(3, u32).init(.{1, 2, 3});
    const v2 = Vec(3, u32).init(.{1, 2, 3});
    const res = v1.add(v2);
    try expect(res.raw[0] == 2);
    try expect(res.raw[1] == 4);
    try expect(res.raw[2] == 6);
}

