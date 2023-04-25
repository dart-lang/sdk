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

bool GCSweeper::SweepPage(Page* page, FreeList* freelist, bool locked) {
  ASSERT(!page->is_image());
  // Large executable pages are handled here. We never truncate Instructions
  // objects, so we never truncate executable pages.
  ASSERT(!page->is_large() || page->is_executable());

  // Keep track whether this page is still in use.
  intptr_t used_in_bytes = 0;

  bool is_executable = page->is_executable();
  uword start = page->object_start();
  uword end = page->object_end();
  uword current = start;

  while (current < end) {
    ObjectPtr raw_obj = UntaggedObject::FromAddr(current);
    ASSERT(Page::Of(raw_obj) == page);
    // These acquire operations balance release operations in array
    // truncation, ensuring the writes creating the filler object are ordered
    // before the writes inserting the filler object into the freelist.
    uword tags = raw_obj->untag()->tags_.load(std::memory_order_acquire);
    intptr_t obj_size = raw_obj->untag()->HeapSize(tags);
    if (UntaggedObject::IsMarked(tags)) {
      // Found marked object. Clear the mark bit and update swept bytes.
      raw_obj->untag()->ClearMarkBit();
      used_in_bytes += obj_size;
    } else {
      uword free_end = current + obj_size;
      while (free_end < end) {
        ObjectPtr next_obj = UntaggedObject::FromAddr(free_end);
        tags = next_obj->untag()->tags_.load(std::memory_order_acquire);
        if (UntaggedObject::IsMarked(tags)) {
          // Reached the end of the free block.
          break;
        }
        // Expand the free block by the size of this object.
        free_end += next_obj->untag()->HeapSize(tags);
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

  return used_in_bytes != 0;  // In use.
}

intptr_t GCSweeper::SweepLargePage(Page* page) {
  ASSERT(!page->is_image());
  ASSERT(page->is_large() && !page->is_executable());

  intptr_t words_to_end = 0;
  ObjectPtr raw_obj = UntaggedObject::FromAddr(page->object_start());
  ASSERT(Page::Of(raw_obj) == page);
  if (raw_obj->untag()->IsMarked()) {
    raw_obj->untag()->ClearMarkBit();
    words_to_end = (raw_obj->untag()->HeapSize() >> kWordSizeLog2);
  }
#ifdef DEBUG
  // Array::MakeFixedLength creates trailing filler objects,
  // but they are always unreachable. Verify that they are not marked.
  uword current =
      UntaggedObject::ToAddr(raw_obj) + raw_obj->untag()->HeapSize();
  uword end = page->object_end();
  while (current < end) {
    ObjectPtr cur_obj = UntaggedObject::FromAddr(current);
    ASSERT(!cur_obj->untag()->IsMarked());
    intptr_t obj_size = cur_obj->untag()->HeapSize();
    memset(reinterpret_cast<void*>(current), Heap::kZapByte, obj_size);
    current += obj_size;
  }
#endif  // DEBUG
  return words_to_end;
}

class ConcurrentSweeperTask : public ThreadPool::Task {
 public:
  explicit ConcurrentSweeperTask(IsolateGroup* isolate_group)
      : isolate_group_(isolate_group) {
    ASSERT(isolate_group != nullptr);
    PageSpace* old_space = isolate_group->heap()->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    old_space->set_tasks(old_space->tasks() + 1);
    old_space->set_phase(PageSpace::kSweepingLarge);
  }

  virtual void Run() {
    bool result = Thread::EnterIsolateGroupAsNonMutator(isolate_group_,
                                                        Thread::kSweeperTask);
    ASSERT(result);
    PageSpace* old_space = isolate_group_->heap()->old_space();
    {
      Thread* thread = Thread::Current();
      ASSERT(thread->BypassSafepoints());  // Or we should be checking in.
      TIMELINE_FUNCTION_GC_DURATION(thread, "ConcurrentSweep");

      old_space->SweepLarge();

      {
        MonitorLocker ml(old_space->tasks_lock());
        ASSERT(old_space->phase() == PageSpace::kSweepingLarge);
        old_space->set_phase(PageSpace::kSweepingRegular);
        ml.NotifyAll();
      }

      old_space->Sweep(/*exclusive*/ false);
    }
    // Exit isolate cleanly *before* notifying it, to avoid shutdown race.
    Thread::ExitIsolateGroupAsNonMutator();
    // This sweeper task is done. Notify the original isolate.
    {
      MonitorLocker ml(old_space->tasks_lock());
      old_space->set_tasks(old_space->tasks() - 1);
      ASSERT(old_space->phase() == PageSpace::kSweepingRegular);
      old_space->set_phase(PageSpace::kDone);
      ml.NotifyAll();
    }
  }

 private:
  IsolateGroup* isolate_group_;
};

void GCSweeper::SweepConcurrent(IsolateGroup* isolate_group) {
  bool result = Dart::thread_pool()->Run<ConcurrentSweeperTask>(isolate_group);
  ASSERT(result);
}

}  // namespace dart
