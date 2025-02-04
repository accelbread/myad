# myad -- Simple LLM server
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "Simple LLM server.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }:
    flakelight-zig ./. {
      license = "AGPL-3.0-or-later";
      zigFlags = [ "--release" ];
      zigSystemLibs = pkgs: [ pkgs.llama-cpp ];
      zigDependencies = pkgs: pkgs.linkFarm "zig-deps" (builtins.map
        (d:
          let captures = builtins.match "git\\+(.*)#([a-z0-9]*)" d.url; in {
            name = d.hash;
            path = builtins.fetchGit {
              url = builtins.elemAt captures 0;
              rev = builtins.elemAt captures 1;
              shallow = true;
            };
          })
        (builtins.attrValues
          (flakelight-zig.lib.parseZon ./build.zig.zon).dependencies));
    };
}
