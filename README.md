[![CI](https://github.com/MrVicarius/zig-linalg/actions/workflows/main.yml/badge.svg)](https://github.com/MrVicarius/zig-linalg/actions)
[![codecov](https://codecov.io/gh/MrVicarius/zig-linalg/graph/badge.svg?token=C3HCN59E4C)](https://codecov.io/gh/MrVicarius/zig-linalg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# zig-linalg

Linear algebra library developed using the [Zig](https://github.com/ziglang/zig) programming
language.

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

