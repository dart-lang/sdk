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

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
