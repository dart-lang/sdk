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
#include "vm/heap/page.h"
#include "vm/heap/spaces.h"
#include "vm/isolate.h"
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

class SemiSpace {
 public:
  explicit SemiSpace(intptr_t gc_threshold_in_words);
  ~SemiSpace();

  Page* TryAllocatePageLocked(bool link);

  bool Contains(uword addr) const;
  void WriteProtect(bool read_only);

  intptr_t used_in_words() const {
    intptr_t size = 0;
    for (const Page* p = head_; p != nullptr; p = p->next()) {
      size += p->used();
    }
    return size >> kWordSizeLog2;
  }
  intptr_t capacity_in_words() const { return capacity_in_words_; }
  intptr_t gc_threshold_in_words() const { return gc_threshold_in_words_; }

  Page* head() const { return head_; }

  void AddList(Page* head, Page* tail);

 private:
  // Size of Pages in this semi-space.
  intptr_t capacity_in_words_ = 0;

  // Size of Pages before we trigger a scavenge. Compare old-space's
  // hard_gc_threshold_in_words_.
  intptr_t gc_threshold_in_words_;

  Page* head_ = nullptr;
  Page* tail_ = nullptr;
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
  // garbage to give the scavenger a chance to stabilize at the new capacity.
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
  static constexpr intptr_t kTLABSize = 512 * KB;

 public:
  Scavenger(Heap* heap, intptr_t max_semi_capacity_in_words);
  ~Scavenger();

  // Check whether this Scavenger contains this address.
  // During scavenging both the to and from spaces contain "legal" objects.
  // During a scavenge this function only returns true for addresses that will
  // be part of the surviving objects.
  bool Contains(uword addr) const { return to_->Contains(addr); }

  uword TryAllocate(Thread* thread, intptr_t size) {
    uword addr = TryAllocateFromTLAB(thread, size);
    if (LIKELY(addr != 0)) {
      return addr;
    }
    TryAllocateNewTLAB(thread, size, true);
    return TryAllocateFromTLAB(thread, size);
  }
  uword TryAllocateNoSafepoint(Thread* thread, intptr_t size) {
    uword addr = TryAllocateFromTLAB(thread, size);
    if (LIKELY(addr != 0)) {
      return addr;
    }
    TryAllocateNewTLAB(thread, size, false);
    return TryAllocateFromTLAB(thread, size);
  }
  intptr_t AbandonRemainingTLAB(Thread* thread);
  void AbandonRemainingTLABForDebugging(Thread* thread);

  // Collect the garbage in this scavenger.
  void Scavenge(Thread* thread, GCType type, GCReason reason);

  intptr_t UsedInWords() const {
    MutexLocker ml(&space_lock_);
    return to_->used_in_words();
  }
  intptr_t CapacityInWords() const {
    MutexLocker ml(&space_lock_);
    return to_->capacity_in_words();
  }
  intptr_t ExternalInWords() const { return external_size_ >> kWordSizeLog2; }
  SpaceUsage GetCurrentUsage() const {
    SpaceUsage usage;
    usage.used_in_words = UsedInWords();
    usage.capacity_in_words = CapacityInWords();
    usage.external_in_words = ExternalInWords();
    return usage;
  }
  intptr_t ThresholdInWords() const { return to_->gc_threshold_in_words(); }

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

  // Tracks an external allocation by incrementing the new space's total
  // external size tracker. Returns false without incrementing the tracker if
  // this allocation will make it exceed kMaxAddrSpaceInWords.
  bool AllocatedExternal(intptr_t size) {
    ASSERT(size >= 0);
    intptr_t expected = external_size_.load();
    intptr_t desired;
    do {
      intptr_t next_external_size_in_words =
          (external_size_ >> kWordSizeLog2) + (size >> kWordSizeLog2);
      if (next_external_size_in_words < 0 ||
          next_external_size_in_words > kMaxAddrSpaceInWords) {
        return false;
      }
      desired = expected + size;
      ASSERT(desired >= 0);
    } while (!external_size_.compare_exchange_weak(expected, desired));
    return true;
  }
  void FreedExternal(intptr_t size) {
    ASSERT(size >= 0);
    external_size_ -= size;
    ASSERT(external_size_ >= 0);
  }

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

  Page* head() const {
    return to_->head();
  }

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
  };

  uword TryAllocateFromTLAB(Thread* thread, intptr_t size) {
    ASSERT(Utils::IsAligned(size, kObjectAlignment));
    ASSERT(heap_ != Dart::vm_isolate_group()->heap());

    const uword result = thread->top();
    const intptr_t remaining = static_cast<intptr_t>(thread->end()) - result;
    ASSERT(remaining >= 0);
    if (UNLIKELY(remaining < size)) {
      return 0;
    }
    ASSERT(to_->Contains(result));
    ASSERT((result & kObjectAlignmentMask) == kNewObjectAlignmentOffset);
    thread->set_top(result + size);
    return result;
  }
  void TryAllocateNewTLAB(Thread* thread, intptr_t size, bool can_safepoint);

  SemiSpace* Prologue(GCReason reason);
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
  void IterateWeak();
  void MournWeakHandles();
  void MournWeakTables();
  void Epilogue(SemiSpace* from);

  void VerifyStoreBuffers(const char* msg);

  void UpdateMaxHeapCapacity();
  void UpdateMaxHeapUsage();

  intptr_t NewSizeInWords(intptr_t old_size_in_words, GCReason reason) const;

  Heap* heap_;

  SemiSpace* to_;

  PromotionStack promotion_stack_;

  intptr_t max_semi_capacity_in_words_;

  // Keep track whether a scavenge is currently running.
  bool scavenging_;
  bool early_tenure_ = false;
  RelaxedAtomic<intptr_t> root_slices_started_;
  RelaxedAtomic<intptr_t> weak_slices_started_;
  StoreBufferBlock* blocks_ = nullptr;

  int64_t gc_time_micros_;
  intptr_t collections_;
  static constexpr int kStatsHistoryCapacity = 4;
  RingBuffer<ScavengeStats, kStatsHistoryCapacity> stats_history_;

  intptr_t scavenge_words_per_micro_;
  intptr_t idle_scavenge_threshold_in_words_;

  // The total size of external data associated with objects in this scavenger.
  RelaxedAtomic<intptr_t> external_size_;

  RelaxedAtomic<bool> failed_to_promote_;
  RelaxedAtomic<bool> abort_;

  // Protects new space during the allocation of new TLABs
  mutable Mutex space_lock_;

  template <bool>
  friend class ScavengerVisitorBase;

  DISALLOW_COPY_AND_ASSIGN(Scavenger);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_SCAVENGER_H_
