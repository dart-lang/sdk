// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/allocation.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

static void* Allocate(uword size, BaseIsolate* isolate) {
  ASSERT(isolate != NULL);
  ASSERT(isolate->current_zone() != NULL);
  if (size > static_cast<uword>(kIntptrMax)) {
    FATAL1("ZoneAllocated object has unexpectedly large size %" Pu "", size);
  }
  return reinterpret_cast<void*>(isolate->current_zone()->AllocUnsafe(size));
}


void* ZoneAllocated::operator new(uword size) {
  return Allocate(size, Isolate::Current());
}


void* ZoneAllocated::operator new(uword size, BaseIsolate* isolate) {
  return Allocate(size, isolate);
}

}  // namespace dart
