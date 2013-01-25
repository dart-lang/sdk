// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/os.h"
#include "vm/unit_test.h"
#include "vm/virtual_memory.h"

namespace dart {

#define __ assembler->


ASSEMBLER_TEST_GENERATE(Simple, assembler) {
  UNIMPLEMENTED();
}


ASSEMBLER_TEST_RUN(Simple, entry) {
  typedef int (*SimpleCode)();
  EXPECT_EQ(42, reinterpret_cast<SimpleCode>(entry)());
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
