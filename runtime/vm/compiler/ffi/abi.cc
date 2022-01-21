// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/abi.h"

#include "vm/constants.h"

namespace dart {

namespace compiler {

namespace ffi {

// See pkg/vm/lib/transformations/ffi/abi.dart, which makes these assumptions.
struct AbiAlignmentDouble {
  int8_t use_one_byte;
  double d;
};
struct AbiAlignmentUint64 {
  int8_t use_one_byte;
  uint64_t i;
};

#if defined(HOST_ARCH_X64) || defined(HOST_ARCH_ARM64) ||                      \
    defined(HOST_ARCH_RISCV64)
static_assert(offsetof(AbiAlignmentDouble, d) == 8,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 8,
              "FFI transformation alignment");
#elif (defined(HOST_ARCH_IA32) && /* NOLINT(whitespace/parens) */              \
       (defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_MACOS) ||          \
        defined(DART_HOST_OS_ANDROID))) ||                                     \
    (defined(HOST_ARCH_ARM) && defined(DART_HOST_OS_IOS))
static_assert(offsetof(AbiAlignmentDouble, d) == 4,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 4,
              "FFI transformation alignment");
#elif defined(HOST_ARCH_IA32) && defined(DART_HOST_OS_WINDOWS) ||              \
    defined(HOST_ARCH_ARM)
static_assert(offsetof(AbiAlignmentDouble, d) == 8,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 8,
              "FFI transformation alignment");
#else
#error "Unknown platform. Please add alignment requirements for ABI."
#endif

#if defined(DART_TARGET_OS_ANDROID)
#define DART_TARGET_OS_NAME Android
#define DART_TARGET_OS_NAME_LC android
#elif defined(DART_TARGET_OS_FUCHSIA)
#define DART_TARGET_OS_NAME Fuchsia
#define DART_TARGET_OS_NAME_LC fuchsia
#elif defined(DART_TARGET_OS_LINUX)
#define DART_TARGET_OS_NAME Linux
#define DART_TARGET_OS_NAME_LC linux
#elif defined(DART_TARGET_OS_MACOS)
#if DART_TARGET_OS_MACOS_IOS
#define DART_TARGET_OS_NAME IOS
#define DART_TARGET_OS_NAME_LC ios
#else
#define DART_TARGET_OS_NAME MacOS
#define DART_TARGET_OS_NAME_LC macos
#endif
#elif defined(DART_TARGET_OS_WINDOWS)
#define DART_TARGET_OS_NAME Windows
#define DART_TARGET_OS_NAME_LC windows
#else
#error Unknown OS
#endif

#if defined(TARGET_ARCH_IA32)
#define TARGET_ARCH_NAME IA32
#define TARGET_ARCH_NAME_LC ia32
#elif defined(TARGET_ARCH_X64)
#define TARGET_ARCH_NAME X64
#define TARGET_ARCH_NAME_LC x64
#elif defined(TARGET_ARCH_ARM)
#define TARGET_ARCH_NAME Arm
#define TARGET_ARCH_NAME_LC arm
#elif defined(TARGET_ARCH_ARM64)
#define TARGET_ARCH_NAME Arm64
#define TARGET_ARCH_NAME_LC arm64
#elif defined(TARGET_ARCH_RISCV32)
#define TARGET_ARCH_NAME Riscv32
#define TARGET_ARCH_NAME_LC riscv32
#elif defined(TARGET_ARCH_RISCV64)
#define TARGET_ARCH_NAME Riscv64
#define TARGET_ARCH_NAME_LC riscv64
#else
#error Unknown arch
#endif

#define ABI_ENUM_VALUE1(os, arch) k##os##arch
#define ABI_ENUM_VALUE2(os, arch) ABI_ENUM_VALUE1(os, arch)
#define ABI_ENUM_VALUE3 ABI_ENUM_VALUE2(DART_TARGET_OS_NAME, TARGET_ARCH_NAME)

Abi TargetAbi() {
  return Abi::ABI_ENUM_VALUE3;
}

#define STRINGIFY2(s) STRINGIFY(s)
#define STRINGIFY(s) #s

const char* target_abi_name =
    STRINGIFY2(DART_TARGET_OS_NAME_LC) "_" STRINGIFY2(TARGET_ARCH_NAME_LC);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
