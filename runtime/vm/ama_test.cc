// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "platform/globals.h"

#include "include/dart_api.h"

#include "vm/constants.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(AMA_Test) {
  // NOTE: These are expectations we should strive to maintain. Please reach out
  // to go/dart-ama before changing them.
#if defined(TARGET_ARCH_ARM64)
  COMPILE_ASSERT(R27 == PP);
  COMPILE_ASSERT(R15 == SPREG);
  COMPILE_ASSERT(R26 == THR);
  COMPILE_ASSERT(R21 == DISPATCH_TABLE_REG);
#endif
}

}  // namespace dart
