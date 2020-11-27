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

void GraphIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  COMPILE_ASSERT(IsAbiPreservedRegister(CODE_REG));
  COMPILE_ASSERT(!IsAbiPreservedRegister(ARGS_DESC_REG));
  COMPILE_ASSERT(IsAbiPreservedRegister(CALLEE_SAVED_TEMP));
  COMPILE_ASSERT(CALLEE_SAVED_TEMP != CODE_REG);
  COMPILE_ASSERT(CALLEE_SAVED_TEMP != ARGS_DESC_REG);

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
