// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_SCAVENGER_H_
#define RUNTIME_VM_HEAP_SCAVENGER_H_

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/heap/spaces.h"
#include "vm/lockers.h"
#include "vm/raw_object.h"
#include "vm/ring_buffer.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class Heap;
class Isolate;
class JSONObject;
class ObjectSet;
template <bool parallel>
class ScavengerVisitorBase;

static constexpr intptr_t kNewPageSize = 512 * KB;
static constexpr intptr_t kNewPageSizeInWords = kNewPageSize / kWordSize;
static constexpr intptr_t kNewPageMask = ~(kNewPageSize - 1);

// A page containing new generation objects.
class NewPage {
 public:
  static NewPage* Allocate();
  void Deallocate();

  uword start() const { return memory_->start(); }
  uword end() const { return memory_->end(); }
  bool Contains(uword addr) const { return memory_->Contains(addr); }
  void WriteProtect(bool read_only) {
    memory_->Protect(read_only ? VirtualMemory::kReadOnly
                               : VirtualMemory::kReadWrite);
  }

  NewPage* next() const { return next_; }
  void set_next(NewPage* next) { next_ = next; }

  Thread* owner() const { return owner_; }

  uword object_start() const { return start() + ObjectStartOffset(); }
  uword object_end() const { return owner_ != nullptr ? owner_->top() : top_; }
  void VisitObjects(ObjectVisitor* visitor) const {
    uword addr = object_start();
    uword end = object_end();
    while (addr < end) {
      ObjectPtr obj = ObjectLayout::FromAddr(addr);
      visitor->VisitObject(obj);
      addr += obj->ptr()->HeapSize();
    }
  }
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const {
    uword addr = object_start();
    uword end = object_end();
    while (addr < end) {
      ObjectPtr obj = ObjectLayout::FromAddr(addr);
      intptr_t size = obj->ptr()->VisitPointers(visitor);
      addr += size;
    }
  }

  static intptr_t ObjectStartOffset() {
    return Utils::RoundUp(sizeof(NewPage), kObjectAlignment) +
           kNewObjectAlignmentOffset;
  }

  static NewPage* Of(ObjectPtr obj) {
    ASSERT(obj->IsHeapObject());
    ASSERT(obj->IsNewObject());
    return Of(static_cast<uword>(obj));
  }
  static NewPage* Of(uword addr) {
    return reinterpret_cast<NewPage*>(addr & kNewPageMask);
  }

  // Remember the limit to which objects have been copied.
  void RecordSurvivors() { survivor_end_ = object_end(); }

  // Move survivor end to the end of the to_ space, making all surviving
  // objects candidates for promotion next time.
  void EarlyTenure() { survivor_end_ = end_; }

  uword promo_candidate_words() const {
    return (survivor_end_ - object_start()) / kWordSize;
  }

  void Acquire(Thread* thread) {
    ASSERT(owner_ == nullptr);
    owner_ = thread;
    thread->set_top(top_);
    thread->set_end(end_);
  }
  void Release(Thread* thread) {
    ASSERT(owner_ == thread);
    owner_ = nullptr;
    top_ = thread->top();
    thread->set_top(0);
    thread->set_end(0);
  }
  void Release() {
    if (owner_ != nullptr) {
      Release(owner_);
    }
  }

  uword TryAllocateGC(intptr_t size) {
    ASSERT(owner_ == nullptr);
    uword result = top_;
    uword new_top = result + size;
    if (LIKELY(new_top < end_)) {
      top_ = new_top;
      return result;
    }
    return 0;
  }

  void Unallocate(uword addr, intptr_t size) {
    ASSERT((addr + size) == top_);
    top_ -= size;
  }

  bool IsSurvivor(uword raw_addr) const { return raw_addr < survivor_end_; }
  bool IsResolved() const { return top_ == resolved_top_; }

 private:
  VirtualMemory* memory_;
  NewPage* next_;

  // The thread using this page for allocation, otherwise NULL.
  Thread* owner_;

  // The address of the next allocation. If owner is non-NULL, this value is
  // stale and the current value is at owner->top_. Called "NEXT" in the
  // original Cheney paper.
  uword top_;

  // The address after the last allocatable byte in this page.
  uword end_;

  // Objects below this address have survived a scavenge.
  uword survivor_end_;

  // A pointer to the first unprocessed object. Resolution completes when this
  // value meets the allocation top. Called "SCAN" in the original Cheney paper.
  uword resolved_top_;

  template <bool>
  friend class ScavengerVisitorBase;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(NewPage);
};

class SemiSpace {
 public:
  static void Init();
  static void Cleanup();
  static intptr_t CachedSize();

  explicit SemiSpace(intptr_t max_capacity_in_words);
  ~SemiSpace();

  NewPage* TryAllocatePageLocked(bool link);

  bool Contains(uword addr) const;
  void WriteProtect(bool read_only);

  intptr_t capacity_in_words() const { return capacity_in_words_; }
  intptr_t max_capacity_in_words() const { return max_capacity_in_words_; }

  NewPage* head() const { return head_; }

  void AddList(NewPage* head, NewPage* tail);

 private:
  // Size of NewPages in this semi-space.
  intptr_t capacity_in_words_ = 0;

  // Size of NewPages before we trigger a scavenge.
  intptr_t max_capacity_in_words_;

  NewPage* head_ = nullptr;
  NewPage* tail_ = nullptr;
};

// Statistics for a particular scavenge.
class ScavengeStats {
 public:
  ScavengeStats() {}
  ScavengeStats(int64_t start_micros,
                int64_t end_micros,
                SpaceUsage before,
                SpaceUsage after,
                intptr_t promo_candidates_in_words,
                intptr_t promoted_in_words,
                intptr_t abandoned_in_words)
      : start_micros_(start_micros),
        end_micros_(end_micros),
        before_(before),
        after_(after),
        promo_candidates_in_words_(promo_candidates_in_words),
        promoted_in_words_(promoted_in_words),
        abandoned_in_words_(abandoned_in_words) {}

  // Of all data before scavenge, what fraction was found to be garbage?
  // If this scavenge included growth, assume the extra capacity would become
  // garbage to give the scavenger a chance to stablize at the new capacity.
  double ExpectedGarbageFraction() const {
    double work =
        after_.used_in_words + promoted_in_words_ + abandoned_in_words_;
    return 1.0 - (work / after_.capacity_in_words);
  }

  // Fraction of promotion candidates that survived and was thereby promoted.
  // Returns zero if there were no promotion candidates.
  double PromoCandidatesSuccessFraction() const {
    return promo_candidates_in_words_ > 0
               ? promoted_in_words_ /
                     static_cast<double>(promo_candidates_in_words_)
               : 0.0;
  }

  intptr_t UsedBeforeInWords() const { return before_.used_in_words; }

  int64_t DurationMicros() const { return end_micros_ - start_micros_; }

 private:
  int64_t start_micros_;
  int64_t end_micros_;
  SpaceUsage before_;
  SpaceUsage after_;
  intptr_t promo_candidates_in_words_;
  intptr_t promoted_in_words_;
  intptr_t abandoned_in_words_;
};

class Scavenger {
 private:
  static const intptr_t kTLABSize = 512 * KB;

 public:
  Scavenger(Heap* heap, intptr_t max_semi_capacity_in_words);
  ~Scavenger();

  // Check whether this Scavenger contains this address.
  // During scavenging both the to and from spaces contain "legal" objects.
  // During a scavenge this function only returns true for addresses that will
  // be part of the surviving objects.
  bool Contains(uword addr) const { return to_->Contains(addr); }

  ObjectPtr FindObject(FindObjectVisitor* visitor);

  uword TryAllocate(Thread* thread, intptr_t size) {
    uword addr = TryAllocateFromTLAB(thread, size);
    if (LIKELY(addr != 0)) {
      return addr;
    }
    TryAllocateNewTLAB(thread, size);
    return TryAllocateFromTLAB(thread, size);
  }
  void AbandonRemainingTLAB(Thread* thread);
  void AbandonRemainingTLABForDebugging(Thread* thread);

  // Collect the garbage in this scavenger.
  void Scavenge();

  // Promote all live objects.
  void Evacuate();

  int64_t UsedInWords() const {
    MutexLocker ml(&space_lock_);
    return to_->capacity_in_words();
  }
  int64_t CapacityInWords() const { return to_->max_capacity_in_words(); }
  int64_t ExternalInWords() const { return external_size_ >> kWordSizeLog2; }
  SpaceUsage GetCurrentUsage() const {
    SpaceUsage usage;
    usage.used_in_words = UsedInWords();
    usage.capacity_in_words = CapacityInWords();
    usage.external_in_words = ExternalInWords();
    return usage;
  }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  void AddRegionsToObjectSet(ObjectSet* set) const;

  void WriteProtect(bool read_only);

  bool ShouldPerformIdleScavenge(int64_t deadline);

  void AddGCTime(int64_t micros) { gc_time_micros_ += micros; }

  int64_t gc_time_micros() const { return gc_time_micros_; }

  void IncrementCollections() { collections_++; }

  intptr_t collections() const { return collections_; }

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* object) const;
#endif  // !PRODUCT

  void AllocatedExternal(intptr_t size) {
    ASSERT(size >= 0);
    external_size_ += size;
    ASSERT(external_size_ >= 0);
  }
  void FreedExternal(intptr_t size) {
    ASSERT(size >= 0);
    external_size_ -= size;
    ASSERT(external_size_ >= 0);
  }

  void MakeNewSpaceIterable();
  int64_t FreeSpaceInWords(Isolate* isolate) const;

  void InitGrowthControl() {
    growth_control_ = true;
  }

  void SetGrowthControlState(bool state) {
    growth_control_ = state;
  }

  bool GrowthControlState() { return growth_control_; }

  bool scavenging() const { return scavenging_; }

  // The maximum number of Dart mutator threads we allow to execute at the same
  // time.
  static intptr_t MaxMutatorThreadCount() {
    // With a max new-space of 16 MB and 512kb TLABs we would allow up to 8
    // mutator threads to run at the same time.
    const intptr_t max_parallel_tlab_usage =
        (FLAG_new_gen_semi_max_size * MB) / Scavenger::kTLABSize;
    const intptr_t max_pool_size = max_parallel_tlab_usage / 4;
    return max_pool_size > 0 ? max_pool_size : 1;
  }

  NewPage* head() const { return to_->head(); }

 private:
  // Ids for time and data records in Heap::GCStats.
  enum {
    // Time
    kDummyScavengeTime = 0,
    kSafePoint = 1,
    kVisitIsolateRoots = 2,
    kIterateStoreBuffers = 3,
    kProcessToSpace = 4,
    kIterateWeaks = 5,
    // Data
    kStoreBufferEntries = 0,
    kDataUnused1 = 1,
    kDataUnused2 = 2,
    kToKBAfterStoreBuffer = 3
  };

  uword TryAllocateFromTLAB(Thread* thread, intptr_t size) {
    ASSERT(Utils::IsAligned(size, kObjectAlignment));
    ASSERT(heap_ != Dart::vm_isolate()->heap());

    const uword result = thread->top();
    const intptr_t remaining = thread->end() - result;
    if (UNLIKELY(remaining < size)) {
      return 0;
    }

    ASSERT(to_->Contains(result));
    ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
    thread->set_top(result + size);
    return result;
  }
  void TryAllocateNewTLAB(Thread* thread, intptr_t size);

  SemiSpace* Prologue();
  intptr_t ParallelScavenge(SemiSpace* from);
  intptr_t SerialScavenge(SemiSpace* from);
  void ReverseScavenge(SemiSpace** from);
  void IterateIsolateRoots(ObjectPointerVisitor* visitor);
  template <bool parallel>
  void IterateStoreBuffers(ScavengerVisitorBase<parallel>* visitor);
  template <bool parallel>
  void IterateRememberedCards(ScavengerVisitorBase<parallel>* visitor);
  void IterateObjectIdTable(ObjectPointerVisitor* visitor);
  template <bool parallel>
  void IterateRoots(ScavengerVisitorBase<parallel>* visitor);
  void MournWeakHandles();
  void Epilogue(SemiSpace* from);

  bool IsUnreachable(ObjectPtr* p);

  void VerifyStoreBuffers();

  void UpdateMaxHeapCapacity();
  void UpdateMaxHeapUsage();

  void MournWeakTables();

  intptr_t NewSizeInWords(intptr_t old_size_in_words) const;

  Heap* heap_;

  SemiSpace* to_;

  PromotionStack promotion_stack_;

  intptr_t max_semi_capacity_in_words_;

  // Keep track whether a scavenge is currently running.
  bool scavenging_;
  bool early_tenure_ = false;
  RelaxedAtomic<intptr_t> root_slices_started_;
  StoreBufferBlock* blocks_ = nullptr;

  int64_t gc_time_micros_;
  intptr_t collections_;
  static const int kStatsHistoryCapacity = 4;
  RingBuffer<ScavengeStats, kStatsHistoryCapacity> stats_history_;

  intptr_t scavenge_words_per_micro_;
  intptr_t idle_scavenge_threshold_in_words_;

  // The total size of external data associated with objects in this scavenger.
  RelaxedAtomic<intptr_t> external_size_;

  RelaxedAtomic<bool> failed_to_promote_;
  RelaxedAtomic<bool> abort_;

  bool growth_control_;

  // Protects new space during the allocation of new TLABs
  mutable Mutex space_lock_;

  template <bool>
  friend class ScavengerVisitorBase;
  friend class ScavengerWeakVisitor;

  DISALLOW_COPY_AND_ASSIGN(Scavenger);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_SCAVENGER_H_
