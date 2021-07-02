// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/abi.h"

#include "vm/constants.h"

namespace dart {

namespace compiler {

namespace ffi {

// See pkg/vm/lib/transformations/ffi.dart, which makes these assumptions.
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
       (defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS) ||                    \
        defined(HOST_OS_ANDROID))) ||                                          \
    (defined(HOST_ARCH_ARM) && defined(HOST_OS_IOS))
static_assert(offsetof(AbiAlignmentDouble, d) == 4,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 4,
              "FFI transformation alignment");
#elif defined(HOST_ARCH_IA32) && defined(HOST_OS_WINDOWS) ||                   \
    defined(HOST_ARCH_ARM)
static_assert(offsetof(AbiAlignmentDouble, d) == 8,
              "FFI transformation alignment");
static_assert(offsetof(AbiAlignmentUint64, i) == 8,
              "FFI transformation alignment");
#else
#error "Unknown platform. Please add alignment requirements for ABI."
#endif

Abi TargetAbi() {
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64)
  return Abi::kWordSize64;
#elif (defined(TARGET_ARCH_IA32) && /* NOLINT(whitespace/parens) */            \
       (defined(TARGET_OS_LINUX) || defined(TARGET_OS_MACOS) ||                \
        defined(TARGET_OS_ANDROID))) ||                                        \
    (defined(TARGET_ARCH_ARM) && defined(TARGET_OS_MACOS_IOS))
  return Abi::kWordSize32Align32;
#elif defined(TARGET_ARCH_IA32) && defined(TARGET_OS_WINDOWS) ||               \
    defined(TARGET_ARCH_ARM)
  return Abi::kWordSize32Align64;
#else
#error "Unknown platform. Please add alignment requirements for ABI."
#endif
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
