// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FREELIST_H_
#define VM_FREELIST_H_

#include "platform/assert.h"
#include "vm/allocation.h"
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
  FreeListElement* next() const {
    // Clear the FreeBit.
    ASSERT((next_ & 1) == 1);
    return reinterpret_cast<FreeListElement*>(next_ ^ 1);
  }
  void set_next(FreeListElement* next) {
    // Set the FreeBit.
    uword addr = reinterpret_cast<uword>(next);
    ASSERT((addr & 1) == 0);
    next_ = addr | 1;
  }

  intptr_t size() const {
    return size_;
  }

  static FreeListElement* AsElement(uword addr, intptr_t size);

  static void InitOnce();

 private:
  // This layout mirrors the layout of RawObject.
  uword next_;
  intptr_t size_;

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
