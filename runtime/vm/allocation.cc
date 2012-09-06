// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/allocation.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/zone.h"

namespace dart {

ZoneAllocated::~ZoneAllocated() {
  UNREACHABLE();
}

void* ZoneAllocated::operator new(uword size) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ASSERT(isolate->current_zone() != NULL);
  if (size > static_cast<uword>(kIntptrMax)) {
    FATAL1("ZoneAllocated object has unexpectedly large size %"Pu"", size);
  }
  return reinterpret_cast<void*>(isolate->current_zone()->AllocUnsafe(size));
}

}  // namespace dart
