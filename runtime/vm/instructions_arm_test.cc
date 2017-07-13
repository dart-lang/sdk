// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  // Code accessing pp is generated, but not executed. Uninitialized pp is OK.
  __ set_constant_pool_allowed(true);
  __ BranchLinkPatchable(*StubCode::InvokeDartCode_entry());
  __ Ret();
}

ASSEMBLER_TEST_RUN(Call, test) {
  // The return address, which must be the address of an instruction contained
  // in the code, points to the Ret instruction above, i.e. one instruction
  // before the end of the code buffer.
  uword end = test->payload_start() + test->code().Size();
  CallPattern call(end - Instr::kInstrSize, test->code());
  EXPECT_EQ(StubCode::InvokeDartCode_entry()->code(), call.TargetCode());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
