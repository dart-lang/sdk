// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#if !defined(PRODUCT)

ISOLATE_UNIT_TEST_CASE(Disassembler) {
  compiler::ObjectPoolBuilder object_pool_builder;
  compiler::Assembler assembler(&object_pool_builder);

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
