pub const Vec = @import("vector.zig").Vec;
pub const Vec2i = Vec(2, i32);
pub const Vec3i = Vec(3, i32);
pub const Vec4i = Vec(4, i32);
pub const Vec2f = Vec(2, f32);
pub const Vec3f = Vec(3, f32);
pub const Vec4f = Vec(4, f32);

pub const Mat = @import("matrix.zig").Mat;
pub const Mat2i = Mat(2, 2, i32);
pub const Mat3i = Mat(3, 3, i32);
pub const Mat4i = Mat(4, 4, i32);
pub const Mat2f = Mat(2, 2, f32);
pub const Mat3f = Mat(3, 3, f32);
pub const Mat4f = Mat(4, 4, f32);
