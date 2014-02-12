// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/pages.h"

#include "platform/assert.h"
#include "vm/compiler_stats.h"
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
DEFINE_FLAG(bool, print_free_list_before_gc, false,
            "Print free list statistics before a GC");
DEFINE_FLAG(bool, print_free_list_after_gc, false,
            "Print free list statistics after a GC");
DEFINE_FLAG(bool, collect_code, true,
            "Attempt to GC infrequently used code.");
DEFINE_FLAG(int, code_collection_interval_in_us, 30000000,
            "Time between attempts to collect unused code.");
DEFINE_FLAG(bool, log_code_drop, false,
            "Emit a log message when pointers to unused code are dropped.");
DEFINE_FLAG(bool, always_drop_code, false,
            "Always try to drop code if the function's usage counter is >= 0");
DECLARE_FLAG(bool, write_protect_code);

HeapPage* HeapPage::Initialize(VirtualMemory* memory, PageType type) {
  ASSERT(memory->size() > VirtualMemory::PageSize());
  bool is_executable = (type == kExecutable);
  memory->Commit(is_executable);

  HeapPage* result = reinterpret_cast<HeapPage*>(memory->address());
  result->memory_ = memory;
  result->next_ = NULL;
  result->executable_ = is_executable;
  return result;
}


HeapPage* HeapPage::Allocate(intptr_t size_in_words, PageType type) {
  VirtualMemory* memory =
      VirtualMemory::Reserve(size_in_words << kWordSizeLog2);
  return Initialize(memory, type);
}


void HeapPage::Deallocate() {
  // The memory for this object will become unavailable after the delete below.
  delete memory_;
}


void HeapPage::VisitObjects(ObjectVisitor* visitor) const {
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    RawObject* raw_obj = RawObject::FromAddr(obj_addr);
    visitor->VisitObject(raw_obj);
    obj_addr += raw_obj->Size();
  }
  ASSERT(obj_addr == end_addr);
}


void HeapPage::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    RawObject* raw_obj = RawObject::FromAddr(obj_addr);
    obj_addr += raw_obj->VisitPointers(visitor);
  }
  ASSERT(obj_addr == end_addr);
}


RawObject* HeapPage::FindObject(FindObjectVisitor* visitor) const {
  uword obj_addr = object_start();
  uword end_addr = object_end();
  if (visitor->VisitRange(obj_addr, end_addr)) {
    while (obj_addr < end_addr) {
      RawObject* raw_obj = RawObject::FromAddr(obj_addr);
      uword next_obj_addr = obj_addr + raw_obj->Size();
      if (visitor->VisitRange(obj_addr, next_obj_addr) &&
          raw_obj->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      obj_addr = next_obj_addr;
    }
    ASSERT(obj_addr == end_addr);
  }
  return Object::null();
}


void HeapPage::WriteProtect(bool read_only) {
  VirtualMemory::Protection prot;
  if (read_only) {
    if (executable_) {
      prot = VirtualMemory::kReadExecute;
    } else {
      prot = VirtualMemory::kReadOnly;
    }
  } else {
    prot = VirtualMemory::kReadWrite;
  }
  bool status = memory_->Protect(prot);
  ASSERT(status);
}


PageSpace::PageSpace(Heap* heap, intptr_t max_capacity_in_words)
    : freelist_(),
      heap_(heap),
      pages_(NULL),
      pages_tail_(NULL),
      large_pages_(NULL),
      max_capacity_in_words_(max_capacity_in_words),
      capacity_in_words_(0),
      used_in_words_(0),
      sweeping_(false),
      page_space_controller_(FLAG_heap_growth_space_ratio,
                             FLAG_heap_growth_rate,
                             FLAG_heap_growth_time_ratio),
      gc_time_micros_(0),
      collections_(0) {
}


PageSpace::~PageSpace() {
  FreePages(pages_);
  FreePages(large_pages_);
}


intptr_t PageSpace::LargePageSizeInWordsFor(intptr_t size) {
  intptr_t page_size = Utils::RoundUp(size + HeapPage::ObjectStartOffset(),
                                      VirtualMemory::PageSize());
  return page_size >> kWordSizeLog2;
}


HeapPage* PageSpace::AllocatePage(HeapPage::PageType type) {
  HeapPage* page = HeapPage::Allocate(kPageSizeInWords, type);
  if (pages_ == NULL) {
    pages_ = page;
  } else {
    const bool is_protected = (pages_tail_->type() == HeapPage::kExecutable)
        && FLAG_write_protect_code;
    if (is_protected) {
      pages_tail_->WriteProtect(false);
    }
    pages_tail_->set_next(page);
    if (is_protected) {
      pages_tail_->WriteProtect(true);
    }
  }
  pages_tail_ = page;
  capacity_in_words_ += kPageSizeInWords;
  page->set_object_end(page->memory_->end());
  return page;
}


HeapPage* PageSpace::AllocateLargePage(intptr_t size, HeapPage::PageType type) {
  intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
  HeapPage* page = HeapPage::Allocate(page_size_in_words, type);
  page->set_next(large_pages_);
  large_pages_ = page;
  capacity_in_words_ += page_size_in_words;
  // Only one object in this page.
  page->set_object_end(page->object_start() + size);
  return page;
}


void PageSpace::FreePage(HeapPage* page, HeapPage* previous_page) {
  capacity_in_words_ -= (page->memory_->size() >> kWordSizeLog2);
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
  capacity_in_words_ -= (page->memory_->size() >> kWordSizeLog2);
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


uword PageSpace::TryAllocate(intptr_t size,
                             HeapPage::PageType type,
                             GrowthPolicy growth_policy) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword result = 0;
  if (size < kAllocatablePageSize) {
    const bool is_protected = (type == HeapPage::kExecutable)
        && FLAG_write_protect_code;
    result = freelist_[type].TryAllocate(size, is_protected);
    if ((result == 0) &&
        (page_space_controller_.CanGrowPageSpace(size) ||
         growth_policy == kForceGrowth) &&
        CanIncreaseCapacityInWords(kPageSizeInWords)) {
      HeapPage* page = AllocatePage(type);
      ASSERT(page != NULL);
      // Start of the newly allocated page is the allocated object.
      result = page->object_start();
      // Enqueue the remainder in the free list.
      uword free_start = result + size;
      intptr_t free_size = page->object_end() - free_start;
      if (free_size > 0) {
        freelist_[type].Free(free_start, free_size);
      }
    }
  } else {
    // Large page allocation.
    intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
    if ((page_size_in_words << kWordSizeLog2) < size) {
      // On overflow we fail to allocate.
      return 0;
    }
    if ((page_space_controller_.CanGrowPageSpace(size) ||
         growth_policy == kForceGrowth) &&
        CanIncreaseCapacityInWords(page_size_in_words)) {
      HeapPage* page = AllocateLargePage(size, type);
      if (page != NULL) {
        result = page->object_start();
      }
    }
  }
  if (result != 0) {
    used_in_words_ += (size >> kWordSizeLog2);
    if (FLAG_compiler_stats && (type == HeapPage::kExecutable)) {
      CompilerStats::code_allocated += size;
    }
  }
  ASSERT((result & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
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


bool PageSpace::Contains(uword addr, HeapPage::PageType type) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    if ((page->type() == type) && page->Contains(addr)) {
      return true;
    }
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    if ((page->type() == type) && page->Contains(addr)) {
      return true;
    }
    page = page->next();
  }
  return false;
}


void PageSpace::StartEndAddress(uword* start, uword* end) const {
  ASSERT(pages_ != NULL || large_pages_ != NULL);
  *start = static_cast<uword>(~0);
  *end = 0;
  for (HeapPage* page = pages_; page != NULL; page = page->next()) {
    *start = Utils::Minimum(*start, page->object_start());
    *end = Utils::Maximum(*end, page->object_end());
  }
  for (HeapPage* page = large_pages_; page != NULL; page = page->next()) {
    *start = Utils::Minimum(*start, page->object_start());
    *end = Utils::Maximum(*end, page->object_end());
  }
  ASSERT(*start != static_cast<uword>(~0));
  ASSERT(*end != 0);
}


void PageSpace::VisitObjects(ObjectVisitor* visitor) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    page->VisitObjects(visitor);
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    page->VisitObjects(visitor);
    page = page->next();
  }
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


RawObject* PageSpace::FindObject(FindObjectVisitor* visitor,
                                 HeapPage::PageType type) const {
  ASSERT(Isolate::Current()->no_gc_scope_depth() != 0);
  HeapPage* page = pages_;
  while (page != NULL) {
    if (page->type() == type) {
      RawObject* obj = page->FindObject(visitor);
      if (obj != Object::null()) {
        return obj;
      }
    }
    page = page->next();
  }

  page = large_pages_;
  while (page != NULL) {
    if (page->type() == type) {
      RawObject* obj = page->FindObject(visitor);
      if (obj != Object::null()) {
        return obj;
      }
    }
    page = page->next();
  }
  return Object::null();
}


void PageSpace::WriteProtect(bool read_only) {
  HeapPage* page = pages_;
  while (page != NULL) {
    page->WriteProtect(read_only);
    page = page->next();
  }
  page = large_pages_;
  while (page != NULL) {
    page->WriteProtect(read_only);
    page = page->next();
  }
}


void PageSpace::PrintToJSONObject(JSONObject* object) {
  JSONObject space(object, "old");
  space.AddProperty("type", "PageSpace");
  space.AddProperty("id", "heaps/old");
  space.AddProperty("name", "PageSpace");
  space.AddProperty("user_name", "old");
  space.AddProperty("collections", collections());
  space.AddProperty("used", UsedInWords() * kWordSize);
  space.AddProperty("capacity", CapacityInWords() * kWordSize);
  space.AddProperty("time", RoundMicrosecondsToSeconds(gc_time_micros()));
}


bool PageSpace::ShouldCollectCode() {
  // Try to collect code if enough time has passed since the last attempt.
  const int64_t start = OS::GetCurrentTimeMicros();
  const int64_t last_code_collection_in_us =
      page_space_controller_.last_code_collection_in_us();

  if ((start - last_code_collection_in_us) >
      FLAG_code_collection_interval_in_us) {
    if (FLAG_log_code_drop) {
      OS::Print("Trying to detach code.\n");
    }
    page_space_controller_.set_last_code_collection_in_us(start);
    return true;
  }
  return false;
}


void PageSpace::MarkSweep(bool invoke_api_callbacks) {
  // MarkSweep is not reentrant. Make sure that is the case.
  ASSERT(!sweeping_);
  sweeping_ = true;
  Isolate* isolate = Isolate::Current();

  NoHandleScope no_handles(isolate);

  if (FLAG_print_free_list_before_gc) {
    OS::Print("Data Freelist (before GC):\n");
    freelist_[HeapPage::kData].Print();
    OS::Print("Executable Freelist (before GC):\n");
    freelist_[HeapPage::kExecutable].Print();
  }

  if (FLAG_verify_before_gc) {
    OS::PrintErr("Verifying before MarkSweep...");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

  const int64_t start = OS::GetCurrentTimeMicros();

  if (FLAG_write_protect_code) {
    // Make code pages writable.
    HeapPage* current_page = pages_;
    while (current_page != NULL) {
      if (current_page->type() == HeapPage::kExecutable) {
        current_page->WriteProtect(false);
      }
      current_page = current_page->next();
    }
    current_page = large_pages_;
    while (current_page != NULL) {
      if (current_page->type() == HeapPage::kExecutable) {
        current_page->WriteProtect(false);
      }
      current_page = current_page->next();
    }
  }

  // Mark all reachable old-gen objects.
  bool collect_code = FLAG_collect_code && ShouldCollectCode();
  GCMarker marker(heap_);
  marker.MarkObjects(isolate, this, invoke_api_callbacks, collect_code);

  int64_t mid1 = OS::GetCurrentTimeMicros();

  // Reset the bump allocation page to unused.
  // Reset the freelists and setup sweeping.
  freelist_[HeapPage::kData].Reset();
  freelist_[HeapPage::kExecutable].Reset();

  int64_t mid2 = OS::GetCurrentTimeMicros();

  GCSweeper sweeper(heap_);
  intptr_t used_in_words = 0;

  HeapPage* prev_page = NULL;
  HeapPage* page = pages_;
  while (page != NULL) {
    HeapPage* next_page = page->next();
    intptr_t page_in_use = sweeper.SweepPage(page, &freelist_[page->type()]);
    if (page_in_use == 0) {
      FreePage(page, prev_page);
    } else {
      used_in_words += (page_in_use >> kWordSizeLog2);
      prev_page = page;
    }
    // Advance to the next page.
    page = next_page;
  }

  int64_t mid3 = OS::GetCurrentTimeMicros();

  prev_page = NULL;
  page = large_pages_;
  while (page != NULL) {
    intptr_t page_in_use = sweeper.SweepLargePage(page);
    HeapPage* next_page = page->next();
    if (page_in_use == 0) {
      FreeLargePage(page, prev_page);
    } else {
      used_in_words += (page_in_use >> kWordSizeLog2);
      prev_page = page;
    }
    // Advance to the next page.
    page = next_page;
  }

  if (FLAG_write_protect_code) {
    // Make code pages read-only.
    HeapPage* current_page = pages_;
    while (current_page != NULL) {
      if (current_page->type() == HeapPage::kExecutable) {
        current_page->WriteProtect(true);
      }
      current_page = current_page->next();
    }
    current_page = large_pages_;
    while (current_page != NULL) {
      if (current_page->type() == HeapPage::kExecutable) {
        current_page->WriteProtect(true);
      }
      current_page = current_page->next();
    }
  }

  // Record data and print if requested.
  intptr_t used_before_in_words = used_in_words_;
  used_in_words_ = used_in_words;

  int64_t end = OS::GetCurrentTimeMicros();

  // Record signals for growth control.
  page_space_controller_.EvaluateGarbageCollection(used_before_in_words,
                                                   used_in_words,
                                                   start, end);

  heap_->RecordTime(kMarkObjects, mid1 - start);
  heap_->RecordTime(kResetFreeLists, mid2 - mid1);
  heap_->RecordTime(kSweepPages, mid3 - mid2);
  heap_->RecordTime(kSweepLargePages, end - mid3);

  if (FLAG_print_free_list_after_gc) {
    OS::Print("Data Freelist (after GC):\n");
    freelist_[HeapPage::kData].Print();
    OS::Print("Executable Freelist (after GC):\n");
    freelist_[HeapPage::kExecutable].Print();
  }

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after MarkSweep...");
    heap_->Verify();
    OS::PrintErr(" done.\n");
  }

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
      desired_utilization_((100.0 - heap_growth_ratio) / 100.0),
      heap_growth_rate_(heap_growth_rate),
      garbage_collection_time_ratio_(garbage_collection_time_ratio),
      last_code_collection_in_us_(OS::GetCurrentTimeMicros()) {
}


PageSpaceController::~PageSpaceController() {}


bool PageSpaceController::CanGrowPageSpace(intptr_t size_in_bytes) {
  intptr_t size_in_words = size_in_bytes >> kWordSizeLog2;
  size_in_words = Utils::RoundUp(size_in_words, PageSpace::kPageSizeInWords);
  intptr_t size_in_pages =  size_in_words / PageSpace::kPageSizeInWords;
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
    intptr_t used_before_in_words, intptr_t used_after_in_words,
    int64_t start, int64_t end) {
  // TODO(iposva): Reevaluate the growth policies.
  ASSERT(used_before_in_words >= used_after_in_words);
  ASSERT(end >= start);
  history_.AddGarbageCollectionTime(start, end);
  int collected_garbage_ratio = static_cast<int>(
      (static_cast<double>(used_before_in_words - used_after_in_words) /
      static_cast<double>(used_before_in_words))
                       * 100.0);
  bool enough_free_space =
      (collected_garbage_ratio >= heap_growth_ratio_);
  int garbage_collection_time_fraction =
      history_.GarbageCollectionTimeFraction();
  bool enough_free_time =
      (garbage_collection_time_fraction <= garbage_collection_time_ratio_);

  Heap* heap = Isolate::Current()->heap();
  if (enough_free_space && enough_free_time) {
    grow_heap_ = 0;
  } else {
    intptr_t growth_target = static_cast<intptr_t>(
        used_after_in_words /  desired_utilization_);
    intptr_t growth_in_words = Utils::RoundUp(
        growth_target - used_after_in_words,
        PageSpace::kPageSizeInWords);
    int growth_in_pages =
        growth_in_words / PageSpace::kPageSizeInWords;
    grow_heap_ = Utils::Maximum(growth_in_pages, heap_growth_rate_);
    heap->RecordData(PageSpace::kPageGrowth, growth_in_pages);
  }
  heap->RecordData(PageSpace::kGarbageRatio, collected_garbage_ratio);
  heap->RecordData(PageSpace::kGCTimeFraction,
                   garbage_collection_time_fraction);
  heap->RecordData(PageSpace::kAllowedGrowth, grow_heap_);
}


PageSpaceGarbageCollectionHistory::PageSpaceGarbageCollectionHistory()
    : index_(0) {
  for (intptr_t i = 0; i < kHistoryLength; i++) {
    start_[i] = 0;
    end_[i] = 0;
  }
}


void PageSpaceGarbageCollectionHistory::
    AddGarbageCollectionTime(int64_t start, int64_t end) {
  int index = index_ % kHistoryLength;
  start_[index] = start;
  end_[index] = end;
  index_++;
}


int PageSpaceGarbageCollectionHistory::GarbageCollectionTimeFraction() {
  int current;
  int previous;
  int64_t gc_time = 0;
  int64_t total_time = 0;
  for (intptr_t i = 1; i < kHistoryLength; i++) {
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
    ASSERT(total_time >= gc_time);
    int result= static_cast<int>((static_cast<double>(gc_time) /
                             static_cast<double>(total_time)) * 100);
    return result;
  }
}

}  // namespace dart
