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

DEFINE_FLAG(int, heap_growth_space_ratio, 20,
            "The desired maximum percentage of free space after GC");
DEFINE_FLAG(int, heap_growth_time_ratio, 3,
            "The desired maximum percentage of time spent in GC");
DEFINE_FLAG(int, heap_growth_rate, 256,
            "The max number of pages the heap can grow at a time");
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
      sweeping_(false),
      page_space_controller_(heap,
                             FLAG_heap_growth_space_ratio,
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
  usage_.capacity_in_words += kPageSizeInWords;
  page->set_object_end(page->memory_->end());
  return page;
}


HeapPage* PageSpace::AllocateLargePage(intptr_t size, HeapPage::PageType type) {
  intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
  HeapPage* page = HeapPage::Allocate(page_size_in_words, type);
  page->set_next(large_pages_);
  large_pages_ = page;
  usage_.capacity_in_words += page_size_in_words;
  // Only one object in this page (at least until String::MakeExternal or
  // Array::MakeArray is called).
  page->set_object_end(page->object_start() + size);
  return page;
}


void PageSpace::FreePage(HeapPage* page, HeapPage* previous_page) {
  usage_.capacity_in_words -= (page->memory_->size() >> kWordSizeLog2);
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
  usage_.capacity_in_words -= (page->memory_->size() >> kWordSizeLog2);
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
  SpaceUsage after_allocation = usage_;
  after_allocation.used_in_words += size >> kWordSizeLog2;
  if (size < kAllocatablePageSize) {
    const bool is_protected = (type == HeapPage::kExecutable)
        && FLAG_write_protect_code;
    result = freelist_[type].TryAllocate(size, is_protected);
    if (result == 0) {
      // Can we grow by one page?
      after_allocation.capacity_in_words += kPageSizeInWords;
      if ((!page_space_controller_.NeedsGarbageCollection(after_allocation) ||
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
    }
  } else {
    // Large page allocation.
    intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
    if ((page_size_in_words << kWordSizeLog2) < size) {
      // On overflow we fail to allocate.
      return 0;
    }
    after_allocation.capacity_in_words += page_size_in_words;
    if ((!page_space_controller_.NeedsGarbageCollection(after_allocation) ||
         growth_policy == kForceGrowth) &&
        CanIncreaseCapacityInWords(page_size_in_words)) {
      HeapPage* page = AllocateLargePage(size, type);
      if (page != NULL) {
        result = page->object_start();
      }
    }
  }
  if (result != 0) {
    usage_ = after_allocation;
    if (FLAG_compiler_stats && (type == HeapPage::kExecutable)) {
      CompilerStats::code_allocated += size;
    }
  }
  ASSERT((result & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
  return result;
}


void PageSpace::AllocateExternal(intptr_t size) {
  intptr_t size_in_words = size >> kWordSizeLog2;
  usage_.external_in_words += size_in_words;
  // TODO(koda): Control growth.
}


void PageSpace::FreeExternal(intptr_t size) {
  intptr_t size_in_words = size >> kWordSizeLog2;
  usage_.external_in_words -= size_in_words;
}


bool PageSpace::Contains(uword addr) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    if (page->Contains(addr)) {
      return true;
    }
    page = NextPageAnySize(page);
  }
  return false;
}


bool PageSpace::Contains(uword addr, HeapPage::PageType type) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    if ((page->type() == type) && page->Contains(addr)) {
      return true;
    }
    page = NextPageAnySize(page);
  }
  return false;
}


void PageSpace::StartEndAddress(uword* start, uword* end) const {
  ASSERT(pages_ != NULL || large_pages_ != NULL);
  *start = static_cast<uword>(~0);
  *end = 0;
  for (HeapPage* page = pages_; page != NULL; page = NextPageAnySize(page)) {
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
    page = NextPageAnySize(page);
  }
}


void PageSpace::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  HeapPage* page = pages_;
  while (page != NULL) {
    page->VisitObjectPointers(visitor);
    page = NextPageAnySize(page);
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
    page = NextPageAnySize(page);
  }
  return Object::null();
}


void PageSpace::WriteProtect(bool read_only) {
  HeapPage* page = pages_;
  while (page != NULL) {
    page->WriteProtect(read_only);
    page = NextPageAnySize(page);
  }
}


void PageSpace::PrintToJSONObject(JSONObject* object) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  JSONObject space(object, "old");
  space.AddProperty("type", "PageSpace");
  space.AddProperty("id", "heaps/old");
  space.AddProperty("name", "PageSpace");
  space.AddProperty("user_name", "old");
  space.AddProperty("collections", collections());
  space.AddProperty("used", UsedInWords() * kWordSize);
  space.AddProperty("capacity", CapacityInWords() * kWordSize);
  space.AddProperty("external", ExternalInWords() * kWordSize);
  space.AddProperty("time", MicrosecondsToSeconds(gc_time_micros()));
  {
    int64_t run_time = OS::GetCurrentTimeMicros() - isolate->start_time();
    run_time = Utils::Maximum(run_time, static_cast<int64_t>(0));
    double run_time_millis = MicrosecondsToMilliseconds(run_time);
    double avg_time_between_collections =
        run_time_millis / static_cast<double>(collections());
    space.AddProperty("avgCollectionPeriodMillis",
                      avg_time_between_collections);
  }
}


class HeapMapAsJSONVisitor : public ObjectVisitor {
 public:
  explicit HeapMapAsJSONVisitor(JSONArray* array)
      : ObjectVisitor(NULL), array_(array) {}
  virtual void VisitObject(RawObject* obj) {
    array_->AddValue(obj->Size() / kObjectAlignment);
    array_->AddValue(obj->GetClassId());
  }
 private:
  JSONArray* array_;
};


void PageSpace::PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream) {
  JSONObject heap_map(stream);
  heap_map.AddProperty("type", "HeapMap");
  heap_map.AddProperty("id", "heapmap");
  heap_map.AddProperty("free_class_id",
                       static_cast<intptr_t>(kFreeListElement));
  heap_map.AddProperty("unit_size_bytes",
                       static_cast<intptr_t>(kObjectAlignment));
  heap_map.AddProperty("page_size_bytes", kPageSizeInWords * kWordSize);
  {
    JSONObject class_list(&heap_map, "class_list");
    isolate->class_table()->PrintToJSONObject(&class_list);
  }
  {
    // "pages" is an array [page0, page1, ..., pageN], each page of the form
    // {"object_start": "0x...", "objects": [size, class id, size, ...]}
    JSONArray all_pages(&heap_map, "pages");
    for (HeapPage* page = pages_; page != NULL; page = page->next()) {
      JSONObject page_container(&all_pages);
      page_container.AddPropertyF("object_start",
                                  "0x%" Px "", page->object_start());
      JSONArray page_map(&page_container, "objects");
      HeapMapAsJSONVisitor printer(&page_map);
      page->VisitObjects(&printer);
    }
  }
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


void PageSpace::WriteProtectCode(bool read_only) {
  if (FLAG_write_protect_code) {
    HeapPage* current_page = pages_;
    while (current_page != NULL) {
      if (current_page->type() == HeapPage::kExecutable) {
        current_page->WriteProtect(read_only);
      }
      current_page = NextPageAnySize(current_page);
    }
  }
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

  // Make code pages writable.
  WriteProtectCode(false);

  // Save old value before GCMarker visits the weak persistent handles.
  SpaceUsage usage_before = usage_;

  // Mark all reachable old-gen objects.
  bool collect_code = FLAG_collect_code && ShouldCollectCode();
  GCMarker marker(heap_);
  marker.MarkObjects(isolate, this, invoke_api_callbacks, collect_code);
  usage_.used_in_words = marker.marked_words();

  int64_t mid1 = OS::GetCurrentTimeMicros();

  // Reset the bump allocation page to unused.
  // Reset the freelists and setup sweeping.
  freelist_[HeapPage::kData].Reset();
  freelist_[HeapPage::kExecutable].Reset();

  int64_t mid2 = OS::GetCurrentTimeMicros();

  GCSweeper sweeper(heap_);

  HeapPage* prev_page = NULL;
  HeapPage* page = pages_;
  while (page != NULL) {
    HeapPage* next_page = page->next();
    bool page_in_use = sweeper.SweepPage(page, &freelist_[page->type()]);
    if (page_in_use) {
      prev_page = page;
    } else {
      FreePage(page, prev_page);
    }
    // Advance to the next page.
    page = next_page;
  }

  int64_t mid3 = OS::GetCurrentTimeMicros();

  prev_page = NULL;
  page = large_pages_;
  while (page != NULL) {
    HeapPage* next_page = page->next();
    bool page_in_use = sweeper.SweepLargePage(page);
    if (page_in_use) {
      prev_page = page;
    } else {
      FreeLargePage(page, prev_page);
    }
    // Advance to the next page.
    page = next_page;
  }

  // Make code pages read-only.
  WriteProtectCode(true);

  int64_t end = OS::GetCurrentTimeMicros();

  // Record signals for growth control. Include size of external allocations.
  page_space_controller_.EvaluateGarbageCollection(usage_before, usage_,
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


PageSpaceController::PageSpaceController(Heap* heap,
                                         int heap_growth_ratio,
                                         int heap_growth_max,
                                         int garbage_collection_time_ratio)
    : heap_(heap),
      is_enabled_(false),
      grow_heap_(heap_growth_max / 2),
      heap_growth_ratio_(heap_growth_ratio),
      desired_utilization_((100.0 - heap_growth_ratio) / 100.0),
      heap_growth_max_(heap_growth_max),
      garbage_collection_time_ratio_(garbage_collection_time_ratio),
      last_code_collection_in_us_(OS::GetCurrentTimeMicros()) {
}


PageSpaceController::~PageSpaceController() {}


bool PageSpaceController::NeedsGarbageCollection(SpaceUsage after) const {
  if (!is_enabled_) {
    return false;
  }
  if (heap_growth_ratio_ == 100) {
    return false;
  }
  intptr_t capacity_increase_in_words =
    after.capacity_in_words - last_usage_.capacity_in_words;
  ASSERT(capacity_increase_in_words >= 0);
  capacity_increase_in_words =
      Utils::RoundUp(capacity_increase_in_words, PageSpace::kPageSizeInWords);
  intptr_t capacity_increase_in_pages =
      capacity_increase_in_words / PageSpace::kPageSizeInWords;
  double multiplier = 1.0;
  // To avoid waste, the first GC should be triggered before too long. After
  // kInitialTimeoutSeconds, gradually lower the capacity limit.
  static const double kInitialTimeoutSeconds = 1.00;
  if (history_.IsEmpty()) {
    double seconds_since_init = MicrosecondsToSeconds(
        OS::GetCurrentTimeMicros() - heap_->isolate()->start_time());
    if (seconds_since_init > kInitialTimeoutSeconds) {
      multiplier *= seconds_since_init / kInitialTimeoutSeconds;
    }
  }
  return capacity_increase_in_pages * multiplier > grow_heap_;
}


void PageSpaceController::EvaluateGarbageCollection(
    SpaceUsage before, SpaceUsage after, int64_t start, int64_t end) {
  ASSERT(end >= start);
  history_.AddGarbageCollectionTime(start, end);
  int gc_time_fraction = history_.GarbageCollectionTimeFraction();
  heap_->RecordData(PageSpace::kGCTimeFraction, gc_time_fraction);

  // Assume garbage increases linearly with allocation:
  // G = kA, and estimate k from the previous cycle.
  intptr_t allocated_since_previous_gc =
      before.used_in_words - last_usage_.used_in_words;
  intptr_t garbage = before.used_in_words - after.used_in_words;
  double k = garbage / static_cast<double>(allocated_since_previous_gc);
  heap_->RecordData(PageSpace::kGarbageRatio, static_cast<int>(k * 100));

  // Define GC to be 'worthwhile' iff at least fraction t of heap is garbage.
  double t = 1.0 - desired_utilization_;
  // If we spend too much time in GC, strive for even more free space.
  if (gc_time_fraction > garbage_collection_time_ratio_) {
    t += (gc_time_fraction - garbage_collection_time_ratio_) / 100.0;
  }

  // Find minimum 'grow_heap_' such that after increasing capacity by
  // 'grow_heap_' pages and filling them, we expect a GC to be worthwhile.
  for (grow_heap_ = 0; grow_heap_ < heap_growth_max_; ++grow_heap_) {
    intptr_t limit =
        after.capacity_in_words + (grow_heap_ * PageSpace::kPageSizeInWords);
    intptr_t allocated_before_next_gc = limit - after.used_in_words;
    double estimated_garbage = k * allocated_before_next_gc;
    if (t <= estimated_garbage / limit) {
      break;
    }
  }
  heap_->RecordData(PageSpace::kPageGrowth, grow_heap_);

  // Limit shrinkage: allow growth by at least half the pages freed by GC.
  intptr_t freed_pages =
      (before.capacity_in_words - after.capacity_in_words) /
      PageSpace::kPageSizeInWords;
  grow_heap_ = Utils::Maximum(grow_heap_, freed_pages / 2);
  heap_->RecordData(PageSpace::kAllowedGrowth, grow_heap_);
  last_usage_ = after;
}


void PageSpaceGarbageCollectionHistory::
    AddGarbageCollectionTime(int64_t start, int64_t end) {
  Entry entry;
  entry.start = start;
  entry.end = end;
  history_.Add(entry);
}


int PageSpaceGarbageCollectionHistory::GarbageCollectionTimeFraction() {
  int64_t gc_time = 0;
  int64_t total_time = 0;
  for (int i = 0; i < history_.Size() - 1; i++) {
    Entry current = history_.Get(i);
    Entry previous = history_.Get(i + 1);
    gc_time += current.end - current.start;
    total_time += current.end - previous.end;
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
