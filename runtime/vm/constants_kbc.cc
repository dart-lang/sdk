// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#define RUNTIME_VM_CONSTANTS_H_  // To work around include guard.
#include "vm/constants_kbc.h"

namespace dart {

#define DECLARE_INSTRUCTIONS(name, fmt, fmta, fmtb, fmtc)                      \
  static const KBCInstr k##name##Instructions[] = {                            \
      KernelBytecode::k##name, 0, 0, 0, KernelBytecode::kReturnTOS, 0, 0, 0,   \
  };
INTERNAL_KERNEL_BYTECODES_LIST(DECLARE_INSTRUCTIONS)
#undef DECLARE_INSTRUCTIONS

void KernelBytecode::GetVMInternalBytecodeInstructions(
    Opcode opcode,
    const KBCInstr** instructions,
    intptr_t* instructions_size) {
  switch (opcode) {
#define CASE(name, fmt, fmta, fmtb, fmtc)                                      \
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
