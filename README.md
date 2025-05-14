[![CI](https://github.com/MrVicarius/zig-linalg/actions/workflows/main.yml/badge.svg)](https://github.com/MrVicarius/zig-linalg/actions)
[![codecov](https://codecov.io/gh/MrVicarius/zig-linalg/graph/badge.svg?token=C3HCN59E4C)](https://codecov.io/gh/MrVicarius/zig-linalg)
[![docs](https://img.shields.io/badge/docs-online-blue.svg)](https://mrvicarius.github.io/zig-linalg/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# zig-linalg

Linear algebra library developed using the [Zig](https://github.com/ziglang/zig) programming
language.

## Features

- Fast, efficient vector and matrix operations using SIMD
- Compile-time known dimensions for better performance and type safety
- Common vector operations: dot product, cross product, normalization, etc.
- Common matrix operations: multiplication, transpose, element-wise operations, etc.
- Convenient type aliases for common dimensions (Vec2f, Mat4f, etc.)
- Integer and floating-point support
- Comprehensive test coverage
- Zero dependencies beyond Zig standard library

## Usage

### Add zig-linalg to your project

Run the following command:
```console
zig fetch --save git+https://github.com/MrVicarius/zig-linalg.git
```

Add this to your `build.zig`:
```zig
    const zla = b.dependecy("zla", .{
        .target = target,
        .optimize = optimize,
    });
    
    exe.root_module.addImport("zla", zla.module("zla"));
```

### Example Usage

```zig
const zla = @import("zla");

// Create some vectors
var v1 = zla.Vec3f.init(.{ 1.0, 0.0, 0.0 });
var v2 = zla.Vec3f.init(.{ 0.0, 1.0, 0.0 });

// Compute cross product
var v3 = v1.cprod(v2); // Results in (0.0, 0.0, 1.0)

// Create and multiply matrices
var m1 = zla.Mat3f.identity();
var m2 = zla.Mat3f.full(2.0);
var m3 = m1.mmul(m2);
```

## Contributing

Contributions are welcome! Here's how you can help:

- **Report Issues**: Found a bug or have a feature request? Open an [issue](https://github.com/MrVicarius/zig-linalg/issues).
- **Submit PRs**: Want to contribute code? Fork the repository and submit a pull request.
  1. Fork the repository
  2. Create your feature branch (`git checkout -b feature/amazing-feature`)
  3. Commit your changes (`git commit -m 'Add some amazing feature'`)
  4. Push to the branch (`git push origin feature/amazing-feature`)
  5. Open a Pull Request

Please ensure your PR includes appropriate tests and documentation.

