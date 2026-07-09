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

void Roots::InitVTables() {
#define DECL(type, name) name().initRO(name().ptr());
  HANDLE_ROOTS_LIST(DECL)
#undef DECL
  for (intptr_t i = 0; i < kNumPredefinedSymbols + 256; i++) {
    symbol_handle(i).initRO(symbol_handle(i).ptr());
  }
  for (intptr_t i = 0; i < kNumStubEntries; i++) {
    stub_handle(i).initRO(stub_handle(i).ptr());
  }
}

void Roots::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  COMPILE_ASSERT(ARRAY_SIZE(raw_.cached_args_descriptors_) ==
                 ArgumentsDescriptor::kCachedDescriptorCount);
  COMPILE_ASSERT(ARRAY_SIZE(raw_.cached_icdata_arrays_) ==
                 ICData::kCachedICDataArrayCount);
  COMPILE_ASSERT(sizeof(Roots::ApiHandle) == sizeof(LocalHandle));
  COMPILE_ASSERT(sizeof(Roots::VMHandle) == kVMHandleSizeInWords * kWordSize);

  visitor->set_gc_root_type("bootstrap roots");

  visitor->VisitPointers(from(), to());
  visitor->VisitPointers(fromah(), toah());

  VMHandle* fromh = this->fromh();
  VMHandle* toh = this->toh();
  for (VMHandle* h = fromh; h <= toh; h++) {
    visitor->VisitPointer(&(h->ptr));
  }

  visitor->clear_gc_root_type();
}

}  // namespace dart
