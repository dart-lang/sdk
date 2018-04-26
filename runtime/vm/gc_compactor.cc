// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_compactor.h"

#include "vm/become.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/pages.h"
#include "vm/thread_barrier.h"
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

  uword Lookup(uword old_addr) const {
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

  bool IsLive(uword old_addr) const {
    uword block_offset = old_addr & ~kBlockMask;
    intptr_t first_unit_position = block_offset >> kObjectAlignmentLog2;
    ASSERT(first_unit_position < kBitsPerWord);
    return (live_bitvector_ & (static_cast<uword>(1) << first_unit_position)) !=
           0;
  }

  uword new_address() const { return new_address_; }
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

class CompactorTask : public ThreadPool::Task {
 public:
  CompactorTask(Isolate* isolate,
                GCCompactor* compactor,
                ThreadBarrier* barrier,
                intptr_t* next_forwarding_task,
                HeapPage* head,
                HeapPage** tail,
                FreeList* freelist)
      : isolate_(isolate),
        compactor_(compactor),
        barrier_(barrier),
        next_forwarding_task_(next_forwarding_task),
        head_(head),
        tail_(tail),
        freelist_(freelist),
        free_page_(NULL),
        free_current_(0),
        free_end_(0) {}

 private:
  void Run();
  void PlanPage(HeapPage* page);
  void SlidePage(HeapPage* page);
  uword PlanBlock(uword first_object, ForwardingPage* forwarding_page);
  uword SlideBlock(uword first_object, ForwardingPage* forwarding_page);
  void PlanMoveToContiguousSize(intptr_t size);

  Isolate* isolate_;
  GCCompactor* compactor_;
  ThreadBarrier* barrier_;
  intptr_t* next_forwarding_task_;
  HeapPage* head_;
  HeapPage** tail_;
  FreeList* freelist_;
  HeapPage* free_page_;
  uword free_current_;
  uword free_end_;

  DISALLOW_COPY_AND_ASSIGN(CompactorTask);
};

// Slides live objects down past free gaps, updates pointers and frees empty
// pages. Keeps cursors pointing to the next free and next live chunks, and
// repeatedly moves the next live chunk to the next free chunk, one block at a
// time, keeping blocks from spanning page boundries (see ForwardingBlock). Free
// space at the end of a page that is too small for the next block is added to
// the freelist.
void GCCompactor::Compact(HeapPage* pages,
                          FreeList* freelist,
                          Mutex* pages_lock) {
  SetupImagePageBoundaries();

  // Divide the heap.
  // TODO(30978): Try to divide based on live bytes or with work stealing.
  intptr_t num_pages = 0;
  for (HeapPage* page = pages; page != NULL; page = page->next()) {
    num_pages++;
  }

  intptr_t num_tasks = FLAG_compactor_tasks;
  RELEASE_ASSERT(num_tasks >= 1);
  if (num_pages < num_tasks) {
    num_tasks = num_pages;
  }
  HeapPage** heads = new HeapPage*[num_tasks];
  HeapPage** tails = new HeapPage*[num_tasks];

  {
    const intptr_t pages_per_task = num_pages / num_tasks;
    intptr_t task_index = 0;
    intptr_t page_index = 0;
    HeapPage* page = pages;
    HeapPage* prev = NULL;
    while (task_index < num_tasks) {
      if (page_index % pages_per_task == 0) {
        heads[task_index] = page;
        tails[task_index] = NULL;
        if (prev != NULL) {
          prev->set_next(NULL);
        }
        task_index++;
      }
      prev = page;
      page = page->next();
      page_index++;
    }
    ASSERT(page_index <= num_pages);
    ASSERT(task_index == num_tasks);
  }

  {
    ThreadBarrier barrier(num_tasks + 1, heap_->barrier(),
                          heap_->barrier_done());
    intptr_t next_forwarding_task = 0;

    for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
      Dart::thread_pool()->Run(new CompactorTask(
          thread()->isolate(), this, &barrier, &next_forwarding_task,
          heads[task_index], &tails[task_index], freelist));
    }

    // Plan pages.
    barrier.Sync();
    // Slides pages. Forward large pages, new space, etc.
    barrier.Sync();
    barrier.Exit();
  }

  for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
    ASSERT(tails[task_index] != NULL);
  }

  {
    TIMELINE_FUNCTION_GC_DURATION(thread(), "ForwardStackPointers");
    ForwardStackPointers();
  }

  {
    MutexLocker ml(pages_lock);

    // Free empty pages.
    for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
      HeapPage* page = tails[task_index]->next();
      while (page != NULL) {
        HeapPage* next = page->next();
        heap_->old_space()->IncreaseCapacityInWordsLocked(
            -(page->memory_->size() >> kWordSizeLog2));
        page->FreeForwardingPage();
        page->Deallocate();
        page = next;
      }
    }

    // Re-join the heap.
    for (intptr_t task_index = 0; task_index < num_tasks - 1; task_index++) {
      tails[task_index]->set_next(heads[task_index + 1]);
    }
    tails[num_tasks - 1]->set_next(NULL);
    heap_->old_space()->pages_tail_ = tails[num_tasks - 1];

    delete[] heads;
    delete[] tails;
  }

  // Free forwarding information from the suriving pages.
  for (HeapPage* page = pages; page != NULL; page = page->next()) {
    page->FreeForwardingPage();
  }
}

void CompactorTask::Run() {
  bool result =
      Thread::EnterIsolateAsHelper(isolate_, Thread::kCompactorTask, true);
  ASSERT(result);
  NOT_IN_PRODUCT(Thread* thread = Thread::Current());
  {
    {
      TIMELINE_FUNCTION_GC_DURATION(thread, "Plan");
      free_page_ = head_;
      free_current_ = free_page_->object_start();
      free_end_ = free_page_->object_end();

      for (HeapPage* page = head_; page != NULL; page = page->next()) {
        PlanPage(page);
      }
    }

    barrier_->Sync();

    {
      TIMELINE_FUNCTION_GC_DURATION(thread, "Slide");
      free_page_ = head_;
      free_current_ = free_page_->object_start();
      free_end_ = free_page_->object_end();

      for (HeapPage* page = head_; page != NULL; page = page->next()) {
        SlidePage(page);
      }

      // Add any leftover in the last used page to the freelist. This is
      // required to make the page walkable during forwarding, etc.
      intptr_t free_remaining = free_end_ - free_current_;
      if (free_remaining != 0) {
        freelist_->Free(free_current_, free_remaining);
      }

      ASSERT(free_page_ != NULL);
      *tail_ = free_page_;  // Last live page.
    }

    // Heap: Regular pages already visited during sliding. Code and image pages
    // have no pointers to forward. Visit large pages and new-space.

    bool more_forwarding_tasks = true;
    while (more_forwarding_tasks) {
      intptr_t forwarding_task =
          AtomicOperations::FetchAndIncrement(next_forwarding_task_);
      switch (forwarding_task) {
        case 0: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardLargePages");
          for (HeapPage* large_page =
                   isolate_->heap()->old_space()->large_pages_;
               large_page != NULL; large_page = large_page->next()) {
            large_page->VisitObjectPointers(compactor_);
          }
          break;
        }
        case 1: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardNewSpace");
          isolate_->heap()->new_space()->VisitObjectPointers(compactor_);
          break;
        }
        case 2: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardRememberedSet");
          isolate_->store_buffer()->VisitObjectPointers(compactor_);
          break;
        }
        case 3: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardWeakTables");
          isolate_->heap()->ForwardWeakTables(compactor_);
          break;
        }
        case 4: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardWeakHandles");
          isolate_->VisitWeakPersistentHandles(compactor_);
          break;
        }
#ifndef PRODUCT
        case 5: {
          if (FLAG_support_service) {
            TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardObjectIdRing");
            isolate_->object_id_ring()->VisitPointers(compactor_);
          }
          break;
        }
#endif  // !PRODUCT
        default:
          more_forwarding_tasks = false;
      }
    }

    barrier_->Sync();
  }
  Thread::ExitIsolateAsHelper(true);

  // This task is done. Notify the original thread.
  barrier_->Exit();
}

void CompactorTask::PlanPage(HeapPage* page) {
  uword current = page->object_start();
  uword end = page->object_end();

  ForwardingPage* forwarding_page = page->AllocateForwardingPage();
  while (current < end) {
    current = PlanBlock(current, forwarding_page);
  }
}

void CompactorTask::SlidePage(HeapPage* page) {
  uword current = page->object_start();
  uword end = page->object_end();

  ForwardingPage* forwarding_page = page->forwarding_page();
  while (current < end) {
    current = SlideBlock(current, forwarding_page);
  }
}

// Plans the destination for a set of live objects starting with the first
// live object that starts in a block, up to and including the last live
// object that starts in that block.
uword CompactorTask::PlanBlock(uword first_object,
                               ForwardingPage* forwarding_page) {
  uword block_start = first_object & kBlockMask;
  uword block_end = block_start + kBlockSize;
  ForwardingBlock* forwarding_block = forwarding_page->BlockFor(first_object);

  // 1. Compute bitvector of surviving allocation units in the block.
  intptr_t block_live_size = 0;
  intptr_t block_dead_size = 0;
  uword current = first_object;
  while (current < block_end) {
    RawObject* obj = RawObject::FromAddr(current);
    intptr_t size = obj->Size();
    if (obj->IsMarked()) {
      forwarding_block->RecordLive(current, size);
      ASSERT(static_cast<intptr_t>(forwarding_block->Lookup(current)) ==
             block_live_size);
      block_live_size += size;
    } else {
      block_dead_size += size;
    }
    current += size;
  }

  // 2. Find the next contiguous space that can fit the live objects that
  // start in the block.
  PlanMoveToContiguousSize(block_live_size);
  forwarding_block->set_new_address(free_current_);
  free_current_ += block_live_size;

  return current;  // First object in the next block
}

uword CompactorTask::SlideBlock(uword first_object,
                                ForwardingPage* forwarding_page) {
  uword block_start = first_object & kBlockMask;
  uword block_end = block_start + kBlockSize;
  ForwardingBlock* forwarding_block = forwarding_page->BlockFor(first_object);

  uword old_addr = first_object;
  while (old_addr < block_end) {
    RawObject* old_obj = RawObject::FromAddr(old_addr);
    intptr_t size = old_obj->Size();
    if (old_obj->IsMarked()) {
      uword new_addr = forwarding_block->Lookup(old_addr);
      if (new_addr != free_current_) {
        ASSERT(HeapPage::Of(free_current_) != HeapPage::Of(new_addr));
        intptr_t free_remaining = free_end_ - free_current_;
        // Add any leftover at the end of a page to the free list.
        if (free_remaining > 0) {
          freelist_->Free(free_current_, free_remaining);
        }
        free_page_ = free_page_->next();
        ASSERT(free_page_ != NULL);
        free_current_ = free_page_->object_start();
        free_end_ = free_page_->object_end();
        ASSERT(free_current_ == new_addr);
      }
      RawObject* new_obj = RawObject::FromAddr(new_addr);

      // Fast path for no movement. There's often a large block of objects at
      // the beginning that don't move.
      if (new_addr != old_addr) {
        // Slide the object down.
        memmove(reinterpret_cast<void*>(new_addr),
                reinterpret_cast<void*>(old_addr), size);
      }
      new_obj->ClearMarkBit();
      new_obj->VisitPointers(compactor_);

      ASSERT(free_current_ == new_addr);
      free_current_ += size;
    } else {
      ASSERT(!forwarding_block->IsLive(old_addr));
    }
    old_addr += size;
  }

  return old_addr;  // First object in the next block.
}

void CompactorTask::PlanMoveToContiguousSize(intptr_t size) {
  // Move the free cursor to ensure 'size' bytes of contiguous space.
  ASSERT(size <= kPageSize);

  // Check if the current free page has enough space.
  intptr_t free_remaining = free_end_ - free_current_;
  if (free_remaining < size) {
    // Not enough; advance to the next free page.
    free_page_ = free_page_->next();
    ASSERT(free_page_ != NULL);
    free_current_ = free_page_->object_start();
    free_end_ = free_page_->object_end();
    free_remaining = free_end_ - free_current_;
    ASSERT(free_remaining >= size);
  }
}

void GCCompactor::SetupImagePageBoundaries() {
  for (intptr_t i = 0; i < kMaxImagePages; i++) {
    image_page_ranges_[i].base = 0;
    image_page_ranges_[i].size = 0;
  }
  intptr_t next_offset = 0;
  HeapPage* image_page = Dart::vm_isolate()->heap()->old_space()->image_pages_;
  while (image_page != NULL) {
    RELEASE_ASSERT(next_offset <= kMaxImagePages);
    image_page_ranges_[next_offset].base = image_page->object_start();
    image_page_ranges_[next_offset].size =
        image_page->object_end() - image_page->object_start();
    image_page = image_page->next();
    next_offset++;
  }
  image_page = heap_->old_space()->image_pages_;
  while (image_page != NULL) {
    RELEASE_ASSERT(next_offset <= kMaxImagePages);
    image_page_ranges_[next_offset].base = image_page->object_start();
    image_page_ranges_[next_offset].size =
        image_page->object_end() - image_page->object_start();
    image_page = image_page->next();
    next_offset++;
  }
}

DART_FORCE_INLINE
void GCCompactor::ForwardPointer(RawObject** ptr) {
  RawObject* old_target = *ptr;
  if (old_target->IsSmiOrNewObject()) {
    return;  // Not moved.
  }

  uword old_addr = RawObject::ToAddr(old_target);
  for (intptr_t i = 0; i < kMaxImagePages; i++) {
    if ((old_addr - image_page_ranges_[i].base) < image_page_ranges_[i].size) {
      return;  // Not moved (unaligned image page).
    }
  }

  HeapPage* page = HeapPage::Of(old_target);
  ForwardingPage* forwarding_page = page->forwarding_page();
  if (forwarding_page == NULL) {
    return;  // Not moved (VM isolate, large page, code page).
  }

  RawObject* new_target =
      RawObject::FromAddr(forwarding_page->Lookup(old_addr));
  *ptr = new_target;
}

// N.B.: This pointer visitor is not idempotent. We must take care to visit
// each pointer exactly once.
void GCCompactor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** ptr = first; ptr <= last; ptr++) {
    ForwardPointer(ptr);
  }
}

void GCCompactor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  ForwardPointer(handle->raw_addr());
}

void GCCompactor::ForwardStackPointers() {
  // N.B.: Heap pointers have already been forwarded. We forward the heap before
  // forwarding the stack to limit the number of places that need to be aware of
  // forwarding when reading stack maps.
  isolate()->VisitObjectPointers(this, StackFrameIterator::kDontValidateFrames);
}

}  // namespace dart
