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

#if defined(HOST_ARCH_X64) || defined(HOST_ARCH_ARM64)
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
#elif defined(DART_TARGET_OS_FUCHSIA)
#define DART_TARGET_OS_NAME Fuchsia
#elif defined(DART_TARGET_OS_LINUX)
#define DART_TARGET_OS_NAME Linux
#elif defined(DART_TARGET_OS_MACOS)
#if DART_TARGET_OS_MACOS_IOS
#define DART_TARGET_OS_NAME IOS
#else
#define DART_TARGET_OS_NAME MacOS
#endif
#elif defined(DART_TARGET_OS_WINDOWS)
#define DART_TARGET_OS_NAME Windows
#else
#error Unknown OS
#endif

#if defined(TARGET_ARCH_IA32)
#define TARGET_ARCH_NAME IA32
#elif defined(TARGET_ARCH_X64)
#define TARGET_ARCH_NAME X64
#elif defined(TARGET_ARCH_ARM)
#define TARGET_ARCH_NAME Arm
#elif defined(TARGET_ARCH_ARM64)
#define TARGET_ARCH_NAME Arm64
#else
#error Unknown arch
#endif

#define ABI_NAME1(os, arch) k##os##arch
#define ABI_NAME2(os, arch) ABI_NAME1(os, arch)
#define ABI_NAME3 ABI_NAME2(DART_TARGET_OS_NAME, TARGET_ARCH_NAME)

Abi TargetAbi() {
  return Abi::ABI_NAME3;
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
