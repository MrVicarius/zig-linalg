//! A linear algebra module providing vector operations with compile-time known dimensions.
//! All vectors are stored using SIMD vectors for efficient computation.

const std = @import("std");
const assert = @import("std").debug.assert;
const expect = @import("std").testing.expect;
const Mat = @import("matrix.zig").Mat;

/// A generic vector type with compile-time known dimensions.
/// Parameters:
///   n: number of elements
///   T: element type (e.g. f32, f64, etc)
pub fn Vec(comptime n: u8, comptime T: type) type {
    return struct {
        /// Raw data storage as SIMD vector
        raw: @Vector(n, T),

        const This = @This();

        // ---------------
        // initialization
        // ---------------

        /// Initialize a vector with raw SIMD data
        pub fn init(data: @Vector(n, T)) This {
            return .{ .raw = data };
        }

        /// Create a vector filled with a single value
        pub fn full(value: T) This {
            return .{ .raw = @splat(value) };
        }

        /// Create a vector filled with zeros
        pub fn zeros() This {
            return .{ .raw = @splat(0) };
        }

        /// Create a vector filled with ones
        pub fn ones() This {
            return .{ .raw = @splat(1) };
        }

        // ------------
        // data access
        // ------------

        /// Get the first component (requires n >= 1)
        pub fn x(this: This) T {
            assert(n >= 1);
            return this.raw[0];
        }

        /// Get the second component (requires n >= 2)
        pub fn y(this: This) T {
            assert(n >= 2);
            return this.raw[1];
        }

        /// Get the third component (requires n >= 3)
        pub fn z(this: This) T {
            assert(n >= 3);
            return this.raw[2];
        }

        /// Get the fourth component (requires n >= 4)
        pub fn w(this: This) T {
            assert(n >= 4);
            return this.raw[3];
        }

        // -----------------
        // logic operations
        // -----------------

        /// Check if two vectors are equal (element-wise comparison)
        pub fn equal(this: This, other: This) bool {
            return @reduce(.And, this.raw == other.raw);
        }

        // ----------------
        // math operations
        // ----------------

        /// Add two vectors element-wise
        pub fn add(this: This, other: This) This {
            return .{ .raw = this.raw + other.raw };
        }

        /// Subtract two vectors element-wise
        pub fn sub(this: This, other: This) This {
            return .{ .raw = this.raw - other.raw };
        }

        /// Multiply two vectors element-wise (Hadamard product)
        pub fn mul(this: This, other: This) This {
            return .{ .raw = this.raw * other.raw };
        }

        /// Divide two vectors element-wise
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

        /// Compute the dot product (inner product) of two vectors
        pub fn dprod(this: This, other: This) T {
            return @reduce(.Add, this.raw * other.raw);
        }

        /// Compute the Euclidean norm (length) of the vector.
        /// Only available for floating-point types.
        pub fn norm(this: This) T {
            assert(@typeInfo(T) != .int);
            return @sqrt(this.dprod(this));
        }

        /// Return a normalized version of the vector (unit length).
        /// Only available for floating-point types.
        pub fn normalize(this: This) This {
            return this.scale(1 / this.norm());
        }

        /// Compute the cross product of two 3D vectors.
        /// Only valid for 3D vectors (n must be 3).
        pub fn cprod(this: This, other: This) This {
            assert(n == 3);

            return This.init(.{
                this.y() * other.z() - this.z() * other.y(),
                this.z() * other.x() - this.x() * other.z(),
                this.x() * other.y() - this.y() * other.x(),
            });
        }

        /// Calculate the angle between two vectors in radians.
        /// Only available for floating-point types.
        pub fn angle(this: This, other: This) T {
            assert(@typeInfo(T) != .int);
            const cos_theta = this.dprod(other) / (this.norm() * other.norm());
            // Handle floating point precision issues
            if (cos_theta > 1) return 0;
            if (cos_theta < -1) return std.math.pi;
            return std.math.acos(cos_theta);
        }

        /// Project this vector onto another vector.
        /// Only available for floating-point types.
        pub fn project(this: This, onto: This) This {
            assert(@typeInfo(T) != .int);
            const factor = this.dprod(onto) / onto.dprod(onto);
            return onto.scale(factor);
        }

        /// Reflect this vector across another vector.
        /// Only available for floating-point types.
        pub fn reflect(this: This, normal: This) This {
            assert(@typeInfo(T) != .int);
            const _n = normal.normalize();
            const d = this.dprod(_n);
            return this.sub(_n.scale(2 * d));
        }

        /// Rotate a 2D vector by an angle (in radians).
        /// Only valid for 2D vectors and floating-point types.
        pub fn rotate(this: This, theta: T) This {
            assert(@typeInfo(T) != .int);
            comptime {
                assert(n == 2);
            }
            const cos = @cos(theta);
            const sin = @sin(theta);
            return This.init(.{
                this.x() * cos - this.y() * sin,
                this.x() * sin + this.y() * cos,
            });
        }

        /// Linear interpolation between two vectors.
        /// Only available for floating-point types.
        pub fn lerp(this: This, other: This, t: T) This {
            assert(@typeInfo(T) != .int);
            return this.scale(1 - t).add(other.scale(t));
        }

        /// Convert the vector to a row matrix (1×n)
        pub fn toRowMatrix(this: This) Mat(1, n, T) {
            return Mat(1, n, T).init(this.raw);
        }

        /// Convert the vector to a column matrix (n×1)
        pub fn toColMatrix(this: This) Mat(n, 1, T) {
            return Mat(n, 1, T).init(this.raw);
        }
    };
}

test "init" {
    const v = Vec(3, u32).init(.{ 1, 2, 3 });
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

test "data access" {
    const v = Vec(4, u32).init(.{ 1, 2, 3, 4 });
    try expect(v.x() == 1);
    try expect(v.y() == 2);
    try expect(v.z() == 3);
    try expect(v.w() == 4);
}

test "equal" {
    const v1 = Vec(3, f32).full(1);
    const v2 = Vec(3, f32).ones();
    const v3 = Vec(3, f32).zeros();

    try expect(v1.equal(v2));
    try expect(!v1.equal(v3));
}

test "add" {
    const v1 = Vec(3, f32).init(.{ 1, 2, 3 });
    const v2 = Vec(3, f32).init(.{ 1, 2, 3 });
    try expect(v1.add(v2).equal(Vec(3, f32).init(.{ 2, 4, 6 })));
}

test "subtract" {
    const v1 = Vec(3, f32).ones();
    const v2 = Vec(3, f32).ones();
    try expect(v1.sub(v2).equal(Vec(3, f32).zeros()));
}

test "multiplication" {
    const v1 = Vec(3, f32).init(.{ 1, 2, 3 });
    const v2 = Vec(3, f32).init(.{ 1, 2, 3 });
    try expect(v1.mul(v2).equal(Vec(3, f32).init(.{ 1, 4, 9 })));
}

test "division" {
    const v1 = Vec(3, f32).init(.{ 1, 2, 3 });
    const v2 = Vec(3, f32).init(.{ 1, 2, 3 });
    try expect(v1.div(v2).equal(Vec(3, f32).ones()));
}

test "bias" {
    const v = Vec(2, f32).ones();
    try expect(v.bias(4).equal(Vec(2, f32).full(5)));
}

test "scale" {
    const v = Vec(2, f32).full(2);
    try expect(v.scale(0.5).equal(Vec(2, f32).ones()));
}

test "dot product" {
    const v1 = Vec(3, f32).init(.{ 1, 2, 3 });
    const v2 = Vec(3, f32).init(.{ 1, 2, 3 });
    try expect(v1.dprod(v2) == 1 + 4 + 9);
}

test "norm" {
    const v = Vec(4, f32).ones();
    try expect(v.norm() == 2);
}

test "normalize" {
    const v = Vec(4, f32).ones();
    const n_v = v.normalize();
    try expect(n_v.equal(Vec(4, f32).full(0.5)));
    try expect(n_v.norm() == 1);
}

test "cross product" {
    const v1 = Vec(3, f32).init(.{ 1, 2, 3 });
    const v2 = Vec(3, f32).init(.{ 3, 4, 5 });
    try expect(v1.cprod(v2).equal(Vec(3, f32).init(.{ -2, 4, -2 })));
}

test "angle between vectors" {
    const v1 = Vec(2, f32).init(.{ 1, 0 });
    const v2 = Vec(2, f32).init(.{ 0, 1 });
    try expect(std.math.approxEqAbs(f32, v1.angle(v2), std.math.pi / 2.0, 1e-6));
}

test "vector projection" {
    const v1 = Vec(2, f32).init(.{ 3, 3 });
    const v2 = Vec(2, f32).init(.{ 0, 1 });
    const proj = v1.project(v2);
    try expect(std.math.approxEqAbs(f32, proj.x(), 0, 1e-6));
    try expect(std.math.approxEqAbs(f32, proj.y(), 3, 1e-6));
}

test "vector reflection" {
    const v = Vec(2, f32).init(.{ 1, -1 });
    const normal = Vec(2, f32).init(.{ 0, 1 });
    const reflected = v.reflect(normal);
    try expect(std.math.approxEqAbs(f32, reflected.x(), 1, 1e-6));
    try expect(std.math.approxEqAbs(f32, reflected.y(), 1, 1e-6));
}

test "vector rotation" {
    const v = Vec(2, f32).init(.{ 1, 0 });
    const rotated = v.rotate(std.math.pi / 2.0);
    try expect(std.math.approxEqAbs(f32, rotated.x(), 0, 1e-6));
    try expect(std.math.approxEqAbs(f32, rotated.y(), 1, 1e-6));
}

test "vector interpolation" {
    const v1 = Vec(3, f32).init(.{ 1, 1, 1 });
    const v2 = Vec(3, f32).init(.{ 3, 3, 3 });
    const v_mid = v1.lerp(v2, 0.5);
    try expect(v_mid.equal(Vec(3, f32).init(.{ 2, 2, 2 })));
}

test "vector to row matrix" {
    const v = Vec(3, f32).init(.{ 1, 2, 3 });
    const m = v.toRowMatrix();
    try expect(m.get(0, 0) == 1);
    try expect(m.get(0, 1) == 2);
    try expect(m.get(0, 2) == 3);
}

test "vector to column matrix" {
    const v = Vec(3, f32).init(.{ 1, 2, 3 });
    const m = v.toColMatrix();
    try expect(m.get(0, 0) == 1);
    try expect(m.get(1, 0) == 2);
    try expect(m.get(2, 0) == 3);
}
