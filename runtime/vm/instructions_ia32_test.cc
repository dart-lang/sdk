// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  __ call(&StubCode::MegamorphicLookupLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(Call, entry) {
  Call call(entry);
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(), call.TargetAddress());
}


ASSEMBLER_TEST_GENERATE(Jump, assembler) {
  __ jmp(&StubCode::MegamorphicLookupLabel());
  __ jmp(&StubCode::OptimizeInvokedFunctionLabel());
  __ ret();
}


ASSEMBLER_TEST_RUN(Jump, entry) {
  Jump jump1(entry);
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(),
            jump1.TargetAddress());
  Jump jump2(entry + jump1.pattern_length_in_bytes());
  EXPECT_EQ(StubCode::OptimizeInvokedFunctionLabel().address(),
            jump2.TargetAddress());
  uword target1 = jump1.TargetAddress();
  uword target2 = jump2.TargetAddress();
  jump1.SetTargetAddress(target2);
  jump2.SetTargetAddress(target1);
  EXPECT_EQ(StubCode::OptimizeInvokedFunctionLabel().address(),
            jump1.TargetAddress());
  EXPECT_EQ(StubCode::MegamorphicLookupLabel().address(),
            jump2.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
