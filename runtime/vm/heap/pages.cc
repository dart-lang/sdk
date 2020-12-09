// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/pages.h"

#include "platform/assert.h"
#include "platform/leak_sanitizer.h"
#include "vm/dart.h"
#include "vm/heap/become.h"
#include "vm/heap/compactor.h"
#include "vm/heap/marker.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/sweeper.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os_thread.h"
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
DEFINE_FLAG(bool, log_growth, false, "Log PageSpace growth policy decisions.");

OldPage* OldPage::Allocate(intptr_t size_in_words,
                           PageType type,
                           const char* name) {
  const bool executable = type == kExecutable;

  VirtualMemory* memory = VirtualMemory::AllocateAligned(
      size_in_words << kWordSizeLog2, kOldPageSize, executable, name);
  if (memory == NULL) {
    return NULL;
  }

  OldPage* result = reinterpret_cast<OldPage*>(memory->address());
  ASSERT(result != NULL);
  result->memory_ = memory;
  result->next_ = NULL;
  result->used_in_bytes_ = 0;
  result->forwarding_page_ = NULL;
  result->card_table_ = NULL;
  result->type_ = type;

  LSAN_REGISTER_ROOT_REGION(result, sizeof(*result));

  return result;
}

void OldPage::Deallocate() {
  if (card_table_ != NULL) {
    free(card_table_);
    card_table_ = NULL;
  }

  bool image_page = is_image_page();

  if (!image_page) {
    LSAN_UNREGISTER_ROOT_REGION(this, sizeof(*this));
  }

  // For a regular heap pages, the memory for this object will become
  // unavailable after the delete below.
  delete memory_;

  // For a heap page from a snapshot, the OldPage object lives in the malloc
  // heap rather than the page itself.
  if (image_page) {
    free(this);
  }
}

void OldPage::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint());
  NoSafepointScope no_safepoint;
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    ObjectPtr raw_obj = ObjectLayout::FromAddr(obj_addr);
    visitor->VisitObject(raw_obj);
    obj_addr += raw_obj->ptr()->HeapSize();
  }
  ASSERT(obj_addr == end_addr);
}

void OldPage::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask));
  NoSafepointScope no_safepoint;
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    ObjectPtr raw_obj = ObjectLayout::FromAddr(obj_addr);
    obj_addr += raw_obj->ptr()->VisitPointers(visitor);
  }
  ASSERT(obj_addr == end_addr);
}

void OldPage::VisitRememberedCards(ObjectPointerVisitor* visitor) {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kScavengerTask));
  NoSafepointScope no_safepoint;

  if (card_table_ == NULL) {
    return;
  }

  bool table_is_empty = false;

  ArrayPtr obj = static_cast<ArrayPtr>(ObjectLayout::FromAddr(object_start()));
  ASSERT(obj->IsArray());
  ASSERT(obj->ptr()->IsCardRemembered());
  ObjectPtr* obj_from = obj->ptr()->from();
  ObjectPtr* obj_to = obj->ptr()->to(Smi::Value(obj->ptr()->length_));

  const intptr_t size = card_table_size();
  for (intptr_t i = 0; i < size; i++) {
    if (card_table_[i] != 0) {
      ObjectPtr* card_from =
          reinterpret_cast<ObjectPtr*>(this) + (i << kSlotsPerCardLog2);
      ObjectPtr* card_to = reinterpret_cast<ObjectPtr*>(card_from) +
                           (1 << kSlotsPerCardLog2) - 1;
      // Minus 1 because to is inclusive.

      if (card_from < obj_from) {
        // First card overlaps with header.
        card_from = obj_from;
      }
      if (card_to > obj_to) {
        // Last card(s) may extend past the object. Array truncation can make
        // this happen for more than one card.
        card_to = obj_to;
      }

      visitor->VisitPointers(card_from, card_to);

      bool has_new_target = false;
      for (ObjectPtr* slot = card_from; slot <= card_to; slot++) {
        if ((*slot)->IsNewObjectMayBeSmi()) {
          has_new_target = true;
          break;
        }
      }

      if (has_new_target) {
        // Card remains remembered.
        table_is_empty = false;
      } else {
        card_table_[i] = 0;
      }
    }
  }

  if (table_is_empty) {
    free(card_table_);
    card_table_ = NULL;
  }
}

ObjectPtr OldPage::FindObject(FindObjectVisitor* visitor) const {
  uword obj_addr = object_start();
  uword end_addr = object_end();
  if (visitor->VisitRange(obj_addr, end_addr)) {
    while (obj_addr < end_addr) {
      ObjectPtr raw_obj = ObjectLayout::FromAddr(obj_addr);
      uword next_obj_addr = obj_addr + raw_obj->ptr()->HeapSize();
      if (visitor->VisitRange(obj_addr, next_obj_addr) &&
          raw_obj->ptr()->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      obj_addr = next_obj_addr;
    }
    ASSERT(obj_addr == end_addr);
  }
  return Object::null();
}

void OldPage::WriteProtect(bool read_only) {
  ASSERT(!is_image_page());

  VirtualMemory::Protection prot;
  if (read_only) {
    if ((type_ == kExecutable) && (memory_->AliasOffset() == 0)) {
      prot = VirtualMemory::kReadExecute;
    } else {
      prot = VirtualMemory::kReadOnly;
    }
  } else {
    prot = VirtualMemory::kReadWrite;
  }
  memory_->Protect(prot);
}

// The initial estimate of how many words we can mark per microsecond (usage
// before / mark-sweep time). This is a conservative value observed running
// Flutter on a Nexus 4. After the first mark-sweep, we instead use a value
// based on the device's actual speed.
static const intptr_t kConservativeInitialMarkSpeed = 20;

PageSpace::PageSpace(Heap* heap, intptr_t max_capacity_in_words)
    : heap_(heap),
      num_freelists_(Utils::Maximum(FLAG_scavenger_tasks, 1) + 1),
      freelists_(new FreeList[num_freelists_]),
      pages_lock_(),
      max_capacity_in_words_(max_capacity_in_words),
      usage_(),
      allocated_black_in_words_(0),
      tasks_lock_(),
      tasks_(0),
      concurrent_marker_tasks_(0),
      phase_(kDone),
#if defined(DEBUG)
      iterating_thread_(NULL),
#endif
      page_space_controller_(heap,
                             FLAG_old_gen_growth_space_ratio,
                             FLAG_old_gen_growth_rate,
                             FLAG_old_gen_growth_time_ratio),
      marker_(NULL),
      gc_time_micros_(0),
      collections_(0),
      mark_words_per_micro_(kConservativeInitialMarkSpeed),
      enable_concurrent_mark_(FLAG_concurrent_mark) {
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
    while (tasks() > 0) {
      ml.Wait();
    }
  }
  FreePages(pages_);
  FreePages(exec_pages_);
  FreePages(large_pages_);
  FreePages(image_pages_);
  ASSERT(marker_ == NULL);
  delete[] freelists_;
}

intptr_t PageSpace::LargePageSizeInWordsFor(intptr_t size) {
  intptr_t page_size = Utils::RoundUp(size + OldPage::ObjectStartOffset(),
                                      VirtualMemory::PageSize());
  return page_size >> kWordSizeLog2;
}

void PageSpace::AddPageLocked(OldPage* page) {
  if (pages_ == nullptr) {
    pages_ = page;
  } else {
    pages_tail_->set_next(page);
  }
  pages_tail_ = page;
}

void PageSpace::AddLargePageLocked(OldPage* page) {
  if (large_pages_ == nullptr) {
    large_pages_ = page;
  } else {
    large_pages_tail_->set_next(page);
  }
  large_pages_tail_ = page;
}

void PageSpace::AddExecPageLocked(OldPage* page) {
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

void PageSpace::RemovePageLocked(OldPage* page, OldPage* previous_page) {
  if (previous_page != NULL) {
    previous_page->set_next(page->next());
  } else {
    pages_ = page->next();
  }
  if (page == pages_tail_) {
    pages_tail_ = previous_page;
  }
}

void PageSpace::RemoveLargePageLocked(OldPage* page, OldPage* previous_page) {
  if (previous_page != NULL) {
    previous_page->set_next(page->next());
  } else {
    large_pages_ = page->next();
  }
  if (page == large_pages_tail_) {
    large_pages_tail_ = previous_page;
  }
}

void PageSpace::RemoveExecPageLocked(OldPage* page, OldPage* previous_page) {
  if (previous_page != NULL) {
    previous_page->set_next(page->next());
  } else {
    exec_pages_ = page->next();
  }
  if (page == exec_pages_tail_) {
    exec_pages_tail_ = previous_page;
  }
}

OldPage* PageSpace::AllocatePage(OldPage::PageType type, bool link) {
  {
    MutexLocker ml(&pages_lock_);
    if (!CanIncreaseCapacityInWordsLocked(kOldPageSizeInWords)) {
      return nullptr;
    }
    IncreaseCapacityInWordsLocked(kOldPageSizeInWords);
  }
  const bool is_exec = (type == OldPage::kExecutable);
  const char* name = Heap::RegionName(is_exec ? Heap::kCode : Heap::kOld);
  OldPage* page = OldPage::Allocate(kOldPageSizeInWords, type, name);
  if (page == nullptr) {
    RELEASE_ASSERT(!FLAG_abort_on_oom);
    IncreaseCapacityInWords(-kOldPageSizeInWords);
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
  if ((type != OldPage::kExecutable) && (heap_ != nullptr) &&
      (!heap_->is_vm_isolate())) {
    page->AllocateForwardingPage();
  }
  return page;
}

OldPage* PageSpace::AllocateLargePage(intptr_t size, OldPage::PageType type) {
  const intptr_t page_size_in_words = LargePageSizeInWordsFor(size);
  {
    MutexLocker ml(&pages_lock_);
    if (!CanIncreaseCapacityInWordsLocked(page_size_in_words)) {
      return nullptr;
    }
    IncreaseCapacityInWordsLocked(page_size_in_words);
  }
  const bool is_exec = (type == OldPage::kExecutable);
  const char* name = Heap::RegionName(is_exec ? Heap::kCode : Heap::kOld);
  OldPage* page = OldPage::Allocate(page_size_in_words, type, name);

  MutexLocker ml(&pages_lock_);
  if (page == nullptr) {
    IncreaseCapacityInWordsLocked(-page_size_in_words);
    return nullptr;
  }
  if (is_exec) {
    AddExecPageLocked(page);
  } else {
    AddLargePageLocked(page);
  }

  // Only one object in this page (at least until Array::MakeFixedLength
  // is called).
  page->set_object_end(page->object_start() + size);
  return page;
}

void PageSpace::TruncateLargePage(OldPage* page,
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

void PageSpace::FreePage(OldPage* page, OldPage* previous_page) {
  bool is_exec = (page->type() == OldPage::kExecutable);
  {
    MutexLocker ml(&pages_lock_);
    IncreaseCapacityInWordsLocked(-(page->memory_->size() >> kWordSizeLog2));
    if (is_exec) {
      RemoveExecPageLocked(page, previous_page);
    } else {
      RemovePageLocked(page, previous_page);
    }
  }
  // TODO(iposva): Consider adding to a pool of empty pages.
  page->Deallocate();
}

void PageSpace::FreeLargePage(OldPage* page, OldPage* previous_page) {
  ASSERT(page->type() != OldPage::kExecutable);
  MutexLocker ml(&pages_lock_);
  IncreaseCapacityInWordsLocked(-(page->memory_->size() >> kWordSizeLog2));
  RemoveLargePageLocked(page, previous_page);
  page->Deallocate();
}

void PageSpace::FreePages(OldPage* pages) {
  OldPage* page = pages;
  while (page != NULL) {
    OldPage* next = page->next();
    page->Deallocate();
    page = next;
  }
}

void PageSpace::EvaluateConcurrentMarking(GrowthPolicy growth_policy) {
  if (growth_policy != kForceGrowth) {
    ASSERT(GrowthControlState());
    if (heap_ != NULL) {  // Some unit tests.
      Thread* thread = Thread::Current();
      if (thread->CanCollectGarbage()) {
        heap_->CheckFinishConcurrentMarking(thread);
        heap_->CheckStartConcurrentMarking(thread, Heap::kOldSpace);
      }
    }
  }
}

uword PageSpace::TryAllocateInFreshPage(intptr_t size,
                                        FreeList* freelist,
                                        OldPage::PageType type,
                                        GrowthPolicy growth_policy,
                                        bool is_locked) {
  ASSERT(Heap::IsAllocatableViaFreeLists(size));

  EvaluateConcurrentMarking(growth_policy);

  uword result = 0;
  SpaceUsage after_allocation = GetCurrentUsage();
  after_allocation.used_in_words += size >> kWordSizeLog2;
  // Can we grow by one page?
  after_allocation.capacity_in_words += kOldPageSizeInWords;
  if (growth_policy == kForceGrowth ||
      !page_space_controller_.ReachedHardThreshold(after_allocation)) {
    OldPage* page = AllocatePage(type);
    if (page == NULL) {
      return 0;
    }
    // Start of the newly allocated page is the allocated object.
    result = page->object_start();
    // Note: usage_.capacity_in_words is increased by AllocatePage.
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
                                             OldPage::PageType type,
                                             GrowthPolicy growth_policy) {
  ASSERT(!Heap::IsAllocatableViaFreeLists(size));

  EvaluateConcurrentMarking(growth_policy);

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
    OldPage* page = AllocateLargePage(size, type);
    if (page != NULL) {
      result = page->object_start();
      // Note: usage_.capacity_in_words is increased by AllocateLargePage.
      usage_.used_in_words += (size >> kWordSizeLog2);
    }
  }
  return result;
}

uword PageSpace::TryAllocateInternal(intptr_t size,
                                     FreeList* freelist,
                                     OldPage::PageType type,
                                     GrowthPolicy growth_policy,
                                     bool is_protected,
                                     bool is_locked) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword result = 0;
  if (Heap::IsAllocatableViaFreeLists(size)) {
    if (is_locked) {
      result = freelist->TryAllocateLocked(size, is_protected);
    } else {
      result = freelist->TryAllocate(size, is_protected);
    }
    if (result == 0) {
      result = TryAllocateInFreshPage(size, freelist, type, growth_policy,
                                      is_locked);
      // usage_ is updated by the call above.
    } else {
      usage_.used_in_words += (size >> kWordSizeLog2);
    }
  } else {
    result = TryAllocateInFreshLargePage(size, type, growth_policy);
    // usage_ is updated by the call above.
  }
  ASSERT((result & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
  return result;
}

void PageSpace::AcquireLock(FreeList* freelist) {
  freelist->mutex()->Lock();
}

void PageSpace::ReleaseLock(FreeList* freelist) {
  intptr_t size = freelist->TakeUnaccountedSizeLocked();
  usage_.used_in_words += (size >> kWordSizeLog2);
  freelist->mutex()->Unlock();
}

class BasePageIterator : ValueObject {
 public:
  explicit BasePageIterator(const PageSpace* space) : space_(space) {}

  OldPage* page() const { return page_; }

  bool Done() const { return page_ == NULL; }

  void Advance() {
    ASSERT(!Done());
    page_ = page_->next();
    if ((page_ == NULL) && (list_ == kRegular)) {
      list_ = kExecutable;
      page_ = space_->exec_pages_;
    }
    if ((page_ == NULL) && (list_ == kExecutable)) {
      list_ = kLarge;
      page_ = space_->large_pages_;
    }
    if ((page_ == NULL) && (list_ == kLarge)) {
      list_ = kImage;
      page_ = space_->image_pages_;
    }
    ASSERT((page_ != NULL) || (list_ == kImage));
  }

 protected:
  enum List { kRegular, kExecutable, kLarge, kImage };

  void Initialize() {
    list_ = kRegular;
    page_ = space_->pages_;
    if (page_ == NULL) {
      list_ = kExecutable;
      page_ = space_->exec_pages_;
      if (page_ == NULL) {
        list_ = kLarge;
        page_ = space_->large_pages_;
        if (page_ == NULL) {
          list_ = kImage;
          page_ = space_->image_pages_;
        }
      }
    }
  }

  const PageSpace* space_ = nullptr;
  List list_;
  OldPage* page_ = nullptr;
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
  OldPage* page() const { return page_; }
  bool Done() const { return page_ == NULL; }
  void Advance() {
    ASSERT(!Done());
    page_ = page_->next();
  }

 private:
  const PageSpace* space_;
  MutexLocker ml_;
  NoSafepointScope no_safepoint;
  OldPage* page_;
};

void PageSpace::MakeIterable() const {
  // Assert not called from concurrent sweeper task.
  // TODO(koda): Use thread/task identity when implemented.
  ASSERT(IsolateGroup::Current()->heap() != NULL);
  for (intptr_t i = 0; i < num_freelists_; i++) {
    freelists_[i].MakeIterable();
  }
}

void PageSpace::AbandonBumpAllocation() {
  for (intptr_t i = 0; i < num_freelists_; i++) {
    freelists_[i].AbandonBumpAllocation();
  }
}

void PageSpace::AbandonMarkingForShutdown() {
  delete marker_;
  marker_ = NULL;
}

void PageSpace::UpdateMaxCapacityLocked() {
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(heap_ != NULL);
  ASSERT(heap_->isolate_group() != NULL);
  auto isolate_group = heap_->isolate_group();
  isolate_group->GetHeapOldCapacityMaxMetric()->SetValue(
      static_cast<int64_t>(usage_.capacity_in_words) * kWordSize);
}

void PageSpace::UpdateMaxUsed() {
  if (heap_ == NULL) {
    // Some unit tests.
    return;
  }
  ASSERT(heap_ != NULL);
  ASSERT(heap_->isolate_group() != NULL);
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

bool PageSpace::Contains(uword addr, OldPage::PageType type) const {
  if (type == OldPage::kExecutable) {
    // Fast path executable pages.
    for (ExclusiveCodePageIterator it(this); !it.Done(); it.Advance()) {
      if (it.page()->Contains(addr)) {
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
    if ((it.page()->type() != OldPage::kExecutable) &&
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

void PageSpace::VisitRememberedCards(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kScavengerTask));

  // Wait for the sweeper to finish mutating the large page list.
  MonitorLocker ml(tasks_lock());
  while (phase() == kSweepingLarge) {
    ml.Wait();  // No safepoint check.
  }

  // Large pages may be added concurrently due to promotion in another scavenge
  // worker, so terminate the traversal when we hit the tail we saw while
  // holding the pages lock, instead of at NULL, otherwise we are racing when we
  // read OldPage::next_ and OldPage::remembered_cards_.
  OldPage* page;
  OldPage* tail;
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

ObjectPtr PageSpace::FindObject(FindObjectVisitor* visitor,
                                OldPage::PageType type) const {
  if (type == OldPage::kExecutable) {
    // Fast path executable pages.
    for (ExclusiveCodePageIterator it(this); !it.Done(); it.Advance()) {
      ObjectPtr obj = it.page()->FindObject(visitor);
      if (obj != Object::null()) {
        return obj;
      }
    }
    return Object::null();
  }

  for (ExclusivePageIterator it(this); !it.Done(); it.Advance()) {
    if (it.page()->type() == type) {
      ObjectPtr obj = it.page()->FindObject(visitor);
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
  virtual void VisitObject(ObjectPtr obj) {
    array_->AddValue(obj->ptr()->HeapSize() / kObjectAlignment);
    array_->AddValue(obj->GetClassId());
  }

 private:
  JSONArray* array_;
};

void PageSpace::PrintHeapMapToJSONStream(Isolate* isolate,
                                         JSONStream* stream) const {
  JSONObject heap_map(stream);
  heap_map.AddProperty("type", "HeapMap");
  heap_map.AddProperty("freeClassId", static_cast<intptr_t>(kFreeListElement));
  heap_map.AddProperty("unitSizeBytes",
                       static_cast<intptr_t>(kObjectAlignment));
  heap_map.AddProperty("pageSizeBytes", kOldPageSizeInWords * kWordSize);
  {
    JSONObject class_list(&heap_map, "classList");
    isolate->class_table()->PrintToJSONObject(&class_list);
  }
  {
    // "pages" is an array [page0, page1, ..., pageN], each page of the form
    // {"object_start": "0x...", "objects": [size, class id, size, ...]}
    // TODO(19445): Use ExclusivePageIterator once HeapMap supports large pages.
    HeapIterationScope iteration(Thread::Current());
    MutexLocker ml(&pages_lock_);
    MakeIterable();
    JSONArray all_pages(&heap_map, "pages");
    for (OldPage* page = pages_; page != NULL; page = page->next()) {
      JSONObject page_container(&all_pages);
      page_container.AddPropertyF("objectStart", "0x%" Px "",
                                  page->object_start());
      JSONArray page_map(&page_container, "objects");
      HeapMapAsJSONVisitor printer(&page_map);
      page->VisitObjects(&printer);
    }
    for (OldPage* page = exec_pages_; page != NULL; page = page->next()) {
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
    OldPage* page = exec_pages_;
    while (page != NULL) {
      ASSERT(page->type() == OldPage::kExecutable);
      page->WriteProtect(read_only);
      page = page->next();
    }
    page = large_pages_;
    while (page != NULL) {
      if (page->type() == OldPage::kExecutable) {
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

  // Discount two pages to account for the newest data and code pages, whose
  // partial use doesn't indicate fragmentation.
  const intptr_t excess_in_words =
      usage_.capacity_in_words - usage_.used_in_words - 2 * kOldPageSizeInWords;
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

void PageSpace::TryReleaseReservation() {
  if (oom_reservation_ == nullptr) return;
  uword addr = reinterpret_cast<uword>(oom_reservation_);
  intptr_t size = oom_reservation_->HeapSize();
  oom_reservation_ = nullptr;
  freelists_[OldPage::kData].Free(addr, size);
}

bool PageSpace::MarkReservation() {
  if (oom_reservation_ == nullptr) {
    return false;
  }
  ObjectLayout* ptr = reinterpret_cast<ObjectLayout*>(oom_reservation_);
  if (!ptr->IsMarked()) {
    ptr->SetMarkBit();
  }
  return true;
}

void PageSpace::TryReserveForOOM() {
  if (oom_reservation_ == nullptr) {
    uword addr = TryAllocate(kOOMReservationSize, OldPage::kData,
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
        ObjectLayout::FromAddr(reinterpret_cast<uword>(oom_reservation_));
    visitor->VisitPointer(&ptr);
    oom_reservation_ =
        reinterpret_cast<FreeListElement*>(ObjectLayout::ToAddr(ptr));
  }
}

void PageSpace::CollectGarbage(bool compact, bool finalize) {
  ASSERT(GrowthControlState());

  if (!finalize) {
#if defined(TARGET_ARCH_IA32)
    return;  // Barrier not implemented.
#else
    if (!enable_concurrent_mark()) return;  // Disabled.
    if (FLAG_marker_tasks == 0) return;     // Disabled.
#endif
  }

  Thread* thread = Thread::Current();
  const int64_t pre_safe_point = OS::GetCurrentMonotonicMicros();
  SafepointOperationScope safepoint_scope(thread);

  const int64_t pre_wait_for_sweepers = OS::GetCurrentMonotonicMicros();
  // Wait for pending tasks to complete and then account for the driver task.
  Phase waited_for;
  {
    MonitorLocker locker(tasks_lock());
    waited_for = phase();
    if (!finalize &&
        (phase() == kMarking || phase() == kAwaitingFinalization)) {
      // Concurrent mark is already running.
      return;
    }

    while (tasks() > 0) {
      locker.Wait();
    }
    ASSERT(phase() == kAwaitingFinalization || phase() == kDone);
    set_tasks(1);
  }

  if (FLAG_verbose_gc) {
    const int64_t wait =
        OS::GetCurrentMonotonicMicros() - pre_wait_for_sweepers;
    if (waited_for == kMarking) {
      THR_Print("Waited %" Pd64 " us for concurrent marking to finish.\n",
                wait);
    } else if (waited_for == kSweepingRegular || waited_for == kSweepingLarge) {
      THR_Print("Waited %" Pd64 " us for concurrent sweeping to finish.\n",
                wait);
    }
  }

  // Ensure that all threads for this isolate are at a safepoint (either
  // stopped or in native code). We have guards around Newgen GC and oldgen GC
  // to ensure that if two threads are racing to collect at the same time the
  // loser skips collection and goes straight to allocation.
  {
    CollectGarbageHelper(compact, finalize, pre_wait_for_sweepers,
                         pre_safe_point);
  }

  // Done, reset the task count.
  {
    MonitorLocker ml(tasks_lock());
    set_tasks(tasks() - 1);
    ml.NotifyAll();
  }
}

void PageSpace::CollectGarbageHelper(bool compact,
                                     bool finalize,
                                     int64_t pre_wait_for_sweepers,
                                     int64_t pre_safe_point) {
  Thread* thread = Thread::Current();
  ASSERT(thread->IsAtSafepoint());
  auto isolate_group = heap_->isolate_group();
  ASSERT(isolate_group == IsolateGroup::Current());

  const int64_t start = OS::GetCurrentMonotonicMicros();

  // Perform various cleanup that relies on no tasks interfering.
  isolate_group->shared_class_table()->FreeOldTables();
  isolate_group->ForEachIsolate(
      [&](Isolate* isolate) { isolate->field_table()->FreeOldTables(); },
      /*at_safepoint=*/true);

  NoSafepointScope no_safepoints;

  if (FLAG_print_free_list_before_gc) {
    for (intptr_t i = 0; i < num_freelists_; i++) {
      OS::PrintErr("Before GC: Freelist %" Pd "\n", i);
      freelists_[i].Print();
    }
  }

  if (FLAG_verify_before_gc) {
    OS::PrintErr("Verifying before marking...");
    heap_->VerifyGC(phase() == kDone ? kForbidMarked : kAllowMarked);
    OS::PrintErr(" done.\n");
  }

  // Make code pages writable.
  if (finalize) WriteProtectCode(false);

  // Save old value before GCMarker visits the weak persistent handles.
  SpaceUsage usage_before = GetCurrentUsage();

  // Mark all reachable old-gen objects.
  if (marker_ == NULL) {
    ASSERT(phase() == kDone);
    marker_ = new GCMarker(isolate_group, heap_);
  } else {
    ASSERT(phase() == kAwaitingFinalization);
  }

  if (!finalize) {
    ASSERT(phase() == kDone);
    marker_->StartConcurrentMark(this);
    return;
  }

  marker_->MarkObjects(this);
  usage_.used_in_words = marker_->marked_words() + allocated_black_in_words_;
  allocated_black_in_words_ = 0;
  mark_words_per_micro_ = marker_->MarkedWordsPerMicro();
  delete marker_;
  marker_ = NULL;

  int64_t mid1 = OS::GetCurrentMonotonicMicros();

  // Abandon the remainder of the bump allocation block.
  AbandonBumpAllocation();
  // Reset the freelists and setup sweeping.
  for (intptr_t i = 0; i < num_freelists_; i++) {
    freelists_[i].Reset();
  }

  int64_t mid2 = OS::GetCurrentMonotonicMicros();
  int64_t mid3 = 0;

  {
    if (FLAG_verify_before_gc) {
      OS::PrintErr("Verifying before sweeping...");
      heap_->VerifyGC(kAllowMarked);
      OS::PrintErr(" done.\n");
    }

    // Executable pages are always swept immediately to simplify
    // code protection.

    TIMELINE_FUNCTION_GC_DURATION(thread, "SweepExecutable");
    GCSweeper sweeper;
    OldPage* prev_page = NULL;
    OldPage* page = exec_pages_;
    FreeList* freelist = &freelists_[OldPage::kExecutable];
    MutexLocker ml(freelist->mutex());
    while (page != NULL) {
      OldPage* next_page = page->next();
      bool page_in_use = sweeper.SweepPage(page, freelist, true /*is_locked*/);
      if (page_in_use) {
        prev_page = page;
      } else {
        FreePage(page, prev_page);
      }
      // Advance to the next page.
      page = next_page;
    }

    mid3 = OS::GetCurrentMonotonicMicros();
  }

  bool has_reservation = MarkReservation();

  if (compact) {
    SweepLarge();
    Compact(thread);
    set_phase(kDone);
  } else if (FLAG_concurrent_sweep && has_reservation) {
    ConcurrentSweep(isolate_group);
  } else {
    SweepLarge();
    Sweep();
    set_phase(kDone);
  }

  TryReserveForOOM();

  // Make code pages read-only.
  if (finalize) WriteProtectCode(true);

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
    for (intptr_t i = 0; i < num_freelists_; i++) {
      OS::PrintErr("After GC: Freelist %" Pd "\n", i);
      freelists_[i].Print();
    }
  }

  UpdateMaxUsed();
  if (heap_ != NULL) {
    heap_->UpdateGlobalMaxUsed();
  }
}

void PageSpace::SweepLarge() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "SweepLarge");

  GCSweeper sweeper;
  OldPage* prev_page = nullptr;
  OldPage* page = large_pages_;
  while (page != nullptr) {
    OldPage* next_page = page->next();
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
}

void PageSpace::Sweep() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Sweep");

  GCSweeper sweeper;

  intptr_t shard = 0;
  const intptr_t num_shards = Utils::Maximum(FLAG_scavenger_tasks, 1);
  for (intptr_t i = 0; i < num_shards; i++) {
    DataFreeList(i)->mutex()->Lock();
  }

  OldPage* prev_page = nullptr;
  OldPage* page = pages_;
  while (page != nullptr) {
    OldPage* next_page = page->next();
    ASSERT(page->type() == OldPage::kData);
    shard = (shard + 1) % num_shards;
    bool page_in_use =
        sweeper.SweepPage(page, DataFreeList(shard), true /*is_locked*/);
    if (page_in_use) {
      prev_page = page;
    } else {
      FreePage(page, prev_page);
    }
    // Advance to the next page.
    page = next_page;
  }

  for (intptr_t i = 0; i < num_shards; i++) {
    DataFreeList(i)->mutex()->Unlock();
  }

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after sweeping...");
    heap_->VerifyGC(kForbidMarked);
    OS::PrintErr(" done.\n");
  }
}

void PageSpace::ConcurrentSweep(IsolateGroup* isolate_group) {
  // Start the concurrent sweeper task now.
  GCSweeper::SweepConcurrent(isolate_group, pages_, pages_tail_, large_pages_,
                             large_pages_tail_, &freelists_[OldPage::kData]);
}

void PageSpace::Compact(Thread* thread) {
  thread->isolate_group()->set_compaction_in_progress(true);
  GCCompactor compactor(thread, heap_);
  compactor.Compact(pages_, &freelists_[OldPage::kData], &pages_lock_);
  thread->isolate_group()->set_compaction_in_progress(false);

  if (FLAG_verify_after_gc) {
    OS::PrintErr("Verifying after compacting...");
    heap_->VerifyGC(kForbidMarked);
    OS::PrintErr(" done.\n");
  }
}

uword PageSpace::TryAllocateDataBumpLocked(FreeList* freelist, intptr_t size) {
  ASSERT(size >= kObjectAlignment);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  intptr_t remaining = freelist->end() - freelist->top();
  if (UNLIKELY(remaining < size)) {
    // Checking this first would be logical, but needlessly slow.
    if (!Heap::IsAllocatableViaFreeLists(size)) {
      return TryAllocateDataLocked(freelist, size, kForceGrowth);
    }
    FreeListElement* block = freelist->TryAllocateLargeLocked(size);
    if (block == NULL) {
      // Allocating from a new page (if growth policy allows) will have the
      // side-effect of populating the freelist with a large block. The next
      // bump allocation request will have a chance to consume that block.
      // TODO(koda): Could take freelist lock just once instead of twice.
      return TryAllocateInFreshPage(size, freelist, OldPage::kData,
                                    kForceGrowth, true /* is_locked*/);
    }
    intptr_t block_size = block->HeapSize();
    if (remaining > 0) {
      freelist->FreeLocked(freelist->top(), remaining);
    }
    freelist->set_top(reinterpret_cast<uword>(block));
    freelist->set_end(freelist->top() + block_size);
    remaining = block_size;
  }
  ASSERT(remaining >= size);
  uword result = freelist->top();
  freelist->set_top(result + size);

  freelist->AddUnaccountedSize(size);

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
    freelist->AddUnaccountedSize(size);
    return result;
  }
  return TryAllocateDataBumpLocked(freelist, size);
}

void PageSpace::SetupImagePage(void* pointer, uword size, bool is_executable) {
  // Setup a OldPage so precompiled Instructions can be traversed.
  // Instructions are contiguous at [pointer, pointer + size). OldPage
  // expects to find objects at [memory->start() + ObjectStartOffset,
  // memory->end()).
  uword offset = OldPage::ObjectStartOffset();
  pointer = reinterpret_cast<void*>(reinterpret_cast<uword>(pointer) - offset);
  ASSERT(Utils::IsAligned(pointer, kObjectAlignment));
  size += offset;

  VirtualMemory* memory = VirtualMemory::ForImagePage(pointer, size);
  ASSERT(memory != NULL);
  OldPage* page = reinterpret_cast<OldPage*>(malloc(sizeof(OldPage)));
  page->memory_ = memory;
  page->next_ = NULL;
  page->object_end_ = memory->end();
  page->used_in_bytes_ = page->object_end_ - page->object_start();
  page->forwarding_page_ = NULL;
  page->card_table_ = NULL;
  if (is_executable) {
    page->type_ = OldPage::kExecutable;
  } else {
    page->type_ = OldPage::kData;
  }

  MutexLocker ml(&pages_lock_);
  page->next_ = image_pages_;
  image_pages_ = page;
}

bool PageSpace::IsObjectFromImagePages(dart::ObjectPtr object) {
  uword object_addr = ObjectLayout::ToAddr(object);
  OldPage* image_page = image_pages_;
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
      is_enabled_(false),
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
  if (!is_enabled_) {
    return false;
  }
  if (heap_growth_ratio_ == 100) {
    return false;
  }
  return after.CombinedUsedInWords() > hard_gc_threshold_in_words_;
}

bool PageSpaceController::ReachedSoftThreshold(SpaceUsage after) const {
  if (!is_enabled_) {
    return false;
  }
  if (heap_growth_ratio_ == 100) {
    return false;
  }
  return after.CombinedUsedInWords() > soft_gc_threshold_in_words_;
}

bool PageSpaceController::ReachedIdleThreshold(SpaceUsage current) const {
  if (!is_enabled_) {
    return false;
  }
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
  heap_->RecordData(PageSpace::kGCTimeFraction, gc_time_fraction);

  // Assume garbage increases linearly with allocation:
  // G = kA, and estimate k from the previous cycle.
  const intptr_t allocated_since_previous_gc =
      before.CombinedUsedInWords() - last_usage_.CombinedUsedInWords();
  intptr_t grow_heap;
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
        (static_cast<intptr_t>(after.CombinedUsedInWords() /
                               desired_utilization_) -
         (after.CombinedUsedInWords())) /
        kOldPageSizeInWords;
    if (garbage_ratio == 0) {
      // No garbage in the previous cycle so it would be hard to compute a
      // grow_heap size based on estimated garbage so we use growth ratio
      // heuristics instead.
      grow_heap =
          Utils::Maximum(static_cast<intptr_t>(heap_growth_max_), grow_pages);
    } else {
      // Find minimum 'grow_heap' such that after increasing capacity by
      // 'grow_heap' pages and filling them, we expect a GC to be worthwhile.
      intptr_t max = heap_growth_max_;
      intptr_t min = 0;
      intptr_t local_grow_heap = 0;
      while (min < max) {
        local_grow_heap = (max + min) / 2;
        const intptr_t limit = after.CombinedUsedInWords() +
                               (local_grow_heap * kOldPageSizeInWords);
        const intptr_t allocated_before_next_gc =
            limit - (after.CombinedUsedInWords());
        const double estimated_garbage = k * allocated_before_next_gc;
        if (t <= estimated_garbage / limit) {
          max = local_grow_heap - 1;
        } else {
          min = local_grow_heap + 1;
        }
      }
      local_grow_heap = (max + min) / 2;
      grow_heap = local_grow_heap;
      ASSERT(grow_heap >= 0);
      // If we are going to grow by heap_grow_max_ then ensure that we
      // will be growing the heap at least by the growth ratio heuristics.
      if (grow_heap >= heap_growth_max_) {
        grow_heap = Utils::Maximum(grow_pages, grow_heap);
      }
    }
  } else {
    heap_->RecordData(PageSpace::kGarbageRatio, 100);
    grow_heap = 0;
  }
  heap_->RecordData(PageSpace::kPageGrowth, grow_heap);
  last_usage_ = after;

  intptr_t max_capacity_in_words = heap_->old_space()->max_capacity_in_words_;
  if (max_capacity_in_words != 0) {
    ASSERT(grow_heap >= 0);
    // Fraction of asymptote used.
    double f = static_cast<double>(after.CombinedUsedInWords() +
                                   (kOldPageSizeInWords * grow_heap)) /
               static_cast<double>(max_capacity_in_words);
    ASSERT(f >= 0.0);
    // Increase weight at the high end.
    f = f * f;
    // Fraction of asymptote available.
    f = 1.0 - f;
    ASSERT(f <= 1.0);
    // Discount growth more the closer we get to the desired asymptote.
    grow_heap = static_cast<intptr_t>(grow_heap * f);
    // Minimum growth step after reaching the asymptote.
    intptr_t min_step = (2 * MB) / kOldPageSize;
    grow_heap = Utils::Maximum(min_step, grow_heap);
  }

  RecordUpdate(before, after, grow_heap, "gc");
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
                      kOldPageSizeInWords;
  }

  // Apply growth cap.
  growth_in_pages =
      Utils::Minimum(static_cast<intptr_t>(heap_growth_max_), growth_in_pages);

  RecordUpdate(after, after, growth_in_pages, "loaded");
}

void PageSpaceController::RecordUpdate(SpaceUsage before,
                                       SpaceUsage after,
                                       intptr_t growth_in_pages,
                                       const char* reason) {
  // Save final threshold compared before growing.
  hard_gc_threshold_in_words_ =
      after.CombinedUsedInWords() + (kOldPageSizeInWords * growth_in_pages);

  // Start concurrent marking when old-space has less than half of new-space
  // available or less than 5% available.
#if defined(TARGET_ARCH_IA32)
  const intptr_t headroom = 0;  // No concurrent marking.
#else
  // Note that heap_ can be null in some unit tests.
  const intptr_t new_space =
      heap_ == nullptr ? 0 : heap_->new_space()->CapacityInWords();
  const intptr_t headroom =
      Utils::Maximum(new_space / 2, hard_gc_threshold_in_words_ / 20);
#endif
  soft_gc_threshold_in_words_ = hard_gc_threshold_in_words_ - headroom;

  // Set a tight idle threshold.
  idle_gc_threshold_in_words_ =
      after.CombinedUsedInWords() + (2 * kOldPageSizeInWords);

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

  if (FLAG_log_growth) {
    THR_Print("%s: threshold=%" Pd "kB, idle_threshold=%" Pd "kB, reason=%s\n",
              heap_->isolate_group()->source()->name,
              hard_gc_threshold_in_words_ / KBInWords,
              idle_gc_threshold_in_words_ / KBInWords, reason);
  }
}

void PageSpaceController::HintFreed(intptr_t size) {
  intptr_t size_in_words = size << kWordSizeLog2;
  if (size_in_words > idle_gc_threshold_in_words_) {
    idle_gc_threshold_in_words_ = 0;
  } else {
    idle_gc_threshold_in_words_ -= size_in_words;
  }

  // TODO(rmacnak): Hasten the soft threshold at some discount?
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
