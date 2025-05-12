const std = @import("std");
const builtin = @import("builtin");

const minimum_zig_version = std.SemanticVersion.parse("0.14.0") catch unreachable;


pub fn build(b: *std.Build) void {
    comptime if (builtin.zig_version.order(minimum_zig_version) == .lt) {
        @compileError(std.fmt.comptimePrint(
            \\Your Zig version does not meet the minimum build requirement:
            \\  required Zig version: {[minimum_zig_version]}
            \\  actual   Zig version: {[current_version]}
            \\
        , .{
            .current_version = builtin.zig_version,
            .minimum_zig_version = minimum_zig_version,
        }));
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zla_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zla = b.addLibrary(.{
        .linkage = .static,
        .name = "zig_linalg",
        .root_module = zla_module,
    });

    b.installArtifact(zla);

    // tests ---------------------------------------------------------------
    const zla_tests = b.addTest(.{
        .root_module = zla_module,
    });
    const vector_tests = b.addTest(.{
        .root_source_file = b.path("src/vector.zig"),
        .target = target,
        .optimize = optimize,
    });
    const matrix_tests = b.addTest(.{
        .root_source_file = b.path("src/matrix.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_zla_tests = b.addRunArtifact(zla_tests);
    const run_vector_tests = b.addRunArtifact(vector_tests);
    const run_matrix_tests = b.addRunArtifact(matrix_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_zla_tests.step);
    test_step.dependOn(&run_vector_tests.step);
    test_step.dependOn(&run_matrix_tests.step);

    // coverage ---------------------------------------------------------------
    const kcov_bin = b.findProgram(&.{"kcov"}, &.{}) catch "kcov";

    const kcov_merge = std.Build.Step.Run.create(b, "kcov merge coverage");
    kcov_merge.rename_step_with_output_arg = false;
    kcov_merge.addArg(kcov_bin);
    kcov_merge.addArg("--merge");
    const coverage_output = kcov_merge.addOutputDirectoryArg(".");

    for ([_]*std.Build.Step.Compile{ zla_tests, vector_tests }) |test_artifact| {
        const kcov_collect = std.Build.Step.Run.create(b, "kcov collect coverage");
        kcov_collect.addArg(kcov_bin);
        kcov_collect.addArg("--collect-only");
        kcov_collect.addPrefixedDirectoryArg("--include-pattern=", b.path("."));
        kcov_merge.addDirectoryArg(kcov_collect.addOutputDirectoryArg(test_artifact.name));
        kcov_collect.addArtifactArg(test_artifact);
        kcov_collect.enableTestRunnerMode();
    }

    const install_coverage = b.addInstallDirectory(.{
        .source_dir = coverage_output,
        .install_dir = .{ .custom = "coverage" },
        .install_subdir = "",
    });

    const coverage_step = b.step("coverage", "Generate a coverage report with kcov");
    coverage_step.dependOn(&install_coverage.step);
}
