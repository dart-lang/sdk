// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/pages.h"

#include "platform/assert.h"
#include "vm/compiler_stats.h"
#include "vm/gc_marker.h"
#include "vm/gc_sweeper.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/thread.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(int, heap_growth_space_ratio, 20,
            "The desired maximum percentage of free space after GC");
DEFINE_FLAG(int, heap_growth_time_ratio, 3,
            "The desired maximum percentage of time spent in GC");
DEFINE_FLAG(int, heap_growth_rate, 280,
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
DEFINE_FLAG(bool, concurrent_sweep, false,
            "Concurrent sweep for old generation.");
DEFINE_FLAG(bool, log_growth, false, "Log PageSpace growth policy decisions.");

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
      pages_lock_(new Mutex()),
      pages_(NULL),
      pages_tail_(NULL),
      exec_pages_(NULL),
      exec_pages_tail_(NULL),
      large_pages_(NULL),
      bump_top_(0),
      bump_end_(0),
      max_capacity_in_words_(max_capacity_in_words),
      tasks_lock_(new Monitor()),
      tasks_(0),
      page_space_controller_(heap,
                             FLAG_heap_growth_space_ratio,
                             FLAG_heap_growth_rate,
                             FLAG_heap_growth_time_ratio),
      gc_time_micros_(0),
      collections_(0) {
}


PageSpace::~PageSpace() {
  {
    MonitorLocker ml(tasks_lock());
    while (tasks() > 0) {
      ml.Wait();
    }
  }
  FreePages(pages_);
  FreePages(exec_pages_);
  FreePages(large_pages_);
  delete pages_lock_;
  delete tasks_lock_;
}


intptr_t PageSpace::LargePageSizeInWordsFor(intptr_t size) {
  intptr_t page_size = Utils::RoundUp(size + HeapPage::ObjectStartOffset(),
                                      VirtualMemory::PageSize());
  return page_size >> kWordSizeLog2;
}


HeapPage* PageSpace::AllocatePage(HeapPage::PageType type) {
  HeapPage* page = HeapPage::Allocate(kPageSizeInWords, type);

  bool is_exec = (type == HeapPage::kExecutable);

  MutexLocker ml(pages_lock_);
  if (!is_exec) {
    if (pages_ == NULL) {
      pages_ = page;
    } else {
      pages_tail_->set_next(page);
    }
    pages_tail_ = page;
  } else {
    if (exec_pages_ == NULL) {
      exec_pages_ = page;
    } else {
      if (FLAG_write_protect_code) {
        exec_pages_tail_->WriteProtect(false);
      }
      exec_pages_tail_->set_next(page);
      if (FLAG_write_protect_code) {
        exec_pages_tail_->WriteProtect(true);
      }
    }
    exec_pages_tail_ = page;
  }
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


void PageSpace::TruncateLargePage(HeapPage* page,
                                  intptr_t new_object_size_in_bytes) {
  const intptr_t old_object_size_in_bytes =
      page->object_end() - page->object_start();
  ASSERT(new_object_size_in_bytes <= old_object_size_in_bytes);
  const intptr_t new_page_size_in_words =
      LargePageSizeInWordsFor(new_object_size_in_bytes);
  VirtualMemory* memory = page->memory_;
  const intptr_t old_page_size_in_words = (memory->size() >> kWordSizeLog2);
  if (new_page_size_in_words < old_page_size_in_words) {
    memory->Truncate(memory->start(), new_page_size_in_words << kWordSizeLog2);
    usage_.capacity_in_words -= old_page_size_in_words;
    usage_.capacity_in_words += new_page_size_in_words;
    page->set_object_end(page->object_start() + new_object_size_in_bytes);
  }
}


void PageSpace::FreePage(HeapPage* page, HeapPage* previous_page) {
  bool is_exec = (page->type() == HeapPage::kExecutable);
  {
    MutexLocker ml(pages_lock_);
    usage_.capacity_in_words -= (page->memory_->size() >> kWordSizeLog2);
    if (!is_exec) {
      // Remove the page from the list of data pages.
      if (previous_page != NULL) {
        previous_page->set_next(page->next());
      } else {
        pages_ = page->next();
      }
      if (page == pages_tail_) {
        pages_tail_ = previous_page;
      }
    } else {
      // Remove the page from the list of executable pages.
      if (previous_page != NULL) {
        previous_page->set_next(page->next());
      } else {
        exec_pages_ = page->next();
      }
      if (page == exec_pages_tail_) {
        exec_pages_tail_ = previous_page;
      }
    }
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


uword PageSpace::TryAllocateInFreshPage(intptr_t size,
                                        HeapPage::PageType type,
                                        GrowthPolicy growth_policy,
                                        bool is_locked) {
  ASSERT(size < kAllocatablePageSize);
  uword result = 0;
  SpaceUsage after_allocation = usage_;
  after_allocation.used_in_words += size >> kWordSizeLog2;
  // Can we grow by one page?
  after_allocation.capacity_in_words += kPageSizeInWords;
  if ((growth_policy == kForceGrowth ||
       !page_space_controller_.NeedsGarbageCollection(after_allocation)) &&
      CanIncreaseCapacityInWords(kPageSizeInWords)) {
    HeapPage* page = AllocatePage(type);
    ASSERT(page != NULL);
    // Start of the newly allocated page is the allocated object.
    result = page->object_start();
    usage_ = after_allocation;
    // Enqueue the remainder in the free list.
    uword free_start = result + size;
    intptr_t free_size = page->object_end() - free_start;
    if (free_size > 0) {
      if (is_locked) {
        freelist_[type].FreeLocked(free_start, free_size);
      } else {
        freelist_[type].Free(free_start, free_size);
      }
    }
  }
  return result;
}


uword PageSpace::TryAllocateInternal(intptr_t size,
                            HeapPage::PageType type,
                            GrowthPolicy growth_policy,
                            bool is_protected,
                            bool is_locked) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword result = 0;
  if (size < kAllocatablePageSize) {
    if (is_locked) {
      result = freelist_[type].TryAllocateLocked(size, is_protected);
    } else {
      result = freelist_[type].TryAllocate(size, is_protected);
    }
    if (result == 0) {
      result = TryAllocateInFreshPage(size, type, growth_policy, is_locked);
    }
  } else {
    // Large page allocation.
    intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
    if ((page_size_in_words << kWordSizeLog2) < size) {
      // On overflow we fail to allocate.
      return 0;
    }
    SpaceUsage after_allocation = usage_;
    after_allocation.used_in_words += size >> kWordSizeLog2;
    after_allocation.capacity_in_words += page_size_in_words;
    if ((growth_policy == kForceGrowth ||
         !page_space_controller_.NeedsGarbageCollection(after_allocation)) &&
        CanIncreaseCapacityInWords(page_size_in_words)) {
      HeapPage* page = AllocateLargePage(size, type);
      if (page != NULL) {
        result = page->object_start();
        usage_ = after_allocation;
      }
    }
  }
  if (result != 0) {
    if (FLAG_compiler_stats && (type == HeapPage::kExecutable)) {
      CompilerStats::code_allocated += size;
    }
  }
  ASSERT((result & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
  return result;
}


  void PageSpace::AcquireDataLock() {
    freelist_[HeapPage::kData].mutex()->Lock();
  }


  void PageSpace::ReleaseDataLock() {
    freelist_[HeapPage::kData].mutex()->Unlock();
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
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
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
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
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
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
  ASSERT((pages_ != NULL) || (exec_pages_ != NULL) || (large_pages_ != NULL));
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
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
  HeapPage* page = pages_;
  while (page != NULL) {
    page->VisitObjects(visitor);
    page = NextPageAnySize(page);
  }
}


void PageSpace::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
  HeapPage* page = pages_;
  while (page != NULL) {
    page->VisitObjectPointers(visitor);
    page = NextPageAnySize(page);
  }
}


RawObject* PageSpace::FindObject(FindObjectVisitor* visitor,
                                 HeapPage::PageType type) const {
  ASSERT(Isolate::Current()->no_gc_scope_depth() != 0);
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
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
  MutexLocker ml(pages_lock_);
  NoGCScope no_gc;
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
  space.AddProperty("type", "HeapSpace");
  space.AddProperty("id", "heaps/old");
  space.AddProperty("name", "old");
  space.AddProperty("vmName", "PageSpace");
  space.AddProperty("collections", collections());
  space.AddProperty("used", UsedInWords() * kWordSize);
  space.AddProperty("capacity", CapacityInWords() * kWordSize);
  space.AddProperty("external", ExternalInWords() * kWordSize);
  space.AddProperty("time", MicrosecondsToSeconds(gc_time_micros()));
  if (collections() > 0) {
    int64_t run_time = OS::GetCurrentTimeMicros() - isolate->start_time();
    run_time = Utils::Maximum(run_time, static_cast<int64_t>(0));
    double run_time_millis = MicrosecondsToMilliseconds(run_time);
    double avg_time_between_collections =
        run_time_millis / static_cast<double>(collections());
    space.AddProperty("avgCollectionPeriodMillis",
                      avg_time_between_collections);
  } else {
    space.AddProperty("avgCollectionPeriodMillis", 0.0);
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
    MutexLocker ml(pages_lock_);
    NoGCScope no_gc;
    JSONArray all_pages(&heap_map, "pages");
    for (HeapPage* page = pages_; page != NULL; page = page->next()) {
      JSONObject page_container(&all_pages);
      page_container.AddPropertyF("object_start",
                                  "0x%" Px "", page->object_start());
      JSONArray page_map(&page_container, "objects");
      HeapMapAsJSONVisitor printer(&page_map);
      page->VisitObjects(&printer);
    }
    for (HeapPage* page = exec_pages_; page != NULL; page = page->next()) {
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
    MutexLocker ml(pages_lock_);
    NoGCScope no_gc;
    // No need to go through all of the data pages first.
    HeapPage* page = exec_pages_;
    while (page != NULL) {
      ASSERT(page->type() == HeapPage::kExecutable);
      page->WriteProtect(read_only);
      page = page->next();
    }
    page = large_pages_;
    while (page != NULL) {
      if (page->type() == HeapPage::kExecutable) {
        page->WriteProtect(read_only);
      }
      page = page->next();
    }
  }
}


void PageSpace::MarkSweep(bool invoke_api_callbacks) {
  Isolate* isolate = heap_->isolate();
  ASSERT(isolate == Isolate::Current());

  // Wait for pending tasks to complete and then account for the driver task.
  {
    MonitorLocker locker(tasks_lock());
    while (tasks() > 0) {
      locker.Wait();
    }
    set_tasks(1);
  }

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

  // Abandon the remainder of the bump allocation block.
  bump_top_ = 0;
  bump_end_ = 0;
  // Reset the freelists and setup sweeping.
  freelist_[HeapPage::kData].Reset();
  freelist_[HeapPage::kExecutable].Reset();

  int64_t mid2 = OS::GetCurrentTimeMicros();
  int64_t mid3 = 0;

  {
    GCSweeper sweeper(heap_);

    // During stop-the-world phases we should use bulk lock when adding elements
    // to the free list.
    MutexLocker mld(freelist_[HeapPage::kData].mutex());
    MutexLocker mle(freelist_[HeapPage::kExecutable].mutex());

    // Large and executable pages are always swept immediately.
    HeapPage* prev_page = NULL;
    HeapPage* page = large_pages_;
    while (page != NULL) {
      HeapPage* next_page = page->next();
      const intptr_t words_to_end = sweeper.SweepLargePage(page);
      if (words_to_end == 0) {
        FreeLargePage(page, prev_page);
      } else {
        TruncateLargePage(page, words_to_end << kWordSizeLog2);
        prev_page = page;
      }
      // Advance to the next page.
      page = next_page;
    }

    prev_page = NULL;
    page = exec_pages_;
    FreeList* freelist = &freelist_[HeapPage::kExecutable];
    while (page != NULL) {
      HeapPage* next_page = page->next();
      bool page_in_use = sweeper.SweepPage(page, freelist);
      if (page_in_use) {
        prev_page = page;
      } else {
        FreePage(page, prev_page);
      }
      // Advance to the next page.
      page = next_page;
    }

    mid3 = OS::GetCurrentTimeMicros();

    if (!FLAG_concurrent_sweep) {
      // Sweep all regular sized pages now.
      prev_page = NULL;
      page = pages_;
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
    } else {
      // Start the concurrent sweeper task now.
      GCSweeper::SweepConcurrent(
          isolate, pages_, pages_tail_, &freelist_[HeapPage::kData]);
    }
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

  // Done, reset the task count.
  {
    MonitorLocker ml(tasks_lock());
    set_tasks(tasks() - 1);
    ml.Notify();
  }
}


uword PageSpace::TryAllocateDataBump(intptr_t size,
                                     GrowthPolicy growth_policy) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  intptr_t remaining = bump_end_ - bump_top_;
  if (remaining < size) {
    // Checking this first would be logical, but needlessly slow.
    if (size >= kAllocatablePageSize) {
      return TryAllocate(size, HeapPage::kData, growth_policy);
    }
    FreeListElement* block = freelist_[HeapPage::kData].TryAllocateLarge(size);
    if (block == NULL) {
      // Allocating from a new page (if growth policy allows) will have the
      // side-effect of populating the freelist with a large block. The next
      // bump allocation request will have a chance to consume that block.
      // TODO(koda): Could take freelist lock just once instead of twice.
      return TryAllocateInFreshPage(size,
                                    HeapPage::kData,
                                    growth_policy,
                                    /* is_locked = */ false);
    }
    intptr_t block_size = block->Size();
    bump_top_ = reinterpret_cast<uword>(block);
    bump_end_ = bump_top_ + block_size;
    remaining = block_size;
  }
  ASSERT(remaining >= size);
  uword result = bump_top_;
  bump_top_ += size;
  usage_.used_in_words += size >> kWordSizeLog2;
  remaining -= size;
  if (remaining > 0) {
    FreeListElement::AsElement(bump_top_, remaining);
  }
  return result;
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
  // The concurrent sweeper might have freed more capacity than was allocated.
  capacity_increase_in_words =
      Utils::Maximum<intptr_t>(0, capacity_increase_in_words);
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
  bool needs_gc = capacity_increase_in_pages * multiplier > grow_heap_;
  if (FLAG_log_growth) {
    OS::PrintErr("%s: %" Pd " * %f %s %" Pd "\n",
                 needs_gc ? "NEEDS GC" : "grow",
                 capacity_increase_in_pages,
                 multiplier,
                 needs_gc ? ">" : "<=",
                 grow_heap_);
  }
  return needs_gc;
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
