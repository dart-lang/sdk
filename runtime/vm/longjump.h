// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_LONGJUMP_H_
#define VM_LONGJUMP_H_

#include <setjmp.h>

#include "vm/allocation.h"

namespace dart {

class LongJump : public ValueObject {
 public:
  LongJump() : top_(NULL) { }

  jmp_buf* Set();
  void Jump(int value, const char* msg);

 private:
  jmp_buf environment_;
  StackResource* top_;

  DISALLOW_COPY_AND_ASSIGN(LongJump);
};

}  // namespace dart

#endif  // VM_LONGJUMP_H_
