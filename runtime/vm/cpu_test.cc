// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/cpu.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(Id) {
#if defined(TARGET_ARCH_IA32)
  EXPECT_STREQ("ia32", CPU::Id());
#elif defined(TARGET_ARCH_X64)
  EXPECT_STREQ("x64", CPU::Id());
#elif defined(TARGET_ARCH_ARM)
  EXPECT_STREQ("arm", CPU::Id());
#else
#error Architecture was not detected as supported by Dart.
#endif
}

}  // namespace dart
