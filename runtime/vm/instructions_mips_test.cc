// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  __ BranchLinkPatchable(*StubCode::InvokeDartCode_entry());
  __ Ret();
}


ASSEMBLER_TEST_RUN(Call, test) {
  // The return address, which must be the address of an instruction contained
  // in the code, points to the Ret instruction above, i.e. two instructions
  // before the end of the code buffer, including the delay slot for the
  // return jump.
  CallPattern call(test->entry() + test->code().Size() - (2*Instr::kInstrSize),
                   test->code());
  EXPECT_EQ(StubCode::InvokeDartCode_entry()->code(), call.TargetCode());
}


}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
