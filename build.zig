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

    // STEPS
    const zlint_step = b.step("zlint", "Run zlint if exists");
    if (b.findProgram(&.{"zlint"}, &.{}) catch null) |zlint_path| {
        const zlint_cmd = b.addSystemCommand(&.{zlint_path});
        zlint_step.dependOn(&zlint_cmd.step);
        b.getInstallStep().dependOn(zlint_step);
    }

    // DEPENDENCIES
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
    exe.root_module.addImport("httpz", httpz.module("httpz"));
    exe.root_module.addImport("pg", pg.module("pg"));
    exe.root_module.addImport("zenv", zenv.module("zenv"));

    b.installArtifact(exe);
}
