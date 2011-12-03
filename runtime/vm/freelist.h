// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FREELIST_H_
#define VM_FREELIST_H_

#include "vm/allocation.h"
#include "vm/assert.h"
#include "vm/raw_object.h"

namespace dart {

// FreeListElement describes a freelist element that has the same size
// as the smallest raw object. It uses the class_ field to point to a fake map
// to enable basic traversing of the heap and to identify the type of freelist
// element. It reuses the second word of the raw object to keep a next_
// pointer to chain elements of the list together. For objects larger than the
// minimal object size, the size of the element is embedded in the element at
// the address following the next_ field.
class FreeListElement {
 public:
  FreeListElement* next() const { return next_; }
  void set_next(FreeListElement* next) { next_ = next; }

  intptr_t Size() const {
    if (class_ == minimal_element_class_) {
      return kObjectAlignment;
    }
    ASSERT(class_ == element_class_);
    return *SizeAddress();
  }

  static FreeListElement* AsElement(uword addr, intptr_t size);

  static void InitOnce();

 private:
  // This layout mirrors the layout of RawObject.
  RawClass* class_;
  FreeListElement* next_;

  // Returns the address of the embedded size.
  intptr_t* SizeAddress() const {
    ASSERT(class_ == element_class_);
    uword addr = reinterpret_cast<uword>(&next_) + kWordSize;
    return reinterpret_cast<intptr_t*>(addr);
  }

  // The two fake classe being used by the FreeList to identify free objects in
  // the heap. These can be static and shared between isolates since they
  // contain no per-isolate information. Actually, they need to be static so
  // that they can be used from free list elements efficiently.
  // The minimal_element_class_ is used by minimally sized free list elements
  // which cannot hold the size within the element.
  // element_class_ is used for free lists elements containing a size.
  static RawClass* minimal_element_class_;
  static RawClass* element_class_;

  // FreeListElements cannot be allocated. Instead references to them are
  // created using the AsElement factory method.
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(FreeListElement);
};


class FreeList {
 public:
  FreeList();
  ~FreeList();

  uword TryAllocate(intptr_t size);
  void Free(uword addr, intptr_t size);

  void Reset();

 private:
  static const int kNumLists = 128;

  static intptr_t IndexForSize(intptr_t size);

  void EnqueueElement(FreeListElement* element, intptr_t index);
  FreeListElement* DequeueElement(intptr_t index);

  void SplitElementAfterAndEnqueue(FreeListElement* element, intptr_t size);

  FreeListElement* free_lists_[kNumLists + 1];

  DISALLOW_COPY_AND_ASSIGN(FreeList);
};

}  // namespace dart

#endif  // VM_FREELIST_H_
