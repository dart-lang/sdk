// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/pages.h"

#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "vm/compiler_stats.h"
#include "vm/gc_marker.h"
#include "vm/gc_sweeper.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os_thread.h"
#include "vm/safepoint.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(int,
            old_gen_growth_space_ratio,
            20,
            "The desired maximum percentage of free space after old gen GC");
DEFINE_FLAG(int,
            old_gen_growth_time_ratio,
            3,
            "The desired maximum percentage of time spent in old gen GC");
DEFINE_FLAG(int,
            old_gen_growth_rate,
            280,
            "The max number of pages the old generation can grow at a time");
DEFINE_FLAG(bool,
            print_free_list_before_gc,
            false,
            "Print free list statistics before a GC");
DEFINE_FLAG(bool,
            print_free_list_after_gc,
            false,
            "Print free list statistics after a GC");
DEFINE_FLAG(int,
            code_collection_interval_in_us,
            30000000,
            "Time between attempts to collect unused code.");
DEFINE_FLAG(bool,
            log_code_drop,
            false,
            "Emit a log message when pointers to unused code are dropped.");
DEFINE_FLAG(bool,
            always_drop_code,
            false,
            "Always try to drop code if the function's usage counter is >= 0");
DEFINE_FLAG(bool, log_growth, false, "Log PageSpace growth policy decisions.");

HeapPage* HeapPage::Initialize(VirtualMemory* memory,
                               PageType type,
                               const char* name) {
  ASSERT(memory != NULL);
  ASSERT(memory->size() > VirtualMemory::PageSize());
  bool is_executable = (type == kExecutable);
  // Create the new page executable (RWX) only if we're not in W^X mode
  bool create_executable = !FLAG_write_protect_code && is_executable;
  if (!memory->Commit(create_executable, name)) {
    return NULL;
  }
  HeapPage* result = reinterpret_cast<HeapPage*>(memory->address());
  ASSERT(result != NULL);
  result->memory_ = memory;
  result->next_ = NULL;
  result->used_in_bytes_ = 0;
  result->type_ = type;

  LSAN_REGISTER_ROOT_REGION(result, sizeof(*result));

  return result;
}

HeapPage* HeapPage::Allocate(intptr_t size_in_words,
                             PageType type,
                             const char* name) {
  VirtualMemory* memory =
      VirtualMemory::Reserve(size_in_words << kWordSizeLog2);
  if (memory == NULL) {
    return NULL;
  }
  HeapPage* result = Initialize(memory, type, name);
  if (result == NULL) {
    delete memory;  // Release reservation to OS.
    return NULL;
  }
  return result;
}

void HeapPage::Deallocate() {
  bool image_page = is_image_page();

  if (!image_page) {
    LSAN_UNREGISTER_ROOT_REGION(this, sizeof(*this));
  }

  // For a regular heap pages, the memory for this object will become
  // unavailable after the delete below.
  delete memory_;

  // For a heap page from a snapshot, the HeapPage object lives in the malloc
  // heap rather than the page itself.
  if (image_page) {
    free(this);
  }
}

void HeapPage::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint());
  NoSafepointScope no_safepoint;
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
  ASSERT(Thread::Current()->IsAtSafepoint());
  NoSafepointScope no_safepoint;
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
  ASSERT(!is_image_page());

  VirtualMemory::Protection prot;
  if (read_only) {
    if (type_ == kExecutable) {
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

PageSpace::PageSpace(Heap* heap,
                     intptr_t max_capacity_in_words,
                     intptr_t max_external_in_words)
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
      max_external_in_words_(max_external_in_words),
      tasks_lock_(new Monitor()),
      tasks_(0),
#if defined(DEBUG)
      iterating_thread_(NULL),
#endif
      page_space_controller_(heap,
                             FLAG_old_gen_growth_space_ratio,
                             FLAG_old_gen_growth_rate,
                             FLAG_old_gen_growth_time_ratio),
      gc_time_micros_(0),
      collections_(0) {
  // We aren't holding the lock but no one can reference us yet.
  UpdateMaxCapacityLocked();
  UpdateMaxUsed();
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
  const bool is_exec = (type == HeapPage::kExecutable);
  const intptr_t kVmNameSize = 128;
  char vm_name[kVmNameSize];
  Heap::RegionName(heap_, is_exec ? Heap::kCode : Heap::kOld, vm_name,
                   kVmNameSize);
  HeapPage* page = HeapPage::Allocate(kPageSizeInWords, type, vm_name);
  if (page == NULL) {
    RELEASE_ASSERT(!FLAG_abort_on_oom);
    return NULL;
  }

  MutexLocker ml(pages_lock_);
  if (!is_exec) {
    if (pages_ == NULL) {
      pages_ = page;
    } else {
      pages_tail_->set_next(page);
    }
    pages_tail_ = page;
  } else {
    // Should not allocate executable pages when running from a precompiled
    // snapshot.
    ASSERT(Dart::vm_snapshot_kind() != Snapshot::kFullAOT);

    if (exec_pages_ == NULL) {
      exec_pages_ = page;
    } else {
      if (FLAG_write_protect_code && !exec_pages_tail_->is_image_page()) {
        exec_pages_tail_->WriteProtect(false);
      }
      exec_pages_tail_->set_next(page);
      if (FLAG_write_protect_code && !exec_pages_tail_->is_image_page()) {
        exec_pages_tail_->WriteProtect(true);
      }
    }
    exec_pages_tail_ = page;
  }
  IncreaseCapacityInWordsLocked(kPageSizeInWords);
  page->set_object_end(page->memory_->end());
  return page;
}

HeapPage* PageSpace::AllocateLargePage(intptr_t size, HeapPage::PageType type) {
  const bool is_exec = (type == HeapPage::kExecutable);
  const intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
  const intptr_t kVmNameSize = 128;
  char vm_name[kVmNameSize];
  Heap::RegionName(heap_, is_exec ? Heap::kCode : Heap::kOld, vm_name,
                   kVmNameSize);
  HeapPage* page = HeapPage::Allocate(page_size_in_words, type, vm_name);
  if (page == NULL) {
    return NULL;
  }
  page->set_next(large_pages_);
  large_pages_ = page;
  IncreaseCapacityInWords(page_size_in_words);
  // Only one object in this page (at least until String::MakeExternal or
  // Array::MakeFixedLength is called).
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
    memory->Truncate(new_page_size_in_words << kWordSizeLog2);
    IncreaseCapacityInWords(new_page_size_in_words - old_page_size_in_words);
    page->set_object_end(page->object_start() + new_object_size_in_bytes);
  }
}

void PageSpace::FreePage(HeapPage* page, HeapPage* previous_page) {
  bool is_exec = (page->type() == HeapPage::kExecutable);
  {
    MutexLocker ml(pages_lock_);
    IncreaseCapacityInWordsLocked(-(page->memory_->size() >> kWordSizeLog2));
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
  IncreaseCapacityInWords(-(page->memory_->size() >> kWordSizeLog2));
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
  SpaceUsage after_allocation = GetCurrentUsage();
  after_allocation.used_in_words += size >> kWordSizeLog2;
  // Can we grow by one page?
  after_allocation.capacity_in_words += kPageSizeInWords;
  if ((growth_policy == kForceGrowth ||
       !page_space_controller_.NeedsGarbageCollection(after_allocation)) &&
      CanIncreaseCapacityInWords(kPageSizeInWords)) {
    HeapPage* page = AllocatePage(type);
    if (page == NULL) {
      return 0;
    }
    // Start of the newly allocated page is the allocated object.
    result = page->object_start();
    // Note: usage_.capacity_in_words is increased by AllocatePage.
    AtomicOperations::IncrementBy(&(usage_.used_in_words),
                                  (size >> kWordSizeLog2));
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
      // usage_ is updated by the call above.
    } else {
      AtomicOperations::IncrementBy(&(usage_.used_in_words),
                                    (size >> kWordSizeLog2));
    }
  } else {
    // Large page allocation.
    intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
    if ((page_size_in_words << kWordSizeLog2) < size) {
      // On overflow we fail to allocate.
      return 0;
    }
    SpaceUsage after_allocation = GetCurrentUsage();
    after_allocation.used_in_words += size >> kWordSizeLog2;
    after_allocation.capacity_in_words += page_size_in_words;
    if ((growth_policy == kForceGrowth ||
         !page_space_controller_.NeedsGarbageCollection(after_allocation)) &&
        CanIncreaseCapacityInWords(page_size_in_words)) {
      HeapPage* page = AllocateLargePage(size, type);
      if (page != NULL) {
        result = page->object_start();
        // Note: usage_.capacity_in_words is increased by AllocateLargePage.
        AtomicOperations::IncrementBy(&(usage_.used_in_words),
                                      (size >> kWordSizeLog2));
      }
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

void PageSpace::AllocateExternal(intptr_t cid, intptr_t size) {
  intptr_t size_in_words = size >> kWordSizeLog2;
  AtomicOperations::IncrementBy(&(usage_.external_in_words), size_in_words);
  NOT_IN_PRODUCT(
      heap_->isolate()->class_table()->UpdateAllocatedExternalOld(cid, size));
  // TODO(koda): Control growth.
}

void PageSpace::FreeExternal(intptr_t size) {
  intptr_t size_in_words = size >> kWordSizeLog2;
  AtomicOperations::DecrementBy(&(usage_.external_in_words), size_in_words);
}

// Provides exclusive access to all pages, and ensures they are walkable.
class ExclusivePageIterator : ValueObject {
 public:
  explicit ExclusivePageIterator(const PageSpace* space)
      : space_(space), ml_(space->pages_lock_) {
    space_->MakeIterable();
    page_ = space_->pages_;
    if (page_ == NULL) {
      page_ = space_->exec_pages_;
      if (page_ == NULL) {
        page_ = space_->large_pages_;
      }
    }
  }
  HeapPage* page() const { return page_; }
  bool Done() const { return page_ == NULL; }
  void Advance() {
    ASSERT(!Done());
    page_ = space_->NextPageAnySize(page_);
  }

 private:
  const PageSpace* space_;
  MutexLocker ml_;
  NoSafepointScope no_safepoint;
  HeapPage* page_;
};

// Provides exclusive access to code pages, and ensures they are walkable.
// NOTE: This does not iterate over large pages which can contain code.
class ExclusiveCodePageIterator : ValueObject {
 public:
  explicit ExclusiveCodePageIterator(const PageSpace* space)
      : space_(space), ml_(space->pages_lock_) {
    space_->MakeIterable();
    page_ = space_->exec_pages_;
  }
  HeapPage* page() const { return page_; }
  bool Done() const { return page_ == NULL; }
  void Advance() {
    ASSERT(!Done());
    page_ = page_->next();
  }

 private:
  const PageSpace* space_;
  MutexLocker ml_;
  NoSafepointScope no_safepoint;
  HeapPage* page_;
};

// Provides exclusive access to large pages, and ensures they are walkable.
class ExclusiveLargePageIterator : ValueObject {
 public:
  explicit ExclusiveLargePageIterator(const PageSpace* space)
      : space_(space), ml_(space->pages_lock_) {
    space_->MakeIterable();
    page_ = space_->large_pages_;
  }
  HeapPage* page() const { return page_; }
  bool Done() const { return page_ == NULL; }
  void Advance() {
    ASSERT(!Done());
    page_ = page_->next();
  }

 private:
  const PageSpace* space_;
  MutexLocker ml_;
  NoSafepointScope no_safepoint;
  HeapPage* page_;
};

void PageSpace::MakeIterable() const {
  // Assert not called from concurrent sweeper task.
  // TODO(koda): Use thread/task identity when implemented.
  ASSERT(Isolate::Current()->heap() != NULL);
  if (bump_top_ < bump_end_) {
    FreeListElement::AsElement(bump_top_, bump_end_ - bump_top_);
  }
}

void PageSpace::AbandonBumpAllocation() {
  if (bump_top_ < bump_end_) {
    freelist_[HeapPage::kData].Free(bump_top_, bump_end_ - bump_top_);
    bump_top_ = 0;
    bump_end_ = 0;
  }
}

void PageSpace::UpdateMaxCapacityLocked() {
#if !defined(PRODUCT)
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(heap_ != NULL);
  ASSERT(heap_->isolate() != NULL);
  Isolate* isolate = heap_->isolate();
  isolate->GetHeapOldCapacityMaxMetric()->SetValue(
      static_cast<int64_t>(usage_.capacity_in_words) * kWordSize);
#endif  // !defined(PRODUCT)
}

void PageSpace::UpdateMaxUsed() {
#if !defined(PRODUCT)
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(heap_ != NULL);
  ASSERT(heap_->isolate() != NULL);
  Isolate* isolate = heap_->isolate();
  isolate->GetHeapOldUsedMaxMetric()->SetValue(UsedInWords() * kWordSize);
#endif  // !defined(PRODUCT)
}

bool PageSpace::Contains(uword addr) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->Contains(addr)) {
      return true;
    }
  }
  return false;
}

bool PageSpace::Contains(uword addr, HeapPage::PageType type) const {
  if (type == HeapPage::kExecutable) {
    // Fast path executable pages.
    for (ExclusiveCodePageIterator it(this); !it.Done(); it.Advance()) {
      if (it.page()->Contains(addr)) {
        return true;
      }
    }
    // Large pages can be executable, walk them too.
    for (ExclusiveLargePageIterator it(this); !it.Done(); it.Advance()) {
      if ((it.page()->type() == type) && it.page()->Contains(addr)) {
        return true;
      }
    }
    return false;
  }
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if ((it.page()->type() == type) && it.page()->Contains(addr)) {
      return true;
    }
  }
  return false;
}

bool PageSpace::DataContains(uword addr) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if ((it.page()->type() != HeapPage::kExecutable) &&
        it.page()->Contains(addr)) {
      return true;
    }
  }
  return false;
}

void PageSpace::AddRegionsToObjectSet(ObjectSet* set) const {
  ASSERT((pages_ != NULL) || (exec_pages_ != NULL) || (large_pages_ != NULL));
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    set->AddRegion(it.page()->object_start(), it.page()->object_end());
  }
}

void PageSpace::VisitObjects(ObjectVisitor* visitor) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    it.page()->VisitObjects(visitor);
  }
}

void PageSpace::VisitObjectsNoImagePages(ObjectVisitor* visitor) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (!it.page()->is_image_page()) {
      it.page()->VisitObjects(visitor);
    }
  }
}

void PageSpace::VisitObjectsImagePages(ObjectVisitor* visitor) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->is_image_page()) {
      it.page()->VisitObjects(visitor);
    }
  }
}

void PageSpace::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    it.page()->VisitObjectPointers(visitor);
  }
}

RawObject* PageSpace::FindObject(FindObjectVisitor* visitor,
                                 HeapPage::PageType type) const {
  if (type == HeapPage::kExecutable) {
    // Fast path executable pages.
    for (ExclusiveCodePageIterator it(this); !it.Done(); it.Advance()) {
      RawObject* obj = it.page()->FindObject(visitor);
      if (obj != Object::null()) {
        return obj;
      }
    }
    // Large pages can be executable, walk them too.
    for (ExclusiveLargePageIterator it(this); !it.Done(); it.Advance()) {
      if (it.page()->type() == type) {
        RawObject* obj = it.page()->FindObject(visitor);
        if (obj != Object::null()) {
          return obj;
        }
      }
    }
    return Object::null();
  }

  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->type() == type) {
      RawObject* obj = it.page()->FindObject(visitor);
      if (obj != Object::null()) {
        return obj;
      }
    }
  }
  return Object::null();
}

void PageSpace::WriteProtect(bool read_only) {
  if (read_only) {
    // Avoid MakeIterable trying to write to the heap.
    AbandonBumpAllocation();
  }
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (!it.page()->is_image_page()) {
      it.page()->WriteProtect(read_only);
    }
  }
}

#ifndef PRODUCT
void PageSpace::PrintToJSONObject(JSONObject* object) const {
  if (!FLAG_support_service) {
    return;
  }
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  JSONObject space(object, "old");
  space.AddProperty("type", "HeapSpace");
  space.AddProperty("name", "old");
  space.AddProperty("vmName", "PageSpace");
  space.AddProperty("collections", collections());
  space.AddProperty64("used", UsedInWords() * kWordSize);
  space.AddProperty64("capacity", CapacityInWords() * kWordSize);
  space.AddProperty64("external", ExternalInWords() * kWordSize);
  space.AddProperty("time", MicrosecondsToSeconds(gc_time_micros()));
  if (collections() > 0) {
    int64_t run_time = isolate->UptimeMicros();
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
  explicit HeapMapAsJSONVisitor(JSONArray* array) : array_(array) {}
  virtual void VisitObject(RawObject* obj) {
    array_->AddValue(obj->Size() / kObjectAlignment);
    array_->AddValue(obj->GetClassId());
  }

 private:
  JSONArray* array_;
};

void PageSpace::PrintHeapMapToJSONStream(Isolate* isolate,
                                         JSONStream* stream) const {
  if (!FLAG_support_service) {
    return;
  }
  JSONObject heap_map(stream);
  heap_map.AddProperty("type", "HeapMap");
  heap_map.AddProperty("freeClassId", static_cast<intptr_t>(kFreeListElement));
  heap_map.AddProperty("unitSizeBytes",
                       static_cast<intptr_t>(kObjectAlignment));
  heap_map.AddProperty("pageSizeBytes", kPageSizeInWords * kWordSize);
  {
    JSONObject class_list(&heap_map, "classList");
    isolate->class_table()->PrintToJSONObject(&class_list);
  }
  {
    // "pages" is an array [page0, page1, ..., pageN], each page of the form
    // {"object_start": "0x...", "objects": [size, class id, size, ...]}
    // TODO(19445): Use ExclusivePageIterator once HeapMap supports large pages.
    HeapIterationScope iteration(Thread::Current());
    MutexLocker ml(pages_lock_);
    MakeIterable();
    JSONArray all_pages(&heap_map, "pages");
    for (HeapPage* page = pages_; page != NULL; page = page->next()) {
      JSONObject page_container(&all_pages);
      page_container.AddPropertyF("objectStart", "0x%" Px "",
                                  page->object_start());
      JSONArray page_map(&page_container, "objects");
      HeapMapAsJSONVisitor printer(&page_map);
      page->VisitObjects(&printer);
    }
    for (HeapPage* page = exec_pages_; page != NULL; page = page->next()) {
      JSONObject page_container(&all_pages);
      page_container.AddPropertyF("objectStart", "0x%" Px "",
                                  page->object_start());
      JSONArray page_map(&page_container, "objects");
      HeapMapAsJSONVisitor printer(&page_map);
      page->VisitObjects(&printer);
    }
  }
}
#endif  // PRODUCT

bool PageSpace::ShouldCollectCode() {
  // Try to collect code if enough time has passed since the last attempt.
  const int64_t start = OS::GetCurrentMonotonicMicros();
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
    NoSafepointScope no_safepoint;
    // No need to go through all of the data pages first.
    HeapPage* page = exec_pages_;
    while (page != NULL) {
      ASSERT(page->type() == HeapPage::kExecutable);
      if (!page->is_image_page()) {
        page->WriteProtect(read_only);
      }
      page = page->next();
    }
    page = large_pages_;
    while (page != NULL) {
      if (page->type() == HeapPage::kExecutable && !page->is_image_page()) {
        page->WriteProtect(read_only);
      }
      page = page->next();
    }
  }
}

void PageSpace::MarkSweep() {
  Thread* thread = Thread::Current();
  Isolate* isolate = heap_->isolate();
  ASSERT(isolate == Isolate::Current());

  const int64_t pre_wait_for_sweepers = OS::GetCurrentMonotonicMicros();

  // Wait for pending tasks to complete and then account for the driver task.
  {
    MonitorLocker locker(tasks_lock());
    while (tasks() > 0) {
      locker.WaitWithSafepointCheck(thread);
    }
    set_tasks(1);
  }

  const int64_t pre_safe_point = OS::GetCurrentMonotonicMicros();

  // Ensure that all threads for this isolate are at a safepoint (either
  // stopped or in native code). We have guards around Newgen GC and oldgen GC
  // to ensure that if two threads are racing to collect at the same time the
  // loser skips collection and goes straight to allocation.
  {
    SafepointOperationScope safepoint_scope(thread);

    const int64_t start = OS::GetCurrentMonotonicMicros();

    // Perform various cleanup that relies on no tasks interfering.
    isolate->class_table()->FreeOldTables();

    NoSafepointScope no_safepoints;

    if (FLAG_print_free_list_before_gc) {
      OS::Print("Data Freelist (before GC):\n");
      freelist_[HeapPage::kData].Print();
      OS::Print("Executable Freelist (before GC):\n");
      freelist_[HeapPage::kExecutable].Print();
    }

    if (FLAG_verify_before_gc) {
      OS::PrintErr("Verifying before marking...");
      heap_->VerifyGC();
      OS::PrintErr(" done.\n");
    }

    // Make code pages writable.
    WriteProtectCode(false);

    // Save old value before GCMarker visits the weak persistent handles.
    SpaceUsage usage_before = GetCurrentUsage();

    // Mark all reachable old-gen objects.
#if defined(PRODUCT)
    bool collect_code = FLAG_collect_code && ShouldCollectCode();
#else
    bool collect_code = FLAG_collect_code && ShouldCollectCode() &&
                        !isolate->HasAttemptedReload();
#endif  // !defined(PRODUCT)
    GCMarker marker(heap_);
    marker.MarkObjects(isolate, this, collect_code);
    usage_.used_in_words = marker.marked_words();

    int64_t mid1 = OS::GetCurrentMonotonicMicros();

    // Abandon the remainder of the bump allocation block.
    AbandonBumpAllocation();
    // Reset the freelists and setup sweeping.
    freelist_[HeapPage::kData].Reset();
    freelist_[HeapPage::kExecutable].Reset();

    int64_t mid2 = OS::GetCurrentMonotonicMicros();
    int64_t mid3 = 0;

    {
      if (FLAG_verify_before_gc) {
        OS::PrintErr("Verifying before sweeping...");
        heap_->VerifyGC(kAllowMarked);
        OS::PrintErr(" done.\n");
      }
      GCSweeper sweeper;

      // During stop-the-world phases we should use bulk lock when adding
      // elements to the free list.
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
        bool page_in_use = sweeper.SweepPage(page, freelist, true);
        if (page_in_use) {
          prev_page = page;
        } else {
          FreePage(page, prev_page);
        }
        // Advance to the next page.
        page = next_page;
      }

      mid3 = OS::GetCurrentMonotonicMicros();

      if (!FLAG_concurrent_sweep) {
        // Sweep all regular sized pages now.
        prev_page = NULL;
        page = pages_;
        while (page != NULL) {
          HeapPage* next_page = page->next();
          bool page_in_use =
              sweeper.SweepPage(page, &freelist_[page->type()], true);
          if (page_in_use) {
            prev_page = page;
          } else {
            FreePage(page, prev_page);
          }
          // Advance to the next page.
          page = next_page;
        }
        if (FLAG_verify_after_gc) {
          OS::PrintErr("Verifying after sweeping...");
          heap_->VerifyGC(kForbidMarked);
          OS::PrintErr(" done.\n");
        }
      } else {
        // Start the concurrent sweeper task now.
        GCSweeper::SweepConcurrent(isolate, pages_, pages_tail_,
                                   &freelist_[HeapPage::kData]);
      }
    }

    // Make code pages read-only.
    WriteProtectCode(true);

    int64_t end = OS::GetCurrentMonotonicMicros();

    // Record signals for growth control. Include size of external allocations.
    page_space_controller_.EvaluateGarbageCollection(
        usage_before, GetCurrentUsage(), start, end);

    heap_->RecordTime(kConcurrentSweep, pre_safe_point - pre_wait_for_sweepers);
    heap_->RecordTime(kSafePoint, start - pre_safe_point);
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

    UpdateMaxUsed();
    if (heap_ != NULL) {
      heap_->UpdateGlobalMaxUsed();
    }
  }

  // Done, reset the task count.
  {
    MonitorLocker ml(tasks_lock());
    set_tasks(tasks() - 1);
    ml.NotifyAll();
  }
}

uword PageSpace::TryAllocateDataBumpInternal(intptr_t size,
                                             GrowthPolicy growth_policy,
                                             bool is_locked) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  intptr_t remaining = bump_end_ - bump_top_;
  if (remaining < size) {
    // Checking this first would be logical, but needlessly slow.
    if (size >= kAllocatablePageSize) {
      return is_locked ? TryAllocateDataLocked(size, growth_policy)
                       : TryAllocate(size, HeapPage::kData, growth_policy);
    }
    FreeListElement* block =
        is_locked ? freelist_[HeapPage::kData].TryAllocateLargeLocked(size)
                  : freelist_[HeapPage::kData].TryAllocateLarge(size);
    if (block == NULL) {
      // Allocating from a new page (if growth policy allows) will have the
      // side-effect of populating the freelist with a large block. The next
      // bump allocation request will have a chance to consume that block.
      // TODO(koda): Could take freelist lock just once instead of twice.
      return TryAllocateInFreshPage(size, HeapPage::kData, growth_policy,
                                    is_locked);
    }
    intptr_t block_size = block->Size();
    if (remaining > 0) {
      if (is_locked) {
        freelist_[HeapPage::kData].FreeLocked(bump_top_, remaining);
      } else {
        freelist_[HeapPage::kData].Free(bump_top_, remaining);
      }
    }
    bump_top_ = reinterpret_cast<uword>(block);
    bump_end_ = bump_top_ + block_size;
    remaining = block_size;
  }
  ASSERT(remaining >= size);
  uword result = bump_top_;
  bump_top_ += size;
  AtomicOperations::IncrementBy(&(usage_.used_in_words),
                                (size >> kWordSizeLog2));
// Note: Remaining block is unwalkable until MakeIterable is called.
#ifdef DEBUG
  if (bump_top_ < bump_end_) {
    // Fail fast if we try to walk the remaining block.
    COMPILE_ASSERT(kIllegalCid == 0);
    *reinterpret_cast<uword*>(bump_top_) = 0;
  }
#endif  // DEBUG
  return result;
}

uword PageSpace::TryAllocateDataBump(intptr_t size,
                                     GrowthPolicy growth_policy) {
  return TryAllocateDataBumpInternal(size, growth_policy, false);
}

uword PageSpace::TryAllocateDataBumpLocked(intptr_t size,
                                           GrowthPolicy growth_policy) {
  return TryAllocateDataBumpInternal(size, growth_policy, true);
}

uword PageSpace::TryAllocatePromoLocked(intptr_t size,
                                        GrowthPolicy growth_policy) {
  FreeList* freelist = &freelist_[HeapPage::kData];
  uword result = freelist->TryAllocateSmallLocked(size);
  if (result != 0) {
    AtomicOperations::IncrementBy(&(usage_.used_in_words),
                                  (size >> kWordSizeLog2));
    return result;
  }
  result = TryAllocateDataBumpLocked(size, growth_policy);
  if (result != 0) return result;
  return TryAllocateDataLocked(size, growth_policy);
}

void PageSpace::SetupImagePage(void* pointer, uword size, bool is_executable) {
  // Setup a HeapPage so precompiled Instructions can be traversed.
  // Instructions are contiguous at [pointer, pointer + size). HeapPage
  // expects to find objects at [memory->start() + ObjectStartOffset,
  // memory->end()).
  uword offset = HeapPage::ObjectStartOffset();
  pointer = reinterpret_cast<void*>(reinterpret_cast<uword>(pointer) - offset);
  size += offset;

  VirtualMemory* memory = VirtualMemory::ForImagePage(pointer, size);
  ASSERT(memory != NULL);
  HeapPage* page = reinterpret_cast<HeapPage*>(malloc(sizeof(HeapPage)));
  page->memory_ = memory;
  page->next_ = NULL;
  page->object_end_ = memory->end();
  page->used_in_bytes_ = page->object_end_ - page->object_start();

  MutexLocker ml(pages_lock_);
  HeapPage **first, **tail;
  if (is_executable) {
    ASSERT(Utils::IsAligned(pointer, OS::PreferredCodeAlignment()));
    page->type_ = HeapPage::kExecutable;
    first = &exec_pages_;
    tail = &exec_pages_tail_;
  } else {
    page->type_ = HeapPage::kData;
    first = &pages_;
    tail = &pages_tail_;
  }
  if (*first == NULL) {
    *first = page;
  } else {
    if (is_executable && FLAG_write_protect_code && !(*tail)->is_image_page()) {
      (*tail)->WriteProtect(false);
    }
    (*tail)->set_next(page);
    if (is_executable && FLAG_write_protect_code && !(*tail)->is_image_page()) {
      (*tail)->WriteProtect(true);
    }
  }
  (*tail) = page;
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
      last_code_collection_in_us_(OS::GetCurrentMonotonicMicros()) {}

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
    double seconds_since_init =
        MicrosecondsToSeconds(heap_->isolate()->UptimeMicros());
    if (seconds_since_init > kInitialTimeoutSeconds) {
      multiplier *= seconds_since_init / kInitialTimeoutSeconds;
    }
  }
  bool needs_gc = capacity_increase_in_pages * multiplier > grow_heap_;
  if (FLAG_log_growth) {
    OS::PrintErr("%s: %" Pd " * %f %s %" Pd "\n",
                 needs_gc ? "NEEDS GC" : "grow", capacity_increase_in_pages,
                 multiplier, needs_gc ? ">" : "<=", grow_heap_);
  }
  return needs_gc;
}

void PageSpaceController::EvaluateGarbageCollection(SpaceUsage before,
                                                    SpaceUsage after,
                                                    int64_t start,
                                                    int64_t end) {
  ASSERT(end >= start);
  history_.AddGarbageCollectionTime(start, end);
  const int gc_time_fraction = history_.GarbageCollectionTimeFraction();
  heap_->RecordData(PageSpace::kGCTimeFraction, gc_time_fraction);

  // Assume garbage increases linearly with allocation:
  // G = kA, and estimate k from the previous cycle.
  const intptr_t allocated_since_previous_gc =
      before.used_in_words - last_usage_.used_in_words;
  if (allocated_since_previous_gc > 0) {
    const intptr_t garbage = before.used_in_words - after.used_in_words;
    ASSERT(garbage >= 0);
    // It makes no sense to expect that each kb allocated will cause more than
    // one kb of garbage, so we clamp k at 1.0.
    const double k = Utils::Minimum(
        1.0, garbage / static_cast<double>(allocated_since_previous_gc));

    const int garbage_ratio = static_cast<int>(k * 100);
    heap_->RecordData(PageSpace::kGarbageRatio, garbage_ratio);

    // Define GC to be 'worthwhile' iff at least fraction t of heap is garbage.
    double t = 1.0 - desired_utilization_;
    // If we spend too much time in GC, strive for even more free space.
    if (gc_time_fraction > garbage_collection_time_ratio_) {
      t += (gc_time_fraction - garbage_collection_time_ratio_) / 100.0;
    }

    // Number of pages we can allocate and still be within the desired growth
    // ratio.
    const intptr_t grow_pages =
        (static_cast<intptr_t>(after.capacity_in_words / desired_utilization_) -
         after.capacity_in_words) /
        PageSpace::kPageSizeInWords;
    if (garbage_ratio == 0) {
      // No garbage in the previous cycle so it would be hard to compute a
      // grow_heap_ size based on estimated garbage so we use growth ratio
      // heuristics instead.
      grow_heap_ =
          Utils::Maximum(static_cast<intptr_t>(heap_growth_max_), grow_pages);
    } else {
      // Find minimum 'grow_heap_' such that after increasing capacity by
      // 'grow_heap_' pages and filling them, we expect a GC to be worthwhile.
      intptr_t max = heap_growth_max_;
      intptr_t min = 0;
      intptr_t local_grow_heap = 0;
      while (min < max) {
        local_grow_heap = (max + min) / 2;
        const intptr_t limit = after.capacity_in_words +
                               (local_grow_heap * PageSpace::kPageSizeInWords);
        const intptr_t allocated_before_next_gc = limit - after.used_in_words;
        const double estimated_garbage = k * allocated_before_next_gc;
        if (t <= estimated_garbage / limit) {
          max = local_grow_heap - 1;
        } else {
          min = local_grow_heap + 1;
        }
      }
      local_grow_heap = (max + min) / 2;
      grow_heap_ = local_grow_heap;
      ASSERT(grow_heap_ >= 0);
      // If we are going to grow by heap_grow_max_ then ensure that we
      // will be growing the heap at least by the growth ratio heuristics.
      if (grow_heap_ >= heap_growth_max_) {
        grow_heap_ = Utils::Maximum(grow_pages, grow_heap_);
      }
    }
  } else {
    heap_->RecordData(PageSpace::kGarbageRatio, 100);
    grow_heap_ = 0;
  }
  heap_->RecordData(PageSpace::kPageGrowth, grow_heap_);

  // Limit shrinkage: allow growth by at least half the pages freed by GC.
  const intptr_t freed_pages =
      (before.capacity_in_words - after.capacity_in_words) /
      PageSpace::kPageSizeInWords;
  grow_heap_ = Utils::Maximum(grow_heap_, freed_pages / 2);
  heap_->RecordData(PageSpace::kAllowedGrowth, grow_heap_);
  last_usage_ = after;
}

void PageSpaceGarbageCollectionHistory::AddGarbageCollectionTime(int64_t start,
                                                                 int64_t end) {
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
    int result = static_cast<int>(
        (static_cast<double>(gc_time) / static_cast<double>(total_time)) * 100);
    return result;
  }
}

}  // namespace dart
