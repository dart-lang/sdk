# Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Shared functions for both precompiler2 and dart_precompiled_runtime2.

function host_arch() {
  # Use uname to determine the host architecture.
  case `uname -m` in
    x86_64)
    echo "X64"
    ;;
    aarch64 | arm64 | armv8*)
    echo "ARM64"
    ;;
    arm | arm7*)
    echo "ARM"
    ;;
    *)
    echo "Unknown host architecture" `uname -m` >&2
    exit 1
    ;;
  esac
}

function parse_target_arch() {
  case "$1" in
  *X64 | \
  *X64C)
  echo "X64"
  ;;
  *ARM64 | \
  *ARM64C)
  echo "ARM64"
  ;;
  *ARM)
  echo "ARM"
  ;;
  *IA32)
  echo "IA32"
  ;;
  *RISCV32)
  echo "RISCV32"
  ;;
  *RISCV64)
  echo "RISCV64"
  ;;
  *)
  echo "Cannot deduce target architecture from $1" >&2
  exit 1
  ;;
  esac
}

function is_cross_compiled() {
  local host_arch="$1"
  local target_arch="$2"
  [[ ("$host_arch" != "ARM64" || "$target_arch" != "ARM") && \
    ("$host_arch" != "$target_arch") ]]
}
