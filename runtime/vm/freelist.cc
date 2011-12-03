// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/freelist.h"

#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// Allocate a fake class to be used as the class for elements of the free list.
// These raw classes are only used to identify free list elements in the heap.
// These classes cannot be allocated in the heap as the elements of the free
// list are not live objects and their class references would not be updated
// during a moving collection. In the general case these classes are also used
// to implement RawObject::Size() to allow other code to safely traverse
// the heap without any knowledge of the embedded free list elements.
RawClass* AllocateFakeClass() {
  RawClass* result =
      reinterpret_cast<RawClass*>(calloc(1, Class::InstanceSize()));
  result->instance_kind_ = kFreeListElement;
  return reinterpret_cast<RawClass*>(RawObject::FromAddr(
      reinterpret_cast<uword>(result)));
}


RawClass* FreeListElement::minimal_element_class_ = NULL;
RawClass* FreeListElement::element_class_ = NULL;


FreeListElement* FreeListElement::AsElement(uword addr, intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  FreeListElement* result = reinterpret_cast<FreeListElement*>(addr);
  if (size == kObjectAlignment) {
    result->class_ = minimal_element_class_;
  } else {
    result->class_ = element_class_;
    *result->SizeAddress() = size;
  }
  result->set_next(NULL);
  ASSERT(result->Size() == size);
  return result;
}


void FreeListElement::InitOnce() {
  ASSERT(sizeof(FreeListElement) == kObjectAlignment);
  ASSERT(minimal_element_class_ == NULL);
  ASSERT(element_class_ == NULL);
  minimal_element_class_ = AllocateFakeClass();
  element_class_ = AllocateFakeClass();
}


FreeList::FreeList() {
  Reset();
}


FreeList::~FreeList() {
  // Nothing to release.
}


uword FreeList::TryAllocate(intptr_t size) {
  int index = IndexForSize(size);
  if ((index != kNumLists) && (free_lists_[index] != NULL)) {
    return reinterpret_cast<uword>(DequeueElement(index));
  }

  if (index < kNumLists) {
    index++;
    while (index < kNumLists) {
      if (free_lists_[index] != NULL) {
        // Dequeue an element from the list, split and enqueue the remainder in
        // the appropriate list.
        FreeListElement* element = DequeueElement(index);
        SplitElementAfterAndEnqueue(element, size);
        return reinterpret_cast<uword>(element);
      }
      index++;
    }
  }

  FreeListElement* previous = NULL;
  FreeListElement* current = free_lists_[kNumLists];
  while (current != NULL) {
    if (current->Size() >= size) {
      // Found an element large enough to hold the requested size. Dequeue,
      // split and enqueue the remainder.
      if (previous == NULL) {
        free_lists_[kNumLists] = current->next();
      } else {
        previous->set_next(current->next());
      }
      SplitElementAfterAndEnqueue(current, size);
      return reinterpret_cast<uword>(current);
    }
    previous = current;
    current = current->next();
  }
  return 0;
}


void FreeList::Free(uword addr, intptr_t size) {
  intptr_t index = IndexForSize(size);
  FreeListElement* element = FreeListElement::AsElement(addr, size);
  EnqueueElement(element, index);
}


void FreeList::Reset() {
  for (int i = 0; i < (kNumLists + 1); i++) {
    free_lists_[i] = NULL;
  }
}

intptr_t FreeList::IndexForSize(intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  intptr_t index = size / kObjectAlignment;
  if (index >= kNumLists) {
    index = kNumLists;
  }
  return index;
}


void FreeList::EnqueueElement(FreeListElement* element, intptr_t index) {
  element->set_next(free_lists_[index]);
  free_lists_[index] = element;
}


FreeListElement* FreeList::DequeueElement(intptr_t index) {
  FreeListElement* result = free_lists_[index];
  free_lists_[index] = result->next();
  return result;
}


void FreeList::SplitElementAfterAndEnqueue(FreeListElement* element,
                                           intptr_t size) {
  intptr_t remainder_size = element->Size() - size;
  if (remainder_size == 0) return;

  element = FreeListElement::AsElement(reinterpret_cast<uword>(element) + size,
                                       remainder_size);
  intptr_t remainder_index = IndexForSize(remainder_size);
  EnqueueElement(element, remainder_index);
}

}  // namespace dart
