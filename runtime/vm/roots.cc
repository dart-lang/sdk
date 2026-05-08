// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/roots.h"

#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/visitor.h"

namespace dart {

Roots Roots::roots_ = {};

COMPILE_ASSERT(ArgumentsDescriptor::kCachedDescriptorCount == 35);
COMPILE_ASSERT(ICData::kCachedICDataArrayCount == 4);

void Roots::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ObjectPtr* from = reinterpret_cast<ObjectPtr*>(&raw_);
  visitor->VisitPointers(from, from + sizeof(Raw) / sizeof(ObjectPtr) - 1);

  from = reinterpret_cast<ObjectPtr*>(&api_);
  visitor->VisitPointers(from, from + sizeof(Api) / sizeof(ObjectPtr) - 1);

  VMHandle* fromh = reinterpret_cast<VMHandle*>(&internal_);
  VMHandle* toh = fromh + sizeof(Internal) / sizeof(VMHandle) - 1;
  for (VMHandle* h = fromh; h <= toh; h++) {
    visitor->VisitPointer(&(h->ptr));
  }
}

}  // namespace dart
