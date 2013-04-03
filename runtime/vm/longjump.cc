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

jmp_buf* LongJump::Set() {
  top_ = Isolate::Current()->top_resource();
  return &environment_;
}


bool LongJump::IsSafeToJump() {
  // We do not want to jump past Dart frames.  Note that this code
  // assumes the stack grows from high to low.
  Isolate* isolate = Isolate::Current();
  uword jumpbuf_addr = reinterpret_cast<uword>(this);
#if defined(USING_SIMULATOR)
  uword top_exit_frame_info = isolate->simulator()->top_exit_frame_info();
#else
  uword top_exit_frame_info = isolate->top_exit_frame_info();
#endif
  return ((top_exit_frame_info == 0) || (jumpbuf_addr < top_exit_frame_info));
}


void LongJump::Jump(int value, const Error& error) {
  // A zero is the default return value from setting up a LongJump using Set.
  ASSERT(value != 0);
  ASSERT(IsSafeToJump());

  Isolate* isolate = Isolate::Current();

  // Remember the error in the sticky error of this isolate.
  isolate->object_store()->set_sticky_error(error);

  // Destruct all the active StackResource objects.
  StackResource* current_resource = isolate->top_resource();
  while (current_resource != top_) {
    current_resource->~StackResource();
    current_resource = isolate->top_resource();
  }
  longjmp(environment_, value);
  UNREACHABLE();
}

}  // namespace dart
