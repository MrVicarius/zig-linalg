//! A linear algebra module providing matrix operations with compile-time known dimensions.
//! All matrices are stored in row-major order using SIMD vectors for efficient computation.

const std = @import("std");
const assert = @import("std").debug.assert;
const expect = @import("std").testing.expect;
const Vec = @import("vector.zig").Vec;

/// A generic matrix type with compile-time known dimensions.
/// Parameters:
///   n: number of rows
///   m: number of columns
///   T: element type (e.g. f32, f64, etc)
pub fn Mat(comptime n: u8, comptime m: u8, comptime T: type) type {
    return struct {
        /// Raw data storage as SIMD vector
        raw: @Vector(n * m, T),

        const This = @This();
        const _n = n;
        const _m = m;

        // ---------------
        // initialization
        // ---------------

        /// Initialize a matrix with raw vector data in row-major order
        pub fn init(data: @Vector(n * m, T)) This {
            return .{ .raw = data };
        }

        /// Create a matrix filled with a single value
        pub fn full(value: T) This {
            return .{ .raw = @splat(value) };
        }

        /// Create a matrix filled with zeros
        pub fn zeros() This {
            return .{ .raw = @splat(0) };
        }

        /// Create a matrix filled with ones
        pub fn ones() This {
            return .{ .raw = @splat(1) };
        }

        /// Create an identity matrix. Only valid for square matrices.
        pub fn identity() This {
            comptime {
                assert(n == m);
            }
            var mat = This.zeros();

            for (0..n) |i| {
                mat.set(i, i, 1);
            }

            return mat;
        }

        /// Set a value at the specified row and column
        pub fn set(this: *This, row: usize, col: usize, value: T) void {
            this.raw[row * m + col] = value;
        }

        // ------------
        // data access
        // ------------

        /// Get the value at the specified row and column
        pub fn get(this: This, row: usize, col: usize) T {
            return this.raw[row * m + col];
        }

        // -----------------
        // logic operations
        // -----------------

        /// Check if two matrices are equal (element-wise comparison)
        pub fn equal(this: This, other: This) bool {
            return @reduce(.And, this.raw == other.raw);
        }

        // ----------------
        // math operations
        // ----------------

        /// Add two matrices element-wise
        pub fn add(this: This, other: This) This {
            return .{ .raw = this.raw + other.raw };
        }

        /// Subtract two matrices element-wise
        pub fn sub(this: This, other: This) This {
            return .{ .raw = this.raw - other.raw };
        }

        /// Multiply two matrices element-wise (Hadamard product)
        pub fn mul(this: This, other: This) This {
            return .{ .raw = this.raw * other.raw };
        }

        /// Divide two matrices element-wise
        pub fn div(this: This, other: This) This {
            return .{ .raw = this.raw / other.raw };
        }

        /// Add a scalar value to all elements
        pub fn bias(this: This, value: T) This {
            return this.add(This.full(value));
        }

        /// Multiply all elements by a scalar value
        pub fn scale(this: This, value: T) This {
            return this.mul(This.full(value));
        }

        /// Transpose the matrix, returning a new matrix with swapped dimensions
        pub fn transpose(this: This) Mat(m, n, T) {
            var result = Mat(m, n, T).zeros();

            for (0..n) |i| {
                for (0..m) |j| {
                    result.set(j, i, this.get(i, j));
                }
            }

            return result;
        }

        /// Shorthand for transpose()
        pub fn t(this: This) Mat(m, n, T) {
            return this.transpose();
        }

        /// Perform matrix multiplication (dot product)
        /// The number of columns in this matrix must match the number of rows in other
        pub fn mmul(this: This, other: anytype) Mat(n, @TypeOf(other)._m, T) {
            const p = @TypeOf(other)._m;
            var result = Mat(n, p, T).zeros();

            for (0..n) |i| {
                for (0..p) |j| {
                    var sum: T = 0;
                    for (0..m) |k| {
                        sum += this.get(i, k) * other.get(k, j);
                    }
                    result.set(i, j, sum);
                }
            }

            return result;
        }

        /// Calculate the trace (sum of diagonal elements).
        /// Only valid for square matrices.
        pub fn trace(this: This) T {
            comptime {
                assert(n == m);
            }
            var sum: T = 0;
            for (0..n) |i| {
                sum += this.get(i, i);
            }
            return sum;
        }

        /// Calculate the determinant of a 2x2 or 3x3 matrix.
        /// Only valid for square matrices of size 2x2 or 3x3.
        pub fn det(this: This) T {
            comptime {
                assert(n == m);
                assert(n == 2 or n == 3);
            }

            if (n == 2) {
                return this.get(0, 0) * this.get(1, 1) - this.get(0, 1) * this.get(1, 0);
            } else { // n == 3
                return this.get(0, 0) * (this.get(1, 1) * this.get(2, 2) - this.get(1, 2) * this.get(2, 1)) -
                    this.get(0, 1) * (this.get(1, 0) * this.get(2, 2) - this.get(1, 2) * this.get(2, 0)) +
                    this.get(0, 2) * (this.get(1, 0) * this.get(2, 1) - this.get(1, 1) * this.get(2, 0));
            }
        }

        /// Extract a submatrix by removing specified row and column.
        pub fn submatrix(this: This, comptime row: u8, comptime col: u8) Mat(n - 1, m - 1, T) {
            comptime {
                assert(row < n);
                assert(col < m);
            }

            var result = Mat(n - 1, m - 1, T).zeros();
            var r: usize = 0;
            var c: usize = 0;

            for (0..n) |i| {
                if (i == row) continue;
                c = 0;
                for (0..m) |j| {
                    if (j == col) continue;
                    result.set(r, c, this.get(i, j));
                    c += 1;
                }
                r += 1;
            }

            return result;
        }

        /// Calculate the inverse of a 2x2 matrix.
        /// Only valid for 2x2 matrices with non-zero determinant.
        /// Only available for floating-point types.
        pub fn inv2(this: This) This {
            assert(@typeInfo(T) != .int);
            comptime {
                assert(n == 2 and m == 2);
            }

            const d = this.det();
            if (d == 0) {
                @panic("Matrix is not invertible (determinant is zero)");
            }

            const inv_det = 1 / d;
            return This.init(.{
                this.get(1, 1) * inv_det, -this.get(0, 1) * inv_det,
                -this.get(1, 0) * inv_det, this.get(0, 0) * inv_det,
            });
        }

        /// Format the matrix as a string for display.
        /// The caller owns the returned memory.
        pub fn format(this: This, allocator: std.mem.Allocator) ![]const u8 {
            var result = std.ArrayList(u8).init(allocator);
            defer result.deinit();

            const writer = result.writer();
            try writer.writeAll("[\n");

            for (0..n) |i| {
                try writer.writeAll("  ");
                for (0..m) |j| {
                    try writer.print("{d} ", .{this.get(i, j)});
                }
                try writer.writeAll("\n");
            }
            try writer.writeAll("]");

            return result.toOwnedSlice();
        }

        /// Convert a row matrix (1×m) to a vector
        pub fn toVecFromRow(this: This) Vec(m, T) {
            comptime {
                assert(n == 1);
            }
            return Vec(m, T).init(this.raw);
        }

        /// Convert a column matrix (n×1) to a vector
        pub fn toVecFromCol(this: This) Vec(n, T) {
            comptime {
                assert(m == 1);
            }
            return Vec(n, T).init(this.raw);
        }
    };
}

test "init rectangular" {
    const m = Mat(2, 3, u32).init(.{
        1, 2, 3,
        4, 5, 6,
    });

    try expect(m.raw[0] == 1);
    try expect(m.raw[1] == 2);
    try expect(m.raw[2] == 3);
    try expect(m.raw[3] == 4);
    try expect(m.raw[4] == 5);
    try expect(m.raw[5] == 6);
}

test "full rectangular" {
    const m = Mat(2, 3, u32).full(2);

    try expect(m.raw[0] == 2);
    try expect(m.raw[1] == 2);
    try expect(m.raw[2] == 2);
    try expect(m.raw[3] == 2);
    try expect(m.raw[4] == 2);
    try expect(m.raw[5] == 2);
}

test "zeros rectangular" {
    const m = Mat(3, 2, u32).zeros();

    try expect(m.raw[0] == 0);
    try expect(m.raw[1] == 0);
    try expect(m.raw[2] == 0);
    try expect(m.raw[3] == 0);
    try expect(m.raw[4] == 0);
    try expect(m.raw[5] == 0);
}

test "ones rectangular" {
    const m = Mat(2, 3, u32).ones();

    try expect(m.raw[0] == 1);
    try expect(m.raw[1] == 1);
    try expect(m.raw[2] == 1);
    try expect(m.raw[3] == 1);
    try expect(m.raw[4] == 1);
    try expect(m.raw[5] == 1);
}

test "identity square" {
    const m = Mat(2, 2, u32).identity();

    try expect(m.raw[0] == 1);
    try expect(m.raw[1] == 0);
    try expect(m.raw[2] == 0);
    try expect(m.raw[3] == 1);
}

test "get values rectangular" {
    const m = Mat(2, 3, u32).init(.{
        1, 2, 3,
        4, 5, 6,
    });

    try expect(m.get(0, 0) == 1);
    try expect(m.get(0, 1) == 2);
    try expect(m.get(0, 2) == 3);
    try expect(m.get(1, 0) == 4);
    try expect(m.get(1, 1) == 5);
    try expect(m.get(1, 2) == 6);
}

test "equal rectangular" {
    const m1 = Mat(2, 3, f32).full(1);
    const m2 = Mat(2, 3, f32).ones();
    const m3 = Mat(2, 3, f32).zeros();

    try expect(m1.equal(m2));
    try expect(!m1.equal(m3));
}

test "add rectangular" {
    const m1 = Mat(2, 3, f32).init(.{ 1, 2, 3, 4, 5, 6 });
    const m2 = Mat(2, 3, f32).init(.{ 1, 2, 3, 4, 5, 6 });
    try expect(m1.add(m2).equal(Mat(2, 3, f32).init(.{ 2, 4, 6, 8, 10, 12 })));
}

test "subtract rectangular" {
    const m1 = Mat(2, 3, f32).ones();
    const m2 = Mat(2, 3, f32).ones();
    try expect(m1.sub(m2).equal(Mat(2, 3, f32).zeros()));
}

test "multiplication rectangular" {
    const m1 = Mat(2, 3, f32).init(.{ 1, 2, 3, 4, 5, 6 });
    const m2 = Mat(2, 3, f32).init(.{ 1, 2, 3, 4, 5, 6 });
    try expect(m1.mul(m2).equal(Mat(2, 3, f32).init(.{ 1, 4, 9, 16, 25, 36 })));
}

test "division rectangular" {
    const m1 = Mat(2, 3, f32).init(.{ 2, 4, 6, 8, 10, 12 });
    const m2 = Mat(2, 3, f32).init(.{ 2, 4, 6, 8, 10, 12 });
    try expect(m1.div(m2).equal(Mat(2, 3, f32).ones()));
}

test "bias rectangular" {
    const m = Mat(2, 3, f32).ones();
    try expect(m.bias(4).equal(Mat(2, 3, f32).full(5)));
}

test "scale rectangular" {
    const m = Mat(2, 3, f32).full(2);
    try expect(m.scale(0.5).equal(Mat(2, 3, f32).ones()));
}

test "transpose rectangular" {
    const m1 = Mat(2, 3, u32).init(.{
        1, 2, 3,
        4, 5, 6,
    });
    const m2 = Mat(3, 2, u32).init(.{
        1, 4,
        2, 5,
        3, 6,
    });

    try expect(m1.transpose().equal(m2));
    try expect(m2.transpose().equal(m1));
}

test "matrix multiplication" {
    const m1 = Mat(2, 3, f32).init(.{
        1, 2, 3,
        4, 5, 6,
    });
    const m2 = Mat(3, 2, f32).init(.{
        7,  8,
        9,  10,
        11, 12,
    });
    const expected = Mat(2, 2, f32).init(.{
        58,  64,
        139, 154,
    });

    try expect(m1.mmul(m2).equal(expected));
}

test "trace" {
    const m = Mat(2, 2, f32).init(.{
        1, 2,
        3, 4,
    });
    try expect(m.trace() == 5);
}

test "determinant 2x2" {
    const m = Mat(2, 2, f32).init(.{
        1, 2,
        3, 4,
    });
    try expect(m.det() == -2);
}

test "determinant 3x3" {
    const m = Mat(3, 3, f32).init(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });
    try expect(m.det() == 0);

    const m2 = Mat(3, 3, f32).init(.{
        2, -3, 1,
        2, 0, -1,
        1, 4, 5,
    });
    try expect(m2.det() == 49);
}

test "submatrix" {
    const m = Mat(3, 3, f32).init(.{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    });
    const sub = m.submatrix(1, 1);
    const expected = Mat(2, 2, f32).init(.{
        1, 3,
        7, 9,
    });
    try expect(sub.equal(expected));
}

test "2x2 matrix inversion" {
    const m = Mat(2, 2, f32).init(.{
        4, 7,
        2, 6,
    });
    const inv = m.inv2();
    const expected = Mat(2, 2, f32).init(.{
        0.6, -0.7,
        -0.2, 0.4,
    });
    
    // Test with approximate equality due to floating point arithmetic
    for (0..2) |i| {
        for (0..2) |j| {
            try expect(std.math.approxEqAbs(f32, inv.get(i, j), expected.get(i, j), 1e-6));
        }
    }

    // Test that m * m^(-1) = I
    const identity = m.mmul(inv);
    const eye = Mat(2, 2, f32).identity();
    for (0..2) |i| {
        for (0..2) |j| {
            try expect(std.math.approxEqAbs(f32, identity.get(i, j), eye.get(i, j), 1e-6));
        }
    }
}

test "matrix format" {
    const m = Mat(2, 2, f32).init(.{
        1, 2,
        3, 4,
    });
    const str = try m.format(std.testing.allocator);
    defer std.testing.allocator.free(str);
    
    const expected = 
        \\[
        \\  1 2 
        \\  3 4 
        \\]
    ;
    try expect(std.mem.eql(u8, str, expected));
}

test "row matrix to vector" {
    const m = Mat(1, 3, f32).init(.{ 1, 2, 3 });
    const v = m.toVecFromRow();
    try expect(v.raw[0] == 1);
    try expect(v.raw[1] == 2);
    try expect(v.raw[2] == 3);
}

test "column matrix to vector" {
    const m = Mat(3, 1, f32).init(.{ 1, 2, 3 });
    const v = m.toVecFromCol();
    try expect(v.raw[0] == 1);
    try expect(v.raw[1] == 2);
    try expect(v.raw[2] == 3);
}

test "vector-matrix conversion roundtrip" {
    const v = Vec(3, f32).init(.{ 1, 2, 3 });
    
    // Row matrix roundtrip
    const row_mat = v.toRowMatrix();
    const v_from_row = row_mat.toVecFromRow();
    try expect(v.equal(v_from_row));
    
    // Column matrix roundtrip
    const col_mat = v.toColMatrix();
    const v_from_col = col_mat.toVecFromCol();
    try expect(v.equal(v_from_col));
}
