// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/graph_intrinsifier.h"

namespace dart {
namespace compiler {

#define __ assembler->

intptr_t GraphIntrinsifier::ParameterSlotFromSp() {
  return -1;
}

static bool IsABIPreservedRegister(Register reg) {
  return ((1 << reg) & kAbiPreservedCpuRegs) != 0;
}

void GraphIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  ASSERT(IsABIPreservedRegister(CODE_REG));
  ASSERT(IsABIPreservedRegister(ARGS_DESC_REG));
  ASSERT(IsABIPreservedRegister(CALLEE_SAVED_TEMP));

  // Save LR by moving it to a callee saved temporary register.
  assembler->Comment("IntrinsicCallPrologue");
  assembler->mov(CALLEE_SAVED_TEMP, Operand(LR));
}

void GraphIntrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  // Restore LR.
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->mov(LR, Operand(CALLEE_SAVED_TEMP));
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
