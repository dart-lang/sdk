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
  AssemblerTest test("Disassembler", &assembler, Thread::Current()->zone());
  test.Assemble();
  Disassembler::Disassemble(test.entry(), test.entry() + assembler.CodeSize());
}

ISOLATE_UNIT_TEST_CASE(Disassembler_InvalidInput) {
  // Test that Disassembler doesn't crash even if the input is nonsense.
  uint32_t bad_input[] = {
      0x00000000, 0xFFFFFFFF, 0x12345678, 0x9ABCDEF0, 0x01110001,
      0xDEADC0DE, 0xBAADF00D, 0xDABADEEE, 0xDABAD111, 0xB000DEAD,
      0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
  };
  Disassembler::Disassemble(
      reinterpret_cast<uword>(&bad_input[0]),
      reinterpret_cast<uword>(ARRAY_SIZE(bad_input) + &bad_input[0]));
}

#endif  // !PRODUCT

}  // namespace dart
