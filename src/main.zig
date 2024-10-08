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

pub const std_options = .{
    .log_level = .info,
    .logFn = @import("log.zig").logImpl,
};

const std = @import("std");
const log = std.log;
const c = @cImport({
    @cInclude("llama.h");
});

pub fn main() !void {
    c.llama_log_set(llamaLog, null);
}

fn llamaLog(
    level: c.ggml_log_level,
    text: [*c]const u8,
    user_data: ?*anyopaque,
) callconv(.C) void {
    _ = user_data;
    switch (level) {
        c.GGML_LOG_LEVEL_ERROR => log.err("{s}", .{text}),
        c.GGML_LOG_LEVEL_WARN => log.warn("{s}", .{text}),
        c.GGML_LOG_LEVEL_INFO => log.info("{s}", .{text}),
        c.GGML_LOG_LEVEL_DEBUG => log.debug("{s}", .{text}),
        else => unreachable,
    }
}
