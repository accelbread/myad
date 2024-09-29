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
const assert = std.debug.assert;
const bread_lib = @import("bread-lib");
const c = @cImport({
    @cInclude("llama.h");
    @cInclude("ggml.h");
});

pub const std_options = .{
    .log_level = .info,
    .logFn = bread_lib.log.logFn,
};

pub fn main() !u8 {
    c.llama_log_set(llamaLog, null);

    c.llama_backend_init();
    defer c.llama_backend_free();

    assert(c.llama_supports_gpu_offload());
    assert(c.llama_max_devices() <= 32);

    var mparams = c.llama_model_default_params();
    mparams.n_gpu_layers = 100;

    const model: *c.llama_model = c.llama_load_model_from_file(
        "/persist/cache/models/dolphin-2.7-mixtral-8x7b-q5_k_m.gguf",
        mparams,
    ) orelse return 1;
    defer c.llama_free_model(model);

    var lparams = c.llama_context_default_params();
    lparams.n_ctx = 0;
    lparams.n_threads = 32;

    const lctx: *c.llama_context =
        c.llama_new_context_with_model(model, lparams) orelse return 1;
    defer c.llama_free(lctx);

    const template_test: c.llama_chat_message = .{
        .role = "user",
        .content = "test",
    };

    assert(c.llama_chat_apply_template(
        model,
        null,
        &template_test,
        1,
        true,
        null,
        0,
    ) > 0);

    std.time.sleep(2000);

    return 0;
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
