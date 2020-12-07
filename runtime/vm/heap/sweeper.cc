// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/sweeper.h"

#include "vm/globals.h"
#include "vm/heap/freelist.h"
#include "vm/heap/heap.h"
#include "vm/heap/pages.h"
#include "vm/heap/safepoint.h"
#include "vm/lockers.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"

namespace dart {

bool GCSweeper::SweepPage(OldPage* page, FreeList* freelist, bool locked) {
  ASSERT(!page->is_image_page());

  // Keep track whether this page is still in use.
  intptr_t used_in_bytes = 0;

  bool is_executable = (page->type() == OldPage::kExecutable);
  uword start = page->object_start();
  uword end = page->object_end();
  uword current = start;

  while (current < end) {
    ObjectPtr raw_obj = ObjectLayout::FromAddr(current);
    ASSERT(OldPage::Of(raw_obj) == page);
    // These acquire operations balance release operations in array
    // truncaton, ensuring the writes creating the filler object are ordered
    // before the writes inserting the filler object into the freelist.
    uword tags = raw_obj->ptr()->tags_.load(std::memory_order_acquire);
    intptr_t obj_size = raw_obj->ptr()->HeapSize(tags);
    if (ObjectLayout::IsMarked(tags)) {
      // Found marked object. Clear the mark bit and update swept bytes.
      raw_obj->ptr()->ClearMarkBit();
      used_in_bytes += obj_size;
    } else {
      uword free_end = current + obj_size;
      while (free_end < end) {
        ObjectPtr next_obj = ObjectLayout::FromAddr(free_end);
        tags = next_obj->ptr()->tags_.load(std::memory_order_acquire);
        if (ObjectLayout::IsMarked(tags)) {
          // Reached the end of the free block.
          break;
        }
        // Expand the free block by the size of this object.
        free_end += next_obj->ptr()->HeapSize(tags);
      }
      obj_size = free_end - current;
      if (is_executable) {
        uword cursor = current;
        uword end = current + obj_size;
        while (cursor < end) {
          *reinterpret_cast<uword*>(cursor) = kBreakInstructionFiller;
          cursor += kWordSize;
        }
      } else {
#if defined(DEBUG)
        memset(reinterpret_cast<void*>(current), Heap::kZapByte, obj_size);
#endif  // DEBUG
      }
      if ((current != start) || (free_end != end)) {
        // Only add to the free list if not covering the whole page.
        if (locked) {
          freelist->FreeLocked(current, obj_size);
        } else {
          freelist->Free(current, obj_size);
        }
      }
    }
    current += obj_size;
  }
  ASSERT(current == end);

  page->set_used_in_bytes(used_in_bytes);
  return used_in_bytes != 0;  // In use.
}

intptr_t GCSweeper::SweepLargePage(OldPage* page) {
  ASSERT(!page->is_image_page());

  intptr_t words_to_end = 0;
  ObjectPtr raw_obj = ObjectLayout::FromAddr(page->object_start());
  ASSERT(OldPage::Of(raw_obj) == page);
  if (raw_obj->ptr()->IsMarked()) {
    raw_obj->ptr()->ClearMarkBit();
    words_to_end = (raw_obj->ptr()->HeapSize() >> kWordSizeLog2);
  }
#ifdef DEBUG
  // Array::MakeFixedLength creates trailing filler objects,
  // but they are always unreachable. Verify that they are not marked.
  uword current = ObjectLayout::ToAddr(raw_obj) + raw_obj->ptr()->HeapSize();
  uword end = page->object_end();
  while (current < end) {
    ObjectPtr cur_obj = ObjectLayout::FromAddr(current);
    ASSERT(!cur_obj->ptr()->IsMarked());
    intptr_t obj_size = cur_obj->ptr()->HeapSize();
    memset(reinterpret_cast<void*>(current), Heap::kZapByte, obj_size);
    current += obj_size;
  }
#endif  // DEBUG
  return words_to_end;
}

class ConcurrentSweeperTask : public ThreadPool::Task {
 public:
  ConcurrentSweeperTask(IsolateGroup* isolate_group,
                        PageSpace* old_space,
                        OldPage* first,
                        OldPage* last,
                        OldPage* large_first,
                        OldPage* large_last)
      : task_isolate_group_(isolate_group),
        old_space_(old_space),
        first_(first),
        last_(last),
        large_first_(large_first),
        large_last_(large_last) {
    ASSERT(task_isolate_group_ != NULL);
    ASSERT(first_ != NULL);
    ASSERT(old_space_ != NULL);
    ASSERT(last_ != NULL);
    MonitorLocker ml(old_space_->tasks_lock());
    old_space_->set_tasks(old_space_->tasks() + 1);
    old_space_->set_phase(PageSpace::kSweepingLarge);
  }

  virtual void Run() {
    bool result = Thread::EnterIsolateGroupAsHelper(
        task_isolate_group_, Thread::kSweeperTask, /*bypass_safepoint=*/true);
    ASSERT(result);
    {
      Thread* thread = Thread::Current();
      ASSERT(thread->BypassSafepoints());  // Or we should be checking in.
      TIMELINE_FUNCTION_GC_DURATION(thread, "ConcurrentSweep");
      GCSweeper sweeper;

      OldPage* page = large_first_;
      OldPage* prev_page = NULL;
      while (page != NULL) {
        OldPage* next_page;
        if (page == large_last_) {
          // Don't access page->next(), which would be a race with mutator
          // allocating new pages.
          next_page = NULL;
        } else {
          next_page = page->next();
        }
        ASSERT(page->type() == OldPage::kData);
        const intptr_t words_to_end = sweeper.SweepLargePage(page);
        if (words_to_end == 0) {
          old_space_->FreeLargePage(page, prev_page);
        } else {
          old_space_->TruncateLargePage(page, words_to_end << kWordSizeLog2);
          prev_page = page;
        }
        page = next_page;
      }

      {
        MonitorLocker ml(old_space_->tasks_lock());
        ASSERT(old_space_->phase() == PageSpace::kSweepingLarge);
        old_space_->set_phase(PageSpace::kSweepingRegular);
        ml.NotifyAll();
      }

      intptr_t shard = 0;
      const intptr_t num_shards = Utils::Maximum(FLAG_scavenger_tasks, 1);
      page = first_;
      prev_page = NULL;
      while (page != NULL) {
        OldPage* next_page;
        if (page == last_) {
          // Don't access page->next(), which would be a race with mutator
          // allocating new pages.
          next_page = NULL;
        } else {
          next_page = page->next();
        }
        ASSERT(page->type() == OldPage::kData);
        shard = (shard + 1) % num_shards;
        bool page_in_use =
            sweeper.SweepPage(page, old_space_->DataFreeList(shard), false);
        if (page_in_use) {
          prev_page = page;
        } else {
          old_space_->FreePage(page, prev_page);
        }
        {
          // Notify the mutator thread that we have added elements to the free
          // list or that more capacity is available.
          MonitorLocker ml(old_space_->tasks_lock());
          ml.Notify();
        }
        page = next_page;
      }
    }
    // Exit isolate cleanly *before* notifying it, to avoid shutdown race.
    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);
    // This sweeper task is done. Notify the original isolate.
    {
      MonitorLocker ml(old_space_->tasks_lock());
      old_space_->set_tasks(old_space_->tasks() - 1);
      ASSERT(old_space_->phase() == PageSpace::kSweepingRegular);
      old_space_->set_phase(PageSpace::kDone);
      ml.NotifyAll();
    }
  }

 private:
  IsolateGroup* task_isolate_group_;
  PageSpace* old_space_;
  OldPage* first_;
  OldPage* last_;
  OldPage* large_first_;
  OldPage* large_last_;
};

void GCSweeper::SweepConcurrent(IsolateGroup* isolate_group,
                                OldPage* first,
                                OldPage* last,
                                OldPage* large_first,
                                OldPage* large_last,
                                FreeList* freelist) {
  bool result = Dart::thread_pool()->Run<ConcurrentSweeperTask>(
      isolate_group, isolate_group->heap()->old_space(), first, last,
      large_first, large_last);
  ASSERT(result);
}

}  // namespace dart
