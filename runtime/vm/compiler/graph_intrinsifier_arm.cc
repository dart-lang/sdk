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

void GraphIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  COMPILE_ASSERT(IsAbiPreservedRegister(CODE_REG));
  COMPILE_ASSERT(IsAbiPreservedRegister(ARGS_DESC_REG));
  COMPILE_ASSERT(IsAbiPreservedRegister(CALLEE_SAVED_TEMP));

  // Save LR by moving it to a callee saved temporary register.
  __ Comment("IntrinsicCallPrologue");
  SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(
      __ mov(CALLEE_SAVED_TEMP, Operand(LR)));
}

void GraphIntrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  // Restore LR.
  __ Comment("IntrinsicCallEpilogue");
  RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR(
      __ mov(LR, Operand(CALLEE_SAVED_TEMP)));
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
