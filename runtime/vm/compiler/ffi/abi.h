// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_ABI_H_
#define RUNTIME_VM_COMPILER_FFI_ABI_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

namespace dart {

namespace compiler {

namespace ffi {

// These ABIs should be kept in sync with
// pkg/vm/lib/transformations/ffi/abi.dart.
enum class Abi {
  kAndroidArm,
  kAndroidArm64,
  kAndroidIA32,
  kAndroidX64,
  kFuchsiaArm64,
  kFuchsiaX64,
  kIOSArm,
  kIOSArm64,
  kIOSX64,
  kLinuxArm,
  kLinuxArm64,
  kLinuxIA32,
  kLinuxX64,
  kLinuxRiscv32,
  kLinuxRiscv64,
  kMacOSArm64,
  kMacOSX64,
  kWindowsArm64,
  kWindowsIA32,
  kWindowsX64,
};

const int64_t num_abis = static_cast<int64_t>(Abi::kWindowsX64) + 1;

// We use the integer values of this enum in
// - runtime/vm/compiler/ffi/native_type.cc
// - runtime/vm/compiler/frontend/kernel_to_il.cc
static_assert(static_cast<int64_t>(Abi::kAndroidArm) == 0,
              "Enum value unexpected.");
static_assert(static_cast<int64_t>(Abi::kWindowsX64) == 19,
              "Enum value unexpected.");
static_assert(num_abis == 20, "Enum value unexpected.");

// The target ABI. Defines sizes and alignment of native types.
Abi TargetAbi();

extern const char* target_abi_name;

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_ABI_H_
