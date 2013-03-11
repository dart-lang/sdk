// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  __ BranchLinkPatchable(&StubCode::InstanceFunctionLookupLabel());
  __ Ret();
}


ASSEMBLER_TEST_RUN(Call, test) {
  // The return address, which must be the address of an instruction contained
  // in the code, points to the Ret instruction above, i.e. one instruction
  // before the end of the code buffer.
  CallPattern call(test->entry() + test->code().Size() - Instr::kInstrSize,
                   test->code());
  EXPECT_EQ(StubCode::InstanceFunctionLookupLabel().address(),
            call.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  __ BranchPatchable(&StubCode::InstanceFunctionLookupLabel());
  __ BranchPatchable(&StubCode::AllocateArrayLabel());
}


ASSEMBLER_TEST_RUN(Jump, test) {
  JumpPattern jump1(test->entry());
  EXPECT_EQ(StubCode::InstanceFunctionLookupLabel().address(),
            jump1.TargetAddress());
  JumpPattern jump2(test->entry() + jump1.pattern_length_in_bytes());
  EXPECT_EQ(StubCode::AllocateArrayLabel().address(),
            jump2.TargetAddress());
  uword target1 = jump1.TargetAddress();
  uword target2 = jump2.TargetAddress();
  jump1.SetTargetAddress(target2);
  jump2.SetTargetAddress(target1);
  EXPECT_EQ(StubCode::AllocateArrayLabel().address(),
            jump1.TargetAddress());
  EXPECT_EQ(StubCode::InstanceFunctionLookupLabel().address(),
            jump2.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
