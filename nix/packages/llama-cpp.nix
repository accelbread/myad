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

{ lib
, fetchFromGitHub
, stdenv
, cmake
, ninja
, rocmPackages
}:

let
  inherit (lib) cmakeBool cmakeFeature licenses platforms;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "llama-cpp";
  version = "3651";

  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = "llama.cpp";
    rev = "refs/tags/b${finalAttrs.version}";
    hash = "sha256-oqDR0u1JDUEUR2fjRRc4/yW7G6BcfvcawaRbhNW3xrI=";
    leaveDotGit = true;
    postFetch = ''
      substituteInPlace $out/cmake/build-info.cmake \
        --replace-fail 'set(BUILD_NUMBER 0)' \
        'set(BUILD_NUMBER ${finalAttrs.version})' \
        --replace-fail 'set(BUILD_COMMIT "unknown")' \
        "set(BUILD_COMMIT \"$(git -C "$out" rev-parse --short HEAD)\")"
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  nativeBuildInputs = [ cmake ninja ];

  buildInputs = with rocmPackages; [ clr hipblas rocblas ];

  cmakeFlags = [
    (cmakeBool "LLAMA_BUILD_TESTS" false)
    (cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (cmakeBool "GGML_NATIVE" false)
    (cmakeBool "GGML_LTO" true)
    (cmakeBool "GGML_HIPBLAS" true)
    (cmakeFeature "CMAKE_C_COMPILER" "hipcc")
    (cmakeFeature "CMAKE_CXX_COMPILER" "hipcc")
    (cmakeFeature "AMDGPU_TARGETS" "gfx1100")
  ];

  meta = {
    description = "LLM inference in C/C++";
    homepage = "https://github.com/ggerganov/llama.cpp";
    license = licenses.mit;
    mainProgram = "llama-cli";
    platforms = platforms.unix;
  };
})
