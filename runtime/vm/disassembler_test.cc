// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assembler.h"
#include "vm/disassembler.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#if defined(TARGET_ARCH_IA32)  // Disassembler only supported on IA32 now.
TEST_CASE(Disassembler) {
  Assembler assembler;
  // The used instructions work on all platforms.
  Register reg = static_cast<Register>(0);
  assembler.AddImmediate(reg, Immediate(1));
  assembler.AddImmediate(reg, Immediate(3));

  // Only verify that the disassembler does not crash.
  AssemblerTest test("Disassembler", &assembler);
  uword entry = test.Assemble();
  Disassembler::Disassemble(entry, entry + assembler.CodeSize());
}
#endif

}  // namespace dart
