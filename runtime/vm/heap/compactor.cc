// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/compactor.h"

#include "platform/atomic.h"
#include "vm/globals.h"
#include "vm/heap/become.h"
#include "vm/heap/heap.h"
#include "vm/heap/pages.h"
#include "vm/thread_barrier.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool,
            force_evacuation,
            false,
            "Force compaction to move every movable object");

typedef uint64_t bitset;

static const intptr_t kBitVectorWordsPerBlock = 1;
// The block size in bytes. One uword is used as a bit vector to keep track
// of the sections-buckets in the block that are used. In 64 bit architectures,
// buckets are of size 16 bytes ("alignment"), or in other words objects
// are placed at addresses multiples of 16 bytes. A bit vector of 64
// bits represents up to 64 buckets and that's why block size
// is defined to be 64*16 bytes (1024 bytes). In 32 bit architectures,
// aligments are of size 8 bytes and the bit vector is of size 32, therefore
// the block size is 32*8 (256 byes).
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
  void Clear() {
    new_address_ = 0;
    // live_bitvector is used to track the used byte buckets in the block.
    // Each bucket represents a size 16 or 8 bytes depending on the architecture.
    // Only live objects use buckets, so the live_bitvector can be a vector
    // like 111000110011, where the 0s represent "dead" (garbage) space.
    // It's used to count the number of used ("live") buckets up to a any bucket
    // index, which in turn is used to calculate the forwarding address of a
    // an old address in Lookup. As an example if an object is stored from
    // bucket 16 (deduced from the address) and only 8 buckets are used up to
    // index 16 (vector has only 8 bits set in the first 15 bits), the object's
    // new address will represent bucket 9 of the forwarding block (the object
    // is "slided" down).
    live_bitvector_ = 0;
  }

  intptr_t ComputeLiveVectorPosition(uword address) const {
    uword block_offset = address & ~kBlockMask;
    intptr_t first_unit_position = block_offset >> kObjectAlignmentLog2;
    ASSERT(first_unit_position < kBitsPerWord);
#if !defined(HASH_IN_OBJECT_HEADER)
    // In 32 bit platforms the previous objects might take one extra live space
    // to store the hashCode when reallocated. The position is duplicated to
    // take into account this extra size. In theory a block can increase in
    // size when sliding.
    first_unit_position <<= 1;
#endif
    return first_unit_position;
  }

  uword Lookup(uword old_addr) const {
    intptr_t first_unit_position = ComputeLiveVectorPosition(old_addr);
    bitset preceding_live_bitmask =
        (static_cast<bitset>(1) << first_unit_position) - 1;
    bitset preceding_live_bitset = live_bitvector_ & preceding_live_bitmask;
    bitset preceding_live_bytes = Utils::CountOneBitsWord(preceding_live_bitset)
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
    intptr_t first_unit_position = ComputeLiveVectorPosition(old_addr);
    live_bitvector_ |= ((static_cast<bitset>(1) << size_in_units) - 1)
                       << first_unit_position;
  }

  bool IsLive(uword old_addr) const {
    intptr_t first_unit_position = ComputeLiveVectorPosition(old_addr);
    return (live_bitvector_ &
            (static_cast<bitset>(1) << first_unit_position)) != 0;
  }

  uword new_address() const { return new_address_; }
  void set_new_address(uword value) { new_address_ = value; }

 private:
  uword new_address_;
  bitset live_bitvector_;
  COMPILE_ASSERT(kBitVectorWordsPerBlock == 1);

  DISALLOW_COPY_AND_ASSIGN(ForwardingBlock);
};

class ForwardingPage {
 public:
  void Clear() {
    for (intptr_t i = 0; i < kBlocksPerPage; i++) {
      blocks_[i].Clear();
    }
  }

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

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ForwardingPage);
};

void HeapPage::AllocateForwardingPage() {
  ASSERT(forwarding_page_ == NULL);
  ASSERT((object_start() + sizeof(ForwardingPage)) < object_end());
  ASSERT(Utils::IsAligned(sizeof(ForwardingPage), kObjectAlignment));
  object_end_ -= sizeof(ForwardingPage);
  forwarding_page_ = reinterpret_cast<ForwardingPage*>(object_end_);
}

class CompactorTask : public ThreadPool::Task {
 public:
  CompactorTask(Isolate* isolate,
                GCCompactor* compactor,
                ThreadBarrier* barrier,
                RelaxedAtomic<intptr_t>* next_forwarding_task,
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
  RelaxedAtomic<intptr_t>* next_forwarding_task_;
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
// time, keeping blocks from spanning page boundaries (see ForwardingBlock).
// Free space at the end of a page that is too small for the next block is
// added to the freelist.
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

  if (FLAG_force_evacuation) {
    // Inject empty pages at the beginning of each worker's list to ensure all
    // objects move and all pages that used to have an object are released.
    // This can be helpful for finding untracked pointers because it prevents
    // an untracked pointer from getting lucky with its target not moving.
    bool oom = false;
    for (intptr_t task_index = 0; task_index < num_tasks && !oom;
         task_index++) {
      const intptr_t pages_per_task = num_pages / num_tasks;
      for (intptr_t j = 0; j < pages_per_task; j++) {
        HeapPage* page = heap_->old_space()->AllocatePage(HeapPage::kData,
                                                          /* link */ false);

        if (page == nullptr) {
          oom = true;
          break;
        }

        FreeListElement::AsElement(page->object_start(),
                                   page->object_end() - page->object_start());

        // The compactor slides down: add the empty pages to the beginning.
        page->set_next(heads[task_index]);
        heads[task_index] = page;
      }
    }
  }

  {
    ThreadBarrier barrier(num_tasks + 1, heap_->barrier(),
                          heap_->barrier_done());
    RelaxedAtomic<intptr_t> next_forwarding_task = {0};

    for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
      Dart::thread_pool()->Run<CompactorTask>(
          thread()->isolate(), this, &barrier, &next_forwarding_task,
          heads[task_index], &tails[task_index], freelist);
    }

    // Plan pages.
    barrier.Sync();
    // Slides pages. Forward large pages, new space, etc.
    barrier.Sync();
    barrier.Exit();
  }

  // Update inner pointers in typed data views (needs to be done after all
  // threads are done with sliding since we need to access fields of the
  // view's backing store)
  //
  // (If the sliding compactor was single-threaded we could do this during the
  // sliding phase: The class id of the backing store can be either accessed by
  // looking at the already-slided-object or the not-yet-slided object. Though
  // with parallel sliding there is no safe way to access the backing store
  // object header.)
  {
    TIMELINE_FUNCTION_GC_DURATION(thread(),
                                  "ForwardTypedDataViewInternalPointers");
    const intptr_t length = typed_data_views_.length();
    for (intptr_t i = 0; i < length; ++i) {
      auto raw_view = typed_data_views_[i];
      const classid_t cid = raw_view->ptr()->typed_data_->GetClassIdMayBeSmi();

      // If we have external typed data we can simply return, since the backing
      // store lives in C-heap and will not move. Otherwise we have to update
      // the inner pointer.
      if (RawObject::IsTypedDataClassId(cid)) {
        raw_view->RecomputeDataFieldForInternalTypedData();
      } else {
        ASSERT(RawObject::IsExternalTypedDataClassId(cid));
      }
    }
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
        page->Deallocate();
        page = next;
      }
    }

    // Re-join the heap.
    for (intptr_t task_index = 0; task_index < num_tasks - 1; task_index++) {
      tails[task_index]->set_next(heads[task_index + 1]);
    }
    tails[num_tasks - 1]->set_next(NULL);
    heap_->old_space()->pages_ = pages = heads[0];
    heap_->old_space()->pages_tail_ = tails[num_tasks - 1];

    delete[] heads;
    delete[] tails;
  }
}

void CompactorTask::Run() {
  bool result =
      Thread::EnterIsolateAsHelper(isolate_, Thread::kCompactorTask, true);
  ASSERT(result);
#ifdef SUPPORT_TIMELINE
  Thread* thread = Thread::Current();
#endif
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
      intptr_t forwarding_task = next_forwarding_task_->fetch_add(1u);
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

  ForwardingPage* forwarding_page = page->forwarding_page();
  ASSERT(forwarding_page != nullptr);
  forwarding_page->Clear();
  while (current < end) {
    current = PlanBlock(current, forwarding_page);
  }
}

void CompactorTask::SlidePage(HeapPage* page) {
  uword current = page->object_start();
  uword end = page->object_end();

  ForwardingPage* forwarding_page = page->forwarding_page();
  ASSERT(forwarding_page != nullptr);
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
    intptr_t size = obj->HeapSize();
    if (obj->IsMarked()) {
#if !defined(HASH_IN_OBJECT_HEADER)  // 32 bit platform
      intptr_t extra_size = 0;
      // The first reallocated object that were to take more space (because
      // they can grow to store the hashCode) than the currently available
      // would be "reallocated" to the same address. So if free_current_ +
      // block_live_size matches the current address the object is not going
      // to be reallocated and it will not use extra memory. This way it
      // is ensured that sliding will never take more memory than the currently
      // available or that the reallocated object overlaps the memory of the
      // next live object.
      if (free_current_ + block_live_size != current) {
        // In 32 bit platforms if the adresses don't match, the object will be
        // reallocated and it might require extra space for the hashCode.
        extra_size = obj->ReallocationExtraSize();
        size += extra_size;
      }
#endif
      forwarding_block->RecordLive(current, size);
      ASSERT(static_cast<intptr_t>(forwarding_block->Lookup(current)) ==
             block_live_size);
      block_live_size += size;
#if !defined(HASH_IN_OBJECT_HEADER)
      // Restore size to the object's size.
      size -= extra_size;
#endif
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
#if !defined(HASH_IN_OBJECT_HEADER)  // 32 bit platform
    intptr_t extra_size = 0;
#endif
    RawObject* old_obj = RawObject::FromAddr(old_addr);
    intptr_t size = old_obj->HeapSize();
    if (old_obj->IsMarked()) {
      uword new_addr = forwarding_block->Lookup(old_addr);
      if (new_addr != free_current_) {
        // The only situation where these two don't match is if we are moving
        // to a new page.  But if we exactly hit the end of the previous page
        // then free_current could be at the start of the next page, so we
        // subtract 1.
        // Question: how can that happen? Wouldn't that mean end of page was
        // written? Isn't end of page used to store the forwarding page?
        ASSERT(HeapPage::Of(free_current_ - 1) != HeapPage::Of(new_addr));
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
#if !defined(HASH_IN_OBJECT_HEADER)  // 32 bit platform
        extra_size = old_obj->ReallocationExtraSize();
#endif
        // Slide the object down.
        old_obj->Reallocate(new_addr, size);
        // memmove(reinterpret_cast<void*>(new_addr),
        //         reinterpret_cast<void*>(old_addr), size);

        if (RawObject::IsTypedDataClassId(new_obj->GetClassId())) {
          reinterpret_cast<RawTypedData*>(new_obj)->RecomputeDataField();
        }
      }
      new_obj->ClearMarkBit();
      new_obj->VisitPointers(compactor_);

      ASSERT(free_current_ == new_addr);
      free_current_ += size;
#if !defined(HASH_IN_OBJECT_HEADER)  // 32 bit platform
      free_current_ += extra_size;
      extra_size = 0;
#endif
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
  ASSERT(!new_target->IsSmiOrNewObject());
  *ptr = new_target;
}

void GCCompactor::VisitTypedDataViewPointers(RawTypedDataView* view,
                                             RawObject** first,
                                             RawObject** last) {
  // First we forward all fields of the typed data view.
  RawObject* old_backing = view->ptr()->typed_data_;
  VisitPointers(first, last);
  RawObject* new_backing = view->ptr()->typed_data_;

  const bool backing_moved = old_backing != new_backing;
  if (backing_moved) {
    // The backing store moved, so we *might* need to update the view's inner
    // pointer. If the backing store is internal typed data we *have* to update
    // it, otherwise (in case of external typed data) we don't have to.
    //
    // Unfortunately we cannot find out whether the backing store is internal
    // or external during sliding phase: Even though we know the old and new
    // location of the backing store another thread might be responsible for
    // moving it and we have no way to tell when it got moved.
    //
    // So instead we queue all those views up and fix their inner pointer in a
    // final phase after compaction.
    MutexLocker ml(&typed_data_view_mutex_);
    typed_data_views_.Add(view);
  } else {
    // The backing store didn't move, we therefore don't need to update the
    // inner pointer.
    if (view->ptr()->data_ == 0) {
      ASSERT(ValueFromRawSmi(view->ptr()->offset_in_bytes_) == 0 &&
             ValueFromRawSmi(view->ptr()->length_) == 0 &&
             view->ptr()->typed_data_ == Object::null());
    }
  }
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
  isolate()->VisitObjectPointers(this, ValidationPolicy::kDontValidateFrames);
}

}  // namespace dart
