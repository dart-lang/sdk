// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->


ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  __ mov(R0, ShifterOperand(42));
  __ mov(PC, ShifterOperand(LR));
}


ASSEMBLER_TEST_RUN(Simple, entry) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, EXECUTE_TEST_CODE_INT32(SimpleCode, entry));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
