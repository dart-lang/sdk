// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_MARKER_H_
#define RUNTIME_VM_HEAP_MARKER_H_

#include "vm/allocation.h"
#include "vm/heap/gc_shared.h"
#include "vm/heap/pointer_block.h"
#include "vm/os_thread.h"  // Mutex.

namespace dart {

// Forward declarations.
class HandleVisitor;
class Heap;
class IsolateGroup;
class ObjectPointerVisitor;
class PageSpace;
template <bool sync>
class MarkingVisitorBase;
class Page;
class Thread;

// The class GCMarker is used to mark reachable old generation objects as part
// of the mark-sweep collection. The marking bit used is defined in
// UntaggedObject. Instances have a lifetime that spans from the beginning of
// concurrent marking (or stop-the-world marking) until marking is complete. In
// particular, an instance may be created and destroyed on different threads if
// the isolate is exited during concurrent marking.
class GCMarker {
 public:
  GCMarker(IsolateGroup* isolate_group, Heap* heap);
  ~GCMarker();

  // Mark roots synchronously, then spawn tasks to concurrently drain the
  // marking queue. Only called when no marking or sweeping is in progress.
  // Marking must later be finalized by calling MarkObjects.
  void StartConcurrentMark(PageSpace* page_space);

  // Contribute to marking.
  void IncrementalMarkWithUnlimitedBudget(PageSpace* page_space);
  void IncrementalMarkWithSizeBudget(PageSpace* page_space, intptr_t size);
  void IncrementalMarkWithTimeBudget(PageSpace* page_space, int64_t deadline);

  // (Re)mark roots, drain the marking queue and finalize weak references.
  // Does not required StartConcurrentMark to have been previously called.
  void MarkObjects(PageSpace* page_space);

  intptr_t marked_words() const { return marked_bytes_ >> kWordSizeLog2; }
  intptr_t MarkedWordsPerMicro() const;

  void PruneWeak(Scavenger* scavenger);

 private:
  void Prologue();
  void Epilogue();
  void ResetSlices();
  void IterateRoots(ObjectPointerVisitor* visitor);
  void IterateWeakRoots(Thread* thread);
  void ProcessWeakHandles(Thread* thread);
  void ProcessWeakTables(Thread* thread);
  void ProcessRememberedSet(Thread* thread);
  void ProcessObjectIdTable(Thread* thread);

  // Called by anyone: finalize and accumulate stats from 'visitor'.
  template <class MarkingVisitorType>
  void FinalizeResultsFrom(MarkingVisitorType* visitor);

  IsolateGroup* const isolate_group_;
  Heap* const heap_;
  MarkingStack marking_stack_;
  MarkingStack new_marking_stack_;
  MarkingStack deferred_marking_stack_;
  GCLinkedLists global_list_;
  MarkingVisitorBase<true>** visitors_;

  Monitor root_slices_monitor_;
  RelaxedAtomic<intptr_t> root_slices_started_;
  intptr_t root_slices_finished_;
  intptr_t root_slices_count_;
  RelaxedAtomic<intptr_t> weak_slices_started_;

  uintptr_t marked_bytes_;
  int64_t marked_micros_;

  friend class ConcurrentMarkTask;
  friend class ParallelMarkTask;
  friend class Scavenger;
  template <bool sync>
  friend class MarkingVisitorBase;
  DISALLOW_IMPLICIT_CONSTRUCTORS(GCMarker);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_MARKER_H_
