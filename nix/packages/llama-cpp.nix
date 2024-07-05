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
  version = "3974";

  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = "llama.cpp";
    rev = "refs/tags/b${finalAttrs.version}";
    hash = "sha256-SD2rh/u2fCWroQpfSaDQu4Z6Inf9wevLpRT7bAuXmoE=";
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

  HIPCXX = "${rocmPackages.llvm.clang}/bin/clang";
  HIP_PATH = "${rocmPackages.clr}";
  HIP_DEVICE_LIB_PATH = "${rocmPackages.rocm-device-libs}/amdgcn/bitcode";

  cmakeFlags = [
    (cmakeBool "LLAMA_BUILD_TESTS" false)
    (cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (cmakeBool "LLAMA_BUILD_COMMON" false)
    (cmakeBool "GGML_NATIVE" false)
    (cmakeBool "GGML_HIPBLAS" true)
    (cmakeBool "GGML_OPENMP" false)
    (cmakeBool "GGML_LLAMAFILE" false)
    (cmakeBool "GGML_CCACHE" false)
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
