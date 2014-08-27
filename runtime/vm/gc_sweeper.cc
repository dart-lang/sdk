// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_sweeper.h"

#include "vm/freelist.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/lockers.h"
#include "vm/pages.h"
#include "vm/thread_pool.h"

namespace dart {

bool GCSweeper::SweepPage(HeapPage* page, FreeList* freelist) {
  // Keep track whether this page is still in use.
  bool in_use = false;

  bool is_executable = (page->type() == HeapPage::kExecutable);
  uword start = page->object_start();
  uword end = page->object_end();
  uword current = start;

  while (current < end) {
    intptr_t obj_size;
    RawObject* raw_obj = RawObject::FromAddr(current);
    if (raw_obj->IsMarked()) {
      // Found marked object. Clear the mark bit and update swept bytes.
      raw_obj->ClearMarkBit();
      obj_size = raw_obj->Size();
      in_use = true;
    } else {
      uword free_end = current + raw_obj->Size();
      while (free_end < end) {
        RawObject* next_obj = RawObject::FromAddr(free_end);
        if (next_obj->IsMarked()) {
          // Reached the end of the free block.
          break;
        }
        // Expand the free block by the size of this object.
        free_end += next_obj->Size();
      }
      obj_size = free_end - current;
      if (is_executable) {
        memset(reinterpret_cast<void*>(current), 0xcc, obj_size);
      }
      if ((current != start) || (free_end != end)) {
        // Only add to the free list if not covering the whole page.
        freelist->FreeLocked(current, obj_size);
      }
    }
    current += obj_size;
  }
  ASSERT(current == end);

  return in_use;
}


intptr_t GCSweeper::SweepLargePage(HeapPage* page) {
  intptr_t words_to_end = 0;
  RawObject* raw_obj = RawObject::FromAddr(page->object_start());
  if (raw_obj->IsMarked()) {
    raw_obj->ClearMarkBit();
    words_to_end = (raw_obj->Size() >> kWordSizeLog2);
  }
#ifdef DEBUG
  // String::MakeExternal and Array::MakeArray create trailing filler objects,
  // but they are always unreachable. Verify that they are not marked.
  uword current = RawObject::ToAddr(raw_obj) + raw_obj->Size();
  uword end = page->object_end();
  while (current < end) {
    RawObject* cur_obj = RawObject::FromAddr(current);
    ASSERT(!cur_obj->IsMarked());
    current += cur_obj->Size();
  }
#endif  // DEBUG
  return words_to_end;
}


class SweeperTask : public ThreadPool::Task {
 public:
  SweeperTask(Isolate* isolate,
              PageSpace* old_space,
              HeapPage* first,
              HeapPage* last,
              FreeList* freelist)
      : task_isolate_(isolate),
        old_space_(old_space),
        first_(first),
        last_(last),
        freelist_(freelist) {
    ASSERT(task_isolate_ != NULL);
    ASSERT(first_ != NULL);
    ASSERT(old_space_ != NULL);
    ASSERT(last_ != NULL);
    ASSERT(freelist_ != NULL);
    MonitorLocker ml(old_space_->tasks_lock());
    old_space_->set_tasks(old_space_->tasks() + 1);
    ml.Notify();
  }

  virtual void Run() {
    Isolate::SetCurrent(task_isolate_);
    GCSweeper sweeper(NULL);

    HeapPage* page = first_;
    HeapPage* prev_page = NULL;

    while (page != NULL) {
      HeapPage* next_page = page->next();
      ASSERT(page->type() == HeapPage::kData);
      bool page_in_use = true;
      {
        MutexLocker ml(freelist_->mutex());
        page_in_use = sweeper.SweepPage(page, freelist_);
      }
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
      if (page == last_) break;
      page = next_page;
    }
    // This sweeper task is done. Notify the original isolate.
    {
      MonitorLocker ml(old_space_->tasks_lock());
      old_space_->set_tasks(old_space_->tasks() - 1);
      ml.Notify();
    }
    Isolate::SetCurrent(NULL);
    delete task_isolate_;
  }

 private:
  Isolate* task_isolate_;
  PageSpace* old_space_;
  HeapPage* first_;
  HeapPage* last_;
  FreeList* freelist_;
};


void GCSweeper::SweepConcurrent(Isolate* isolate,
                                HeapPage* first,
                                HeapPage* last,
                                FreeList* freelist) {
  SweeperTask* task =
      new SweeperTask(isolate->ShallowCopy(),
                      isolate->heap()->old_space(),
                      first, last,
                      freelist);
  ThreadPool* pool = Dart::thread_pool();
  pool->Run(task);
}

}  // namespace dart
