// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_FREELIST_H_
#define RUNTIME_VM_HEAP_FREELIST_H_

#include "platform/assert.h"
#include "platform/atomic.h"
#include "vm/allocation.h"
#include "vm/bit_set.h"
#include "vm/os_thread.h"
#include "vm/raw_object.h"

namespace dart {

// FreeListElement describes a freelist element.  Smallest FreeListElement is
// two words in size.  Second word of the raw object is used to keep a next_
// pointer to chain elements of the list together. For objects larger than the
// object size encodable in tags field, the size of the element is embedded in
// the element at the address following the next_ field. All words written by
// the freelist are guaranteed to look like Smis.
// A FreeListElement never has its header mark bit set.
class FreeListElement {
 public:
  FreeListElement* next() const { return next_; }
  uword next_address() const { return reinterpret_cast<uword>(&next_); }

  void set_next(FreeListElement* next) { next_ = next; }

  intptr_t HeapSize() {
    intptr_t size = ObjectLayout::SizeTag::decode(tags_);
    if (size != 0) return size;
    return *SizeAddress();
  }

  static FreeListElement* AsElement(uword addr, intptr_t size);

  static void Init();

  static intptr_t HeaderSizeFor(intptr_t size);

  // Used to allocate class for free list elements in Object::InitOnce.
  class FakeInstance {
   public:
    FakeInstance() {}
    static cpp_vtable vtable() { return 0; }
    static intptr_t InstanceSize() { return 0; }
    static intptr_t NextFieldOffset() { return -kWordSize; }
    static const ClassId kClassId = kFreeListElement;
    static bool IsInstance() { return true; }

   private:
    DISALLOW_ALLOCATION();
    DISALLOW_COPY_AND_ASSIGN(FakeInstance);
  };

 private:
  // This layout mirrors the layout of RawObject.
  RelaxedAtomic<uword> tags_;
  RelaxedAtomic<FreeListElement*> next_;

  // Returns the address of the embedded size.
  intptr_t* SizeAddress() const {
    uword addr = reinterpret_cast<uword>(&next_) + kWordSize;
    return reinterpret_cast<intptr_t*>(addr);
  }

  // FreeListElements cannot be allocated. Instead references to them are
  // created using the AsElement factory method.
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(FreeListElement);
};

class FreeList {
 public:
  FreeList();
  ~FreeList();

  uword TryAllocate(intptr_t size, bool is_protected);
  void Free(uword addr, intptr_t size);

  void Reset();

  void Print() const;

  Mutex* mutex() { return &mutex_; }
  uword TryAllocateLocked(intptr_t size, bool is_protected);
  void FreeLocked(uword addr, intptr_t size);

  // Returns a large element, at least 'minimum_size', or NULL if none exists.
  FreeListElement* TryAllocateLarge(intptr_t minimum_size);
  FreeListElement* TryAllocateLargeLocked(intptr_t minimum_size);

  // Allocates locked and unprotected memory, but only from small elements
  // (i.e., fixed size lists).
  uword TryAllocateSmallLocked(intptr_t size) {
    DEBUG_ASSERT(mutex_.IsOwnedByCurrentThread());
    if (size > last_free_small_size_) {
      return 0;
    }
    int index = IndexForSize(size);
    if (index != kNumLists && free_map_.Test(index)) {
      return reinterpret_cast<uword>(DequeueElement(index));
    }
    if ((index + 1) < kNumLists) {
      intptr_t next_index = free_map_.Next(index + 1);
      if (next_index != -1) {
        FreeListElement* element = DequeueElement(next_index);
        SplitElementAfterAndEnqueue(element, size, false);
        return reinterpret_cast<uword>(element);
      }
    }
    return 0;
  }

  uword TryAllocateBumpLocked(intptr_t size) {
    ASSERT(mutex_.IsOwnedByCurrentThread());
    uword result = top_;
    uword new_top = result + size;
    if (new_top <= end_) {
      top_ = new_top;
      unaccounted_size_ += size;
      return result;
    }
    return 0;
  }
  intptr_t TakeUnaccountedSizeLocked() {
    ASSERT(mutex_.IsOwnedByCurrentThread());
    intptr_t result = unaccounted_size_;
    unaccounted_size_ = 0;
    return result;
  }

  // Ensures OldPage::VisitObjects can successful walk over a partially
  // allocated bump region.
  void MakeIterable() {
    if (top_ < end_) {
      FreeListElement::AsElement(top_, end_ - top_);
    }
  }
  // Returns the bump region to the free list.
  void AbandonBumpAllocation() {
    if (top_ < end_) {
      Free(top_, end_ - top_);
      top_ = 0;
      end_ = 0;
    }
  }

  uword top() const { return top_; }
  uword end() const { return end_; }
  void set_top(uword value) { top_ = value; }
  void set_end(uword value) { end_ = value; }
  void AddUnaccountedSize(intptr_t size) { unaccounted_size_ += size; }

 private:
  static const int kNumLists = 128;
  static const intptr_t kInitialFreeListSearchBudget = 1000;

  static intptr_t IndexForSize(intptr_t size) {
    ASSERT(size >= kObjectAlignment);
    ASSERT(Utils::IsAligned(size, kObjectAlignment));

    intptr_t index = size >> kObjectAlignmentLog2;
    if (index >= kNumLists) {
      index = kNumLists;
    }
    return index;
  }

  intptr_t LengthLocked(int index) const;

  void EnqueueElement(FreeListElement* element, intptr_t index);
  FreeListElement* DequeueElement(intptr_t index) {
    FreeListElement* result = free_lists_[index];
    FreeListElement* next = result->next();
    if (next == NULL && index != kNumLists) {
      intptr_t size = index << kObjectAlignmentLog2;
      if (size == last_free_small_size_) {
        // Note: This is -1 * kObjectAlignment if no other small sizes remain.
        last_free_small_size_ =
            free_map_.ClearLastAndFindPrevious(index) * kObjectAlignment;
      } else {
        free_map_.Set(index, false);
      }
    }
    free_lists_[index] = next;
    return result;
  }

  void SplitElementAfterAndEnqueue(FreeListElement* element,
                                   intptr_t size,
                                   bool is_protected);

  void PrintSmall() const;
  void PrintLarge() const;

  // Bump pointer region.
  uword top_ = 0;
  uword end_ = 0;

  // Allocated from the bump pointer region, but not yet added to
  // PageSpace::usage_. Used to avoid expensive atomic adds during parallel
  // scavenge.
  intptr_t unaccounted_size_ = 0;

  // Lock protecting the free list data structures.
  mutable Mutex mutex_;

  BitSet<kNumLists> free_map_;

  FreeListElement* free_lists_[kNumLists + 1];

  intptr_t freelist_search_budget_ = kInitialFreeListSearchBudget;

  // The largest available small size in bytes, or negative if there is none.
  intptr_t last_free_small_size_;

  DISALLOW_COPY_AND_ASSIGN(FreeList);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_FREELIST_H_
