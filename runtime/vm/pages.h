// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PAGES_H_
#define VM_PAGES_H_

#include "vm/freelist.h"
#include "vm/globals.h"
#include "vm/virtual_memory.h"

namespace dart {

// Forward declarations.
class Heap;
class ObjectPointerVisitor;

// An aligned page containing old generation objects. Alignment is used to be
// able to get to a HeapPage header quickly based on a pointer to an object.
class HeapPage {
 public:
  HeapPage* next() const { return next_; }
  void set_next(HeapPage* next) { next_ = next; }

  bool Contains(uword addr) {
    return memory_->Contains(addr);
  }

  uword start() const { return reinterpret_cast<uword>(this); }
  uword end() const { return memory_->end(); }

  uword top() const { return top_; }
  void set_top(uword top) { top_ = top; }

  uword first_object_start() const {
    return (reinterpret_cast<uword>(this) + sizeof(HeapPage));
  }

  void set_used(uword used) { used_ = used; }
  uword used() const { return used_; }
  void AddUsed(uword size) {
    used_ += size;
  }

  uword TryBumpAllocate(intptr_t size) {
    uword result = top();
    intptr_t remaining_space = end() - result;
    if (remaining_space < size) {
      return 0;
    }
    set_top(result + size);
    return result;
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  RawObject* FindObject(FindObjectVisitor* visitor) const;

 private:
  static HeapPage* Initialize(VirtualMemory* memory, bool is_executable);
  static HeapPage* Allocate(intptr_t size, bool is_executable);

  // Deallocate the virtual memory backing this page. The page pointer to this
  // page becomes immediately inaccessible.
  void Deallocate();

  VirtualMemory* memory_;
  HeapPage* next_;
  uword used_;
  uword top_;

  friend class PageSpace;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(HeapPage);
};


// The history holds the timing information of the last garbage collection
// runs.
class PageSpaceGarbageCollectionHistory {
 public:
  PageSpaceGarbageCollectionHistory();
  ~PageSpaceGarbageCollectionHistory() {}

  void AddGarbageCollectionTime(uint64_t start, uint64_t end);

  int GarbageCollectionTimeFraction();

 private:
  static const uint32_t kHistoryLength = 4;
  uint64_t start_[kHistoryLength];
  uint64_t end_[kHistoryLength];
  uint32_t index_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(PageSpaceGarbageCollectionHistory);
};


// If GC is able to reclaim more than heap_growth_ratio (in percent) memory
// and if the relative GC time is below a given threshold,
// then the heap is not grown when the next GC decision is made.
// PageSpaceController controls the heap size.
class PageSpaceController {
 public:
  PageSpaceController(int heap_growth_ratio,
                      int heap_growth_rate,
                      int garbage_collection_time_ratio);
  ~PageSpaceController();

  bool CanGrowPageSpace(intptr_t size_in_bytes);

  // A garbage collection is considered as successful if more than
  // heap_growth_ratio % of memory got deallocated by the garbage collector.
  // In this case garbage collection will be performed next time. Otherwise
  // the heap will grow.
  void EvaluateGarbageCollection(size_t in_use_before, size_t in_use_after,
                                 int64_t start, int64_t end);

  void Enable() {
    is_enabled_ = true;
  }

 private:
  bool is_enabled_;

  // Heap growth control variable.
  uword grow_heap_;

  // If the garbage collector was not able to free more than heap_growth_ratio_
  // memory, then the heap is grown. Otherwise garbage collection is performed.
  int heap_growth_ratio_;

  // Number of pages we grow.
  int heap_growth_rate_;

  // If the relative GC time stays below garbage_collection_time_ratio_
  // garbage collection can be performed.
  int garbage_collection_time_ratio_;

  PageSpaceGarbageCollectionHistory history_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpaceController);
};


class PageSpace {
 public:
  // TODO(iposva): Determine heap sizes and tune the page size accordingly.
  static const intptr_t kPageSize = 256 * KB;
  static const intptr_t kPageAlignment = kPageSize;

  PageSpace(Heap* heap, intptr_t max_capacity, bool is_executable = false);
  ~PageSpace();

  uword TryAllocate(intptr_t size);

  intptr_t in_use() const { return in_use_; }
  intptr_t capacity() const { return capacity_; }

  bool Contains(uword addr) const;
  bool IsValidAddress(uword addr) const {
    return Contains(addr);
  }
  static bool IsPageAllocatableSize(intptr_t size) {
    return size <= kAllocatablePageSize;
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  RawObject* FindObject(FindObjectVisitor* visitor) const;

  // Collect the garbage in the page space using mark-sweep.
  void MarkSweep(bool invoke_api_callbacks);

  static HeapPage* PageFor(RawObject* raw_obj) {
    return reinterpret_cast<HeapPage*>(
        RawObject::ToAddr(raw_obj) & ~(kPageSize -1));
  }

  void EnableGrowthControl() {
    page_space_controller_.Enable();
  }

 private:
  static const intptr_t kAllocatablePageSize = kPageSize - sizeof(HeapPage);

  void AllocatePage();
  void FreePage(HeapPage* page, HeapPage* previous_page);
  HeapPage* AllocateLargePage(intptr_t size);
  void FreeLargePage(HeapPage* page, HeapPage* previous_page);
  void FreePages(HeapPage* pages);

  static intptr_t LargePageSizeFor(intptr_t size);

  bool CanIncreaseCapacity(intptr_t increase) {
    ASSERT(capacity_ <= max_capacity_);
    return increase <= (max_capacity_ - capacity_);
  }

  uword TryBumpAllocate(intptr_t size);

  FreeList freelist_;

  Heap* heap_;

  HeapPage* pages_;
  HeapPage* pages_tail_;
  HeapPage* large_pages_;

  // Page being used for bump allocation.
  // The value has different meanings:
  // NULL: Still bump allocating from last allocated fresh page.
  // !NULL: Last page that had enough room to bump allocate, when we reach the
  // tail page, we give up bump allocating.
  HeapPage* bump_page_;

  // Various sizes being tracked for this generation.
  intptr_t max_capacity_;
  intptr_t capacity_;
  intptr_t in_use_;

  // Old-gen GC cycle count.
  int count_;

  bool is_executable_;

  // Keep track whether a MarkSweep is currently running.
  bool sweeping_;

  PageSpaceController page_space_controller_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpace);
};

}  // namespace dart

#endif  // VM_PAGES_H_
