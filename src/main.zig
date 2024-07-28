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
const log = std.log;
const bread_lib = @import("bread-lib");
const c = @cImport({
    @cInclude("llama.h");
});

pub const std_options = .{
    .log_level = .info,
    .logFn = bread_lib.log.logFn,
};

pub fn main() !void {
    c.llama_log_set(llamaLog, null);
}

fn llamaLog(
    level: c.ggml_log_level,
    text: [*c]const u8,
    user_data: ?*anyopaque,
) callconv(.C) void {
    const llama_log = std.log.scoped(.@"llama.cpp");
    _ = user_data;

    var str: []const u8 = std.mem.span(text);
    if ((str.len > 0) and (str[str.len - 1] == '\n')) {
        str.len -= 1;
    }

    switch (level) {
        c.GGML_LOG_LEVEL_NONE => {},
        c.GGML_LOG_LEVEL_CONT => {},
        c.GGML_LOG_LEVEL_DEBUG => llama_log.debug("{s}", .{str}),
        c.GGML_LOG_LEVEL_INFO => llama_log.info("{s}", .{str}),
        c.GGML_LOG_LEVEL_WARN => llama_log.warn("{s}", .{str}),
        c.GGML_LOG_LEVEL_ERROR => llama_log.err("{s}", .{str}),
        else => unreachable,
    }
}
