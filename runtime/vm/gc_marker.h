// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_GC_MARKER_H_
#define RUNTIME_VM_GC_MARKER_H_

#include "vm/allocation.h"
#include "vm/os_thread.h"  // Mutex.

namespace dart {

// Forward declarations.
class HandleVisitor;
class Heap;
class Isolate;
class ObjectPointerVisitor;
class PageSpace;
class RawWeakProperty;

// The class GCMarker is used to mark reachable old generation objects as part
// of the mark-sweep collection. The marking bit used is defined in RawObject.
class GCMarker : public ValueObject {
 public:
  explicit GCMarker(Heap* heap) : heap_(heap), marked_bytes_(0) {}
  ~GCMarker() {}

  void MarkObjects(Isolate* isolate,
                   PageSpace* page_space,
                   bool collect_code);

  intptr_t marked_words() { return marked_bytes_ >> kWordSizeLog2; }

 private:
  void Prologue(Isolate* isolate);
  void Epilogue(Isolate* isolate);
  void IterateRoots(Isolate* isolate,
                    ObjectPointerVisitor* visitor,
                    intptr_t slice_index,
                    intptr_t num_slices);
  void IterateWeakRoots(Isolate* isolate, HandleVisitor* visitor);
  template <class MarkingVisitorType>
  void IterateWeakReferences(Isolate* isolate, MarkingVisitorType* visitor);
  void ProcessWeakTables(PageSpace* page_space);
  void ProcessObjectIdTable(Isolate* isolate);

  // Called by anyone: finalize and accumulate stats from 'visitor'.
  template <class MarkingVisitorType>
  void FinalizeResultsFrom(MarkingVisitorType* visitor);

  Heap* heap_;

  Mutex stats_mutex_;
  // TODO(koda): Remove after verifying it's redundant w.r.t. ClassHeapStats.
  uintptr_t marked_bytes_;

  friend class MarkTask;
  DISALLOW_IMPLICIT_CONSTRUCTORS(GCMarker);
};

}  // namespace dart

#endif  // RUNTIME_VM_GC_MARKER_H_
