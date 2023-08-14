// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Logic shared between the Scavenger and Marker.

#include "vm/heap/gc_shared.h"

#include "vm/dart_api_state.h"
#include "vm/heap/scavenger.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/object.h"

namespace dart {

void GCLinkedLists::Release() {
#define FOREACH(type, var) var.Release();
  GC_LINKED_LIST(FOREACH)
#undef FOREACH
}

bool GCLinkedLists::IsEmpty() {
#define FOREACH(type, var)                                                     \
  if (!var.IsEmpty()) {                                                        \
    return false;                                                              \
  }
  GC_LINKED_LIST(FOREACH)
  return true;
#undef FOREACH
}

void GCLinkedLists::FlushInto(GCLinkedLists* to) {
#define FOREACH(type, var) var.FlushInto(&to->var);
  GC_LINKED_LIST(FOREACH)
#undef FOREACH
}

Heap::Space SpaceForExternal(FinalizerEntryPtr raw_entry) {
  // As with WeakTables, Smis are "old".
  return raw_entry->untag()->value()->IsImmediateOrOldObject() ? Heap::kOld
                                                               : Heap::kNew;
}

}  // namespace dart
