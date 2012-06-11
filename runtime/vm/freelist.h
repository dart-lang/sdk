// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FREELIST_H_
#define VM_FREELIST_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/raw_object.h"

namespace dart {

// FreeListElement describes a freelist element.  Smallest FreeListElement is
// two words in size.  Second word of the raw object is used to keep a next_
// pointer to chain elements of the list together. For objects larger than the
// object size encodable in tags field, the size of the element is embedded in
// the element at the address following the next_ field.
class FreeListElement {
 public:
  FreeListElement* next() const {
    return next_;
  }

  void set_next(FreeListElement* next) {
    next_ = next;
  }

  intptr_t Size() {
    intptr_t size = RawObject::SizeTag::decode(tags_);
    if (size != 0) return size;
    return *SizeAddress();
  }

  static FreeListElement* AsElement(uword addr, intptr_t size);

  static void InitOnce();

  // Used to allocate class for free list elements in Object::InitOnce.
  class FakeInstance {
   public:
    FakeInstance() { }
    static cpp_vtable vtable() { return 0; }
    static intptr_t InstanceSize() { return 0; }
    static const ObjectKind kInstanceKind = kFreeListElement;
    static bool IsInstance() { return true; }

   private:
    DISALLOW_ALLOCATION();
    DISALLOW_COPY_AND_ASSIGN(FakeInstance);
  };

 private:
  // This layout mirrors the layout of RawObject.
  uword tags_;
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
