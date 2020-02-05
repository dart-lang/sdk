// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_H_
#define RUNTIME_VM_CONSTANTS_H_

namespace dart {

// Alignment strategies for how to align values.
enum AlignmentStrategy {
  // Align to the size of the value.
  kAlignedToValueSize,
  // Align to the size of the value, but align 8 byte-sized values to 4 bytes.
  // Both double and int64.
  kAlignedToValueSizeBut8AlignedTo4,
  // Align to the architecture size.
  kAlignedToWordSize,
  // Align to the architecture size, but align 8 byte-sized values to 8 bytes.
  // Both double and int64.
  kAlignedToWordSizeBut8AlignedTo8,
};

// Minimum size strategies for how to store values.
enum ExtensionStrategy {
  // Values can have arbitrary small size with the upper bits undefined.
  kNotExtended,
  // Values smaller than 4 bytes are passed around zero- or signextended to
  // 4 bytes.
  kExtendedTo4
};

}  // namespace dart

#if defined(TARGET_ARCH_IA32)
#include "vm/constants_ia32.h"
#elif defined(TARGET_ARCH_X64)
#include "vm/constants_x64.h"
#elif defined(TARGET_ARCH_ARM)
#include "vm/constants_arm.h"
#elif defined(TARGET_ARCH_ARM64)
#include "vm/constants_arm64.h"
#else
#error Unknown architecture.
#endif

namespace dart {

class RegisterNames {
 public:
  static const char* RegisterName(Register reg) {
    ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
    return cpu_reg_names[reg];
  }
  static const char* FpuRegisterName(FpuRegister reg) {
    ASSERT((0 <= reg) && (reg < kNumberOfFpuRegisters));
    return fpu_reg_names[reg];
  }
};

static constexpr bool IsArgumentRegister(Register reg) {
  return ((1 << reg) & CallingConventions::kArgumentRegisters) != 0;
}

static constexpr bool IsFpuArgumentRegister(FpuRegister reg) {
  return ((1 << reg) & CallingConventions::kFpuArgumentRegisters) != 0;
}

static constexpr bool IsCalleeSavedRegister(Register reg) {
  return ((1 << reg) & CallingConventions::kCalleeSaveCpuRegisters) != 0;
}

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_H_
