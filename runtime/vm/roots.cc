// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/roots.h"

#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/handles.h"
#include "vm/object.h"
#include "vm/visitor.h"

namespace dart {

void Roots::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  COMPILE_ASSERT(ARRAY_SIZE(raw_.cached_args_descriptors_) ==
                 ArgumentsDescriptor::kCachedDescriptorCount);
  COMPILE_ASSERT(ARRAY_SIZE(raw_.cached_icdata_arrays_) ==
                 ICData::kCachedICDataArrayCount);
  COMPILE_ASSERT(sizeof(Roots::ApiHandle) == sizeof(LocalHandle));
  COMPILE_ASSERT(sizeof(Roots::VMHandle) == kVMHandleSizeInWords * kWordSize);

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
