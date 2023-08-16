// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_PAGES_H_
#define RUNTIME_VM_HEAP_PAGES_H_

#include "platform/atomic.h"
#include "vm/globals.h"
#include "vm/heap/freelist.h"
#include "vm/heap/page.h"
#include "vm/heap/spaces.h"
#include "vm/lockers.h"
#include "vm/ring_buffer.h"
#include "vm/thread.h"
#include "vm/virtual_memory.h"

namespace dart {

DECLARE_FLAG(bool, write_protect_code);

// Forward declarations.
class Heap;
class JSONObject;
class ObjectPointerVisitor;
class ObjectSet;
class ForwardingPage;
class GCMarker;

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
  static constexpr intptr_t kHistoryLength = 4;
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
  bool ReachedHardThreshold(SpaceUsage after) const;
  bool ReachedSoftThreshold(SpaceUsage after) const;

  // Returns whether an idle GC is worthwhile.
  bool ReachedIdleThreshold(SpaceUsage current) const;

  // Should be called after each collection to update the controller state.
  void EvaluateGarbageCollection(SpaceUsage before,
                                 SpaceUsage after,
                                 int64_t start,
                                 int64_t end);
  void EvaluateAfterLoading(SpaceUsage after);

  void set_last_usage(SpaceUsage current) { last_usage_ = current; }

 private:
  friend class PageSpace;  // For MergeOtherPageSpaceController

  void RecordUpdate(SpaceUsage before, SpaceUsage after, const char* reason);
  void RecordUpdate(SpaceUsage before,
                    SpaceUsage after,
                    intptr_t growth_in_pages,
                    const char* reason);

  Heap* heap_;

  // Usage after last evaluated GC or last enabled.
  SpaceUsage last_usage_;

  // If the garbage collector was not able to free more than heap_growth_ratio_
  // memory, then the heap is grown. Otherwise garbage collection is performed.
  const int heap_growth_ratio_;

  // The desired percent of heap in-use after a garbage collection.
  // Equivalent to \frac{100-heap_growth_ratio_}{100}.
  const double desired_utilization_;

  // Max number of pages we grow.
  const int heap_growth_max_;

  // If the relative GC time goes above garbage_collection_time_ratio_ %,
  // we grow the heap more aggressively.
  const int garbage_collection_time_ratio_;

  // Perform a stop-the-world GC when usage exceeds this amount.
  intptr_t hard_gc_threshold_in_words_;

  // Begin concurrent marking when usage exceeds this amount.
  intptr_t soft_gc_threshold_in_words_;

  // Run idle GC if time permits when usage exceeds this amount.
  intptr_t idle_gc_threshold_in_words_;

  PageSpaceGarbageCollectionHistory history_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpaceController);
};

class PageSpace {
 public:
  enum GrowthPolicy { kControlGrowth, kForceGrowth };
  enum Phase {
    kDone,
    kMarking,
    kAwaitingFinalization,
    kSweepingLarge,
    kSweepingRegular
  };

  PageSpace(Heap* heap, intptr_t max_capacity_in_words);
  ~PageSpace();

  uword TryAllocate(intptr_t size,
                    bool is_executable = false,
                    GrowthPolicy growth_policy = kControlGrowth) {
    bool is_protected = (is_executable) && FLAG_write_protect_code;
    bool is_locked = false;
    return TryAllocateInternal(
        size, &freelists_[is_executable ? kExecutableFreelist : kDataFreelist],
        is_executable, growth_policy, is_protected, is_locked);
  }
  DART_FORCE_INLINE
  uword TryAllocatePromoLocked(FreeList* freelist, intptr_t size) {
    if (LIKELY(IsAllocatableViaFreeLists(size))) {
      uword result;
      if (freelist->TryAllocateBumpLocked(size, &result)) {
        return result;
      }
    }
    return TryAllocatePromoLockedSlow(freelist, size);
  }
  DART_FORCE_INLINE
  uword AllocateSnapshotLocked(FreeList* freelist, intptr_t size) {
    if (LIKELY(IsAllocatableViaFreeLists(size))) {
      uword result;
      if (freelist->TryAllocateBumpLocked(size, &result)) {
        return result;
      }
    }
    return AllocateSnapshotLockedSlow(freelist, size);
  }

  void TryReleaseReservation();
  bool MarkReservation();
  void TryReserveForOOM();
  void VisitRoots(ObjectPointerVisitor* visitor);

  bool ReachedHardThreshold() const {
    return page_space_controller_.ReachedHardThreshold(usage_);
  }
  bool ReachedSoftThreshold() const {
    return page_space_controller_.ReachedSoftThreshold(usage_);
  }
  bool ReachedIdleThreshold() const {
    return page_space_controller_.ReachedIdleThreshold(usage_);
  }
  void EvaluateAfterLoading() {
    page_space_controller_.EvaluateAfterLoading(usage_);
  }

  intptr_t UsedInWords() const { return usage_.used_in_words; }
  intptr_t CapacityInWords() const {
    MutexLocker ml(&pages_lock_);
    return usage_.capacity_in_words;
  }
  void IncreaseCapacityInWords(intptr_t increase_in_words) {
    MutexLocker ml(&pages_lock_);
    IncreaseCapacityInWordsLocked(increase_in_words);
  }
  void IncreaseCapacityInWordsLocked(intptr_t increase_in_words) {
    DEBUG_ASSERT(pages_lock_.IsOwnedByCurrentThread());
    usage_.capacity_in_words += increase_in_words;
    UpdateMaxCapacityLocked();
  }

  void UpdateMaxCapacityLocked();
  void UpdateMaxUsed();

  int64_t ExternalInWords() const { return usage_.external_in_words; }
  SpaceUsage GetCurrentUsage() const {
    MutexLocker ml(&pages_lock_);
    return usage_;
  }
  int64_t ImageInWords() const {
    int64_t size = 0;
    MutexLocker ml(&pages_lock_);
    for (Page* page = image_pages_; page != nullptr; page = page->next()) {
      size += page->memory_->size();
    }
    return size >> kWordSizeLog2;
  }

  bool Contains(uword addr) const;
  bool ContainsUnsafe(uword addr) const;
  bool CodeContains(uword addr) const;
  bool DataContains(uword addr) const;
  bool IsValidAddress(uword addr) const { return Contains(addr); }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectsNoImagePages(ObjectVisitor* visitor) const;
  void VisitObjectsImagePages(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  void VisitRememberedCards(ObjectPointerVisitor* visitor) const;
  void ResetProgressBars() const;

  // Collect the garbage in the page space using mark-sweep or mark-compact.
  void CollectGarbage(Thread* thread, bool compact, bool finalize);

  void AddRegionsToObjectSet(ObjectSet* set) const;

  // Note: Code pages are made executable/non-executable when 'read_only' is
  // true/false, respectively.
  void WriteProtect(bool read_only);
  void WriteProtectCode(bool read_only);

  bool ShouldStartIdleMarkSweep(int64_t deadline);
  bool ShouldPerformIdleMarkCompact(int64_t deadline);
  void IncrementalMarkWithSizeBudget(intptr_t size);
  void IncrementalMarkWithTimeBudget(int64_t deadline);
  void AssistTasks(MonitorLocker* ml);

  void AddGCTime(int64_t micros) { gc_time_micros_ += micros; }

  int64_t gc_time_micros() const { return gc_time_micros_; }

  void IncrementCollections() { collections_++; }

  intptr_t collections() const { return collections_; }

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* object) const;
  void PrintHeapMapToJSONStream(IsolateGroup* isolate_group,
                                JSONStream* stream) const;
#endif  // PRODUCT

  void AllocateBlack(intptr_t size) {
    allocated_black_in_words_.fetch_add(size >> kWordSizeLog2);
  }

  // Tracks an external allocation by incrementing the old space's total
  // external size tracker. Returns false without incrementing the tracker if
  // this allocation will make it exceed kMaxAddrSpaceInWords.
  bool AllocatedExternal(intptr_t size) {
    ASSERT(size >= 0);
    intptr_t size_in_words = size >> kWordSizeLog2;
    intptr_t expected = usage_.external_in_words.load();
    intptr_t desired;
    do {
      desired = expected + size_in_words;
      if (desired < 0 || desired > kMaxAddrSpaceInWords) {
        return false;
      }
      ASSERT(desired >= 0);
    } while (
        !usage_.external_in_words.compare_exchange_weak(expected, desired));
    return true;
  }
  void FreedExternal(intptr_t size) {
    ASSERT(size >= 0);
    intptr_t size_in_words = size >> kWordSizeLog2;
    usage_.external_in_words -= size_in_words;
    ASSERT(usage_.external_in_words >= 0);
  }

  // Bulk data allocation.
  FreeList* DataFreeList(intptr_t i = 0) {
    return &freelists_[kDataFreelist + i];
  }
  void AcquireLock(FreeList* freelist);
  void ReleaseLock(FreeList* freelist);

  void PauseConcurrentMarking();
  void ResumeConcurrentMarking();
  void YieldConcurrentMarking();

  Monitor* tasks_lock() const { return &tasks_lock_; }
  intptr_t tasks() const { return tasks_; }
  void set_tasks(intptr_t val) {
    ASSERT(val >= 0);
    tasks_ = val;
  }
  intptr_t concurrent_marker_tasks() const {
    DEBUG_ASSERT(tasks_lock_.IsOwnedByCurrentThread());
    return concurrent_marker_tasks_;
  }
  void set_concurrent_marker_tasks(intptr_t val) {
    ASSERT(val >= 0);
    DEBUG_ASSERT(tasks_lock_.IsOwnedByCurrentThread());
    concurrent_marker_tasks_ = val;
  }
  intptr_t concurrent_marker_tasks_active() const {
    DEBUG_ASSERT(tasks_lock_.IsOwnedByCurrentThread());
    return concurrent_marker_tasks_active_;
  }
  void set_concurrent_marker_tasks_active(intptr_t val) {
    ASSERT(val >= 0);
    DEBUG_ASSERT(tasks_lock_.IsOwnedByCurrentThread());
    concurrent_marker_tasks_active_ = val;
  }
  bool pause_concurrent_marking() const { return pause_concurrent_marking_; }
  Phase phase() const { return phase_; }
  void set_phase(Phase val) { phase_ = val; }

  void SetupImagePage(void* pointer, uword size, bool is_executable);

  // Return any bump allocation block to the freelist.
  void AbandonBumpAllocation();
  // Have threads release marking stack blocks, etc.
  void AbandonMarkingForShutdown();

  bool enable_concurrent_mark() const { return enable_concurrent_mark_; }
  void set_enable_concurrent_mark(bool enable_concurrent_mark) {
    enable_concurrent_mark_ = enable_concurrent_mark;
  }

  bool IsObjectFromImagePages(ObjectPtr object);

 private:
  // Ids for time and data records in Heap::GCStats.
  enum {
    // Time
    kConcurrentSweep = 0,
    kSafePoint = 1,
    kMarkObjects = 2,
    kResetFreeLists = 3,
    kSweepPages = 4,
    kSweepLargePages = 5,
  };

  uword TryAllocateDataLocked(FreeList* freelist,
                              intptr_t size,
                              GrowthPolicy growth_policy) {
    bool is_executable = false;
    bool is_protected = false;
    bool is_locked = true;
    return TryAllocateInternal(size, freelist, is_executable, growth_policy,
                               is_protected, is_locked);
  }
  uword TryAllocateInternal(intptr_t size,
                            FreeList* freelist,
                            bool is_executable,
                            GrowthPolicy growth_policy,
                            bool is_protected,
                            bool is_locked);
  uword TryAllocateInFreshPage(intptr_t size,
                               FreeList* freelist,
                               bool is_executable,
                               GrowthPolicy growth_policy,
                               bool is_locked);
  uword TryAllocateInFreshLargePage(intptr_t size,
                                    bool is_executable,
                                    GrowthPolicy growth_policy);

  // Attempt to allocate from bump block rather than normal freelist.
  uword TryAllocateDataBumpLocked(FreeList* freelist, intptr_t size);
  uword TryAllocatePromoLockedSlow(FreeList* freelist, intptr_t size);
  uword AllocateSnapshotLockedSlow(FreeList* freelist, intptr_t size);

  // Makes bump block walkable; do not call concurrently with mutator.
  void MakeIterable() const;

  void AddPageLocked(Page* page);
  void AddLargePageLocked(Page* page);
  void AddExecPageLocked(Page* page);
  void RemovePageLocked(Page* page, Page* previous_page);
  void RemoveLargePageLocked(Page* page, Page* previous_page);
  void RemoveExecPageLocked(Page* page, Page* previous_page);

  Page* AllocatePage(bool is_executable, bool link = true);
  Page* AllocateLargePage(intptr_t size, bool is_executable);

  void TruncateLargePage(Page* page, intptr_t new_object_size_in_bytes);
  void FreePage(Page* page, Page* previous_page);
  void FreeLargePage(Page* page, Page* previous_page);
  void FreePages(Page* pages);

  void CollectGarbageHelper(Thread* thread, bool compact, bool finalize);
  void SweepLarge();
  void Sweep(bool exclusive);
  void ConcurrentSweep(IsolateGroup* isolate_group);
  void Compact(Thread* thread);

  static intptr_t LargePageSizeInWordsFor(intptr_t size);

  bool CanIncreaseCapacityInWordsLocked(intptr_t increase_in_words) {
    if (max_capacity_in_words_ == 0) {
      // Unlimited.
      return true;
    }
    intptr_t free_capacity_in_words =
        (max_capacity_in_words_ - usage_.capacity_in_words);
    return ((free_capacity_in_words > 0) &&
            (increase_in_words <= free_capacity_in_words));
  }

  Heap* const heap_;

  // One list for executable pages at freelists_[kExecutableFreelist].
  // FLAG_scavenger_tasks count of lists for data pages starting at
  // freelists_[kDataFreelist]. The sweeper inserts into the data page
  // freelists round-robin. The scavenger workers each use one of the data
  // page freelists without locking.
  const intptr_t num_freelists_;
  enum {
    kExecutableFreelist = 0,
    kDataFreelist = 1,
  };
  FreeList* freelists_;
  static constexpr intptr_t kOOMReservationSize = 32 * KB;
  FreeListElement* oom_reservation_ = nullptr;

  // Use ExclusivePageIterator for safe access to these.
  mutable Mutex pages_lock_;
  Page* pages_ = nullptr;
  Page* pages_tail_ = nullptr;
  Page* exec_pages_ = nullptr;
  Page* exec_pages_tail_ = nullptr;
  Page* large_pages_ = nullptr;
  Page* large_pages_tail_ = nullptr;
  Page* image_pages_ = nullptr;
  Page* sweep_regular_ = nullptr;
  Page* sweep_large_ = nullptr;

  // Various sizes being tracked for this generation.
  intptr_t max_capacity_in_words_;

  // NOTE: The capacity component of usage_ is updated by the concurrent
  // sweeper. Use (Increase)CapacityInWords(Locked) for thread-safe access.
  SpaceUsage usage_;
  RelaxedAtomic<intptr_t> allocated_black_in_words_;

  // Keep track of running MarkSweep tasks.
  mutable Monitor tasks_lock_;
  intptr_t tasks_;
  intptr_t concurrent_marker_tasks_;
  intptr_t concurrent_marker_tasks_active_;
  RelaxedAtomic<bool> pause_concurrent_marking_;
  Phase phase_;

#if defined(DEBUG)
  Thread* iterating_thread_;
#endif
  PageSpaceController page_space_controller_;
  GCMarker* marker_;

  int64_t gc_time_micros_;
  intptr_t collections_;
  intptr_t mark_words_per_micro_;

  bool enable_concurrent_mark_;

  friend class BasePageIterator;
  friend class ExclusivePageIterator;
  friend class ExclusiveCodePageIterator;
  friend class ExclusiveLargePageIterator;
  friend class HeapIterationScope;
  friend class HeapSnapshotWriter;
  friend class PageSpaceController;
  friend class ConcurrentSweeperTask;
  friend class GCCompactor;
  friend class CompactorTask;

  DISALLOW_IMPLICIT_CONSTRUCTORS(PageSpace);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_PAGES_H_
