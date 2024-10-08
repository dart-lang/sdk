// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/constants_kbc.h"

namespace dart {

static const intptr_t kInstructionSize0 = 1;
static const intptr_t kInstructionSizeA = 2;
static const intptr_t kInstructionSizeD = 2;
static const intptr_t kInstructionSizeWideD = 5;
static const intptr_t kInstructionSizeX = 2;
static const intptr_t kInstructionSizeWideX = 5;
static const intptr_t kInstructionSizeT = 2;
static const intptr_t kInstructionSizeWideT = 4;
static const intptr_t kInstructionSizeA_E = 3;
static const intptr_t kInstructionSizeWideA_E = 6;
static const intptr_t kInstructionSizeA_Y = 3;
static const intptr_t kInstructionSizeWideA_Y = 6;
static const intptr_t kInstructionSizeD_F = 3;
static const intptr_t kInstructionSizeWideD_F = 6;
static const intptr_t kInstructionSizeA_B_C = 4;

const intptr_t KernelBytecode::kInstructionSize[] = {
#define SIZE_ORDN(encoding) kInstructionSize##encoding
#define SIZE_WIDE(encoding) kInstructionSizeWide##encoding
#define SIZE_RESV(encoding) SIZE_ORDN(encoding)
#define SIZE(name, encoding, kind, op1, op2, op3) SIZE_##kind(encoding),
    KERNEL_BYTECODES_LIST(SIZE)
#undef SIZE_ORDN
#undef SIZE_WIDE
#undef SIZE_RESV
#undef SIZE
};

static const KBCInstr kVMInternal_ImplicitConstructorClosureInstructions[] = {
    KernelBytecode::kVMInternal_ImplicitConstructorClosure,
    0,
    0,
    KernelBytecode::kPush,
    0,
    KernelBytecode::kReturnTOS,
};

static const KBCInstr
    kVMInternal_ImplicitConstructorClosure_WideInstructions[] = {
        KernelBytecode::kTrap,
};

#define DECLARE_INSTRUCTIONS(name, fmt, kind, fmta, fmtb, fmtc)                \
  static const KBCInstr k##name##Instructions[] = {                            \
      KernelBytecode::k##name,                                                 \
      KernelBytecode::kReturnTOS,                                              \
  };
INTERNAL_KERNEL_BYTECODES_WITH_DEFAULT_CODE(DECLARE_INSTRUCTIONS)
#undef DECLARE_INSTRUCTIONS

void KernelBytecode::GetVMInternalBytecodeInstructions(
    Opcode opcode,
    const KBCInstr** instructions,
    intptr_t* instructions_size) {
  switch (opcode) {
#define CASE(name, fmt, kind, fmta, fmtb, fmtc)                                \
  case k##name:                                                                \
    *instructions = k##name##Instructions;                                     \
    *instructions_size = sizeof(k##name##Instructions);                        \
    return;

    INTERNAL_KERNEL_BYTECODES_LIST(CASE)
#undef CASE

    default:
      UNREACHABLE();
  }
}

}  // namespace dart
