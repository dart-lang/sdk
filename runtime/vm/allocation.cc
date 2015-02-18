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
  return Allocate(size, Isolate::Current()->current_zone());
}


void* ZoneAllocated::operator new(uword size, BaseIsolate* isolate) {
  ASSERT(isolate != NULL);
  return Allocate(size, isolate->current_zone());
}


void* ZoneAllocated::operator new(uword size, Zone* zone) {
  ASSERT(zone == Isolate::Current()->current_zone());
  return Allocate(size, zone);
}


void StackResource::Unwind(Isolate* isolate, uword stack_pointer) {
  while (isolate->top_resource() != NULL &&
         (reinterpret_cast<uword>(isolate->top_resource()) < stack_pointer)) {
    isolate->top_resource()->~StackResource();
  }
#if defined(DEBUG)
  // All remaining stack resources should be below stack_pointer.
  StackResource* current = isolate->top_resource();
  while (current != NULL) {
    ASSERT(reinterpret_cast<uword>(current) >= stack_pointer);
    current = current->previous_;
  }
#endif  // DEBUG
}


void StackResource::Unwind(Isolate* isolate, StackResource* new_top) {
  StackResource* current_resource = isolate->top_resource();
  while (current_resource != new_top) {
    current_resource->~StackResource();
    current_resource = isolate->top_resource();
  }
}

}  // namespace dart
