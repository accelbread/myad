// myad -- Simple LLM server
// Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option) any
// later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_model = if (builtin.cpu.arch == .x86_64)
                .{ .explicit = &std.Target.x86.cpu.x86_64_v3 }
            else
                .baseline,
        },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const exe_opts = .{
        .name = "myad",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = optimize != .Debug,
    };

    const bread_lib = b.dependency("bread-lib", .{}).module("bread-lib");

    const exe = b.addExecutable(exe_opts);
    exe.root_module.addImport("bread-lib", bread_lib);

    exe.pie = true;
    exe.want_lto = optimize != .Debug;
    exe.compress_debug_sections = .zlib;

    exe.linkLibC();
    exe.linkSystemLibrary("llama");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const exe_check = b.addExecutable(exe_opts);
    exe_check.root_module.addImport("bread-lib", bread_lib);
    exe_check.linkLibC();
    exe_check.linkSystemLibrary("llama");
    const check_step = b.step("check", "Check if app compiles");
    check_step.dependOn(&exe_check.step);
}
