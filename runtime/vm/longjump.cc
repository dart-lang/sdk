// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/longjump.h"

#include "include/dart_api.h"

#include "vm/dart_api_impl.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/os.h"

namespace dart {

jmp_buf* LongJumpScope::Set() {
  ASSERT(top_ == nullptr);
  top_ = Thread::Current()->top_resource();
  return &environment_;
}

void LongJumpScope::Jump(int value, const Error& error) {
  ASSERT(!error.IsNull());

  // Remember the error in the sticky error of this isolate.
  Thread::Current()->set_sticky_error(error);

  Jump(value);
}

void LongJumpScope::Jump(int value) {
  // A zero is the default return value from setting up a LongJumpScope
  // using Set.
  ASSERT(value != 0);

  Thread* thread = Thread::Current();
  DEBUG_ASSERT(thread->TopErrorHandlerIsSetJump());

  // Destruct all the active StackResource objects.
  StackResource::UnwindAbove(thread, top_);
  longjmp(environment_, value);
  UNREACHABLE();
}

}  // namespace dart
