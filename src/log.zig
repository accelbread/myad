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

pub fn logImpl(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = switch (level) {
        .err => "\x1B[1;31mE",
        .warn => "\x1B[1;33mW",
        .info => "\x1B[0;32mI",
        .debug => "\x1B[0;34mD",
    };
    const tag = if (scope == .default) "" else "[" ++ @tagName(scope) ++ "]";
    const fmt_str = prefix ++ tag ++ " " ++ format ++ "\x1B[0m\n";

    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    writer.print(fmt_str, args) catch return;
    bw.flush() catch return;
}
