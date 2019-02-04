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
  ASSERT(top_ == NULL);
  top_ = Thread::Current()->top_resource();
  return &environment_;
}

void LongJumpScope::Jump(int value, const Error& error) {
  // A zero is the default return value from setting up a LongJumpScope
  // using Set.
  ASSERT(value != 0);
  ASSERT(!error.IsNull());

  Thread* thread = Thread::Current();
  DEBUG_ASSERT(thread->TopErrorHandlerIsSetJump());

#if defined(DEBUG)
#define CHECK_REUSABLE_HANDLE(name)                                            \
  ASSERT(!thread->reusable_##name##_handle_scope_active());
  REUSABLE_HANDLE_LIST(CHECK_REUSABLE_HANDLE)
#undef CHECK_REUSABLE_HANDLE
#endif  // defined(DEBUG)

  // Remember the error in the sticky error of this isolate.
  thread->set_sticky_error(error);

  // Destruct all the active StackResource objects.
  StackResource::UnwindAbove(thread, top_);
  longjmp(environment_, value);
  UNREACHABLE();
}

}  // namespace dart
