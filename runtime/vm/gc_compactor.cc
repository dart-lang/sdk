// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_compactor.h"

#include "vm/become.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/pages.h"
#include "vm/timeline.h"

namespace dart {

ForwardingMap::ForwardingMap() : size_(0), capacity_(4 * KB), sorted_(true) {
  entries_ = reinterpret_cast<Entry*>(malloc(capacity_ * sizeof(Entry)));
}

ForwardingMap::~ForwardingMap() {
  free(entries_);
}

void ForwardingMap::Insert(RawObject* before, RawObject* after) {
  // Avoid unnecessary entries.
  ASSERT(before != after);

  // Ensure validity of fast paths in Lookup.
  ASSERT(before->IsHeapObject());
  ASSERT(before->IsOldObject());

  if (size_ >= capacity_) {
    capacity_ *= 2;
    entries_ =
        reinterpret_cast<Entry*>(realloc(entries_, capacity_ * sizeof(Entry)));
    if (entries_ == NULL) {
      OUT_OF_MEMORY();
    }
  }

  entries_[size_].before = before;
  entries_[size_].after = after;
  size_++;
  sorted_ = false;
}

int ForwardingMap::CompareEntries(Entry* a, Entry* b) {
  ASSERT(a->before != b->before);
  if (a->before < b->before) {
    return -1;
  }
  return 1;
}

void ForwardingMap::Sort() {
  typedef int (*CompareFunction)(const void*, const void*);
  qsort(entries_, size_, sizeof(Entry),
        reinterpret_cast<CompareFunction>(CompareEntries));
  sorted_ = true;
}

RawObject* ForwardingMap::Lookup(RawObject* before) {
  ASSERT(sorted_);

  if (!before->IsHeapObject()) {
    return before;
  }

  if (!before->IsOldObject()) {
    return before;
  }

  // Fast path for most popular pointer target.
  if (before == Object::null()) {
    return before;
  }

  intptr_t min = 0;
  intptr_t max = size_ - 1;
  while (min <= max) {
    intptr_t mid = ((max - min) / 2) + min;
    RawObject* key = entries_[mid].before;
    if (key == before) {
      return entries_[mid].after;
    } else if (key < before) {
      min = mid + 1;
    } else {
      max = mid - 1;
    }
  }

  // No entry: not moved.
  return before;
}

// Slides live objects down past free gaps. Keeps cursors pointing to the next
// free and next live chunks, and repeatedly moves the next live chunk to the
// next free chunk. Free space at the end of a page that is too small for the
// next live object is added to the freelist. Empty pages are released.
// Returns the new tail page.
HeapPage* GCCompactor::SlidePages(HeapPage* pages, FreeList* freelist) {
  TIMELINE_FUNCTION_GC_DURATION(thread(), "SlidePages");

  HeapPage* free_page = pages;
  uword free_current = free_page->object_start();
  uword free_end = free_page->object_end();

  HeapPage* live_page = pages;
  while (live_page != NULL) {
    uword live_current = live_page->object_start();
    uword live_end = live_page->object_end();
    while (live_current < live_end) {
      RawObject* old_obj = RawObject::FromAddr(live_current);
      intptr_t size = old_obj->Size();
      if (old_obj->IsMarked()) {
        // Found the next live object.

        if (old_obj->GetClassId() == kClassCid) {
          // Skip space to ensure class objects do not move. Computing the size
          // of larger objects requires consulting their class, whose old body
          // might be overwritten during the sliding.
          // TODO(rmacnak): Keep class sizes off heap or class objects in
          // non-moving pages.

          // Skip pages until class's page.
          while (!free_page->Contains(live_current)) {
            intptr_t free_remaining = free_end - free_current;
            if (free_remaining != 0) {
              freelist->FreeLocked(free_current, free_remaining);
            }
            // And advance to the next free page.
            free_page = free_page->next();
            ASSERT(free_page != NULL);
            free_current = free_page->object_start();
            free_end = free_page->object_end();
          }
          ASSERT(free_page != NULL);

          // Skip within page until class's address.
          intptr_t free_skip = live_current - free_current;
          if (free_skip != 0) {
            freelist->FreeLocked(free_current, free_skip);
            free_current += free_skip;
          }

          // Class object won't move.
          ASSERT(free_current == live_current);
        }

        // Check if the current free page has enough space.
        intptr_t free_remaining = free_end - free_current;
        if (free_remaining < size) {
          if (free_remaining != 0) {
            // Record any remaining space in the current free page.
            // This will be at most kAllocatablePageSize.
            ASSERT(free_remaining >= kObjectAlignment);
            freelist->FreeLocked(free_current, free_remaining);
          }
          // And advance to the next free page.
          free_page = free_page->next();
          ASSERT(free_page != NULL);
          free_current = free_page->object_start();
          free_end = free_page->object_end();
          free_remaining = free_end - free_current;
          ASSERT(free_remaining >= size);
        }

        uword new_addr = free_current;
        free_current += size;

        if (new_addr == live_current) {
          // There's often a large block of objects at the beginning that don't
          // move.
          old_obj->ClearMarkBit();
        } else {
          // Slide the object down to the next free chunk.
          memmove(reinterpret_cast<void*>(new_addr),
                  reinterpret_cast<void*>(live_current), size);

          RawObject* new_obj = RawObject::FromAddr(new_addr);
          new_obj->ClearMarkBit();

          // And record the relocation.
          forwarding_map_.Insert(old_obj, new_obj);
          heap_->ForwardWeakEntries(old_obj, new_obj);
        }
      }
      live_current += size;
    }
    live_page = live_page->next();
  }

  // Add any leftover in the last free page to the freelist.
  intptr_t free_remaining = free_end - free_current;
  if (free_remaining != 0) {
    ASSERT(free_remaining >= kObjectAlignment);
    freelist->FreeLocked(free_current, free_remaining);
  }

  // Free empty pages.
  HeapPage* tail = free_page;
  HeapPage* next = free_page->next();
  free_page->set_next(NULL);
  free_page = next;
  while (free_page != NULL) {
    next = free_page->next();
    heap_->old_space()->IncreaseCapacityInWordsLocked(
        -(free_page->memory_->size() >> kWordSizeLog2));
    free_page->Deallocate();
    free_page = next;
  }
  return tail;
}

void GCCompactor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** ptr = first; ptr <= last; ptr++) {
    RawObject* old_target = *ptr;
    RawObject* new_target = forwarding_map_.Lookup(old_target);
    if (old_target != new_target) {
      *ptr = new_target;
    }
  }
}

void GCCompactor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  RawObject* old_target = handle->raw();
  RawObject* new_target = forwarding_map_.Lookup(old_target);
  if (old_target != new_target) {
    *handle->raw_addr() = new_target;
  }
}

void GCCompactor::ForwardPointers() {
  // N.B.: This pointer visitor is not idempotent. We must take care to visit
  // each pointer exactly once.

  forwarding_map_.Sort();

  TIMELINE_FUNCTION_GC_DURATION(thread(), "ForwardPointers");

  // Heap pointers.
  // N.B.: We forward the heap before forwarding the stack. This limits the
  // amount of following of forwarding pointers needed to get at stack maps.
  heap_->VisitObjectPointers(this);

  // C++ pointers.
  isolate()->VisitObjectPointers(this, StackFrameIterator::kDontValidateFrames);
#ifndef PRODUCT
  if (FLAG_support_service) {
    ObjectIdRing* ring = isolate()->object_id_ring();
    ASSERT(ring != NULL);
    ring->VisitPointers(this);
  }
#endif  // !PRODUCT

  // Weak persistent handles.
  isolate()->VisitWeakPersistentHandles(this);

  // Remembered set.
  isolate()->store_buffer()->VisitObjectPointers(this);
}

// Moves live objects to fresh pages. Returns the number of bytes moved.
intptr_t GCCompactor::EvacuatePages(HeapPage* pages) {
  TIMELINE_FUNCTION_GC_DURATION(thread(), "EvacuatePages");

  intptr_t moved_bytes = 0;
  for (HeapPage* page = pages; page != NULL; page = page->next()) {
    uword old_addr = page->object_start();
    uword end = page->object_end();
    while (old_addr < end) {
      RawObject* old_obj = RawObject::FromAddr(old_addr);
      const intptr_t size = old_obj->Size();
      if (old_obj->IsMarked()) {
        ASSERT(!old_obj->IsFreeListElement());
        ASSERT(!old_obj->IsForwardingCorpse());
        uword new_addr = heap_->old_space()->TryAllocateDataBumpLocked(
            size, PageSpace::kForceGrowth);
        if (new_addr == 0) {
          OUT_OF_MEMORY();
        }

        memmove(reinterpret_cast<void*>(new_addr),
                reinterpret_cast<void*>(old_addr), size);

        RawObject* new_obj = RawObject::FromAddr(new_addr);
        new_obj->ClearMarkBit();

        ForwardingCorpse* forwarder =
            ForwardingCorpse::AsForwarder(old_addr, size);
        forwarder->set_target(new_obj);
        heap_->ForwardWeakEntries(old_obj, new_obj);

        moved_bytes += size;
      }
      old_addr += size;
    }
  }

  return moved_bytes;
}

}  // namespace dart
