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
#include "vm/heap/tlab.h"
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

// Wrapper around VirtualMemory that adds caching and handles the empty case.
class SemiSpace {
 public:
  static void Init();
  static void Cleanup();

  // Get a space of the given size. Returns NULL on out of memory. If size is 0,
  // returns an empty space: pointer(), start() and end() all return NULL.
  // The name parameter may be NULL. If non-NULL it is ued to give the OS a name
  // for the underlying virtual memory region.
  static SemiSpace* New(intptr_t size_in_words, const char* name);

  // Hand back an unused space.
  void Delete();

  void* pointer() const { return region_.pointer(); }
  uword start() const { return region_.start(); }
  uword end() const { return region_.end(); }
  intptr_t size_in_words() const {
    return static_cast<intptr_t>(region_.size()) >> kWordSizeLog2;
  }
  bool Contains(uword address) const { return region_.Contains(address); }

  // Set write protection mode for this space. The space must not be protected
  // when Delete is called.
  // TODO(koda): Remember protection mode in VirtualMemory and assert this.
  void WriteProtect(bool read_only);

 private:
  explicit SemiSpace(VirtualMemory* reserved);
  ~SemiSpace();

  VirtualMemory* reserved_;  // NULL for an empty space.
  MemoryRegion region_;

  static SemiSpace* cache_;
  static Mutex* mutex_;
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
    TryAllocateNewTLAB(thread);
    return TryAllocateFromTLAB(thread, size);
  }
  void MakeTLABIterable(const TLAB& tlab);
  void AbandonRemainingTLABForDebugging(Thread* thread);
  template <bool parallel>
  bool TryAllocateNewTLAB(ScavengerVisitorBase<parallel>* visitor);

  // When a thread gets scheduled it will try to acquire a TLAB.
  void TryAcquireCachedTLAB(Thread* thread) {
    MutexLocker ml(&space_lock_);
    thread->set_tlab(TryAcquireCachedTLABLocked());
  }
  TLAB TryAcquireCachedTLABLocked();

  // When a thread gets unscheduled it will release it's TLAB.
  void ReleaseAndCacheTLAB(Thread* thread) {
    MutexLocker ml(&space_lock_);
    CacheTLABLocked(thread->tlab());
    thread->set_tlab(TLAB());
  }
  void CacheTLABLocked(TLAB tlab);

  // Collect the garbage in this scavenger.
  void Scavenge();

  // Promote all live objects.
  void Evacuate();

  // Report (TLAB) abandoned bytes that should be taken account when
  // deciding whether to grow new space or not.
  void AddAbandonedInBytes(intptr_t value) {
    MutexLocker ml(&space_lock_);
    AddAbandonedInBytesLocked(value);
  }
  int64_t GetAndResetAbandonedInBytes() {
    int64_t result = abandoned_;
    abandoned_ = 0;
    return result;
  }

  int64_t UsedInWords() const {
    MutexLocker ml(&space_lock_);
    return (top_ - FirstObjectStart()) >> kWordSizeLog2;
  }
  int64_t CapacityInWords() const { return to_->size_in_words(); }
  int64_t ExternalInWords() const { return external_size_ >> kWordSizeLog2; }
  SpaceUsage GetCurrentUsage() const {
    SpaceUsage usage;
    usage.used_in_words = UsedInWords();
    usage.capacity_in_words = CapacityInWords();
    usage.external_in_words = ExternalInWords();
    return usage;
  }

  void VisitObjects(ObjectVisitor* visitor);
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

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

  void AllocateExternal(intptr_t cid, intptr_t size);
  void FreeExternal(intptr_t size);

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

 private:
  static const intptr_t kTLABSize = 512 * KB;

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
    TLAB tlab = thread->tlab();
    const intptr_t remaining = tlab.RemainingSize();
    if (UNLIKELY(remaining < size)) {
      return 0;
    }

    const uword result = tlab.top;
    ASSERT(to_->Contains(result));
    ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
    const uword new_top = tlab.top + size;
    ASSERT(to_->Contains(new_top) || new_top == to_->end());
    thread->set_tlab(tlab.BumpAllocate(size));
    return result;
  }
  void TryAllocateNewTLAB(Thread* thread);
  void AddAbandonedInBytesLocked(intptr_t value) { abandoned_ += value; }
  void AbandonTLABsLocked();

  uword FirstObjectStart() const {
    return to_->start() + kNewObjectAlignmentOffset;
  }
  SemiSpace* Prologue();
  intptr_t ParallelScavenge(SemiSpace* from);
  intptr_t SerialScavenge(SemiSpace* from);
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

  uword top_;
  uword end_;

  MallocGrowableArray<TLAB> abandoned_tlabs_;
  MallocGrowableArray<TLAB> free_tlabs_;

  SemiSpace* to_;

  Heap* heap_;

  // A pointer to the first unscanned object.  Scanning completes when
  // this value meets the allocation top.
  uword resolved_top_;

  // Objects below this address have survived a scavenge.
  uword survivor_end_;

  // Abandoned (TLAB) bytes that need to be accounted for when deciding
  // whether to grow newspace or not.
  intptr_t abandoned_ = 0;

  PromotionStack promotion_stack_;

  intptr_t max_semi_capacity_in_words_;

  // Keep track whether a scavenge is currently running.
  bool scavenging_;
  RelaxedAtomic<intptr_t> root_slices_started_;
  StoreBufferBlock* blocks_;

  int64_t gc_time_micros_;
  intptr_t collections_;
  static const int kStatsHistoryCapacity = 4;
  RingBuffer<ScavengeStats, kStatsHistoryCapacity> stats_history_;

  intptr_t scavenge_words_per_micro_;
  intptr_t idle_scavenge_threshold_in_words_;

  // The total size of external data associated with objects in this scavenger.
  RelaxedAtomic<intptr_t> external_size_;

  bool failed_to_promote_;

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
