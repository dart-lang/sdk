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

// Binary search table for updating pointers during a sliding compaction.
// TODO(rmacnak): Replace with lookup scheme based on bitmap of live allocation
// units.
class ForwardingMap : public ValueObject {
 public:
  ForwardingMap();
  ~ForwardingMap();

  void Insert(RawObject* before, RawObject* after);
  void Sort();
  RawObject* Lookup(RawObject* before);

 private:
  struct Entry {
    RawObject* before;
    RawObject* after;
  };

  static int CompareEntries(Entry* a, Entry* b);

  intptr_t size_;
  intptr_t capacity_;
  Entry* entries_;
  bool sorted_;
};

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

  HeapPage* SlidePages(HeapPage* pages, FreeList* freelist);
  void ForwardPointers();

  intptr_t EvacuatePages(HeapPage* page);

 private:
  void VisitPointers(RawObject** first, RawObject** last);
  void VisitHandle(uword addr);

  Heap* heap_;
  ForwardingMap forwarding_map_;
};

}  // namespace dart

#endif  // RUNTIME_VM_GC_COMPACTOR_H_
