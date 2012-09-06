// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/freelist.h"

#include "vm/bit_set.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {


FreeListElement* FreeListElement::AsElement(uword addr, intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  FreeListElement* result = reinterpret_cast<FreeListElement*>(addr);

  uword tags = 0;
  tags = RawObject::FreeBit::update(true, tags);
  tags = RawObject::SizeTag::update(size, tags);
  tags = RawObject::ClassIdTag::update(kFreeListElement, tags);

  result->tags_ = tags;
  if (size > RawObject::SizeTag::kMaxSizeTag) {
    *result->SizeAddress() = size;
  }
  result->set_next(NULL);

  return result;
}


void FreeListElement::InitOnce() {
  ASSERT(sizeof(FreeListElement) == kObjectAlignment);
  ASSERT(OFFSET_OF(FreeListElement, tags_) == Object::tags_offset());
}


FreeList::FreeList() {
  Reset();
}


FreeList::~FreeList() {
  // Nothing to release.
}


uword FreeList::TryAllocate(intptr_t size) {
  int index = IndexForSize(size);
  if ((index != kNumLists) && free_map_.Test(index)) {
    return reinterpret_cast<uword>(DequeueElement(index));
  }

  if ((index + 1) < kNumLists) {
    intptr_t next_index = free_map_.Next(index + 1);
    if (next_index != -1) {
      // Dequeue an element from the list, split and enqueue the remainder in
      // the appropriate list.
      FreeListElement* element = DequeueElement(next_index);
      SplitElementAfterAndEnqueue(element, size);
      return reinterpret_cast<uword>(element);
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
  free_map_.Reset();
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
  FreeListElement* next = free_lists_[index];
  if (next == NULL && index != kNumLists) {
    free_map_.Set(index, true);
  }
  element->set_next(next);
  free_lists_[index] = element;
}


FreeListElement* FreeList::DequeueElement(intptr_t index) {
  FreeListElement* result = free_lists_[index];
  FreeListElement* next = result->next();
  if (next == NULL && index != kNumLists) {
    free_map_.Set(index, false);
  }
  free_lists_[index] = next;
  return result;
}


intptr_t FreeList::Length(int index) const {
  ASSERT(index >= 0);
  ASSERT(index < kNumLists);
  intptr_t result = 0;
  FreeListElement* element = free_lists_[index];
  while (element != NULL) {
    ++result;
    element = element->next();
  }
  return result;
}


void FreeList::Print() const {
  OS::Print("%*s %*s %*s\n", 10, "Class", 10, "Length", 10, "Size");
  OS::Print("--------------------------------\n");
  int total_index = 0;
  int total_length = 0;
  int total_size = 0;
  for (int i = 0; i < kNumLists; ++i) {
    if (free_lists_[i] == NULL) {
      continue;
    }
    total_index += 1;
    intptr_t length = Length(i);
    total_length += length;
    intptr_t size = length * i * kObjectAlignment;
    total_size += size;
    OS::Print("%*d %*"Pd" %*"Pd"\n",
              10, i * kObjectAlignment, 10, length, 10, size);
  }
  OS::Print("--------------------------------\n");
  OS::Print("%*d %*d %*d\n", 10, total_index, 10, total_length, 10, total_size);
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
