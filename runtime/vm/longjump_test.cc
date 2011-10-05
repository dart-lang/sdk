// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"
#include "vm/longjump.h"
#include "vm/unit_test.h"

namespace dart {

static void LongJumpHelper(LongJump* jump) {
  jump->Jump(1, "LongJump Test");
  UNREACHABLE();
}


TEST_CASE(LongJump) {
  LongJump jump;
  if (setjmp(*jump.Set()) == 0) {
    LongJumpHelper(&jump);
    UNREACHABLE();
  }
}

}  // namespace dart
