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


class PageSpace {
 public:
  // TODO(iposva): Determine heap sizes and tune the page size accordingly.
  static const intptr_t kPageSize = 256 * KB;
  static const intptr_t kPageAlignment = kPageSize;

  PageSpace(Heap* heap, intptr_t max_capacity, bool is_executable = false);
  ~PageSpace();

  uword TryAllocate(intptr_t size);

  intptr_t in_use() const { return in_use_; }
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

 private:
  static const intptr_t kAllocatablePageSize = kPageSize - sizeof(HeapPage);

  void AllocatePage();
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

  // Various sizes being tracked for this generation.
  intptr_t max_capacity_;
  intptr_t capacity_;
  intptr_t in_use_;

  // Old-gen GC cycle count.
  int count_;

  bool is_executable_;

  // Keep track whether a MarkSweep is currently running.
  bool sweeping_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpace);
};

}  // namespace dart

#endif  // VM_PAGES_H_
