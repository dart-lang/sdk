// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assembler.h"
#include "vm/disassembler.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

// Disassembler only supported on IA32, X64, and ARM.
#if defined(TARGET_ARCH_IA32) ||                                               \
    defined(TARGET_ARCH_X64) ||                                                \
    defined(TARGET_ARCH_ARM)
TEST_CASE(Disassembler) {
  Assembler assembler;
  // The used instructions work on all platforms.
  Register reg = static_cast<Register>(0);
  assembler.PopRegister(reg);
  assembler.Stop("testing disassembler");

  // Only verify that the disassembler does not crash.
  AssemblerTest test("Disassembler", &assembler);
  test.Assemble();
  Disassembler::Disassemble(test.entry(), test.entry() + assembler.CodeSize());
}
#endif

}  // namespace dart
