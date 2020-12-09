// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/freelist.h"

#include "vm/bit_set.h"
#include "vm/hash_map.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/raw_object.h"

namespace dart {

FreeListElement* FreeListElement::AsElement(uword addr, intptr_t size) {
  // Precondition: the (page containing the) header of the element is
  // writable.
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  FreeListElement* result = reinterpret_cast<FreeListElement*>(addr);

  uword tags = 0;
  tags = ObjectLayout::SizeTag::update(size, tags);
  tags = ObjectLayout::ClassIdTag::update(kFreeListElement, tags);
  ASSERT((addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset);
  tags = ObjectLayout::OldBit::update(true, tags);
  tags = ObjectLayout::OldAndNotMarkedBit::update(true, tags);
  tags = ObjectLayout::OldAndNotRememberedBit::update(true, tags);
  tags = ObjectLayout::NewBit::update(false, tags);
  result->tags_ = tags;

  if (size > ObjectLayout::SizeTag::kMaxSizeTag) {
    *result->SizeAddress() = size;
  }
  result->set_next(NULL);
  return result;
  // Postcondition: the (page containing the) header of the element is
  // writable.
}

void FreeListElement::Init() {
  ASSERT(sizeof(FreeListElement) == kObjectAlignment);
  ASSERT(OFFSET_OF(FreeListElement, tags_) == Object::tags_offset());
}

intptr_t FreeListElement::HeaderSizeFor(intptr_t size) {
  if (size == 0) return 0;
  return ((size > ObjectLayout::SizeTag::kMaxSizeTag) ? 3 : 2) * kWordSize;
}

FreeList::FreeList() : mutex_() {
  Reset();
}

FreeList::~FreeList() {
}

uword FreeList::TryAllocate(intptr_t size, bool is_protected) {
  MutexLocker ml(&mutex_);
  return TryAllocateLocked(size, is_protected);
}

uword FreeList::TryAllocateLocked(intptr_t size, bool is_protected) {
  DEBUG_ASSERT(mutex_.IsOwnedByCurrentThread());
  // Precondition: is_protected is false or else all free list elements are
  // in non-writable pages.

  // Postcondition: if allocation succeeds, the allocated block is writable.
  int index = IndexForSize(size);
  if ((index != kNumLists) && free_map_.Test(index)) {
    FreeListElement* element = DequeueElement(index);
    if (is_protected) {
      VirtualMemory::Protect(reinterpret_cast<void*>(element), size,
                             VirtualMemory::kReadWrite);
    }
    return reinterpret_cast<uword>(element);
  }

  if ((index + 1) < kNumLists) {
    intptr_t next_index = free_map_.Next(index + 1);
    if (next_index != -1) {
      // Dequeue an element from the list, split and enqueue the remainder in
      // the appropriate list.
      FreeListElement* element = DequeueElement(next_index);
      if (is_protected) {
        // Make the allocated block and the header of the remainder element
        // writable.  The remainder will be non-writable if necessary after
        // the call to SplitElementAfterAndEnqueue.
        // If the remainder size is zero, only the element itself needs to
        // be made writable.
        intptr_t remainder_size = element->HeapSize() - size;
        intptr_t region_size =
            size + FreeListElement::HeaderSizeFor(remainder_size);
        VirtualMemory::Protect(reinterpret_cast<void*>(element), region_size,
                               VirtualMemory::kReadWrite);
      }
      SplitElementAfterAndEnqueue(element, size, is_protected);
      return reinterpret_cast<uword>(element);
    }
  }

  FreeListElement* previous = NULL;
  FreeListElement* current = free_lists_[kNumLists];
  // We are willing to search the freelist further for a big block.
  // For each successful free-list search we:
  //   * increase the search budget by #allocated-words
  //   * decrease the search budget by #free-list-entries-traversed
  //     which guarantees us to not waste more than around 1 search step per
  //     word of allocation
  //
  // If we run out of search budget we fall back to allocating a new page and
  // reset the search budget.
  intptr_t tries_left = freelist_search_budget_ + (size >> kWordSizeLog2);
  while (current != NULL) {
    if (current->HeapSize() >= size) {
      // Found an element large enough to hold the requested size. Dequeue,
      // split and enqueue the remainder.
      intptr_t remainder_size = current->HeapSize() - size;
      intptr_t region_size =
          size + FreeListElement::HeaderSizeFor(remainder_size);
      if (is_protected) {
        // Make the allocated block and the header of the remainder element
        // writable.  The remainder will be non-writable if necessary after
        // the call to SplitElementAfterAndEnqueue.
        VirtualMemory::Protect(reinterpret_cast<void*>(current), region_size,
                               VirtualMemory::kReadWrite);
      }

      if (previous == NULL) {
        free_lists_[kNumLists] = current->next();
      } else {
        // If the previous free list element's next field is protected, it
        // needs to be unprotected before storing to it and reprotected
        // after.
        bool target_is_protected = false;
        uword target_address = 0L;
        if (is_protected) {
          uword writable_start = reinterpret_cast<uword>(current);
          uword writable_end = writable_start + region_size - 1;
          target_address = previous->next_address();
          target_is_protected =
              !VirtualMemory::InSamePage(target_address, writable_start) &&
              !VirtualMemory::InSamePage(target_address, writable_end);
        }
        if (target_is_protected) {
          VirtualMemory::Protect(reinterpret_cast<void*>(target_address),
                                 kWordSize, VirtualMemory::kReadWrite);
        }
        previous->set_next(current->next());
        if (target_is_protected) {
          VirtualMemory::Protect(reinterpret_cast<void*>(target_address),
                                 kWordSize, VirtualMemory::kReadExecute);
        }
      }
      SplitElementAfterAndEnqueue(current, size, is_protected);
      freelist_search_budget_ =
          Utils::Minimum(tries_left, kInitialFreeListSearchBudget);
      return reinterpret_cast<uword>(current);
    } else if (tries_left-- < 0) {
      freelist_search_budget_ = kInitialFreeListSearchBudget;
      return 0;  // Trigger allocation of new page.
    }
    previous = current;
    current = current->next();
  }
  return 0;
}

void FreeList::Free(uword addr, intptr_t size) {
  MutexLocker ml(&mutex_);
  FreeLocked(addr, size);
}

void FreeList::FreeLocked(uword addr, intptr_t size) {
  DEBUG_ASSERT(mutex_.IsOwnedByCurrentThread());
  // Precondition required by AsElement and EnqueueElement: the (page
  // containing the) header of the freed block should be writable.  This is
  // the case when called for newly allocated pages because they are
  // allocated as writable.  It is the case when called during GC sweeping
  // because the entire heap is writable.
  intptr_t index = IndexForSize(size);
  FreeListElement* element = FreeListElement::AsElement(addr, size);
  EnqueueElement(element, index);
  // Postcondition: the (page containing the) header is left writable.
}

void FreeList::Reset() {
  MutexLocker ml(&mutex_);
  free_map_.Reset();
  last_free_small_size_ = -1;
  for (int i = 0; i < (kNumLists + 1); i++) {
    free_lists_[i] = NULL;
  }
}

void FreeList::EnqueueElement(FreeListElement* element, intptr_t index) {
  FreeListElement* next = free_lists_[index];
  if (next == NULL && index != kNumLists) {
    free_map_.Set(index, true);
    last_free_small_size_ =
        Utils::Maximum(last_free_small_size_, index << kObjectAlignmentLog2);
  }
  element->set_next(next);
  free_lists_[index] = element;
}

intptr_t FreeList::LengthLocked(int index) const {
  DEBUG_ASSERT(mutex_.IsOwnedByCurrentThread());
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

void FreeList::PrintSmall() const {
  int small_sizes = 0;
  int small_objects = 0;
  intptr_t small_bytes = 0;
  for (int i = 0; i < kNumLists; ++i) {
    if (free_lists_[i] == NULL) {
      continue;
    }
    small_sizes += 1;
    intptr_t list_length = LengthLocked(i);
    small_objects += list_length;
    intptr_t list_bytes = list_length * i * kObjectAlignment;
    small_bytes += list_bytes;
    OS::PrintErr(
        "small %3d [%8d bytes] : "
        "%8" Pd " objs; %8.1f KB; %8.1f cum KB\n",
        i, static_cast<int>(i * kObjectAlignment), list_length,
        list_bytes / static_cast<double>(KB),
        small_bytes / static_cast<double>(KB));
  }
}

class IntptrPair {
 public:
  IntptrPair() : first_(-1), second_(-1) {}
  IntptrPair(intptr_t first, intptr_t second)
      : first_(first), second_(second) {}

  intptr_t first() const { return first_; }
  intptr_t second() const { return second_; }
  void set_second(intptr_t s) { second_ = s; }

  bool operator==(const IntptrPair& other) {
    return (first_ == other.first_) && (second_ == other.second_);
  }

  bool operator!=(const IntptrPair& other) {
    return (first_ != other.first_) || (second_ != other.second_);
  }

 private:
  intptr_t first_;
  intptr_t second_;
};

void FreeList::PrintLarge() const {
  int large_sizes = 0;
  int large_objects = 0;
  intptr_t large_bytes = 0;
  MallocDirectChainedHashMap<NumbersKeyValueTrait<IntptrPair> > map;
  FreeListElement* node;
  for (node = free_lists_[kNumLists]; node != NULL; node = node->next()) {
    IntptrPair* pair = map.Lookup(node->HeapSize());
    if (pair == NULL) {
      large_sizes += 1;
      map.Insert(IntptrPair(node->HeapSize(), 1));
    } else {
      pair->set_second(pair->second() + 1);
    }
    large_objects += 1;
  }

  MallocDirectChainedHashMap<NumbersKeyValueTrait<IntptrPair> >::Iterator it =
      map.GetIterator();
  IntptrPair* pair;
  while ((pair = it.Next()) != NULL) {
    intptr_t size = pair->first();
    intptr_t list_length = pair->second();
    intptr_t list_bytes = list_length * size;
    large_bytes += list_bytes;
    OS::PrintErr("large %3" Pd " [%8" Pd
                 " bytes] : "
                 "%8" Pd " objs; %8.1f KB; %8.1f cum KB\n",
                 size / kObjectAlignment, size, list_length,
                 list_bytes / static_cast<double>(KB),
                 large_bytes / static_cast<double>(KB));
  }
}

void FreeList::Print() const {
  MutexLocker ml(&mutex_);
  PrintSmall();
  PrintLarge();
}

void FreeList::SplitElementAfterAndEnqueue(FreeListElement* element,
                                           intptr_t size,
                                           bool is_protected) {
  // Precondition required by AsElement and EnqueueElement: either
  // element->Size() == size, or else the (page containing the) header of
  // the remainder element starting at element + size is writable.
  intptr_t remainder_size = element->HeapSize() - size;
  if (remainder_size == 0) return;

  uword remainder_address = reinterpret_cast<uword>(element) + size;
  element = FreeListElement::AsElement(remainder_address, remainder_size);
  intptr_t remainder_index = IndexForSize(remainder_size);
  EnqueueElement(element, remainder_index);

  // Postcondition: when allocating in a protected page, the fraction of the
  // remainder element which does not share a page with the allocated element is
  // no longer writable. This means that if the remainder's header is not fully
  // contained in the last page of the allocation, we need to re-protect the
  // page it ends on.
  if (is_protected) {
    const uword remainder_header_size =
        FreeListElement::HeaderSizeFor(remainder_size);
    if (!VirtualMemory::InSamePage(
            remainder_address - 1,
            remainder_address + remainder_header_size - 1)) {
      VirtualMemory::Protect(
          reinterpret_cast<void*>(
              Utils::RoundUp(remainder_address, VirtualMemory::PageSize())),
          remainder_address + remainder_header_size -
              Utils::RoundUp(remainder_address, VirtualMemory::PageSize()),
          VirtualMemory::kReadExecute);
    }
  }
}

FreeListElement* FreeList::TryAllocateLarge(intptr_t minimum_size) {
  MutexLocker ml(&mutex_);
  return TryAllocateLargeLocked(minimum_size);
}

FreeListElement* FreeList::TryAllocateLargeLocked(intptr_t minimum_size) {
  DEBUG_ASSERT(mutex_.IsOwnedByCurrentThread());
  FreeListElement* previous = NULL;
  FreeListElement* current = free_lists_[kNumLists];
  // TODO(koda): Find largest.
  // We are willing to search the freelist further for a big block.
  intptr_t tries_left =
      freelist_search_budget_ + (minimum_size >> kWordSizeLog2);
  while (current != NULL) {
    FreeListElement* next = current->next();
    if (current->HeapSize() >= minimum_size) {
      if (previous == NULL) {
        free_lists_[kNumLists] = next;
      } else {
        previous->set_next(next);
      }
      freelist_search_budget_ =
          Utils::Minimum(tries_left, kInitialFreeListSearchBudget);
      return current;
    } else if (tries_left-- < 0) {
      freelist_search_budget_ = kInitialFreeListSearchBudget;
      return 0;  // Trigger allocation of new page.
    }
    previous = current;
    current = next;
  }
  return NULL;
}

}  // namespace dart
