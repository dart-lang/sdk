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

namespace dart {

jmp_buf* LongJump::Set() {
  top_ = Isolate::Current()->top_resource();
  return &environment_;
}


void LongJump::Jump(int value, const char* msg) {
  // A zero is the default return value from setting up a LongJump using Set.
  ASSERT(value != 0);

  Isolate* isolate = Isolate::Current();

  // Remember the message in the sticky error message of this isolate.
  const String& error = String::Handle(String::New(msg));
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
