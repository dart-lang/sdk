// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/pages.h"

#include "platform/assert.h"
#include "platform/leak_sanitizer.h"
#include "platform/unwinding_records.h"
#include "vm/dart.h"
#include "vm/heap/become.h"
#include "vm/heap/compactor.h"
#include "vm/heap/incremental_compactor.h"
#include "vm/heap/marker.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/sweeper.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os_thread.h"
#include "vm/thread_barrier.h"
#include "vm/unwinding_records.h"
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
DEFINE_FLAG(bool, log_growth, false, "Log PageSpace growth policy decisions.");

// The initial estimate of how many words we can mark per microsecond (usage
// before / mark-sweep time). This is a conservative value observed running
// Flutter on a Nexus 4. After the first mark-sweep, we instead use a value
// based on the device's actual speed.
static constexpr intptr_t kConservativeInitialMarkSpeed = 20;

PageSpace::PageSpace(Heap* heap, intptr_t max_capacity_in_words)
    : heap_(heap),
      num_freelists_(Scavenger::NumDataFreelists() + 1),
      freelists_(new FreeList[num_freelists_]),
      pages_lock_(),
      max_capacity_in_words_(max_capacity_in_words),
      usage_(),
      allocated_black_in_words_(0),
      tasks_lock_(),
      tasks_(0),
      concurrent_marker_tasks_(0),
      concurrent_marker_tasks_active_(0),
      pause_concurrent_marking_(0),
      phase_(kDone),
#if defined(DEBUG)
      iterating_thread_(nullptr),
#endif
      page_space_controller_(heap,
                             FLAG_old_gen_growth_space_ratio,
                             FLAG_old_gen_growth_rate,
                             FLAG_old_gen_growth_time_ratio),
      marker_(nullptr),
      gc_time_micros_(0),
      collections_(0),
      mark_words_per_micro_(kConservativeInitialMarkSpeed),
      enable_concurrent_mark_(FLAG_concurrent_mark) {
  ASSERT(heap != nullptr);

  // We aren't holding the lock but no one can reference us yet.
  UpdateMaxCapacityLocked();
  UpdateMaxUsed();

  for (intptr_t i = 0; i < num_freelists_; i++) {
    freelists_[i].Reset();
  }

  TryReserveForOOM();
}

PageSpace::~PageSpace() {
  {
    MonitorLocker ml(tasks_lock());
    AssistTasks(&ml);
    while (tasks() > 0) {
      ml.Wait();
    }
  }
  FreePages(pages_);
  FreePages(exec_pages_);
  FreePages(large_pages_);
  FreePages(image_pages_);
  ASSERT(marker_ == nullptr);
  delete[] freelists_;
}

intptr_t PageSpace::LargePageSizeInWordsFor(intptr_t size) {
  intptr_t page_size = Utils::RoundUp(size + Page::OldObjectStartOffset(),
                                      VirtualMemory::PageSize());
  return page_size >> kWordSizeLog2;
}

void PageSpace::AddPageLocked(Page* page) {
  if (pages_ == nullptr) {
    pages_ = page;
  } else {
    pages_tail_->set_next(page);
  }
  pages_tail_ = page;
}

void PageSpace::AddLargePageLocked(Page* page) {
  if (large_pages_ == nullptr) {
    large_pages_ = page;
  } else {
    large_pages_tail_->set_next(page);
  }
  large_pages_tail_ = page;
}

void PageSpace::AddExecPageLocked(Page* page) {
  if (exec_pages_ == nullptr) {
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

void PageSpace::RemovePageLocked(Page* page, Page* previous_page) {
  if (previous_page != nullptr) {
    previous_page->set_next(page->next());
  } else {
    pages_ = page->next();
  }
  if (page == pages_tail_) {
    pages_tail_ = previous_page;
  }
}

void PageSpace::RemoveLargePageLocked(Page* page, Page* previous_page) {
  if (previous_page != nullptr) {
    previous_page->set_next(page->next());
  } else {
    large_pages_ = page->next();
  }
  if (page == large_pages_tail_) {
    large_pages_tail_ = previous_page;
  }
}

void PageSpace::RemoveExecPageLocked(Page* page, Page* previous_page) {
  if (previous_page != nullptr) {
    previous_page->set_next(page->next());
  } else {
    exec_pages_ = page->next();
  }
  if (page == exec_pages_tail_) {
    exec_pages_tail_ = previous_page;
  }
}

Page* PageSpace::AllocatePage(bool is_exec, bool link) {
  {
    MutexLocker ml(&pages_lock_);
    if (!CanIncreaseCapacityInWordsLocked(kPageSizeInWords)) {
      return nullptr;
    }
    IncreaseCapacityInWordsLocked(kPageSizeInWords);
  }
  uword flags = 0;
  if (is_exec) {
    flags |= Page::kExecutable;
  }
  if ((heap_ != nullptr) && (heap_->is_vm_isolate())) {
    flags |= Page::kVMIsolate;
  }
  Page* page = Page::Allocate(kPageSize, flags);
  if (page == nullptr) {
    RELEASE_ASSERT(!FLAG_abort_on_oom);
    IncreaseCapacityInWords(-kPageSizeInWords);
    return nullptr;
  }

  MutexLocker ml(&pages_lock_);
  if (link) {
    if (is_exec) {
      AddExecPageLocked(page);
    } else {
      AddPageLocked(page);
    }
  }

  page->set_object_end(page->memory_->end());
  if (!is_exec && (heap_ != nullptr) && !heap_->is_vm_isolate()) {
    page->AllocateForwardingPage();
  }

  if (is_exec) {
    UnwindingRecords::RegisterExecutablePage(page);
  }
  return page;
}

Page* PageSpace::AllocateLargePage(intptr_t size, bool is_exec) {
  const intptr_t page_size_in_words = LargePageSizeInWordsFor(
      size + (is_exec ? UnwindingRecordsPlatform::SizeInBytes() : 0));
  {
    MutexLocker ml(&pages_lock_);
    if (!CanIncreaseCapacityInWordsLocked(page_size_in_words)) {
      return nullptr;
    }
    IncreaseCapacityInWordsLocked(page_size_in_words);
  }
  uword flags = Page::kLarge;
  if (is_exec) {
    flags |= Page::kExecutable;
  }
  if ((heap_ != nullptr) && (heap_->is_vm_isolate())) {
    flags |= Page::kVMIsolate;
  }
  Page* page = Page::Allocate(page_size_in_words << kWordSizeLog2, flags);

  MutexLocker ml(&pages_lock_);
  if (page == nullptr) {
    IncreaseCapacityInWordsLocked(-page_size_in_words);
    return nullptr;
  } else {
    intptr_t actual_size_in_words = page->memory_->size() >> kWordSizeLog2;
    if (actual_size_in_words != page_size_in_words) {
      IncreaseCapacityInWordsLocked(actual_size_in_words - page_size_in_words);
    }
  }
  if (is_exec) {
    AddExecPageLocked(page);
  } else {
    AddLargePageLocked(page);
  }

  if (is_exec) {
    UnwindingRecords::RegisterExecutablePage(page);
  }

  // Only one object in this page (at least until Array::MakeFixedLength
  // is called).
  page->set_object_end(page->object_start() + size);
  return page;
}

void PageSpace::TruncateLargePage(Page* page,
                                  intptr_t new_object_size_in_bytes) {
  const intptr_t old_object_size_in_bytes =
      page->object_end() - page->object_start();
  ASSERT(new_object_size_in_bytes <= old_object_size_in_bytes);
  ASSERT(!page->is_executable());
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

void PageSpace::FreePage(Page* page, Page* previous_page) {
  bool is_exec = page->is_executable();
  {
    MutexLocker ml(&pages_lock_);
    IncreaseCapacityInWordsLocked(-(page->memory_->size() >> kWordSizeLog2));
    if (is_exec) {
      RemoveExecPageLocked(page, previous_page);
    } else {
      RemovePageLocked(page, previous_page);
    }
  }
  if (is_exec && !page->is_image()) {
    UnwindingRecords::UnregisterExecutablePage(page);
  }
  page->Deallocate();
}

void PageSpace::FreeLargePage(Page* page, Page* previous_page) {
  ASSERT(!page->is_executable());
  MutexLocker ml(&pages_lock_);
  IncreaseCapacityInWordsLocked(-(page->memory_->size() >> kWordSizeLog2));
  RemoveLargePageLocked(page, previous_page);
  page->Deallocate();
}

void PageSpace::FreePages(Page* pages) {
  Page* page = pages;
  while (page != nullptr) {
    Page* next = page->next();
    if (page->is_executable() && !page->is_image()) {
      UnwindingRecords::UnregisterExecutablePage(page);
    }
    page->Deallocate();
    page = next;
  }
}

uword PageSpace::TryAllocateInFreshPage(intptr_t size,
                                        FreeList* freelist,
                                        bool is_exec,
                                        GrowthPolicy growth_policy,
                                        bool is_locked) {
  ASSERT(IsAllocatableViaFreeLists(size));

  if (growth_policy != kForceGrowth) {
    ASSERT(!Thread::Current()->force_growth());
    heap_->CheckConcurrentMarking(Thread::Current(), GCReason::kOldSpace,
                                  kPageSize);
  }

  uword result = 0;
  SpaceUsage after_allocation = GetCurrentUsage();
  after_allocation.used_in_words += size >> kWordSizeLog2;
  // Can we grow by one page?
  after_allocation.capacity_in_words += kPageSizeInWords;
  if (growth_policy == kForceGrowth ||
      !page_space_controller_.ReachedHardThreshold(after_allocation)) {
    Page* page = AllocatePage(is_exec);
    if (page == nullptr) {
      return 0;
    }
    // Start of the newly allocated page is the allocated object.
    result = page->object_start();
    // Note: usage_.capacity_in_words is increased by AllocatePage.
    Page::Of(result)->add_live_bytes(size);
    usage_.used_in_words += (size >> kWordSizeLog2);
    // Enqueue the remainder in the free list.
    uword free_start = result + size;
    intptr_t free_size = page->object_end() - free_start;
    if (free_size > 0) {
      if (is_locked) {
        freelist->FreeLocked(free_start, free_size);
      } else {
        freelist->Free(free_start, free_size);
      }
    }
  }
  return result;
}

uword PageSpace::TryAllocateInFreshLargePage(intptr_t size,
                                             bool is_exec,
                                             GrowthPolicy growth_policy) {
  ASSERT(!IsAllocatableViaFreeLists(size));

  if (growth_policy != kForceGrowth) {
    ASSERT(!Thread::Current()->force_growth());
    heap_->CheckConcurrentMarking(Thread::Current(), GCReason::kOldSpace, size);
  }

  intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
  if ((page_size_in_words << kWordSizeLog2) < size) {
    // On overflow we fail to allocate.
    return 0;
  }

  uword result = 0;
  SpaceUsage after_allocation = GetCurrentUsage();
  after_allocation.used_in_words += size >> kWordSizeLog2;
  after_allocation.capacity_in_words += page_size_in_words;
  if (growth_policy == kForceGrowth ||
      !page_space_controller_.ReachedHardThreshold(after_allocation)) {
    Page* page = AllocateLargePage(size, is_exec);
    if (page != nullptr) {
      result = page->object_start();
      // Note: usage_.capacity_in_words is increased by AllocateLargePage.
      Page::Of(result)->add_live_bytes(size);
      usage_.used_in_words += (size >> kWordSizeLog2);
    }
  }
  return result;
}

uword PageSpace::TryAllocateInternal(intptr_t size,
                                     FreeList* freelist,
                                     bool is_exec,
                                     GrowthPolicy growth_policy,
                                     bool is_protected,
                                     bool is_locked) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword result = 0;
  if (IsAllocatableViaFreeLists(size)) {
    if (is_locked) {
      result = freelist->TryAllocateLocked(size, is_protected);
    } else {
      result = freelist->TryAllocate(size, is_protected);
    }
    if (result == 0) {
      result = TryAllocateInFreshPage(size, freelist, is_exec, growth_policy,
                                      is_locked);
      // usage_ is updated by the call above.
    } else {
      if (!is_protected) {
        Page::Of(result)->add_live_bytes(size);
      }
      usage_.used_in_words += (size >> kWordSizeLog2);
    }
  } else {
    result = TryAllocateInFreshLargePage(size, is_exec, growth_policy);
    // usage_ is updated by the call above.
  }
  ASSERT((result & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
  return result;
}

void PageSpace::AcquireLock(FreeList* freelist) {
  freelist->mutex()->Lock();
}

void PageSpace::ReleaseLock(FreeList* freelist) {
  usage_.used_in_words +=
      (freelist->TakeUnaccountedSizeLocked() >> kWordSizeLog2);
  freelist->mutex()->Unlock();
  usage_.used_in_words -= (freelist->ReleaseBumpAllocation() >> kWordSizeLog2);
}

void PageSpace::PauseConcurrentMarking() {
  MonitorLocker ml(&tasks_lock_);
  ASSERT(pause_concurrent_marking_.load() == 0);
  pause_concurrent_marking_.store(1);
  while (concurrent_marker_tasks_active_ != 0) {
    ml.Wait();
  }
}

void PageSpace::ResumeConcurrentMarking() {
  MonitorLocker ml(&tasks_lock_);
  ASSERT(pause_concurrent_marking_.load() != 0);
  pause_concurrent_marking_.store(0);
  ml.NotifyAll();
}

void PageSpace::YieldConcurrentMarking() {
  MonitorLocker ml(&tasks_lock_);
  if (pause_concurrent_marking_.load() != 0) {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Pause");
    concurrent_marker_tasks_active_--;
    if (concurrent_marker_tasks_active_ == 0) {
      ml.NotifyAll();
    }
    while (pause_concurrent_marking_.load() != 0) {
      ml.Wait();
    }
    concurrent_marker_tasks_active_++;
  }
}

class BasePageIterator : ValueObject {
 public:
  explicit BasePageIterator(const PageSpace* space) : space_(space) {}

  Page* page() const { return page_; }

  bool Done() const { return page_ == nullptr; }

  void Advance() {
    ASSERT(!Done());
    page_ = page_->next();
    if ((page_ == nullptr) && (list_ == kRegular)) {
      list_ = kExecutable;
      page_ = space_->exec_pages_;
    }
    if ((page_ == nullptr) && (list_ == kExecutable)) {
      list_ = kLarge;
      page_ = space_->large_pages_;
    }
    if ((page_ == nullptr) && (list_ == kLarge)) {
      list_ = kImage;
      page_ = space_->image_pages_;
    }
    ASSERT((page_ != nullptr) || (list_ == kImage));
  }

 protected:
  enum List { kRegular, kExecutable, kLarge, kImage };

  void Initialize() {
    list_ = kRegular;
    page_ = space_->pages_;
    if (page_ == nullptr) {
      list_ = kExecutable;
      page_ = space_->exec_pages_;
      if (page_ == nullptr) {
        list_ = kLarge;
        page_ = space_->large_pages_;
        if (page_ == nullptr) {
          list_ = kImage;
          page_ = space_->image_pages_;
        }
      }
    }
  }

  const PageSpace* space_ = nullptr;
  List list_;
  Page* page_ = nullptr;
};

// Provides unsafe access to all pages. Assumes pages are walkable.
class UnsafeExclusivePageIterator : public BasePageIterator {
 public:
  explicit UnsafeExclusivePageIterator(const PageSpace* space)
      : BasePageIterator(space) {
    Initialize();
  }
};

// Provides exclusive access to all pages, and ensures they are walkable.
class ExclusivePageIterator : public BasePageIterator {
 public:
  explicit ExclusivePageIterator(const PageSpace* space)
      : BasePageIterator(space), ml_(&space->pages_lock_) {
    space_->MakeIterable();
    Initialize();
  }

 private:
  MutexLocker ml_;
  NoSafepointScope no_safepoint;
};

// Provides exclusive access to code pages, and ensures they are walkable.
// NOTE: This does not iterate over large pages which can contain code.
class ExclusiveCodePageIterator : ValueObject {
 public:
  explicit ExclusiveCodePageIterator(const PageSpace* space)
      : space_(space), ml_(&space->pages_lock_) {
    space_->MakeIterable();
    page_ = space_->exec_pages_;
  }
  Page* page() const { return page_; }
  bool Done() const { return page_ == nullptr; }
  void Advance() {
    ASSERT(!Done());
    page_ = page_->next();
  }

 private:
  const PageSpace* space_;
  MutexLocker ml_;
  NoSafepointScope no_safepoint;
  Page* page_;
};

void PageSpace::MakeIterable() const {
  // Assert not called from concurrent sweeper task.
  // TODO(koda): Use thread/task identity when implemented.
  ASSERT(IsolateGroup::Current()->heap() != nullptr);
  for (intptr_t i = 0; i < num_freelists_; i++) {
    freelists_[i].MakeIterable();
  }
}

void PageSpace::ReleaseBumpAllocation() {
  for (intptr_t i = 0; i < num_freelists_; i++) {
    size_t leftover = freelists_[i].ReleaseBumpAllocation();
    usage_.used_in_words -= (leftover >> kWordSizeLog2);
  }
}

void PageSpace::AbandonMarkingForShutdown() {
  delete marker_;
  marker_ = nullptr;
}

void PageSpace::UpdateMaxCapacityLocked() {
  ASSERT(heap_ != nullptr);
  ASSERT(heap_->isolate_group() != nullptr);
  auto isolate_group = heap_->isolate_group();
  isolate_group->GetHeapOldCapacityMaxMetric()->SetValue(
      static_cast<int64_t>(usage_.capacity_in_words) * kWordSize);
}

void PageSpace::UpdateMaxUsed() {
  ASSERT(heap_ != nullptr);
  ASSERT(heap_->isolate_group() != nullptr);
  auto isolate_group = heap_->isolate_group();
  isolate_group->GetHeapOldUsedMaxMetric()->SetValue(UsedInWords() * kWordSize);
}

bool PageSpace::Contains(uword addr) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->Contains(addr)) {
      return true;
    }
  }
  return false;
}

bool PageSpace::ContainsUnsafe(uword addr) const {
  for (UnsafeExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->Contains(addr)) {
      return true;
    }
  }
  return false;
}

bool PageSpace::CodeContains(uword addr) const {
  for (ExclusiveCodePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->Contains(addr)) {
      return true;
    }
  }
  return false;
}

void PageSpace::AddRegionsToObjectSet(ObjectSet* set) const {
  ASSERT((pages_ != nullptr) || (exec_pages_ != nullptr) ||
         (large_pages_ != nullptr));
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
    if (!it.page()->is_image()) {
      it.page()->VisitObjects(visitor);
    }
  }
}

void PageSpace::VisitObjectsImagePages(ObjectVisitor* visitor) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->is_image()) {
      it.page()->VisitObjects(visitor);
    }
  }
}

void PageSpace::VisitObjectsUnsafe(ObjectVisitor* visitor) const {
  for (UnsafeExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    it.page()->VisitObjectsUnsafe(visitor);
  }
}

void PageSpace::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    it.page()->VisitObjectPointers(visitor);
  }
}

void PageSpace::VisitRememberedCards(
    PredicateObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->OwnsGCSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kScavengerTask));

  // Wait for the sweeper to finish mutating the large page list.
  {
    MonitorLocker ml(tasks_lock());
    while (phase() == kSweepingLarge) {
      ml.Wait();  // No safepoint check.
    }
  }

  // Large pages may be added concurrently due to promotion in another scavenge
  // worker, so terminate the traversal when we hit the tail we saw while
  // holding the pages lock, instead of at nullptr, otherwise we are racing when
  // we read Page::next_ and Page::remembered_cards_.
  Page* page;
  Page* tail;
  {
    MutexLocker ml(&pages_lock_);
    page = large_pages_;
    tail = large_pages_tail_;
  }
  while (page != nullptr) {
    page->VisitRememberedCards(visitor);
    if (page == tail) break;
    page = page->next();
  }
}

void PageSpace::ResetProgressBars() const {
  for (Page* page = large_pages_; page != nullptr; page = page->next()) {
    page->ResetProgressBar();
  }
}

void PageSpace::WriteProtect(bool read_only) {
  if (read_only) {
    // Avoid MakeIterable trying to write to the heap.
    ReleaseBumpAllocation();
  }
  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (!it.page()->is_image()) {
      it.page()->WriteProtect(read_only);
    }
  }
}

#ifndef PRODUCT
void PageSpace::PrintToJSONObject(JSONObject* object) const {
  auto isolate_group = IsolateGroup::Current();
  ASSERT(isolate_group != nullptr);
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
    int64_t run_time = isolate_group->UptimeMicros();
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
  void VisitObject(ObjectPtr obj) override {
    array_->AddValue(obj->untag()->HeapSize() / kObjectAlignment);
    array_->AddValue(obj->GetClassIdOfHeapObject());
  }

 private:
  JSONArray* array_;
};

void PageSpace::PrintHeapMapToJSONStream(IsolateGroup* isolate_group,
                                         JSONStream* stream) const {
  JSONObject heap_map(stream);
  heap_map.AddProperty("type", "HeapMap");
  heap_map.AddProperty("freeClassId", static_cast<intptr_t>(kFreeListElement));
  heap_map.AddProperty("unitSizeBytes",
                       static_cast<intptr_t>(kObjectAlignment));
  heap_map.AddProperty("pageSizeBytes", kPageSizeInWords * kWordSize);
  {
    JSONObject class_list(&heap_map, "classList");
    isolate_group->class_table()->PrintToJSONObject(&class_list);
  }
  {
    // "pages" is an array [page0, page1, ..., pageN], each page of the form
    // {"object_start": "0x...", "objects": [size, class id, size, ...]}
    // TODO(19445): Use ExclusivePageIterator once HeapMap supports large pages.
    HeapIterationScope iteration(Thread::Current());
    MutexLocker ml(&pages_lock_);
    MakeIterable();
    JSONArray all_pages(&heap_map, "pages");
    for (Page* page = pages_; page != nullptr; page = page->next()) {
      JSONObject page_container(&all_pages);
      page_container.AddPropertyF("objectStart", "0x%" Px "",
                                  page->object_start());
      JSONArray page_map(&page_container, "objects");
      HeapMapAsJSONVisitor printer(&page_map);
      page->VisitObjects(&printer);
    }
    for (Page* page = exec_pages_; page != nullptr; page = page->next()) {
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

void PageSpace::WriteProtectCode(bool read_only) {
  if (FLAG_write_protect_code) {
    MutexLocker ml(&pages_lock_);
    NoSafepointScope no_safepoint;
    // No need to go through all of the data pages first.
    Page* page = exec_pages_;
    while (page != nullptr) {
      ASSERT(page->is_executable());
      page->WriteProtect(read_only);
      page = page->next();
    }
    page = large_pages_;
    while (page != nullptr) {
      if (page->is_executable()) {
        page->WriteProtect(read_only);
      }
      page = page->next();
    }
  }
}

bool PageSpace::ShouldStartIdleMarkSweep(int64_t deadline) {
  // To make a consistent decision, we should not yield for a safepoint in the
  // middle of deciding whether to perform an idle GC.
  NoSafepointScope no_safepoint;

  if (!page_space_controller_.ReachedIdleThreshold(usage_)) {
    return false;
  }

  {
    MonitorLocker locker(tasks_lock());
    if (tasks() > 0) {
      // A concurrent sweeper is running. If we start a mark sweep now
      // we'll have to wait for it, and this wait time is not included in
      // mark_words_per_micro_.
      return false;
    }
  }

  // This uses the size of new-space because the pause time to start concurrent
  // marking is related to the size of the root set, which is mostly new-space.
  int64_t estimated_mark_completion =
      OS::GetCurrentMonotonicMicros() +
      heap_->new_space()->UsedInWords() / mark_words_per_micro_;
  return estimated_mark_completion <= deadline;
}

bool PageSpace::ShouldPerformIdleMarkCompact(int64_t deadline) {
  // To make a consistent decision, we should not yield for a safepoint in the
  // middle of deciding whether to perform an idle GC.
  NoSafepointScope no_safepoint;

  // When enabled, prefer the incremental/evacuating compactor over the
  // full/sliding compactor.
  if (FLAG_use_incremental_compactor) {
    return false;
  }

  // Discount two pages to account for the newest data and code pages, whose
  // partial use doesn't indicate fragmentation.
  const intptr_t excess_in_words =
      usage_.capacity_in_words - usage_.used_in_words - 2 * kPageSizeInWords;
  const double excess_ratio = static_cast<double>(excess_in_words) /
                              static_cast<double>(usage_.capacity_in_words);
  const bool fragmented = excess_ratio > 0.05;

  if (!fragmented && !page_space_controller_.ReachedIdleThreshold(usage_)) {
    return false;
  }

  {
    MonitorLocker locker(tasks_lock());
    if (tasks() > 0) {
      // A concurrent sweeper is running. If we start a mark sweep now
      // we'll have to wait for it, and this wait time is not included in
      // mark_words_per_micro_.
      return false;
    }
  }

  // Assuming compaction takes as long as marking.
  intptr_t mark_compact_words_per_micro = mark_words_per_micro_ / 2;
  if (mark_compact_words_per_micro == 0) {
    mark_compact_words_per_micro = 1;  // Prevent division by zero.
  }

  int64_t estimated_mark_compact_completion =
      OS::GetCurrentMonotonicMicros() +
      UsedInWords() / mark_compact_words_per_micro;
  return estimated_mark_compact_completion <= deadline;
}

void PageSpace::IncrementalMarkWithSizeBudget(intptr_t size) {
  if (marker_ != nullptr) {
    marker_->IncrementalMarkWithSizeBudget(this, size);
  }
}

void PageSpace::IncrementalMarkWithTimeBudget(int64_t deadline) {
  if (marker_ != nullptr) {
    marker_->IncrementalMarkWithTimeBudget(this, deadline);
  }
}

void PageSpace::AssistTasks(MonitorLocker* ml) {
  if (phase() == PageSpace::kMarking) {
    ml->Exit();
    marker_->IncrementalMarkWithUnlimitedBudget(this);
    ml->Enter();
  }
  if ((phase() == kSweepingLarge) || (phase() == kSweepingRegular)) {
    ml->Exit();
    Sweep(/*exclusive*/ false);
    SweepLarge();
    ml->Enter();
  }
}

void PageSpace::TryReleaseReservation() {
  ASSERT(phase() != kSweepingLarge);
  ASSERT(phase() != kSweepingRegular);
  if (oom_reservation_ == nullptr) return;
  uword addr = reinterpret_cast<uword>(oom_reservation_);
  intptr_t size = oom_reservation_->HeapSize();
  oom_reservation_ = nullptr;
  freelists_[kDataFreelist].Free(addr, size);
}

bool PageSpace::MarkReservation() {
  if (oom_reservation_ == nullptr) {
    return false;
  }
  UntaggedObject* ptr = reinterpret_cast<UntaggedObject*>(oom_reservation_);
  if (!ptr->IsMarked()) {
    ptr->SetMarkBit();
  }
  return true;
}

void PageSpace::TryReserveForOOM() {
  if (oom_reservation_ == nullptr) {
    uword addr = TryAllocate(kOOMReservationSize, /*exec*/ false,
                             kForceGrowth /* Don't re-enter GC */);
    if (addr != 0) {
      oom_reservation_ = FreeListElement::AsElement(addr, kOOMReservationSize);
    }
  }
}

void PageSpace::VisitRoots(ObjectPointerVisitor* visitor) {
  if (oom_reservation_ != nullptr) {
    // FreeListElements are generally held untagged, but ObjectPointerVisitors
    // expect tagged pointers.
    ObjectPtr ptr =
        UntaggedObject::FromAddr(reinterpret_cast<uword>(oom_reservation_));
    visitor->VisitPointer(&ptr);
    oom_reservation_ =
        reinterpret_cast<FreeListElement*>(UntaggedObject::ToAddr(ptr));
  }
}

void PageSpace::CollectGarbage(Thread* thread, bool compact, bool finalize) {
  ASSERT(!thread->force_growth());
  ASSERT(thread->OwnsGCSafepoint());

  if (!finalize) {
    if (!enable_concurrent_mark()) return;  // Disabled.
    if (FLAG_marker_tasks == 0) return;     // Disabled.
  }

  // Wait for pending tasks to complete and then account for the driver task.
  {
    MonitorLocker locker(tasks_lock());
    if (!finalize &&
        (phase() == kMarking || phase() == kAwaitingFinalization)) {
      // Concurrent mark is already running.
      return;
    }

    AssistTasks(&locker);
    while (tasks() > 0) {
      locker.Wait();
    }
    ASSERT(phase() == kAwaitingFinalization || phase() == kDone);
    set_tasks(1);
  }

  // Ensure that all threads for this isolate are at a safepoint (either
  // stopped or in native code). We have guards around Newgen GC and oldgen GC
  // to ensure that if two threads are racing to collect at the same time the
  // loser skips collection and goes straight to allocation.
  CollectGarbageHelper(thread, compact, finalize);

  // Done, reset the task count.
  {
    MonitorLocker ml(tasks_lock());
    set_tasks(tasks() - 1);
    ml.NotifyAll();
  }
}

class ParallelSweepTask : public SafepointTask {
 public:
  ParallelSweepTask(PageSpace* old_space,
                    IsolateGroup* isolate_group,
                    ThreadBarrier* barrier,
                    bool new_space_is_swept)
      : SafepointTask(isolate_group, barrier, Thread::kSweeperTask),
        old_space_(old_space),
        new_space_is_swept_(new_space_is_swept) {}

  void RunEnteredIsolateGroup() override {
    old_space_->SweepExecutable();
    if (!new_space_is_swept_) {
      old_space_->SweepNew();
    }
  }

 private:
  PageSpace* old_space_;
  bool new_space_is_swept_;
};

void PageSpace::CollectGarbageHelper(Thread* thread,
                                     bool compact,
                                     bool finalize) {
  ASSERT(thread->OwnsGCSafepoint());
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group == IsolateGroup::Current());

  const int64_t start = OS::GetCurrentMonotonicMicros();

  // Perform various cleanup that relies on no tasks interfering.
  isolate_group->class_table_allocator()->FreePending();
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) { isolate->field_table()->FreeOldTables(); },
      /*at_safepoint=*/true);

  if (FLAG_verify_before_gc) {
    heap_->VerifyGC("Verifying before marking",
                    phase() == kDone ? kForbidMarked : kAllowMarked);
  }

  // Make code pages writable.
  if (finalize) WriteProtectCode(false);

  // Save old value before GCMarker visits the weak persistent handles.
  SpaceUsage usage_before = GetCurrentUsage();

  // Mark all reachable old-gen objects.
  if (marker_ == nullptr) {
    ASSERT(phase() == kDone);
    marker_ = new GCMarker(isolate_group, heap_);
    if (FLAG_use_incremental_compactor) {
      GCIncrementalCompactor::Prologue(this);
    }
  } else {
    ASSERT(phase() == kAwaitingFinalization);
  }

  if (!finalize) {
    ASSERT(phase() == kDone);
    marker_->StartConcurrentMark(this);
    return;
  }

  // Abandon the remainder of the bump allocation block.
  ReleaseBumpAllocation();

  marker_->MarkObjects(this);
  usage_.used_in_words = marker_->marked_words() + allocated_black_in_words_;
  allocated_black_in_words_ = 0;
  mark_words_per_micro_ = marker_->MarkedWordsPerMicro();
  delete marker_;
  marker_ = nullptr;

  if (FLAG_verify_store_buffer) {
    VerifyStoreBuffers("Verifying remembered set after marking");
  }

  if (FLAG_verify_before_gc) {
    heap_->VerifyGC("Verifying before sweeping", kAllowMarked);
  }

  bool has_reservation = MarkReservation();

  bool new_space_is_swept = false;
  if (FLAG_use_incremental_compactor) {
    new_space_is_swept = GCIncrementalCompactor::Epilogue(this);
  }

  // Reset the freelists and setup sweeping.
  for (intptr_t i = 0; i < num_freelists_; i++) {
    freelists_[i].Reset();
  }

  {
    // Move pages to sweeper work lists.
    MutexLocker ml(&pages_lock_);
    ASSERT(sweep_large_ == nullptr);
    sweep_large_ = large_pages_;
    large_pages_ = large_pages_tail_ = nullptr;
    ASSERT(sweep_regular_ == nullptr);
    if (!compact) {
      sweep_regular_ = pages_;
      pages_ = pages_tail_ = nullptr;
    }
    if (!new_space_is_swept) {
      sweep_new_ = heap_->new_space()->head();
      heap_->new_space()->set_freed_in_words(0);
    }
    sweep_executable_ = exec_pages_;
  }

  {
    // STW sweeping: executable and new pages.
    // Executable pages are always swept during the STW phase to simplify
    // code protection.
    const intptr_t num_tasks = heap_->new_space()->NumScavengeWorkers();
    ThreadBarrier* barrier = new ThreadBarrier(num_tasks, /*initial=*/1);
    IntrusiveDList<SafepointTask> tasks;
    for (intptr_t i = 0; i < num_tasks; i++) {
      tasks.Append(new ParallelSweepTask(this, isolate_group, barrier,
                                         new_space_is_swept));
    }
    isolate_group->safepoint_handler()->RunTasks(&tasks);
  }

  bool is_concurrent_sweep_running = false;
  if (compact) {
    Compact(thread);
    set_phase(kDone);
    is_concurrent_sweep_running = true;
  } else if (FLAG_concurrent_sweep && has_reservation) {
    ConcurrentSweep(isolate_group);
    is_concurrent_sweep_running = true;
  } else {
    SweepLarge();
    Sweep(/*exclusive*/ true);
    set_phase(kDone);
  }

  if (FLAG_verify_after_gc && !is_concurrent_sweep_running) {
    heap_->VerifyGC("Verifying after sweeping", kForbidMarked);
  }

  TryReserveForOOM();

  // Make code pages read-only.
  if (finalize) WriteProtectCode(true);

  int64_t end = OS::GetCurrentMonotonicMicros();

  // Record signals for growth control. Include size of external allocations.
  page_space_controller_.EvaluateGarbageCollection(
      usage_before, GetCurrentUsage(), start, end);

  UpdateMaxUsed();
  if (heap_ != nullptr) {
    heap_->UpdateGlobalMaxUsed();
  }
}

class CollectStoreBufferEvacuateVisitor : public ObjectPointerVisitor {
 public:
  CollectStoreBufferEvacuateVisitor(ObjectSet* in_store_buffer, const char* msg)
      : ObjectPointerVisitor(IsolateGroup::Current()),
        in_store_buffer_(in_store_buffer),
        msg_(msg) {}

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = *ptr;
      RELEASE_ASSERT_WITH_MSG(obj->untag()->IsRemembered(), msg_);
      RELEASE_ASSERT_WITH_MSG(obj->IsOldObject(), msg_);

      RELEASE_ASSERT_WITH_MSG(!obj->untag()->IsCardRemembered(), msg_);
      if (obj.GetClassIdOfHeapObject() == kArrayCid) {
        const uword length =
            Smi::Value(static_cast<UntaggedArray*>(obj.untag())->length());
        RELEASE_ASSERT_WITH_MSG(!Array::UseCardMarkingForAllocation(length),
                                msg_);
      }
      in_store_buffer_->Add(obj);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    UNREACHABLE();  // Store buffer blocks are not compressed.
  }
#endif

 private:
  ObjectSet* const in_store_buffer_;
  const char* msg_;

  DISALLOW_COPY_AND_ASSIGN(CollectStoreBufferEvacuateVisitor);
};

class CheckStoreBufferEvacuateVisitor : public ObjectVisitor,
                                        public ObjectPointerVisitor {
 public:
  CheckStoreBufferEvacuateVisitor(ObjectSet* in_store_buffer, const char* msg)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        in_store_buffer_(in_store_buffer),
        msg_(msg) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsPseudoObject()) return;
    RELEASE_ASSERT_WITH_MSG(obj->IsOldObject(), msg_);
    if (!obj->untag()->IsMarked()) return;

    if (obj->untag()->IsRemembered()) {
      RELEASE_ASSERT_WITH_MSG(in_store_buffer_->Contains(obj), msg_);
    } else {
      RELEASE_ASSERT_WITH_MSG(!in_store_buffer_->Contains(obj), msg_);
    }

    visiting_ = obj;
    is_remembered_ = obj->untag()->IsRemembered();
    is_card_remembered_ = obj->untag()->IsCardRemembered();
    if (is_card_remembered_) {
      RELEASE_ASSERT_WITH_MSG(!is_remembered_, msg_);
      RELEASE_ASSERT_WITH_MSG(Page::Of(obj)->progress_bar_ == 0, msg_);
    }
    obj->untag()->VisitPointers(this);
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = *ptr;
      if (obj->IsHeapObject() && obj->untag()->IsEvacuationCandidate()) {
        if (is_card_remembered_) {
          if (!Page::Of(visiting_)->IsCardRemembered(ptr)) {
            FATAL(
                "%s: Old object %#" Px " references new object %#" Px
                ", but the "
                "slot's card is not remembered. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_), static_cast<uword>(obj),
                ptr);
          }
        } else if (!is_remembered_) {
          FATAL("%s: Old object %#" Px " references new object %#" Px
                ", but it is "
                "not in any store buffer. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_), static_cast<uword>(obj),
                ptr);
        }
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = ptr->Decompress(heap_base);
      if (obj->IsHeapObject() && obj->IsNewObject()) {
        if (is_card_remembered_) {
          if (!Page::Of(visiting_)->IsCardRemembered(ptr)) {
            FATAL(
                "%s: Old object %#" Px " references new object %#" Px
                ", but the "
                "slot's card is not remembered. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_), static_cast<uword>(obj),
                ptr);
          }
        } else if (!is_remembered_) {
          FATAL("%s: Old object %#" Px " references new object %#" Px
                ", but it is "
                "not in any store buffer. Consider using rr to watch the "
                "slot %p and reverse-continue to find the store with a missing "
                "barrier.\n",
                msg_, static_cast<uword>(visiting_), static_cast<uword>(obj),
                ptr);
        }
      }
    }
  }
#endif

 private:
  const ObjectSet* const in_store_buffer_;
  ObjectPtr visiting_;
  bool is_remembered_;
  bool is_card_remembered_;
  const char* msg_;
};

void PageSpace::VerifyStoreBuffers(const char* msg) {
  ASSERT(msg != nullptr);
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  ObjectSet* in_store_buffer = new (zone) ObjectSet(zone);
  heap_->AddRegionsToObjectSet(in_store_buffer);

  {
    CollectStoreBufferEvacuateVisitor visitor(in_store_buffer, msg);
    heap_->isolate_group()->store_buffer()->VisitObjectPointers(&visitor);
  }

  {
    CheckStoreBufferEvacuateVisitor visitor(in_store_buffer, msg);
    heap_->old_space()->VisitObjects(&visitor);
  }
}

void PageSpace::SweepExecutable() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "SweepExecutable");

  Page* page;
  {
    MutexLocker ml(&pages_lock_);
    page = sweep_executable_;
    sweep_executable_ = nullptr;
  }
  if (page == nullptr) {
    return;
  }

  GCSweeper sweeper;
  Page* prev_page = nullptr;
  FreeList* freelist = &freelists_[kExecutableFreelist];
  MutexLocker ml(freelist->mutex());
  while (page != nullptr) {
    Page* next_page = page->next();
    bool page_in_use = sweeper.SweepPage(page, freelist);
    if (page_in_use) {
      prev_page = page;
    } else {
      FreePage(page, prev_page);
    }
    page = next_page;
  }
}

void PageSpace::SweepNew() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "SweepNew");

  GCSweeper sweeper;
  intptr_t free = 0;
  {
    MutexLocker ml(&pages_lock_);
    while (sweep_new_ != nullptr) {
      Page* page = sweep_new_;
      sweep_new_ = page->next();
      ml.Unlock();
      page->Release();
      free += sweeper.SweepNewPage(page);
      ml.Lock();
    }
  }
  heap_->new_space()->add_freed_in_words(free >> kWordSizeLog2);
}

void PageSpace::SweepLarge() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "SweepLarge");

  GCSweeper sweeper;
  MutexLocker ml(&pages_lock_);
  while (sweep_large_ != nullptr) {
    Page* page = sweep_large_;
    sweep_large_ = page->next();
    page->set_next(nullptr);
    ASSERT(!page->is_executable());

    ml.Unlock();
    intptr_t words_to_end = sweeper.SweepLargePage(page);
    intptr_t size;
    if (words_to_end == 0) {
      size = page->memory_->size();
      page->Deallocate();
      ml.Lock();
      IncreaseCapacityInWordsLocked(-(size >> kWordSizeLog2));
    } else {
      TruncateLargePage(page, words_to_end << kWordSizeLog2);
      ml.Lock();
      AddLargePageLocked(page);
    }
  }
}

void PageSpace::Sweep(bool exclusive) {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Sweep");

  GCSweeper sweeper;

  intptr_t shard = 0;
  const intptr_t num_shards = heap_->new_space()->NumScavengeWorkers();
  ASSERT(num_shards < num_freelists_);
  if (exclusive) {
    for (intptr_t i = 0; i < num_shards; i++) {
      DataFreeList(i)->mutex()->Lock();
    }
  }

  MutexLocker ml(&pages_lock_);
  while (sweep_regular_ != nullptr) {
    Page* page = sweep_regular_;
    sweep_regular_ = page->next();
    page->set_next(nullptr);
    ASSERT(!page->is_executable());

    ml.Unlock();
    // Cycle through the shards round-robin so that free space is roughly
    // evenly distributed among the freelists and so roughly evenly available
    // to each scavenger worker.
    shard = (shard + 1) % num_shards;
    FreeList* freelist = DataFreeList(shard);
    if (!exclusive) {
      freelist->mutex()->Lock();
    }
    bool page_in_use = sweeper.SweepPage(page, freelist);
    if (!exclusive) {
      freelist->mutex()->Unlock();
    }
    intptr_t size;
    if (!page_in_use) {
      size = page->memory_->size();
      page->Deallocate();
    }
    ml.Lock();

    if (page_in_use) {
      AddPageLocked(page);
    } else {
      IncreaseCapacityInWordsLocked(-(size >> kWordSizeLog2));
    }
  }

  if (exclusive) {
    for (intptr_t i = 0; i < num_shards; i++) {
      DataFreeList(i)->mutex()->Unlock();
    }
  }
}

void PageSpace::ConcurrentSweep(IsolateGroup* isolate_group) {
  // Start the concurrent sweeper task now.
  GCSweeper::SweepConcurrent(isolate_group);
}

void PageSpace::Compact(Thread* thread) {
  GCCompactor compactor(thread, heap_);
  compactor.Compact(pages_, &freelists_[kDataFreelist], &pages_lock_);

  if (FLAG_verify_after_gc) {
    heap_->VerifyGC("Verifying after compacting", kForbidMarked);
  }
}

uword PageSpace::TryAllocateDataBumpLocked(FreeList* freelist, intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  if (!IsAllocatableViaFreeLists(size)) {
    return TryAllocateDataLocked(freelist, size, kForceGrowth);
  }

  intptr_t remaining = freelist->end() - freelist->top();
  if (UNLIKELY(remaining < size)) {
    FreeListElement* block = freelist->TryAllocateLargeLocked(size);
    if (block == nullptr) {
      // Allocating from a new page (if growth policy allows) will have the
      // side-effect of populating the freelist with a large block. The next
      // bump allocation request will have a chance to consume that block.
      return TryAllocateInFreshPage(size, freelist, false /* exec */,
                                    kForceGrowth, true /* is_locked*/);
    }
    intptr_t block_size = block->HeapSize();
    if (remaining > 0) {
      usage_.used_in_words -= (remaining >> kWordSizeLog2);
      Page::Of(freelist->top())->add_live_bytes(remaining);
      freelist->FreeLocked(freelist->top(), remaining);
    }
    freelist->set_top(reinterpret_cast<uword>(block));
    freelist->set_end(freelist->top() + block_size);
    // To avoid accounting overhead during each bump pointer allocation, we add
    // the size of the whole bump area here and subtract the remaining size
    // when switching to a new area.
    usage_.used_in_words += (block_size >> kWordSizeLog2);
    Page::Of(block)->add_live_bytes(block_size);
    remaining = block_size;
  }
  ASSERT(remaining >= size);
  uword result = freelist->top();
  freelist->set_top(result + size);

// Note: Remaining block is unwalkable until MakeIterable is called.
#ifdef DEBUG
  if (freelist->top() < freelist->end()) {
    // Fail fast if we try to walk the remaining block.
    COMPILE_ASSERT(kIllegalCid == 0);
    *reinterpret_cast<uword*>(freelist->top()) = 0;
  }
#endif  // DEBUG
  return result;
}

uword PageSpace::TryAllocatePromoLockedSlow(FreeList* freelist, intptr_t size) {
  uword result = freelist->TryAllocateSmallLocked(size);
  if (result != 0) {
    Page::Of(result)->add_live_bytes(size);
    freelist->AddUnaccountedSize(size);
    return result;
  }
  return TryAllocateDataBumpLocked(freelist, size);
}

uword PageSpace::AllocateSnapshotLockedSlow(FreeList* freelist, intptr_t size) {
  uword result = TryAllocateDataBumpLocked(freelist, size);
  if (result != 0) {
    return result;
  }
  OUT_OF_MEMORY();
}

void PageSpace::SetupImagePage(void* pointer, uword size, bool is_executable) {
  if (VirtualMemory::ShouldDualMapExecutablePages()) {
    // See |Instructions::PayloadStart| for more details about this restriction.
    FATAL(
        "Dual mapping of executable pages assumes no image pages in the heap");
  }

  // Setup a Page so precompiled Instructions can be traversed.
  // Instructions are contiguous at [pointer, pointer + size). Page
  // expects to find objects at [memory->start() + ObjectStartOffset,
  // memory->end()).
  uword offset = Page::OldObjectStartOffset();
  pointer = reinterpret_cast<void*>(reinterpret_cast<uword>(pointer) - offset);
  ASSERT(Utils::IsAligned(pointer, kObjectAlignment));
  size += offset;

  VirtualMemory* memory = VirtualMemory::ForImagePage(pointer, size);
  ASSERT(memory != nullptr);
  Page* page = reinterpret_cast<Page*>(malloc(sizeof(Page)));
  uword flags = Page::kImage;
  if (is_executable) {
    flags |= Page::kExecutable;
  }
  page->flags_ = flags;
  page->memory_ = memory;
  page->next_ = nullptr;
  page->forwarding_page_ = nullptr;
  page->card_table_ = nullptr;
  page->progress_bar_ = 0;
  page->owner_ = nullptr;
  page->top_ = memory->end();
  page->end_ = memory->end();
  page->survivor_end_ = 0;
  page->resolved_top_ = 0;
  page->live_bytes_ = 0;

  MutexLocker ml(&pages_lock_);
  page->next_ = image_pages_;
  image_pages_ = page;
}

bool PageSpace::IsObjectFromImagePages(dart::ObjectPtr object) {
  uword object_addr = UntaggedObject::ToAddr(object);
  Page* image_page = image_pages_;
  while (image_page != nullptr) {
    if (image_page->Contains(object_addr)) {
      return true;
    }
    image_page = image_page->next();
  }
  return false;
}

PageSpaceController::PageSpaceController(Heap* heap,
                                         int heap_growth_ratio,
                                         int heap_growth_max,
                                         int garbage_collection_time_ratio)
    : heap_(heap),
      heap_growth_ratio_(heap_growth_ratio),
      desired_utilization_((100.0 - heap_growth_ratio) / 100.0),
      heap_growth_max_(heap_growth_max),
      garbage_collection_time_ratio_(garbage_collection_time_ratio),
      idle_gc_threshold_in_words_(0) {
  const intptr_t growth_in_pages = heap_growth_max / 2;
  RecordUpdate(last_usage_, last_usage_, growth_in_pages, "initial");
}

PageSpaceController::~PageSpaceController() {}

bool PageSpaceController::ReachedHardThreshold(SpaceUsage after) const {
  if (heap_growth_ratio_ == 100) {
    return false;
  }
  if ((heap_ != nullptr) && (heap_->mode() == Dart_PerformanceMode_Latency)) {
    return false;
  }
  return after.CombinedUsedInWords() > hard_gc_threshold_in_words_;
}

bool PageSpaceController::ReachedSoftThreshold(SpaceUsage after) const {
  if (heap_growth_ratio_ == 100) {
    return false;
  }
  if ((heap_ != nullptr) && (heap_->mode() == Dart_PerformanceMode_Latency)) {
    return false;
  }
  return after.CombinedUsedInWords() > soft_gc_threshold_in_words_;
}

bool PageSpaceController::ReachedIdleThreshold(SpaceUsage current) const {
  if (heap_growth_ratio_ == 100) {
    return false;
  }
  return current.CombinedUsedInWords() > idle_gc_threshold_in_words_;
}

void PageSpaceController::EvaluateGarbageCollection(SpaceUsage before,
                                                    SpaceUsage after,
                                                    int64_t start,
                                                    int64_t end) {
  ASSERT(end >= start);
  history_.AddGarbageCollectionTime(start, end);
  const int gc_time_fraction = history_.GarbageCollectionTimeFraction();

  // Assume garbage increases linearly with allocation:
  // G = kA, and estimate k from the previous cycle.
  const intptr_t allocated_since_previous_gc =
      before.CombinedUsedInWords() - last_usage_.CombinedUsedInWords();
  intptr_t growth_in_pages;
  if (allocated_since_previous_gc > 0) {
    intptr_t garbage =
        before.CombinedUsedInWords() - after.CombinedUsedInWords();
    // Garbage may be negative if when the OOM reservation is refilled.
    garbage = Utils::Maximum(static_cast<intptr_t>(0), garbage);
    // It makes no sense to expect that each kb allocated will cause more than
    // one kb of garbage, so we clamp k at 1.0.
    const double k = Utils::Minimum(
        1.0, garbage / static_cast<double>(allocated_since_previous_gc));

    const int garbage_ratio = static_cast<int>(k * 100);

    // Number of pages we can allocate and still be within the desired growth
    // ratio.
    const intptr_t growth_ratio_heuristic =
        (static_cast<intptr_t>(after.CombinedUsedInWords() /
                               desired_utilization_) -
         (after.CombinedUsedInWords())) /
        kPageSizeInWords;
    if (garbage_ratio == 0) {
      // No garbage in the previous cycle so it would be hard to compute a
      // growth_in_pages size based on estimated garbage so we use growth ratio
      // heuristics instead.
      growth_in_pages = growth_ratio_heuristic;
    } else if (garbage_collection_time_ratio_ == 0) {
      // Exclude time from the growth policy decision for --deterministic.
      growth_in_pages = growth_ratio_heuristic;
    } else if (gc_time_fraction <= garbage_collection_time_ratio_) {
      // Stick with the ratio hueristic when we're staying under the desired
      // time fraction.
      growth_in_pages = growth_ratio_heuristic;
    } else {
      // Define GC to be 'worthwhile' iff at least fraction t of heap is
      // garbage.
      double t = 1.0 - desired_utilization_;
      // If we spend too much time in GC, strive for even more free space.
      if (gc_time_fraction > garbage_collection_time_ratio_) {
        t += (gc_time_fraction - garbage_collection_time_ratio_) / 100.0;
      }

      // Find minimum 'growth_in_pages' such that after increasing capacity by
      // 'growth_in_pages' pages and filling them, we expect a GC to be
      // worthwhile.
      intptr_t max = heap_growth_max_;
      intptr_t min = 0;
      intptr_t local_growth_in_pages = 0;
      while (min < max) {
        local_growth_in_pages = (max + min) / 2;
        const intptr_t limit = after.CombinedUsedInWords() +
                               (local_growth_in_pages * kPageSizeInWords);
        const intptr_t allocated_before_next_gc =
            limit - (after.CombinedUsedInWords());
        const double estimated_garbage = k * allocated_before_next_gc;
        if (t <= estimated_garbage / limit) {
          max = local_growth_in_pages - 1;
        } else {
          min = local_growth_in_pages + 1;
        }
      }
      local_growth_in_pages = (max + min) / 2;
      growth_in_pages = local_growth_in_pages;
      ASSERT(growth_in_pages >= 0);
      // If we are going to grow by heap_grow_max_ then ensure that we
      // will be growing the heap at least by the growth ratio heuristics.
      if (growth_in_pages >= heap_growth_max_) {
        growth_in_pages =
            Utils::Maximum(growth_in_pages, growth_ratio_heuristic);
      }
    }
  } else {
    growth_in_pages = 0;
  }
  last_usage_ = after;

  intptr_t max_capacity_in_words = heap_->old_space()->max_capacity_in_words_;
  if (max_capacity_in_words != 0) {
    ASSERT(growth_in_pages >= 0);
    // Fraction of asymptote used.
    double f = static_cast<double>(after.CombinedUsedInWords() +
                                   (kPageSizeInWords * growth_in_pages)) /
               static_cast<double>(max_capacity_in_words);
    ASSERT(f >= 0.0);
    // Increase weight at the high end.
    f = f * f;
    // Fraction of asymptote available.
    f = 1.0 - f;
    ASSERT(f <= 1.0);
    // Discount growth more the closer we get to the desired asymptote.
    growth_in_pages = static_cast<intptr_t>(growth_in_pages * f);
    // Minimum growth step after reaching the asymptote.
    intptr_t min_step = (2 * MB) / kPageSize;
    growth_in_pages = Utils::Maximum(min_step, growth_in_pages);
  }

  RecordUpdate(before, after, growth_in_pages, "gc");
}

void PageSpaceController::EvaluateAfterLoading(SpaceUsage after) {
  // Number of pages we can allocate and still be within the desired growth
  // ratio.
  intptr_t growth_in_pages;
  if (desired_utilization_ == 0.0) {
    growth_in_pages = heap_growth_max_;
  } else {
    growth_in_pages = (static_cast<intptr_t>(after.CombinedUsedInWords() /
                                             desired_utilization_) -
                       (after.CombinedUsedInWords())) /
                      kPageSizeInWords;
  }

  // Apply growth cap.
  intptr_t heap_growth_min = FLAG_new_gen_semi_max_size * MB / kPageSize;
  growth_in_pages =
      Utils::Maximum(static_cast<intptr_t>(heap_growth_min), growth_in_pages);
  growth_in_pages =
      Utils::Minimum(static_cast<intptr_t>(heap_growth_max_), growth_in_pages);

  RecordUpdate(after, after, growth_in_pages, "loaded");
}

void PageSpaceController::RecordUpdate(SpaceUsage before,
                                       SpaceUsage after,
                                       intptr_t growth_in_pages,
                                       const char* reason) {
  // Save final threshold compared before growing.
  intptr_t threshold =
      after.CombinedUsedInWords() + (kPageSizeInWords * growth_in_pages);

  bool concurrent_mark = FLAG_concurrent_mark && (FLAG_marker_tasks != 0);
  if (concurrent_mark) {
    soft_gc_threshold_in_words_ = threshold;
    hard_gc_threshold_in_words_ = kIntptrMax / kWordSize;
  } else {
    soft_gc_threshold_in_words_ = kIntptrMax / kWordSize;
    hard_gc_threshold_in_words_ = threshold;
  }

  // Set a tight idle threshold.
  idle_gc_threshold_in_words_ =
      after.CombinedUsedInWords() + (2 * kPageSizeInWords);

#if defined(SUPPORT_TIMELINE)
  Thread* thread = Thread::Current();
  if (thread != nullptr) {
    TIMELINE_FUNCTION_GC_DURATION(thread, "UpdateGrowthLimit");
    tbes.SetNumArguments(6);
    tbes.CopyArgument(0, "Reason", reason);
    tbes.FormatArgument(1, "Before.CombinedUsed (kB)", "%" Pd "",
                        RoundWordsToKB(before.CombinedUsedInWords()));
    tbes.FormatArgument(2, "After.CombinedUsed (kB)", "%" Pd "",
                        RoundWordsToKB(after.CombinedUsedInWords()));
    tbes.FormatArgument(3, "Hard Threshold (kB)", "%" Pd "",
                        RoundWordsToKB(hard_gc_threshold_in_words_));
    tbes.FormatArgument(4, "Soft Threshold (kB)", "%" Pd "",
                        RoundWordsToKB(soft_gc_threshold_in_words_));
    tbes.FormatArgument(5, "Idle Threshold (kB)", "%" Pd "",
                        RoundWordsToKB(idle_gc_threshold_in_words_));
  }
#endif

  if (FLAG_log_growth || FLAG_verbose_gc) {
    THR_Print("%s: hard_threshold=%" Pd "MB, soft_threshold=%" Pd
              "MB, idle_threshold=%" Pd "MB, reason=%s\n",
              heap_->isolate_group()->source()->name,
              RoundWordsToMB(hard_gc_threshold_in_words_),
              RoundWordsToMB(soft_gc_threshold_in_words_),
              RoundWordsToMB(idle_gc_threshold_in_words_), reason);
  }
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
