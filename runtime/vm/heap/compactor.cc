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

// Each Page is divided into blocks of size kBlockSize. Each object belongs
// to the block containing its header word (so up to kBlockSize +
// kAllocatablePageSize - 2 * kObjectAlignment bytes belong to the same block).
// During compaction, all live objects in the same block will slide such that
// they all end up on the same Page, and all gaps within the block will be
// closed. During sliding, a bitvector is computed that indicates which
// allocation units are live, so the new address of any object in the block can
// be found by adding the number of live allocation units before the object to
// the block's new start address.
// Compare CountingBlock used for heap snapshot generation.
class ForwardingBlock {
 public:
  void Clear() {
    new_address_ = 0;
    live_bitvector_ = 0;
  }

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
  // known and forwarding location is chosen. Does not mark words in subsequent
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

void Page::AllocateForwardingPage() {
  ASSERT(forwarding_page_ == nullptr);
  ASSERT((object_start() + sizeof(ForwardingPage)) < object_end());
  ASSERT(Utils::IsAligned(sizeof(ForwardingPage), kObjectAlignment));
  top_ -= sizeof(ForwardingPage);
  forwarding_page_ = reinterpret_cast<ForwardingPage*>(top_);
}

struct Partition {
  Page* head;
  Page* tail;
};

class CompactorTask : public ThreadPool::Task {
 public:
  CompactorTask(IsolateGroup* isolate_group,
                GCCompactor* compactor,
                ThreadBarrier* barrier,
                RelaxedAtomic<intptr_t>* next_planning_task,
                RelaxedAtomic<intptr_t>* next_sliding_task,
                RelaxedAtomic<intptr_t>* next_forwarding_task,
                intptr_t num_tasks,
                Partition* partitions,
                FreeList* freelist)
      : isolate_group_(isolate_group),
        compactor_(compactor),
        barrier_(barrier),
        next_planning_task_(next_planning_task),
        next_sliding_task_(next_sliding_task),
        next_forwarding_task_(next_forwarding_task),
        num_tasks_(num_tasks),
        partitions_(partitions),
        freelist_(freelist),
        free_page_(nullptr),
        free_current_(0),
        free_end_(0) {}

  void Run();
  void RunEnteredIsolateGroup();

 private:
  void PlanPage(Page* page);
  void SlidePage(Page* page);
  uword PlanBlock(uword first_object, ForwardingPage* forwarding_page);
  uword SlideBlock(uword first_object, ForwardingPage* forwarding_page);
  void PlanMoveToContiguousSize(intptr_t size);

  IsolateGroup* isolate_group_;
  GCCompactor* compactor_;
  ThreadBarrier* barrier_;
  RelaxedAtomic<intptr_t>* next_planning_task_;
  RelaxedAtomic<intptr_t>* next_sliding_task_;
  RelaxedAtomic<intptr_t>* next_forwarding_task_;
  intptr_t num_tasks_;
  Partition* partitions_;
  FreeList* freelist_;
  Page* free_page_;
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
void GCCompactor::Compact(Page* pages, FreeList* freelist, Mutex* pages_lock) {
  SetupImagePageBoundaries();

  // Divide the heap.
  // TODO(30978): Try to divide based on live bytes or with work stealing.
  intptr_t num_pages = 0;
  for (Page* page = pages; page != nullptr; page = page->next()) {
    num_pages++;
  }

  intptr_t num_tasks = FLAG_compactor_tasks;
  RELEASE_ASSERT(num_tasks >= 1);
  if (num_pages < num_tasks) {
    num_tasks = num_pages;
  }

  Partition* partitions = new Partition[num_tasks];

  {
    const intptr_t pages_per_task = num_pages / num_tasks;
    intptr_t task_index = 0;
    intptr_t page_index = 0;
    Page* page = pages;
    Page* prev = nullptr;
    while (task_index < num_tasks) {
      if (page_index % pages_per_task == 0) {
        partitions[task_index].head = page;
        partitions[task_index].tail = nullptr;
        if (prev != nullptr) {
          prev->set_next(nullptr);
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
        Page* page = heap_->old_space()->AllocatePage(/* exec */ false,
                                                      /* link */ false);

        if (page == nullptr) {
          oom = true;
          break;
        }

        FreeListElement::AsElement(page->object_start(),
                                   page->object_end() - page->object_start());

        // The compactor slides down: add the empty pages to the beginning.
        page->set_next(partitions[task_index].head);
        partitions[task_index].head = page;
      }
    }
  }

  {
    ThreadBarrier* barrier = new ThreadBarrier(num_tasks, 1);
    RelaxedAtomic<intptr_t> next_planning_task = {0};
    RelaxedAtomic<intptr_t> next_sliding_task = {0};
    RelaxedAtomic<intptr_t> next_forwarding_task = {0};

    for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
      if (task_index < (num_tasks - 1)) {
        // Begin compacting on a helper thread.
        Dart::thread_pool()->Run<CompactorTask>(
            thread()->isolate_group(), this, barrier, &next_planning_task,
            &next_sliding_task, &next_forwarding_task, num_tasks, partitions,
            freelist);
      } else {
        // Last worker is the main thread.
        CompactorTask task(thread()->isolate_group(), this, barrier,
                           &next_planning_task, &next_sliding_task,
                           &next_forwarding_task, num_tasks, partitions,
                           freelist);
        task.RunEnteredIsolateGroup();
        barrier->Sync();
        barrier->Release();
      }
    }
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
      const classid_t cid =
          raw_view->untag()->typed_data()->GetClassIdMayBeSmi();

      // If we have external typed data we can simply return, since the backing
      // store lives in C-heap and will not move. Otherwise we have to update
      // the inner pointer.
      if (IsTypedDataClassId(cid)) {
        raw_view->untag()->RecomputeDataFieldForInternalTypedData();
      } else {
        ASSERT(IsExternalTypedDataClassId(cid));
      }
    }
  }

  for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
    ASSERT(partitions[task_index].tail != nullptr);
  }

  {
    TIMELINE_FUNCTION_GC_DURATION(thread(), "ForwardStackPointers");
    ForwardStackPointers();
  }

  {
    TIMELINE_FUNCTION_GC_DURATION(thread(),
                                  "ForwardPostponedSuspendStatePointers");
    // After heap sliding is complete and ObjectStore pointers are forwarded
    // it is finally safe to visit SuspendState objects with copied frames.
    can_visit_stack_frames_ = true;
    const intptr_t length = postponed_suspend_states_.length();
    for (intptr_t i = 0; i < length; ++i) {
      auto suspend_state = postponed_suspend_states_[i];
      suspend_state->untag()->VisitPointers(this);
    }
  }

  heap_->old_space()->VisitRoots(this);

  {
    MutexLocker ml(pages_lock);

    // Free empty pages.
    for (intptr_t task_index = 0; task_index < num_tasks; task_index++) {
      Page* page = partitions[task_index].tail->next();
      while (page != nullptr) {
        Page* next = page->next();
        heap_->old_space()->IncreaseCapacityInWordsLocked(
            -(page->memory_->size() >> kWordSizeLog2));
        page->Deallocate();
        page = next;
      }
    }

    // Re-join the heap.
    for (intptr_t task_index = 0; task_index < num_tasks - 1; task_index++) {
      partitions[task_index].tail->set_next(partitions[task_index + 1].head);
    }
    partitions[num_tasks - 1].tail->set_next(nullptr);
    heap_->old_space()->pages_ = pages = partitions[0].head;
    heap_->old_space()->pages_tail_ = partitions[num_tasks - 1].tail;

    delete[] partitions;
  }
}

void CompactorTask::Run() {
  if (!barrier_->TryEnter()) {
    barrier_->Release();
    return;
  }

  bool result =
      Thread::EnterIsolateGroupAsHelper(isolate_group_, Thread::kCompactorTask,
                                        /*bypass_safepoint=*/true);
  ASSERT(result);

  RunEnteredIsolateGroup();

  Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

  // This task is done. Notify the original thread.
  barrier_->Sync();
  barrier_->Release();
}

void CompactorTask::RunEnteredIsolateGroup() {
#ifdef SUPPORT_TIMELINE
  Thread* thread = Thread::Current();
#endif
  {
    while (true) {
      intptr_t planning_task = next_planning_task_->fetch_add(1u);
      if (planning_task >= num_tasks_) break;

      TIMELINE_FUNCTION_GC_DURATION(thread, "Plan");
      Page* head = partitions_[planning_task].head;
      free_page_ = head;
      free_current_ = head->object_start();
      free_end_ = head->object_end();

      for (Page* page = head; page != nullptr; page = page->next()) {
        PlanPage(page);
      }
    }

    barrier_->Sync();

    while (true) {
      intptr_t sliding_task = next_sliding_task_->fetch_add(1u);
      if (sliding_task >= num_tasks_) break;

      TIMELINE_FUNCTION_GC_DURATION(thread, "Slide");
      Page* head = partitions_[sliding_task].head;
      free_page_ = head;
      free_current_ = head->object_start();
      free_end_ = head->object_end();

      for (Page* page = head; page != nullptr; page = page->next()) {
        SlidePage(page);
      }

      // Add any leftover in the last used page to the freelist. This is
      // required to make the page walkable during forwarding, etc.
      intptr_t free_remaining = free_end_ - free_current_;
      if (free_remaining != 0) {
        freelist_->Free(free_current_, free_remaining);
      }

      ASSERT(free_page_ != nullptr);
      partitions_[sliding_task].tail = free_page_;  // Last live page.
    }

    // Heap: Regular pages already visited during sliding. Code and image pages
    // have no pointers to forward. Visit large pages and new-space.

    bool more_forwarding_tasks = true;
    while (more_forwarding_tasks) {
      intptr_t forwarding_task = next_forwarding_task_->fetch_add(1u);
      switch (forwarding_task) {
        case 0: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardLargePages");
          for (Page* large_page =
                   isolate_group_->heap()->old_space()->large_pages_;
               large_page != nullptr; large_page = large_page->next()) {
            large_page->VisitObjectPointers(compactor_);
          }
          break;
        }
        case 1: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardNewSpace");
          isolate_group_->heap()->new_space()->VisitObjectPointers(compactor_);
          break;
        }
        case 2: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardRememberedSet");
          isolate_group_->store_buffer()->VisitObjectPointers(compactor_);
          break;
        }
        case 3: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardWeakTables");
          isolate_group_->heap()->ForwardWeakTables(compactor_);
          break;
        }
        case 4: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardWeakHandles");
          isolate_group_->VisitWeakPersistentHandles(compactor_);
          break;
        }
#ifndef PRODUCT
        case 5: {
          TIMELINE_FUNCTION_GC_DURATION(thread, "ForwardObjectIdRing");
          isolate_group_->ForEachIsolate(
              [&](Isolate* isolate) {
                ObjectIdRing* ring = isolate->object_id_ring();
                if (ring != nullptr) {
                  ring->VisitPointers(compactor_);
                }
              },
              /*at_safepoint=*/true);
          break;
        }
#endif  // !PRODUCT
        default:
          more_forwarding_tasks = false;
      }
    }
  }
}

void CompactorTask::PlanPage(Page* page) {
  uword current = page->object_start();
  uword end = page->object_end();

  ForwardingPage* forwarding_page = page->forwarding_page();
  ASSERT(forwarding_page != nullptr);
  forwarding_page->Clear();
  while (current < end) {
    current = PlanBlock(current, forwarding_page);
  }
}

void CompactorTask::SlidePage(Page* page) {
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
  uword current = first_object;
  while (current < block_end) {
    ObjectPtr obj = UntaggedObject::FromAddr(current);
    intptr_t size = obj->untag()->HeapSize();
    if (obj->untag()->IsMarked()) {
      forwarding_block->RecordLive(current, size);
      ASSERT(static_cast<intptr_t>(forwarding_block->Lookup(current)) ==
             block_live_size);
      block_live_size += size;
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
    ObjectPtr old_obj = UntaggedObject::FromAddr(old_addr);
    intptr_t size = old_obj->untag()->HeapSize();
    if (old_obj->untag()->IsMarked()) {
      uword new_addr = forwarding_block->Lookup(old_addr);
      if (new_addr != free_current_) {
        // The only situation where these two don't match is if we are moving
        // to a new page.  But if we exactly hit the end of the previous page
        // then free_current could be at the start of the next page, so we
        // subtract 1.
        ASSERT(Page::Of(free_current_ - 1) != Page::Of(new_addr));
        intptr_t free_remaining = free_end_ - free_current_;
        // Add any leftover at the end of a page to the free list.
        if (free_remaining > 0) {
          freelist_->Free(free_current_, free_remaining);
        }
        free_page_ = free_page_->next();
        ASSERT(free_page_ != nullptr);
        free_current_ = free_page_->object_start();
        free_end_ = free_page_->object_end();
        ASSERT(free_current_ == new_addr);
      }
      ObjectPtr new_obj = UntaggedObject::FromAddr(new_addr);

      // Fast path for no movement. There's often a large block of objects at
      // the beginning that don't move.
      if (new_addr != old_addr) {
        // Slide the object down.
        memmove(reinterpret_cast<void*>(new_addr),
                reinterpret_cast<void*>(old_addr), size);

        if (IsTypedDataClassId(new_obj->GetClassId())) {
          static_cast<TypedDataPtr>(new_obj)->untag()->RecomputeDataField();
        }
      }
      new_obj->untag()->ClearMarkBit();
      new_obj->untag()->VisitPointers(compactor_);

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
    ASSERT(free_page_ != nullptr);
    free_current_ = free_page_->object_start();
    free_end_ = free_page_->object_end();
    free_remaining = free_end_ - free_current_;
    ASSERT(free_remaining >= size);
  }
}

void GCCompactor::SetupImagePageBoundaries() {
  MallocGrowableArray<ImagePageRange> ranges(4);

  Page* image_page =
      Dart::vm_isolate_group()->heap()->old_space()->image_pages_;
  while (image_page != nullptr) {
    ImagePageRange range = {image_page->object_start(),
                            image_page->object_end()};
    ranges.Add(range);
    image_page = image_page->next();
  }
  image_page = heap_->old_space()->image_pages_;
  while (image_page != nullptr) {
    ImagePageRange range = {image_page->object_start(),
                            image_page->object_end()};
    ranges.Add(range);
    image_page = image_page->next();
  }

  ranges.Sort(CompareImagePageRanges);
  intptr_t image_page_count;
  ranges.StealBuffer(&image_page_ranges_, &image_page_count);
  image_page_hi_ = image_page_count - 1;
}

DART_FORCE_INLINE
void GCCompactor::ForwardPointer(ObjectPtr* ptr) {
  ObjectPtr old_target = *ptr;
  if (old_target->IsSmiOrNewObject()) {
    return;  // Not moved.
  }

  uword old_addr = UntaggedObject::ToAddr(old_target);
  intptr_t lo = 0;
  intptr_t hi = image_page_hi_;
  while (lo <= hi) {
    intptr_t mid = (hi - lo + 1) / 2 + lo;
    ASSERT(mid >= lo);
    ASSERT(mid <= hi);
    if (old_addr < image_page_ranges_[mid].start) {
      hi = mid - 1;
    } else if (old_addr >= image_page_ranges_[mid].end) {
      lo = mid + 1;
    } else {
      return;  // Not moved (unaligned image page).
    }
  }

  Page* page = Page::Of(old_target);
  ForwardingPage* forwarding_page = page->forwarding_page();
  if (forwarding_page == nullptr) {
    return;  // Not moved (VM isolate, large page, code page).
  }

  ObjectPtr new_target =
      UntaggedObject::FromAddr(forwarding_page->Lookup(old_addr));
  ASSERT(!new_target->IsSmiOrNewObject());
  *ptr = new_target;
}

DART_FORCE_INLINE
void GCCompactor::ForwardCompressedPointer(uword heap_base,
                                           CompressedObjectPtr* ptr) {
  ObjectPtr old_target = ptr->Decompress(heap_base);
  if (old_target->IsSmiOrNewObject()) {
    return;  // Not moved.
  }

  uword old_addr = UntaggedObject::ToAddr(old_target);
  intptr_t lo = 0;
  intptr_t hi = image_page_hi_;
  while (lo <= hi) {
    intptr_t mid = (hi - lo + 1) / 2 + lo;
    ASSERT(mid >= lo);
    ASSERT(mid <= hi);
    if (old_addr < image_page_ranges_[mid].start) {
      hi = mid - 1;
    } else if (old_addr >= image_page_ranges_[mid].end) {
      lo = mid + 1;
    } else {
      return;  // Not moved (unaligned image page).
    }
  }

  Page* page = Page::Of(old_target);
  ForwardingPage* forwarding_page = page->forwarding_page();
  if (forwarding_page == nullptr) {
    return;  // Not moved (VM isolate, large page, code page).
  }

  ObjectPtr new_target =
      UntaggedObject::FromAddr(forwarding_page->Lookup(old_addr));
  ASSERT(!new_target->IsSmiOrNewObject());
  *ptr = new_target;
}

void GCCompactor::VisitTypedDataViewPointers(TypedDataViewPtr view,
                                             CompressedObjectPtr* first,
                                             CompressedObjectPtr* last) {
  // First we forward all fields of the typed data view.
  ObjectPtr old_backing = view->untag()->typed_data();
  VisitCompressedPointers(view->heap_base(), first, last);
  ObjectPtr new_backing = view->untag()->typed_data();

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
    if (view->untag()->data_ == nullptr) {
      ASSERT(RawSmiValue(view->untag()->offset_in_bytes()) == 0 &&
             RawSmiValue(view->untag()->length()) == 0 &&
             view->untag()->typed_data() == Object::null());
    }
  }
}

// N.B.: This pointer visitor is not idempotent. We must take care to visit
// each pointer exactly once.
void GCCompactor::VisitPointers(ObjectPtr* first, ObjectPtr* last) {
  for (ObjectPtr* ptr = first; ptr <= last; ptr++) {
    ForwardPointer(ptr);
  }
}

#if defined(DART_COMPRESSED_POINTERS)
void GCCompactor::VisitCompressedPointers(uword heap_base,
                                          CompressedObjectPtr* first,
                                          CompressedObjectPtr* last) {
  for (CompressedObjectPtr* ptr = first; ptr <= last; ptr++) {
    ForwardCompressedPointer(heap_base, ptr);
  }
}
#endif

bool GCCompactor::CanVisitSuspendStatePointers(SuspendStatePtr suspend_state) {
  if ((suspend_state->untag()->pc() != 0) && !can_visit_stack_frames_) {
    // Visiting pointers of SuspendState objects with copied stack frame
    // needs to query stack map, which can touch other Dart objects
    // (such as GrowableObjectArray of InstructionsTable).
    // Those objects may have an inconsistent state during compaction,
    // so processing of SuspendState objects is postponed to the later
    // stage of compaction.
    MutexLocker ml(&postponed_suspend_states_mutex_);
    postponed_suspend_states_.Add(suspend_state);
    return false;
  }
  return true;
}

void GCCompactor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  ForwardPointer(handle->ptr_addr());
}

void GCCompactor::ForwardStackPointers() {
  // N.B.: Heap pointers have already been forwarded. We forward the heap before
  // forwarding the stack to limit the number of places that need to be aware of
  // forwarding when reading stack maps.
  isolate_group()->VisitObjectPointers(this,
                                       ValidationPolicy::kDontValidateFrames);
}

}  // namespace dart
