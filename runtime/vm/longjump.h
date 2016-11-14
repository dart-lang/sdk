// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_LONGJUMP_H_
#define RUNTIME_VM_LONGJUMP_H_

#include <setjmp.h>

#include "vm/allocation.h"
#include "vm/isolate.h"

namespace dart {

class Error;

class LongJumpScope : public StackResource {
 public:
  LongJumpScope()
      : StackResource(Thread::Current()),
        top_(NULL),
        base_(Thread::Current()->long_jump_base()) {
    Thread::Current()->set_long_jump_base(this);
  }

  ~LongJumpScope() { Thread::Current()->set_long_jump_base(base_); }

  jmp_buf* Set();
  void Jump(int value, const Error& error);

  // Would it be safe to use this longjump?
  //
  // Checks to make sure that the jump would not cross Dart frames.
  bool IsSafeToJump();

 private:
  jmp_buf environment_;
  StackResource* top_;
  LongJumpScope* base_;

  DISALLOW_COPY_AND_ASSIGN(LongJumpScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_LONGJUMP_H_
