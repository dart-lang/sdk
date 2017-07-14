// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/longjump.h"

#include "include/dart_api.h"

#include "vm/dart_api_impl.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/simulator.h"

namespace dart {

jmp_buf* LongJumpScope::Set() {
  ASSERT(top_ == NULL);
  top_ = Thread::Current()->top_resource();
  return &environment_;
}

bool LongJumpScope::IsSafeToJump() {
  // We do not want to jump past Dart frames.  Note that this code
  // assumes the stack grows from high to low.
  Thread* thread = Thread::Current();
  uword jumpbuf_addr = Thread::GetCurrentStackPointer();
#if defined(USING_SIMULATOR)
  Simulator* sim = Simulator::Current();
  // When using simulator, only mutator thread should refer to Simulator
  // since there can be only one per isolate.
  uword top_exit_frame_info =
      thread->IsMutatorThread() ? sim->top_exit_frame_info() : 0;
#else
  uword top_exit_frame_info = thread->top_exit_frame_info();
#endif
  if (!thread->IsMutatorThread()) {
    // A helper thread does not execute Dart code, so it's safe to jump.
    ASSERT(top_exit_frame_info == 0);
    return true;
  }
  return ((top_exit_frame_info == 0) || (jumpbuf_addr < top_exit_frame_info));
}

void LongJumpScope::Jump(int value, const Error& error) {
  // A zero is the default return value from setting up a LongJumpScope
  // using Set.
  ASSERT(value != 0);
  ASSERT(IsSafeToJump());

  Thread* thread = Thread::Current();

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
