// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/allocation.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

StackResource::StackResource(Isolate* isolate)
    : isolate_(isolate), previous_(NULL) {
  // We can only have longjumps and exceptions when there is a current
  // isolate.  If there is no current isolate, we don't need to
  // protect this case.
  if (isolate) {
    previous_ = isolate->top_resource();
    isolate->set_top_resource(this);
  }
}


StackResource::~StackResource() {
  if (isolate()) {
    StackResource* top = isolate()->top_resource();
    ASSERT(top == this);
    isolate()->set_top_resource(previous_);
  }
  ASSERT(Isolate::Current() == isolate());
}

ZoneAllocated::~ZoneAllocated() {
  UNREACHABLE();
}

void* ZoneAllocated::operator new(uword size) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ASSERT(isolate->current_zone() != NULL);
  return reinterpret_cast<void*>(isolate->current_zone()->Allocate(size));
}

}  // namespace dart
