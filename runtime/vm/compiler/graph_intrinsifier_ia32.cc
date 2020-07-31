// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/graph_intrinsifier.h"

namespace dart {
namespace compiler {

#define __ assembler->

intptr_t GraphIntrinsifier::ParameterSlotFromSp() {
  return 0;
}

void GraphIntrinsifier::IntrinsicCallPrologue(Assembler* assembler) {
  COMPILE_ASSERT(CALLEE_SAVED_TEMP != ARGS_DESC_REG);

  assembler->Comment("IntrinsicCallPrologue");
  assembler->movl(CALLEE_SAVED_TEMP, ARGS_DESC_REG);
}

void GraphIntrinsifier::IntrinsicCallEpilogue(Assembler* assembler) {
  assembler->Comment("IntrinsicCallEpilogue");
  assembler->movl(ARGS_DESC_REG, CALLEE_SAVED_TEMP);
}

#undef __

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32)
