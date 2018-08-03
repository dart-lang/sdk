// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/longjump.h"
#include "vm/thread.h"
#include "vm/unit_test.h"

namespace dart {

static void LongJumpHelper(LongJumpScope* jump) {
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New("LongJumpHelper"))));
  jump->Jump(1, error);
  UNREACHABLE();
}

TEST_CASE(LongJump) {
  LongJumpScope* base = Thread::Current()->long_jump_base();
  {
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      LongJumpHelper(&jump);
      UNREACHABLE();
    }
  }
  ASSERT(base == Thread::Current()->long_jump_base());
}

}  // namespace dart
