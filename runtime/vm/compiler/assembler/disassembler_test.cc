// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

// TODO(vegorov) this test is disabled on DBC because there is no PopRegister
// method on DBC assembler.
#if !defined(PRODUCT) && !defined(TARGET_ARCH_DBC)

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

#endif  // !PRODUCT

}  // namespace dart
