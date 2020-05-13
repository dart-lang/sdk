// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_COMPACTOR_H_
#define RUNTIME_VM_HEAP_COMPACTOR_H_

#include "platform/growable_array.h"

#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class FreeList;
class Heap;
class OldPage;

// Implements a sliding compactor.
class GCCompactor : public ValueObject,
                    public HandleVisitor,
                    public ObjectPointerVisitor {
 public:
  GCCompactor(Thread* thread, Heap* heap)
      : HandleVisitor(thread),
        ObjectPointerVisitor(thread->isolate_group()),
        heap_(heap) {}
  ~GCCompactor() {}

  void Compact(OldPage* pages, FreeList* freelist, Mutex* mutex);

 private:
  friend class CompactorTask;

  void SetupImagePageBoundaries();
  void ForwardStackPointers();
  void ForwardPointer(ObjectPtr* ptr);
  void VisitTypedDataViewPointers(TypedDataViewPtr view,
                                  ObjectPtr* first,
                                  ObjectPtr* last);
  void VisitPointers(ObjectPtr* first, ObjectPtr* last);
  void VisitHandle(uword addr);

  Heap* heap_;

  struct ImagePageRange {
    uword base;
    uword size;
  };
  // There are up to 4 images to consider:
  // {instructions, data} x {vm isolate, current isolate}
  static const intptr_t kMaxImagePages = 4;
  ImagePageRange image_page_ranges_[kMaxImagePages];

  // The typed data views whose inner pointer must be updated after sliding is
  // complete.
  Mutex typed_data_view_mutex_;
  MallocGrowableArray<TypedDataViewPtr> typed_data_views_;
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_COMPACTOR_H_
