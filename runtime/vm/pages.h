// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PAGES_H_
#define VM_PAGES_H_

#include "vm/freelist.h"
#include "vm/globals.h"
#include "vm/virtual_memory.h"

namespace dart {

DECLARE_FLAG(bool, collect_code);
DECLARE_FLAG(bool, log_code_drop);
DECLARE_FLAG(bool, always_drop_code);

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
  PageSpaceGarbageCollectionHistory();
  ~PageSpaceGarbageCollectionHistory() {}

  void AddGarbageCollectionTime(int64_t start, int64_t end);

  int GarbageCollectionTimeFraction();

 private:
  static const intptr_t kHistoryLength = 4;
  int64_t start_[kHistoryLength];
  int64_t end_[kHistoryLength];
  intptr_t index_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(PageSpaceGarbageCollectionHistory);
};


// If GC is able to reclaim more than heap_growth_ratio (in percent) memory
// and if the relative GC time is below a given threshold,
// then the heap is not grown when the next GC decision is made.
// PageSpaceController controls the heap size.
class PageSpaceController {
 public:
  PageSpaceController(int heap_growth_ratio,
                      int heap_growth_rate,
                      int garbage_collection_time_ratio);
  ~PageSpaceController();

  bool CanGrowPageSpace(intptr_t size_in_bytes);

  // A garbage collection is considered as successful if more than
  // heap_growth_ratio % of memory got deallocated by the garbage collector.
  // In this case garbage collection will be performed next time. Otherwise
  // the heap will grow.
  void EvaluateGarbageCollection(intptr_t used_before_in_words,
                                 intptr_t used_after_in_words,
                                 int64_t start, int64_t end);

  int64_t last_code_collection_in_us() { return last_code_collection_in_us_; }
  void set_last_code_collection_in_us(int64_t t) {
    last_code_collection_in_us_ = t;
  }

  void set_is_enabled(bool state) {
    is_enabled_ = state;
  }
  bool is_enabled() {
    return is_enabled_;
  }

 private:
  bool is_enabled_;

  // Heap growth control variable.
  intptr_t grow_heap_;

  // If the garbage collector was not able to free more than heap_growth_ratio_
  // memory, then the heap is grown. Otherwise garbage collection is performed.
  int heap_growth_ratio_;

  // The desired percent of heap in-use after a garbage collection.
  // Equivalent to \frac{100-heap_growth_ratio_}{100}.
  double desired_utilization_;

  // Number of pages we grow.
  int heap_growth_rate_;

  // If the relative GC time stays below garbage_collection_time_ratio_
  // garbage collection can be performed.
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
                    GrowthPolicy growth_policy = kControlGrowth);

  intptr_t UsedInWords() const { return used_in_words_; }
  intptr_t CapacityInWords() const { return capacity_in_words_; }

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
    page_space_controller_.set_is_enabled(state);
  }

  bool GrowthControlState() {
    return page_space_controller_.is_enabled();
  }

  void WriteProtect(bool read_only);

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

  HeapPage* AllocatePage(HeapPage::PageType type);
  void FreePage(HeapPage* page, HeapPage* previous_page);
  HeapPage* AllocateLargePage(intptr_t size, HeapPage::PageType type);
  void FreeLargePage(HeapPage* page, HeapPage* previous_page);
  void FreePages(HeapPage* pages);

  static intptr_t LargePageSizeInWordsFor(intptr_t size);

  bool CanIncreaseCapacityInWords(intptr_t increase_in_words) {
    ASSERT(capacity_in_words_ <= max_capacity_in_words_);
    return increase_in_words <= (max_capacity_in_words_ - capacity_in_words_);
  }

  FreeList freelist_[HeapPage::kNumPageTypes];

  Heap* heap_;

  HeapPage* pages_;
  HeapPage* pages_tail_;
  HeapPage* large_pages_;

  // Various sizes being tracked for this generation.
  intptr_t max_capacity_in_words_;
  intptr_t capacity_in_words_;
  intptr_t used_in_words_;

  // Keep track whether a MarkSweep is currently running.
  bool sweeping_;

  PageSpaceController page_space_controller_;

  int64_t gc_time_micros_;
  intptr_t collections_;

  friend class PageSpaceController;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpace);
};

}  // namespace dart

#endif  // VM_PAGES_H_
