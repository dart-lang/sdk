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

static const intptr_t kBitVectorWordsPerBlock = 1;
static const intptr_t kBlockSize =
    kObjectAlignment * kBitsPerWord * kBitVectorWordsPerBlock;
static const intptr_t kBlockMask = ~(kBlockSize - 1);
static const intptr_t kBlocksPerPage = kPageSize / kBlockSize;

// Each HeapPage is divided into blocks of size kBlockSize. Each object belongs
// to the block containing its header word (so up to kBlockSize +
// kAllocatablePageSize - 2 * kObjectAlignment bytes belong to the same block).
// During compaction, all live objects in the same block will slide such that
// they all end up on the same HeapPage, and all gaps within the block will be
// closed. During sliding, a bitvector is computed that indictates which
// allocation units are live, so the new address of any object in the block can
// be found by adding the number of live allocation units before the object to
// the block's new start address.
class ForwardingBlock {
 public:
  ForwardingBlock() : new_address_(0), live_bitvector_(0) {}

  uword Lookup(uword old_addr) {
    uword block_offset = old_addr & ~kBlockMask;
    intptr_t first_unit_position = block_offset >> kObjectAlignmentLog2;
    ASSERT(first_unit_position < kBitsPerWord);
    uword preceding_live_bitmask =
        (static_cast<uword>(1) << first_unit_position) - 1;
    uword preceding_live_bitset = live_bitvector_ & preceding_live_bitmask;
    uword preceding_live_bytes = Utils::CountOneBitsWord(preceding_live_bitset)
                                 << kObjectAlignmentLog2;
    return new_address_ + preceding_live_bytes;
  }

  // Marks a range of allocation units belonging to an object live by setting
  // the corresponding bits in this ForwardingBlock.  Does not update the
  // new_address_ field; that is done after the total live size of the block is
  // known and forwarding location is choosen. Does not mark words in subsequent
  // ForwardingBlocks live for objects that extend into the next block.
  void RecordLive(uword old_addr, intptr_t size) {
    intptr_t size_in_units = size >> kObjectAlignmentLog2;
    if (size_in_units >= kBitsPerWord) {
      size_in_units = kBitsPerWord - 1;
    }
    uword block_offset = old_addr & ~kBlockMask;
    intptr_t first_unit_position = block_offset >> kObjectAlignmentLog2;
    ASSERT(first_unit_position < kBitsPerWord);
    live_bitvector_ |= ((static_cast<uword>(1) << size_in_units) - 1)
                       << first_unit_position;
  }

  // Marks all bits after a given address. This is used to ensure that some
  // objects do not move (classes).
  void MarkAllFrom(uword start_addr) {
    uword block_offset = start_addr & ~kBlockMask;
    intptr_t first_unit_position = block_offset >> kObjectAlignmentLog2;
    ASSERT(first_unit_position < kBitsPerWord);
    live_bitvector_ = static_cast<uword>(-1) << first_unit_position;
  }

  void set_new_address(uword value) { new_address_ = value; }

 private:
  uword new_address_;
  uword live_bitvector_;
  COMPILE_ASSERT(kBitVectorWordsPerBlock == 1);

  DISALLOW_COPY_AND_ASSIGN(ForwardingBlock);
};

class ForwardingPage {
 public:
  ForwardingPage() : blocks_() {}

  uword Lookup(uword old_addr) { return BlockFor(old_addr)->Lookup(old_addr); }

  ForwardingBlock* BlockFor(uword old_addr) {
    intptr_t page_offset = old_addr & ~kPageMask;
    intptr_t block_number = page_offset / kBlockSize;
    ASSERT(block_number >= 0);
    ASSERT(block_number <= kBlocksPerPage);
    return &blocks_[block_number];
  }

 private:
  ForwardingBlock blocks_[kBlocksPerPage];

  DISALLOW_COPY_AND_ASSIGN(ForwardingPage);
};

ForwardingPage* HeapPage::AllocateForwardingPage() {
  ASSERT(forwarding_page_ == NULL);
  forwarding_page_ = new ForwardingPage();
  return forwarding_page_;
}

void HeapPage::FreeForwardingPage() {
  ASSERT(forwarding_page_ != NULL);
  delete forwarding_page_;
  forwarding_page_ = NULL;
}

// Slides live objects down past free gaps, updates pointers and frees empty
// pages. Keeps cursors pointing to the next free and next live chunks, and
// repeatedly moves the next live chunk to the next free chunk, one block at a
// time, keeping blocks from spanning page boundries (see ForwardingBlock). Free
// space at the end of a page that is too small for the next block is added to
// the freelist.
void GCCompactor::CompactBySliding(HeapPage* pages,
                                   FreeList* freelist,
                                   Mutex* pages_lock) {
  {
    TIMELINE_FUNCTION_GC_DURATION(thread(), "SlideObjects");
    MutexLocker ml(pages_lock);

    free_page_ = pages;
    free_current_ = free_page_->object_start();
    free_end_ = free_page_->object_end();
    freelist_ = freelist;

    HeapPage* live_page = pages;
    while (live_page != NULL) {
      SlidePage(live_page);
      live_page = live_page->next();
    }

    // Add any leftover in the last used page to the freelist. This is required
    // to make the page walkable during forwarding, etc.
    intptr_t free_remaining = free_end_ - free_current_;
    if (free_remaining != 0) {
      ASSERT(free_remaining >= kObjectAlignment);
      freelist->FreeLocked(free_current_, free_remaining);
    }

    // Unlink empty pages so they will not be visited during forwarding.
    // We cannot deallocate them until forwarding is complete.
    HeapPage* tail = free_page_;
    HeapPage* first_unused_page = tail->next();
    tail->set_next(NULL);
    heap_->old_space()->pages_tail_ = tail;
    free_page_ = first_unused_page;
  }

  {
    TIMELINE_FUNCTION_GC_DURATION(thread(), "ForwardPointers");
    ForwardPointersForSliding();
  }

  {
    MutexLocker ml(pages_lock);

    // Free empty pages.
    HeapPage* page = free_page_;
    while (page != NULL) {
      HeapPage* next = page->next();
      heap_->old_space()->IncreaseCapacityInWordsLocked(
          -(page->memory_->size() >> kWordSizeLog2));
      page->FreeForwardingPage();
      page->Deallocate();
      page = next;
    }
  }

  // Free forwarding information from the suriving pages.
  for (HeapPage* page = pages; page != NULL; page = page->next()) {
    page->FreeForwardingPage();
  }
}

void GCCompactor::SlidePage(HeapPage* page) {
  uword current = page->object_start();
  uword end = page->object_end();

  ForwardingPage* forwarding_page = page->AllocateForwardingPage();
  while (current < end) {
    current = SlideBlock(current, forwarding_page);
  }
}

uword GCCompactor::SlideBlock(uword first_object,
                              ForwardingPage* forwarding_page) {
  uword start = first_object & kBlockMask;
  uword end = start + kBlockSize;
  ForwardingBlock* forwarding_block = forwarding_page->BlockFor(first_object);

  // 1. Compute bitvector of surviving allocation units in the block.
  bool has_class = false;
  intptr_t block_live_size = 0;
  uword current = first_object;
  while (current < end) {
    RawObject* obj = RawObject::FromAddr(current);
    intptr_t size = obj->Size();
    if (obj->IsMarked()) {
      if (obj->GetClassId() == kClassCid) {
        has_class = true;
      }
      forwarding_block->RecordLive(current, size);
      ASSERT(static_cast<intptr_t>(forwarding_block->Lookup(current)) ==
             block_live_size);
      block_live_size += size;
    }
    current += size;
  }

  // 2. Find the next contiguous space that can fit the block.
  if (has_class) {
    // This will waste the space used by dead objects that are before the class
    // object.
    MoveToExactAddress(first_object);
    ASSERT(free_current_ == first_object);

    // This is not MarkAll because the first part of a block might
    // be the tail end of an object belonging to the previous block
    // or the page header.
    forwarding_block->MarkAllFrom(first_object);
    ASSERT(forwarding_block->Lookup(first_object) == 0);
  } else {
    MoveToContiguousSize(block_live_size);
  }
  forwarding_block->set_new_address(free_current_);

  // 3. Move objects in the block.
  uword old_addr = first_object;
  while (old_addr < end) {
    RawObject* old_obj = RawObject::FromAddr(old_addr);
    intptr_t size = old_obj->Size();
    if (old_obj->IsMarked()) {
      // Assert the current free page has enough space. This we hold because we
      // grabbed space for the whole block up front.
      intptr_t free_remaining = free_end_ - free_current_;
      ASSERT(free_remaining >= size);

      uword new_addr = free_current_;
      free_current_ += size;
      RawObject* new_obj = RawObject::FromAddr(new_addr);

      ASSERT(forwarding_page->Lookup(old_addr) == new_addr);

      // Fast path for no movement. There's often a large block of objects at
      // the beginning that don't move.
      if (new_addr != old_addr) {
        ASSERT(old_obj->GetClassId() != kClassCid);

        // Slide the object down.
        memmove(reinterpret_cast<void*>(new_addr),
                reinterpret_cast<void*>(old_addr), size);

        // TODO(rmacnak): Most objects do not have weak table entries.
        // For both compaction and become, it's probably faster to visit
        // the weak tables once during forwarding instead of per-object.
        heap_->ForwardWeakEntries(old_obj, new_obj);
      }
      new_obj->ClearMarkBit();
    } else {
      if (has_class) {
        // Add to free list; note we're not bothering to coalesce here.
        freelist_->FreeLocked(old_addr, size);
        free_current_ += size;
      }
    }
    old_addr += size;
  }

  return old_addr;  // First object in the next block.
}

void GCCompactor::MoveToExactAddress(uword addr) {
  // Skip space to ensure class objects do not move. Computing the size
  // of larger objects requires consulting their class, whose old body
  // might be overwritten during the sliding.
  // TODO(rmacnak): Keep class sizes off heap or class objects in
  // non-moving pages.

  // Skip pages until class's page.
  while (!free_page_->Contains(addr)) {
    intptr_t free_remaining = free_end_ - free_current_;
    if (free_remaining != 0) {
      // Note we aren't bothering to check for a whole page to release.
      freelist_->FreeLocked(free_current_, free_remaining);
    }
    // And advance to the next free page.
    free_page_ = free_page_->next();
    ASSERT(free_page_ != NULL);
    free_current_ = free_page_->object_start();
    free_end_ = free_page_->object_end();
  }
  ASSERT(free_page_ != NULL);

  // Skip within page until class's address.
  intptr_t free_skip = addr - free_current_;
  if (free_skip != 0) {
    freelist_->FreeLocked(free_current_, free_skip);
    free_current_ += free_skip;
  }

  // Class object won't move.
  ASSERT(free_current_ == addr);
}

void GCCompactor::MoveToContiguousSize(intptr_t size) {
  // Move the free cursor to ensure 'size' bytes of contiguous space.
  ASSERT(size <= kPageSize);

  // Check if the current free page has enough space.
  intptr_t free_remaining = free_end_ - free_current_;
  if (free_remaining < size) {
    if (free_remaining != 0) {
      freelist_->FreeLocked(free_current_, free_remaining);
    }
    // And advance to the next free page.
    free_page_ = free_page_->next();
    ASSERT(free_page_ != NULL);
    free_current_ = free_page_->object_start();
    free_end_ = free_page_->object_end();
    free_remaining = free_end_ - free_current_;
    ASSERT(free_remaining >= size);
  }
}

DART_FORCE_INLINE
static void ForwardPointerForSliding(RawObject** ptr) {
  RawObject* old_target = *ptr;
  if (old_target->IsSmiOrNewObject()) {
    return;  // Not moved.
  }
  HeapPage* page = HeapPage::Of(old_target);
  ForwardingPage* forwarding_page = page->forwarding_page();
  if (forwarding_page == NULL) {
    return;  // Not moved (VM isolate, image page, large page, code page).
  }
  RawObject* new_target = RawObject::FromAddr(
      forwarding_page->Lookup(RawObject::ToAddr(old_target)));
  *ptr = new_target;
}

void GCCompactor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** ptr = first; ptr <= last; ptr++) {
    ForwardPointerForSliding(ptr);
  }
}

void GCCompactor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  ForwardPointerForSliding(handle->raw_addr());
}

void GCCompactor::ForwardPointersForSliding() {
  // N.B.: This pointer visitor is not idempotent. We must take care to visit
  // each pointer exactly once.

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
