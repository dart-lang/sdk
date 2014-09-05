// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PAGES_H_
#define VM_PAGES_H_

#include "vm/freelist.h"
#include "vm/globals.h"
#include "vm/ring_buffer.h"
#include "vm/spaces.h"
#include "vm/virtual_memory.h"

namespace dart {

DECLARE_FLAG(bool, collect_code);
DECLARE_FLAG(bool, log_code_drop);
DECLARE_FLAG(bool, always_drop_code);
DECLARE_FLAG(bool, write_protect_code);

// Forward declarations.
class Heap;
class JSONObject;
class ObjectPointerVisitor;

// A page containing old generation objects.
class HeapPage {
 public:
  enum PageType {
    kData = 0,
    kExecutable,
    kNumPageTypes
  };

  HeapPage* next() const { return next_; }
  void set_next(HeapPage* next) { next_ = next; }

  bool Contains(uword addr) {
    return memory_->Contains(addr);
  }

  uword object_start() const {
    return (reinterpret_cast<uword>(this) + ObjectStartOffset());
  }
  uword object_end() const {
    return object_end_;
  }

  PageType type() const {
    return executable_ ? kExecutable : kData;
  }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  RawObject* FindObject(FindObjectVisitor* visitor) const;

  void WriteProtect(bool read_only);

  static intptr_t ObjectStartOffset() {
    return Utils::RoundUp(sizeof(HeapPage), OS::kMaxPreferredCodeAlignment);
  }

 private:
  void set_object_end(uword val) {
    ASSERT((val & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
    object_end_ = val;
  }

  static HeapPage* Initialize(VirtualMemory* memory, PageType type);
  static HeapPage* Allocate(intptr_t size_in_words, PageType type);

  // Deallocate the virtual memory backing this page. The page pointer to this
  // page becomes immediately inaccessible.
  void Deallocate();

  VirtualMemory* memory_;
  HeapPage* next_;
  uword object_end_;
  bool executable_;

  friend class PageSpace;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(HeapPage);
};


// The history holds the timing information of the last garbage collection
// runs.
class PageSpaceGarbageCollectionHistory {
 public:
  PageSpaceGarbageCollectionHistory() {}
  ~PageSpaceGarbageCollectionHistory() {}

  void AddGarbageCollectionTime(int64_t start, int64_t end);

  int GarbageCollectionTimeFraction();

  bool IsEmpty() const { return history_.Size() == 0; }

 private:
  struct Entry {
    int64_t start;
    int64_t end;
  };
  static const intptr_t kHistoryLength = 4;
  RingBuffer<Entry, kHistoryLength> history_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(PageSpaceGarbageCollectionHistory);
};


// PageSpaceController controls the heap size.
class PageSpaceController {
 public:
  // The heap is passed in for recording stats only. The controller does not
  // invoke GC by itself.
  PageSpaceController(Heap* heap,
                      int heap_growth_ratio,
                      int heap_growth_max,
                      int garbage_collection_time_ratio);
  ~PageSpaceController();

  // Returns whether growing to 'after' should trigger a GC.
  // This method can be called before allocation (e.g., pretenuring) or after
  // (e.g., promotion), as it does not change the state of the controller.
  bool NeedsGarbageCollection(SpaceUsage after) const;

  // Should be called after each collection to update the controller state.
  void EvaluateGarbageCollection(SpaceUsage before,
                                 SpaceUsage after,
                                 int64_t start, int64_t end);

  int64_t last_code_collection_in_us() { return last_code_collection_in_us_; }
  void set_last_code_collection_in_us(int64_t t) {
    last_code_collection_in_us_ = t;
  }

  void Enable(SpaceUsage current) {
    last_usage_ = current;
    is_enabled_ = true;
  }
  void Disable() {
    is_enabled_ = false;
  }
  bool is_enabled() {
    return is_enabled_;
  }

 private:
  Heap* heap_;

  bool is_enabled_;

  // Usage after last evaluated GC or last enabled.
  SpaceUsage last_usage_;

  // Pages of capacity growth allowed before next GC is advised.
  intptr_t grow_heap_;

  // If the garbage collector was not able to free more than heap_growth_ratio_
  // memory, then the heap is grown. Otherwise garbage collection is performed.
  int heap_growth_ratio_;

  // The desired percent of heap in-use after a garbage collection.
  // Equivalent to \frac{100-heap_growth_ratio_}{100}.
  double desired_utilization_;

  // Max number of pages we grow.
  int heap_growth_max_;

  // If the relative GC time goes above garbage_collection_time_ratio_ %,
  // we grow the heap more aggressively.
  int garbage_collection_time_ratio_;

  // The time in microseconds of the last time we tried to collect unused
  // code.
  int64_t last_code_collection_in_us_;

  PageSpaceGarbageCollectionHistory history_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpaceController);
};


class PageSpace {
 public:
  // TODO(iposva): Determine heap sizes and tune the page size accordingly.
  static const intptr_t kPageSizeInWords = 256 * KBInWords;

  enum GrowthPolicy {
    kControlGrowth,
    kForceGrowth
  };

  PageSpace(Heap* heap, intptr_t max_capacity_in_words);
  ~PageSpace();

  uword TryAllocate(intptr_t size,
                    HeapPage::PageType type = HeapPage::kData,
                    GrowthPolicy growth_policy = kControlGrowth) {
    bool is_protected =
        (type == HeapPage::kExecutable) && FLAG_write_protect_code;
    bool is_locked = false;
    return TryAllocateInternal(
        size, type, growth_policy, is_protected, is_locked);
  }

  bool NeedsGarbageCollection() const {
    return page_space_controller_.NeedsGarbageCollection(usage_) ||
           NeedsExternalGC();
  }

  intptr_t UsedInWords() const { return usage_.used_in_words; }
  intptr_t CapacityInWords() const { return usage_.capacity_in_words; }
  intptr_t ExternalInWords() const {
    return usage_.external_in_words;
  }
  SpaceUsage GetCurrentUsage() const { return usage_; }

  bool Contains(uword addr) const;
  bool Contains(uword addr, HeapPage::PageType type) const;
  bool IsValidAddress(uword addr) const {
    return Contains(addr);
  }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  RawObject* FindObject(FindObjectVisitor* visitor,
                        HeapPage::PageType type) const;

  // Checks if enough time has elapsed since the last attempt to collect
  // code.
  bool ShouldCollectCode();

  // Collect the garbage in the page space using mark-sweep.
  void MarkSweep(bool invoke_api_callbacks);

  void StartEndAddress(uword* start, uword* end) const;

  void SetGrowthControlState(bool state) {
    if (state) {
      page_space_controller_.Enable(usage_);
    } else {
      page_space_controller_.Disable();
    }
  }

  bool GrowthControlState() {
    return page_space_controller_.is_enabled();
  }

  bool NeedsExternalGC() const {
    return UsedInWords() + ExternalInWords() > max_capacity_in_words_;
  }

  // TODO(koda): Unify protection handling.
  void WriteProtect(bool read_only);
  void WriteProtectCode(bool read_only);

  void AddGCTime(int64_t micros) {
    gc_time_micros_ += micros;
  }

  int64_t gc_time_micros() const {
    return gc_time_micros_;
  }

  void IncrementCollections() {
    collections_++;
  }

  intptr_t collections() const {
    return collections_;
  }

  void PrintToJSONObject(JSONObject* object);
  void PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream);

  void AllocateExternal(intptr_t size);
  void FreeExternal(intptr_t size);

  // Bulk data allocation.
  void AcquireDataLock();
  void ReleaseDataLock();

  uword TryAllocateDataLocked(intptr_t size, GrowthPolicy growth_policy) {
    bool is_protected = false;
    bool is_locked = true;
    return TryAllocateInternal(size,
                               HeapPage::kData,
                               growth_policy,
                               is_protected, is_locked);
  }

  Monitor* tasks_lock() const { return tasks_lock_; }
  intptr_t tasks() const { return tasks_; }
  void set_tasks(intptr_t val) {
    ASSERT(val >= 0);
    tasks_ = val;
  }

  // Attempt to allocate from bump block rather than normal freelist.
  uword TryAllocateDataBump(intptr_t size, GrowthPolicy growth_policy);
  uword TryAllocateDataBumpLocked(intptr_t size, GrowthPolicy growth_policy);
  uword TryAllocatePromoLocked(intptr_t size, GrowthPolicy growth_policy);

 private:
  // Ids for time and data records in Heap::GCStats.
  enum {
    // Time
    kMarkObjects = 0,
    kResetFreeLists = 1,
    kSweepPages = 2,
    kSweepLargePages = 3,
    // Data
    kGarbageRatio = 0,
    kGCTimeFraction = 1,
    kPageGrowth = 2,
    kAllowedGrowth = 3
  };

  static const intptr_t kAllocatablePageSize = 64 * KB;

  uword TryAllocateInternal(intptr_t size,
                            HeapPage::PageType type,
                            GrowthPolicy growth_policy,
                            bool is_protected,
                            bool is_locked);
  uword TryAllocateInFreshPage(intptr_t size,
                               HeapPage::PageType type,
                               GrowthPolicy growth_policy,
                               bool is_locked);
  uword TryAllocateDataBumpInternal(intptr_t size,
                                    GrowthPolicy growth_policy,
                                    bool is_locked);
  HeapPage* AllocatePage(HeapPage::PageType type);
  void FreePage(HeapPage* page, HeapPage* previous_page);
  HeapPage* AllocateLargePage(intptr_t size, HeapPage::PageType type);
  void TruncateLargePage(HeapPage* page, intptr_t new_object_size_in_bytes);
  void FreeLargePage(HeapPage* page, HeapPage* previous_page);
  void FreePages(HeapPage* pages);
  HeapPage* NextPageAnySize(HeapPage* page) const {
    ASSERT((pages_tail_ == NULL) || (pages_tail_->next() == NULL));
    ASSERT((exec_pages_tail_ == NULL) || (exec_pages_tail_->next() == NULL));
    if (page == pages_tail_) {
      return (exec_pages_ != NULL) ? exec_pages_ : large_pages_;
    }
    return page == exec_pages_tail_ ? large_pages_ : page->next();
  }

  static intptr_t LargePageSizeInWordsFor(intptr_t size);

  bool CanIncreaseCapacityInWords(intptr_t increase_in_words) {
    ASSERT(CapacityInWords() <= max_capacity_in_words_);
    return increase_in_words <= (max_capacity_in_words_ - CapacityInWords());
  }

  FreeList freelist_[HeapPage::kNumPageTypes];

  Heap* heap_;

  Mutex* pages_lock_;
  HeapPage* pages_;
  HeapPage* pages_tail_;
  HeapPage* exec_pages_;
  HeapPage* exec_pages_tail_;
  HeapPage* large_pages_;

  // A block of memory in a data page, managed by bump allocation. The remainder
  // is kept formatted as a FreeListElement, but is not in any freelist.
  uword bump_top_;
  uword bump_end_;

  // Various sizes being tracked for this generation.
  intptr_t max_capacity_in_words_;
  SpaceUsage usage_;

  // Keep track of running MarkSweep tasks.
  Monitor* tasks_lock_;
  intptr_t tasks_;

  PageSpaceController page_space_controller_;

  int64_t gc_time_micros_;
  intptr_t collections_;

  friend class PageSpaceController;
  friend class SweeperTask;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpace);
};

}  // namespace dart

#endif  // VM_PAGES_H_
