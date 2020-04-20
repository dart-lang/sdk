// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/compiler/assembler/assembler.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/stub_code.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->

ASSEMBLER_TEST_GENERATE(Call, assembler) {
  compiler::ExternalLabel label(StubCode::InvokeDartCode().EntryPoint());
  __ call(&label);
  __ ret();
}

ASSEMBLER_TEST_RUN(Call, test) {
  CallPattern call(test->entry());
  EXPECT_EQ(StubCode::InvokeDartCode().EntryPoint(), call.TargetAddress());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
