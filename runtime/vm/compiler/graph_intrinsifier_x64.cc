// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/graph_intrinsifier.h"

namespace dart {
namespace compiler {

#define __ assembler->

intptr_t GraphIntrinsifier::ParameterSlotFromSp() {
  return 0;
}

static bool IsABIPreservedRegister(Register reg) {
  return ((1 << reg) & CallingConventions::kCalleeSaveCpuRegisters) != 0;
}

void GraphIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  ASSERT(IsABIPreservedRegister(CODE_REG));
  ASSERT(!IsABIPreservedRegister(ARGS_DESC_REG));
  ASSERT(IsABIPreservedRegister(CALLEE_SAVED_TEMP));
  ASSERT(CALLEE_SAVED_TEMP != CODE_REG);
  ASSERT(CALLEE_SAVED_TEMP != ARGS_DESC_REG);

  assembler->Comment("IntrinsicCallPrologue");
  assembler->movq(CALLEE_SAVED_TEMP, ARGS_DESC_REG);
}

void GraphIntrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->movq(ARGS_DESC_REG, CALLEE_SAVED_TEMP);
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
