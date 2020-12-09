// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_PAGES_H_
#define RUNTIME_VM_HEAP_PAGES_H_

#include "platform/atomic.h"
#include "vm/globals.h"
#include "vm/heap/freelist.h"
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

static constexpr intptr_t kOldPageSize = 512 * KB;
static constexpr intptr_t kOldPageSizeInWords = kOldPageSize / kWordSize;
static constexpr intptr_t kOldPageMask = ~(kOldPageSize - 1);

static constexpr intptr_t kBitVectorWordsPerBlock = 1;
static constexpr intptr_t kBlockSize =
    kObjectAlignment * kBitsPerWord * kBitVectorWordsPerBlock;
static constexpr intptr_t kBlockMask = ~(kBlockSize - 1);
static constexpr intptr_t kBlocksPerPage = kOldPageSize / kBlockSize;

// A page containing old generation objects.
class OldPage {
 public:
  enum PageType { kExecutable = 0, kData };

  OldPage* next() const { return next_; }
  void set_next(OldPage* next) { next_ = next; }

  bool Contains(uword addr) const { return memory_->Contains(addr); }
  intptr_t AliasOffset() const { return memory_->AliasOffset(); }

  uword object_start() const { return memory_->start() + ObjectStartOffset(); }
  uword object_end() const { return object_end_; }
  uword used_in_bytes() const { return used_in_bytes_; }
  void set_used_in_bytes(uword value) {
    ASSERT(Utils::IsAligned(value, kObjectAlignment));
    used_in_bytes_ = value;
  }

  ForwardingPage* forwarding_page() const { return forwarding_page_; }
  void AllocateForwardingPage();

  PageType type() const { return type_; }

  bool is_image_page() const { return !memory_->vm_owns_region(); }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  ObjectPtr FindObject(FindObjectVisitor* visitor) const;

  void WriteProtect(bool read_only);

  static intptr_t ObjectStartOffset() {
    return Utils::RoundUp(sizeof(OldPage), kMaxObjectAlignment);
  }

  // Warning: This does not work for objects on image pages because image pages
  // are not aligned. However, it works for objects on large pages, because
  // only one object is allocated per large page.
  static OldPage* Of(ObjectPtr obj) {
    ASSERT(obj->IsHeapObject());
    ASSERT(obj->IsOldObject());
    return reinterpret_cast<OldPage*>(static_cast<uword>(obj) & kOldPageMask);
  }

  // Warning: This does not work for addresses on image pages or on large pages.
  static OldPage* Of(uword addr) {
    return reinterpret_cast<OldPage*>(addr & kOldPageMask);
  }

  // Warning: This does not work for objects on image pages.
  static ObjectPtr ToExecutable(ObjectPtr obj) {
    OldPage* page = Of(obj);
    VirtualMemory* memory = page->memory_;
    const intptr_t alias_offset = memory->AliasOffset();
    if (alias_offset == 0) {
      return obj;  // Not aliased.
    }
    uword addr = ObjectLayout::ToAddr(obj);
    if (memory->Contains(addr)) {
      return ObjectLayout::FromAddr(addr + alias_offset);
    }
    // obj is executable.
    ASSERT(memory->ContainsAlias(addr));
    return obj;
  }

  // Warning: This does not work for objects on image pages.
  static ObjectPtr ToWritable(ObjectPtr obj) {
    OldPage* page = Of(obj);
    VirtualMemory* memory = page->memory_;
    const intptr_t alias_offset = memory->AliasOffset();
    if (alias_offset == 0) {
      return obj;  // Not aliased.
    }
    uword addr = ObjectLayout::ToAddr(obj);
    if (memory->ContainsAlias(addr)) {
      return ObjectLayout::FromAddr(addr - alias_offset);
    }
    // obj is writable.
    ASSERT(memory->Contains(addr));
    return obj;
  }

  // 1 card = 128 slots.
  static const intptr_t kSlotsPerCardLog2 = 7;
  static const intptr_t kBytesPerCardLog2 = kWordSizeLog2 + kSlotsPerCardLog2;

  intptr_t card_table_size() const {
    return memory_->size() >> kBytesPerCardLog2;
  }

  static intptr_t card_table_offset() {
    return OFFSET_OF(OldPage, card_table_);
  }

  void RememberCard(ObjectPtr const* slot) {
    ASSERT(Contains(reinterpret_cast<uword>(slot)));
    if (card_table_ == NULL) {
      card_table_ = reinterpret_cast<uint8_t*>(
          calloc(card_table_size(), sizeof(uint8_t)));
    }
    intptr_t offset =
        reinterpret_cast<uword>(slot) - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    card_table_[index] = 1;
  }
  void VisitRememberedCards(ObjectPointerVisitor* visitor);

 private:
  void set_object_end(uword value) {
    ASSERT((value & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
    object_end_ = value;
  }

  // Returns NULL on OOM.
  static OldPage* Allocate(intptr_t size_in_words,
                           PageType type,
                           const char* name);

  // Deallocate the virtual memory backing this page. The page pointer to this
  // page becomes immediately inaccessible.
  void Deallocate();

  VirtualMemory* memory_;
  OldPage* next_;
  uword object_end_;
  uword used_in_bytes_;
  ForwardingPage* forwarding_page_;
  uint8_t* card_table_;  // Remembered set, not marking.
  PageType type_;

  friend class PageSpace;
  friend class GCCompactor;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(OldPage);
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
  void HintFreed(intptr_t size);

  void set_last_usage(SpaceUsage current) { last_usage_ = current; }

  void Enable() { is_enabled_ = true; }
  void Disable() { is_enabled_ = false; }
  bool is_enabled() { return is_enabled_; }

 private:
  friend class PageSpace;  // For MergeOtherPageSpaceController

  void RecordUpdate(SpaceUsage before, SpaceUsage after, const char* reason);
  void RecordUpdate(SpaceUsage before,
                    SpaceUsage after,
                    intptr_t growth_in_pages,
                    const char* reason);

  Heap* heap_;

  bool is_enabled_;

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
                    OldPage::PageType type = OldPage::kData,
                    GrowthPolicy growth_policy = kControlGrowth) {
    bool is_protected =
        (type == OldPage::kExecutable) && FLAG_write_protect_code;
    bool is_locked = false;
    return TryAllocateInternal(size, &freelists_[type], type, growth_policy,
                               is_protected, is_locked);
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
  void HintFreed(intptr_t size) { page_space_controller_.HintFreed(size); }

  int64_t UsedInWords() const { return usage_.used_in_words; }
  int64_t CapacityInWords() const {
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
    for (OldPage* page = image_pages_; page != nullptr; page = page->next()) {
      size += page->memory_->size();
    }
    return size >> kWordSizeLog2;
  }

  bool Contains(uword addr) const;
  bool ContainsUnsafe(uword addr) const;
  bool Contains(uword addr, OldPage::PageType type) const;
  bool DataContains(uword addr) const;
  bool IsValidAddress(uword addr) const { return Contains(addr); }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectsNoImagePages(ObjectVisitor* visitor) const;
  void VisitObjectsImagePages(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  void VisitRememberedCards(ObjectPointerVisitor* visitor) const;

  ObjectPtr FindObject(FindObjectVisitor* visitor,
                       OldPage::PageType type) const;

  // Collect the garbage in the page space using mark-sweep or mark-compact.
  void CollectGarbage(bool compact, bool finalize);

  void AddRegionsToObjectSet(ObjectSet* set) const;

  void InitGrowthControl() {
    page_space_controller_.set_last_usage(usage_);
    page_space_controller_.Enable();
  }

  void SetGrowthControlState(bool state) {
    if (state) {
      page_space_controller_.Enable();
    } else {
      page_space_controller_.Disable();
    }
  }

  bool GrowthControlState() { return page_space_controller_.is_enabled(); }

  // Note: Code pages are made executable/non-executable when 'read_only' is
  // true/false, respectively.
  void WriteProtect(bool read_only);
  void WriteProtectCode(bool read_only);

  bool ShouldStartIdleMarkSweep(int64_t deadline);
  bool ShouldPerformIdleMarkCompact(int64_t deadline);

  void AddGCTime(int64_t micros) { gc_time_micros_ += micros; }

  int64_t gc_time_micros() const { return gc_time_micros_; }

  void IncrementCollections() { collections_++; }

  intptr_t collections() const { return collections_; }

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* object) const;
  void PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream) const;
#endif  // PRODUCT

  void AllocateBlack(intptr_t size) {
    allocated_black_in_words_.fetch_add(size >> kWordSizeLog2);
  }

  void AllocatedExternal(intptr_t size) {
    ASSERT(size >= 0);
    intptr_t size_in_words = size >> kWordSizeLog2;
    usage_.external_in_words += size_in_words;
  }
  void FreedExternal(intptr_t size) {
    ASSERT(size >= 0);
    intptr_t size_in_words = size >> kWordSizeLog2;
    usage_.external_in_words -= size_in_words;
  }

  // Bulk data allocation.
  FreeList* DataFreeList(intptr_t i = 0) {
    return &freelists_[OldPage::kData + i];
  }
  void AcquireLock(FreeList* freelist);
  void ReleaseLock(FreeList* freelist);

  uword TryAllocateDataLocked(FreeList* freelist,
                              intptr_t size,
                              GrowthPolicy growth_policy) {
    bool is_protected = false;
    bool is_locked = true;
    return TryAllocateInternal(size, freelist, OldPage::kData, growth_policy,
                               is_protected, is_locked);
  }

  Monitor* tasks_lock() const { return &tasks_lock_; }
  intptr_t tasks() const { return tasks_; }
  void set_tasks(intptr_t val) {
    ASSERT(val >= 0);
    tasks_ = val;
  }
  intptr_t concurrent_marker_tasks() const { return concurrent_marker_tasks_; }
  void set_concurrent_marker_tasks(intptr_t val) {
    ASSERT(val >= 0);
    concurrent_marker_tasks_ = val;
  }
  Phase phase() const { return phase_; }
  void set_phase(Phase val) { phase_ = val; }

  // Attempt to allocate from bump block rather than normal freelist.
  uword TryAllocateDataBumpLocked(intptr_t size) {
    return TryAllocateDataBumpLocked(&freelists_[OldPage::kData], size);
  }
  uword TryAllocateDataBumpLocked(FreeList* freelist, intptr_t size);
  DART_FORCE_INLINE
  uword TryAllocatePromoLocked(FreeList* freelist, intptr_t size) {
    uword result = freelist->TryAllocateBumpLocked(size);
    if (result != 0) {
      return result;
    }
    return TryAllocatePromoLockedSlow(freelist, size);
  }
  uword TryAllocatePromoLockedSlow(FreeList* freelist, intptr_t size);

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
    // Data
    kGarbageRatio = 0,
    kGCTimeFraction = 1,
    kPageGrowth = 2,
    kAllowedGrowth = 3
  };

  uword TryAllocateInternal(intptr_t size,
                            FreeList* freelist,
                            OldPage::PageType type,
                            GrowthPolicy growth_policy,
                            bool is_protected,
                            bool is_locked);
  uword TryAllocateInFreshPage(intptr_t size,
                               FreeList* freelist,
                               OldPage::PageType type,
                               GrowthPolicy growth_policy,
                               bool is_locked);
  uword TryAllocateInFreshLargePage(intptr_t size,
                                    OldPage::PageType type,
                                    GrowthPolicy growth_policy);

  void EvaluateConcurrentMarking(GrowthPolicy growth_policy);

  // Makes bump block walkable; do not call concurrently with mutator.
  void MakeIterable() const;

  void AddPageLocked(OldPage* page);
  void AddLargePageLocked(OldPage* page);
  void AddExecPageLocked(OldPage* page);
  void RemovePageLocked(OldPage* page, OldPage* previous_page);
  void RemoveLargePageLocked(OldPage* page, OldPage* previous_page);
  void RemoveExecPageLocked(OldPage* page, OldPage* previous_page);

  OldPage* AllocatePage(OldPage::PageType type, bool link = true);
  OldPage* AllocateLargePage(intptr_t size, OldPage::PageType type);

  void TruncateLargePage(OldPage* page, intptr_t new_object_size_in_bytes);
  void FreePage(OldPage* page, OldPage* previous_page);
  void FreeLargePage(OldPage* page, OldPage* previous_page);
  void FreePages(OldPage* pages);

  void CollectGarbageHelper(bool compact,
                            bool finalize,
                            int64_t pre_wait_for_sweepers,
                            int64_t pre_safe_point);
  void SweepLarge();
  void Sweep();
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

  // One list for executable pages at freelists_[OldPage::kExecutable].
  // FLAG_scavenger_tasks count of lists for data pages starting at
  // freelists_[OldPage::kData]. The sweeper inserts into the data page
  // freelists round-robin. The scavenger workers each use one of the data
  // page freelists without locking.
  const intptr_t num_freelists_;
  FreeList* freelists_;
  static constexpr intptr_t kOOMReservationSize = 32 * KB;
  FreeListElement* oom_reservation_ = nullptr;

  // Use ExclusivePageIterator for safe access to these.
  mutable Mutex pages_lock_;
  OldPage* pages_ = nullptr;
  OldPage* pages_tail_ = nullptr;
  OldPage* exec_pages_ = nullptr;
  OldPage* exec_pages_tail_ = nullptr;
  OldPage* large_pages_ = nullptr;
  OldPage* large_pages_tail_ = nullptr;
  OldPage* image_pages_ = nullptr;

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
