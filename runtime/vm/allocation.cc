// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/allocation.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

static void* Allocate(uword size, Zone* zone) {
  ASSERT(zone != NULL);
  if (size > static_cast<uword>(kIntptrMax)) {
    FATAL1("ZoneAllocated object has unexpectedly large size %" Pu "", size);
  }
  return reinterpret_cast<void*>(zone->AllocUnsafe(size));
}


void* ZoneAllocated::operator new(uword size) {
  return Allocate(size, Thread::Current()->zone());
}


void* ZoneAllocated::operator new(uword size, Zone* zone) {
  ASSERT(zone == Thread::Current()->zone());
  return Allocate(size, zone);
}


void StackResource::UnwindAbove(Thread* thread, StackResource* new_top) {
  StackResource* current_resource = thread->top_resource();
  while (current_resource != new_top) {
    current_resource->~StackResource();
    current_resource = thread->top_resource();
  }
}


#if defined(DEBUG)
NoSafepointScope::NoSafepointScope() : StackResource(Thread::Current()) {
  thread()->IncrementNoSafepointScopeDepth();
}


NoSafepointScope::~NoSafepointScope() {
  thread()->DecrementNoSafepointScopeDepth();
}
#endif  // defined(DEBUG)

}  // namespace dart
