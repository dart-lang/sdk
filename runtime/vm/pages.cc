// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/pages.h"

#include "platform/assert.h"
#include "vm/gc_marker.h"
#include "vm/gc_sweeper.h"
#include "vm/object.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(int, heap_growth_space_ratio, 10,
            "The desired maximum percentage of free space after GC");
DEFINE_FLAG(int, heap_growth_time_ratio, 3,
            "The desired maximum percentage of time spent in GC");
DEFINE_FLAG(int, heap_growth_rate, 4,
            "The size the heap is grown, in heap pages");

HeapPage* HeapPage::Initialize(VirtualMemory* memory, bool is_executable) {
  ASSERT(memory->size() > VirtualMemory::PageSize());
  memory->Commit(is_executable);

  HeapPage* result = reinterpret_cast<HeapPage*>(memory->address());
  result->memory_ = memory;
  result->next_ = NULL;
  result->used_ = 0;
  result->top_ = result->first_object_start();
  return result;
}


HeapPage* HeapPage::Allocate(intptr_t size, bool is_executable) {
  VirtualMemory* memory =
      VirtualMemory::ReserveAligned(size, PageSpace::kPageAlignment);
  return Initialize(memory, is_executable);
}


void HeapPage::Deallocate() {
  // The memory for this object will become unavailable after the delete below.
  delete memory_;
}


void HeapPage::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  uword obj_addr = first_object_start();
  uword end_addr = top();
  while (obj_addr < end_addr) {
    RawObject* raw_obj = RawObject::FromAddr(obj_addr);
    obj_addr += raw_obj->VisitPointers(visitor);
  }
  ASSERT(obj_addr == end_addr);
}


RawObject* HeapPage::FindObject(FindObjectVisitor* visitor) const {
  uword obj_addr = first_object_start();
  uword end_addr = top();
  while (obj_addr < end_addr) {
    RawObject* raw_obj = RawObject::FromAddr(obj_addr);
    if (raw_obj->FindObject(visitor)) {
      return raw_obj;  // Found object, return it.
    }
    obj_addr += raw_obj->Size();
  }
  ASSERT(obj_addr == end_addr);
  return Object::null();
}


PageSpace::PageSpace(Heap* heap, intptr_t max_capacity, bool is_executable)
    : freelist_(),
      heap_(heap),
      pages_(NULL),
      pages_tail_(NULL),
      large_pages_(NULL),
      bump_page_(NULL),
      max_capacity_(max_capacity),
      capacity_(0),
      in_use_(0),
      count_(0),
      is_executable_(is_executable),
      sweeping_(false),
      page_space_controller_(FLAG_heap_growth_space_ratio,
                             FLAG_heap_growth_rate,
                             FLAG_heap_growth_time_ratio) {
}


PageSpace::~PageSpace() {
  FreePages(pages_);
  FreePages(large_pages_);
}


intptr_t PageSpace::LargePageSizeFor(intptr_t size) {
  intptr_t page_size = Utils::RoundUp(size + sizeof(HeapPage),
                                      VirtualMemory::PageSize());
  return page_size;
}


void PageSpace::AllocatePage() {
  HeapPage* page = HeapPage::Allocate(kPageSize, is_executable_);
  if (pages_ == NULL) {
    pages_ = page;
  } else {
    pages_tail_->set_next(page);
  }
  pages_tail_ = page;
  bump_page_ = NULL;  // Reenable scanning of pages for bump allocation.
  capacity_ += kPageSize;
}


HeapPage* PageSpace::AllocateLargePage(intptr_t size) {
  intptr_t page_size = LargePageSizeFor(size);
  HeapPage* page = HeapPage::Allocate(page_size, is_executable_);
  page->set_next(large_pages_);
  large_pages_ = page;
  capacity_ += page_size;
  return page;
}


void PageSpace::FreePage(HeapPage* page, HeapPage* previous_page) {
  capacity_ -= page->memory_->size();
  // Remove the page from the list.
  if (previous_page != NULL) {
    previous_page->set_next(page->next());
  } else {
    pages_ = page->next();
  }
  if (page == pages_tail_) {
    pages_tail_ = previous_page;
  }
  // TODO(iposva): Consider adding to a pool of empty pages.
  page->Deallocate();
}


void PageSpace::FreeLargePage(HeapPage* page, HeapPage* previous_page) {
  capacity_ -= page->memory_->size();
  // Remove the page from the list.
  if (previous_page != NULL) {
    previous_page->set_next(page->next());
  } else {
    large_pages_ = page->next();
  }
  page->Deallocate();
}


void PageSpace::FreePages(HeapPage* pages) {
  HeapPage* page = pages;
  while (page != NULL) {
    HeapPage* next = page->next();
    page->Deallocate();
    page = next;
  }
}


uword PageSpace::TryBumpAllocate(intptr_t size) {
  if (pages_tail_ == NULL) {
    return 0;
  }
  uword result = pages_tail_->TryBumpAllocate(size);
  if (result != 0) {
    return result;
  }
  if (bump_page_ == NULL) {
    // The bump page has not yet been used: Start at the beginning of the list.
    bump_page_ = pages_;
  }
  // The last page has already been attempted above.
  while (bump_page_ != pages_tail_) {
    ASSERT(bump_page_->next() != NULL);
    result = bump_page_->TryBumpAllocate(size);
    if (result != 0) {
      return result;
    }
    bump_page_ = bump_page_->next();
  }
  // Ran through all of the pages trying to bump allocate: Give up.
  return 0;
}


uword PageSpace::TryAllocate(intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword result = 0;
  if (size < kAllocatablePageSize) {
    result = TryBumpAllocate(size);
    if (result == 0) {
      result = freelist_.TryAllocate(size);
      if ((result == 0) &&
          (page_space_controller_.CanGrowPageSpace(size) ||
           (size < (capacity() - in_use()))) &&  // Fragmentation
          CanIncreaseCapacity(kPageSize)) {
        AllocatePage();
        result = TryBumpAllocate(size);
        ASSERT(result != 0);
      }
    }
  } else {
    // Large page allocation.
    intptr_t page_size = LargePageSizeFor(size);
    if (page_size < size) {
      // On overflow we fail to allocate.
      return 0;
    }
    if (CanIncreaseCapacity(page_size)) {
      HeapPage* page = AllocateLargePage(size);
      if (page != NULL) {
        result = page->top();
        page->set_top(result + size);
      }
    }
  }
  if (result != 0) {
    in_use_ += size;
  }
  return result;
}


bool PageSpace::Contains(uword addr) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    if (page->Contains(addr)) {
      return true;
    }
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    if (page->Contains(addr)) {
      return true;
    }
    page = page->next();
  }
  return false;
}


void PageSpace::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    page->VisitObjectPointers(visitor);
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    page->VisitObjectPointers(visitor);
    page = page->next();
  }
}


RawObject* PageSpace::FindObject(FindObjectVisitor* visitor) const {
  ASSERT(Isolate::Current()->no_gc_scope_depth() != 0);
  HeapPage* page = pages_;
  while (page != NULL) {
    RawObject* obj = page->FindObject(visitor);
    if (obj != Object::null()) {
      return obj;
    }
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    RawObject* obj = page->FindObject(visitor);
    if (obj != Object::null()) {
      return obj;
    }
    page = page->next();
  }
  return Object::null();
}


void PageSpace::MarkSweep(bool invoke_api_callbacks) {
  // MarkSweep is not reentrant. Make sure that is the case.
  ASSERT(!sweeping_);
  sweeping_ = true;
  Isolate* isolate = Isolate::Current();
  NoHandleScope no_handles(isolate);

  if (FLAG_verify_before_gc) {
    OS::PrintErr("Verifying before MarkSweep... ");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  Timer timer(true, "MarkSweep");
  timer.Start();
  int64_t start = OS::GetCurrentTimeMillis();

  // Mark all reachable old-gen objects.
  GCMarker marker(heap_);
  marker.MarkObjects(isolate, this, invoke_api_callbacks);

  // Reset the bump allocation page to unused.
  bump_page_ = NULL;
  // Reset the freelists and setup sweeping.
  freelist_.Reset();
  GCSweeper sweeper(heap_);
  intptr_t in_use = 0;

  HeapPage* prev_page = NULL;
  HeapPage* page = pages_;
  while (page != NULL) {
    intptr_t page_in_use = sweeper.SweepPage(page, &freelist_);
    HeapPage* next_page = page->next();
    if (page_in_use == 0) {
      FreePage(page, prev_page);
    } else {
      in_use += page_in_use;
      prev_page = page;
    }
    // Advance to the next page.
    page = next_page;
  }

  prev_page = NULL;
  page = large_pages_;
  while (page != NULL) {
    intptr_t page_in_use = sweeper.SweepLargePage(page);
    HeapPage* next_page = page->next();
    if (page_in_use == 0) {
      FreeLargePage(page, prev_page);
    } else {
      in_use += page_in_use;
      prev_page = page;
    }
    // Advance to the next page.
    page = next_page;
  }

  // Record data and print if requested.
  intptr_t in_use_before = in_use_;
  in_use_ = in_use;

  timer.Stop();

  // Record signals for growth control.
  int64_t elapsed = timer.TotalElapsedTime() * kMicrosecondsPerMillisecond;
  page_space_controller_.EvaluateGarbageCollection(in_use_before, in_use,
                                                   start, start + elapsed);

  if (FLAG_verbose_gc) {
    const intptr_t KB2 = KB / 2;
    OS::PrintErr("Mark-Sweep[%d]: %lldus (%dK -> %dK, %dK)\n",
                 count_,
                 timer.TotalElapsedTime(),
                 (in_use_before + (KB2)) / KB,
                 (in_use + (KB2)) / KB,
                 (capacity_ + KB2) / KB);
  }

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after MarkSweep... ");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  count_++;
  // Done, reset the marker.
  ASSERT(sweeping_);
  sweeping_ = false;
}


PageSpaceController::PageSpaceController(int heap_growth_ratio,
                                         int heap_growth_rate,
                                         int garbage_collection_time_ratio)
    : is_enabled_(false),
      grow_heap_(heap_growth_rate),
      heap_growth_ratio_(heap_growth_ratio),
      heap_growth_rate_(heap_growth_rate),
      garbage_collection_time_ratio_(garbage_collection_time_ratio) {
}


PageSpaceController::~PageSpaceController() {}


bool PageSpaceController::CanGrowPageSpace(intptr_t size_in_bytes) {
  size_in_bytes = Utils::RoundUp(size_in_bytes, PageSpace::kPageSize);
  intptr_t size_in_pages =  size_in_bytes / PageSpace::kPageSize;
  if (!is_enabled_) {
    return true;
  }
  if (heap_growth_ratio_ == 100) {
    return true;
  }
  if (grow_heap_ <= 0) {
    return false;
  }
  grow_heap_ -= size_in_pages;
  return true;
}


void PageSpaceController::EvaluateGarbageCollection(
    size_t in_use_before, size_t in_use_after, int64_t start, int64_t end) {
  ASSERT(in_use_before >= in_use_after);
  ASSERT(end >= start);
  history_.AddGarbageCollectionTime(start, end);
  int collected_garbage_ratio =
      static_cast<int>((static_cast<double>(in_use_before - in_use_after) /
                        static_cast<double>(in_use_before)) * 100);
  if ((collected_garbage_ratio > heap_growth_ratio_) &&
      (history_.GarbageCollectionTimeFraction() <
       garbage_collection_time_ratio_)) {
    grow_heap_ = 0;
  } else {
    grow_heap_ = heap_growth_rate_;
  }
}


PageSpaceGarbageCollectionHistory::PageSpaceGarbageCollectionHistory()
    : index_(0) {
  for (uint32_t i = 0; i < kHistoryLength; i++) {
    start_[i] = 0;
    end_[i] = 0;
  }
}


void PageSpaceGarbageCollectionHistory::
    AddGarbageCollectionTime(uint64_t start, uint64_t end) {
  int index = index_ % kHistoryLength;
  start_[index] = start;
  end_[index] = end;
  index_++;
}


int PageSpaceGarbageCollectionHistory::GarbageCollectionTimeFraction() {
  int current;
  int previous;
  uint64_t gc_time = 0;
  uint64_t total_time = 0;
  for (uint32_t i = 1; i < kHistoryLength; i++) {
    current = (index_ - i) % kHistoryLength;
    previous = (index_ - 1 - i) % kHistoryLength;
    if (end_[previous] == 0) {
       break;
    }
    // iterate over the circular buffer in reverse order
    gc_time += end_[current] - start_[current];
    total_time += end_[current] - end_[previous];
  }
  if (total_time == 0) {
    return 0;
  } else {
    return static_cast<int>((static_cast<double>(gc_time) /
                             static_cast<double>(total_time))*100);
  }
}

}  // namespace dart
