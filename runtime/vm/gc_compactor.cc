// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_compactor.h"

#include "vm/become.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/pages.h"

namespace dart {

void GCCompactor::EvacuatePage(HeapPage* page) {
  uword current = page->object_start();
  uword end = page->object_end();
  while (current < end) {
    RawObject* raw_obj = RawObject::FromAddr(current);
    const intptr_t size = raw_obj->Size();
    if (!raw_obj->IsFreeListElement() && !raw_obj->IsForwardingCorpse()) {
      uword new_obj = heap_->old_space()->TryAllocateDataLocked(
          size, PageSpace::kForceGrowth);
      if (new_obj == 0) {
        OUT_OF_MEMORY();
      }

      memmove(reinterpret_cast<void*>(new_obj),
              reinterpret_cast<void*>(current), size);

      ForwardingCorpse* forwarder =
          ForwardingCorpse::AsForwarder(current, size);
      forwarder->set_target(RawObject::FromAddr(new_obj));
      heap_->ForwardWeakEntries(raw_obj, RawObject::FromAddr(new_obj));
    }
    current += size;
  }
}

}  // namespace dart
