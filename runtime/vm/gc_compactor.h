// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_GC_COMPACTOR_H_
#define RUNTIME_VM_GC_COMPACTOR_H_

#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class FreeList;
class Heap;
class HeapPage;
class RawObject;

// Implements an evacuating compactor and a sliding compactor.
class GCCompactor : public ValueObject,
                    private HandleVisitor,
                    private ObjectPointerVisitor {
 public:
  GCCompactor(Thread* thread, Heap* heap)
      : HandleVisitor(thread),
        ObjectPointerVisitor(thread->isolate()),
        heap_(heap) {}
  ~GCCompactor() {}

  void CompactBySliding(HeapPage* pages, FreeList* freelist, Mutex* mutex);

  intptr_t EvacuatePages(HeapPage* page);

 private:
  void SlidePage(HeapPage* page);
  uword SlideBlock(uword first_object, ForwardingPage* forwarding_page);
  void MoveToExactAddress(uword addr);
  void MoveToContiguousSize(intptr_t size);

  void ForwardPointersForSliding();
  void VisitPointers(RawObject** first, RawObject** last);
  void VisitHandle(uword addr);

  Heap* heap_;

  HeapPage* free_page_;
  uword free_current_;
  uword free_end_;
  FreeList* freelist_;
};

}  // namespace dart

#endif  // RUNTIME_VM_GC_COMPACTOR_H_
