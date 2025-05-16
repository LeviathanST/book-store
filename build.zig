const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "book-store-api",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    });
    const pg = b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
    });
    const zenv = b.dependency("zenv", .{
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");

    exe.root_module.addImport("httpz", httpz.module("httpz"));
    exe.root_module.addImport("pg", pg.module("pg"));
    exe.root_module.addImport("zenv", zenv.module("zenv"));
    run_step.dependOn(&run_exe.step);
}
