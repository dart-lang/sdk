// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FREELIST_H_
#define RUNTIME_VM_FREELIST_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/bit_set.h"
#include "vm/raw_object.h"
#include "vm/os_thread.h"

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

  intptr_t Size() {
    intptr_t size = RawObject::SizeTag::decode(tags_);
    if (size != 0) return size;
    return *SizeAddress();
  }

  static FreeListElement* AsElement(uword addr, intptr_t size);

  static void InitOnce();

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
  uint32_t tags_;
#if defined(HASH_IN_OBJECT_HEADER)
  uint32_t hash_;
#endif
  FreeListElement* next_;

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

  Mutex* mutex() { return mutex_; }
  uword TryAllocateLocked(intptr_t size, bool is_protected);
  void FreeLocked(uword addr, intptr_t size);

  // Returns a large element, at least 'minimum_size', or NULL if none exists.
  FreeListElement* TryAllocateLarge(intptr_t minimum_size);
  FreeListElement* TryAllocateLargeLocked(intptr_t minimum_size);

  // Allocates locked and unprotected memory, but only from small elements
  // (i.e., fixed size lists).
  uword TryAllocateSmallLocked(intptr_t size);

 private:
  static const int kNumLists = 128;
  static const intptr_t kInitialFreeListSearchBudget = 1000;

  static intptr_t IndexForSize(intptr_t size);

  intptr_t LengthLocked(int index) const;

  void EnqueueElement(FreeListElement* element, intptr_t index);
  FreeListElement* DequeueElement(intptr_t index);

  void SplitElementAfterAndEnqueue(FreeListElement* element,
                                   intptr_t size,
                                   bool is_protected);

  void PrintSmall() const;
  void PrintLarge() const;

  // Lock protecting the free list data structures.
  Mutex* mutex_;

  BitSet<kNumLists> free_map_;

  FreeListElement* free_lists_[kNumLists + 1];

  intptr_t freelist_search_budget_;

  // The largest available small size in bytes, or negative if there is none.
  intptr_t last_free_small_size_;

  DISALLOW_COPY_AND_ASSIGN(FreeList);
};

}  // namespace dart

#endif  // RUNTIME_VM_FREELIST_H_
