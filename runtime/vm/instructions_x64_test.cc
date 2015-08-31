// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  __ Call(*StubCode::InvokeDartCode_entry());
  __ ret();
}


static intptr_t prologue_code_size = -1;


ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  ASSERT(assembler->CodeSize() == 0);
  __ pushq(PP);
  __ LoadPoolPointer();
  prologue_code_size = assembler->CodeSize();
  __ JmpPatchable(*StubCode::InvokeDartCode_entry(), PP);
  __ JmpPatchable(*StubCode::AllocateArray_entry(), PP);
  __ popq(PP);
  __ ret();
}


ASSEMBLER_TEST_RUN(Jump, test) {
  ASSERT(prologue_code_size != -1);
  const Code& code = test->code();
  const Instructions& instrs = Instructions::Handle(code.instructions());
  bool status =
      VirtualMemory::Protect(reinterpret_cast<void*>(instrs.EntryPoint()),
                             instrs.size(),
                             VirtualMemory::kReadWrite);
  EXPECT(status);
  JumpPattern jump1(test->entry() + prologue_code_size, test->code());
  jump1.IsValid();
  EXPECT_EQ(StubCode::InvokeDartCode_entry()->label().address(),
            jump1.TargetAddress());
  JumpPattern jump2((test->entry() +
                     jump1.pattern_length_in_bytes() + prologue_code_size),
                    test->code());
  const Code& array_stub =
      Code::Handle(StubCode::AllocateArray_entry()->code());
  EXPECT_EQ(array_stub.EntryPoint(), jump2.TargetAddress());
  uword target1 = jump1.TargetAddress();
  uword target2 = jump2.TargetAddress();
  jump1.SetTargetAddress(target2);
  jump2.SetTargetAddress(target1);
  EXPECT_EQ(array_stub.EntryPoint(), jump1.TargetAddress());
  EXPECT_EQ(StubCode::InvokeDartCode_entry()->label().address(),
            jump2.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
