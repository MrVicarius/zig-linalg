//! Root module that provides convenient type aliases for commonly used vector and matrix dimensions.
//! Integer (i32) and single-precision floating point (f32) variants are provided.

pub const Vec = @import("vector.zig").Vec;
/// 2D integer vector
pub const Vec2i = Vec(2, i32);
/// 3D integer vector
pub const Vec3i = Vec(3, i32);
/// 4D integer vector
pub const Vec4i = Vec(4, i32);
/// 2D float vector
pub const Vec2f = Vec(2, f32);
/// 3D float vector
pub const Vec3f = Vec(3, f32);
/// 4D float vector
pub const Vec4f = Vec(4, f32);

pub const Mat = @import("matrix.zig").Mat;
/// 2x2 integer matrix
pub const Mat2i = Mat(2, 2, i32);
/// 3x3 integer matrix
pub const Mat3i = Mat(3, 3, i32);
/// 4x4 integer matrix
pub const Mat4i = Mat(4, 4, i32);
/// 2x2 float matrix
pub const Mat2f = Mat(2, 2, f32);
/// 3x3 float matrix
pub const Mat3f = Mat(3, 3, f32);
/// 4x4 float matrix
pub const Mat4f = Mat(4, 4, f32);
