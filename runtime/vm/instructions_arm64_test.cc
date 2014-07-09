// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  StubCode* stub_code = Isolate::Current()->stub_code();
  __ BranchLinkPatchable(&stub_code->InvokeDartCodeLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(Call, test) {
  // The return address, which must be the address of an instruction contained
  // in the code, points to the Ret instruction above, i.e. one instruction
  // before the end of the code buffer.
  CallPattern call(test->entry() + test->code().Size() - Instr::kInstrSize,
                   test->code());
  StubCode* stub_code = Isolate::Current()->stub_code();
  EXPECT_EQ(stub_code->InvokeDartCodeLabel().address(),
            call.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  StubCode* stub_code = Isolate::Current()->stub_code();
  __ BranchPatchable(&stub_code->InvokeDartCodeLabel());
  __ BranchPatchable(&stub_code->AllocateArrayLabel());
}


ASSEMBLER_TEST_RUN(Jump, test) {
  const Code& code = test->code();
  const Instructions& instrs = Instructions::Handle(code.instructions());
  bool status =
      VirtualMemory::Protect(reinterpret_cast<void*>(instrs.EntryPoint()),
                             instrs.size(),
                             VirtualMemory::kReadWrite);
  StubCode* stub_code = Isolate::Current()->stub_code();
  EXPECT(status);
  JumpPattern jump1(test->entry(), test->code());
  EXPECT_EQ(stub_code->InvokeDartCodeLabel().address(),
            jump1.TargetAddress());
  JumpPattern jump2(test->entry() + jump1.pattern_length_in_bytes(),
                    test->code());
  EXPECT_EQ(stub_code->AllocateArrayLabel().address(),
            jump2.TargetAddress());
  uword target1 = jump1.TargetAddress();
  uword target2 = jump2.TargetAddress();
  jump1.SetTargetAddress(target2);
  jump2.SetTargetAddress(target1);
  EXPECT_EQ(stub_code->AllocateArrayLabel().address(),
            jump1.TargetAddress());
  EXPECT_EQ(stub_code->InvokeDartCodeLabel().address(),
            jump2.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
