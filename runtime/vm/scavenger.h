// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SCAVENGER_H_
#define RUNTIME_VM_SCAVENGER_H_

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/raw_object.h"
#include "vm/ring_buffer.h"
#include "vm/spaces.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class Heap;
class Isolate;
class JSONObject;
class ObjectSet;
class ScavengerVisitor;

// Wrapper around VirtualMemory that adds caching and handles the empty case.
class SemiSpace {
 public:
  static void InitOnce();

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
                intptr_t promoted_in_words)
      : start_micros_(start_micros),
        end_micros_(end_micros),
        before_(before),
        after_(after),
        promo_candidates_in_words_(promo_candidates_in_words),
        promoted_in_words_(promoted_in_words) {}

  // Of all data before scavenge, what fraction was found to be garbage?
  // If this scavenge included growth, assume the extra capacity would become
  // garbage to give the scavenger a chance to stablize at the new capacity.
  double ExpectedGarbageFraction() const {
    intptr_t survived = after_.used_in_words + promoted_in_words_;
    return 1.0 - (survived / static_cast<double>(after_.capacity_in_words));
  }

  // Fraction of promotion candidates that survived and was thereby promoted.
  // Returns zero if there were no promotion candidates.
  double PromoCandidatesSuccessFraction() const {
    return promo_candidates_in_words_ > 0
               ? promoted_in_words_ /
                     static_cast<double>(promo_candidates_in_words_)
               : 0.0;
  }

  int64_t DurationMicros() const { return end_micros_ - start_micros_; }

 private:
  int64_t start_micros_;
  int64_t end_micros_;
  SpaceUsage before_;
  SpaceUsage after_;
  intptr_t promo_candidates_in_words_;
  intptr_t promoted_in_words_;
};

class Scavenger {
 public:
  Scavenger(Heap* heap,
            intptr_t max_semi_capacity_in_words,
            uword object_alignment);
  ~Scavenger();

  // Check whether this Scavenger contains this address.
  // During scavenging both the to and from spaces contain "legal" objects.
  // During a scavenge this function only returns true for addresses that will
  // be part of the surviving objects.
  bool Contains(uword addr) const { return to_->Contains(addr); }

  RawObject* FindObject(FindObjectVisitor* visitor) const;

  uword AllocateGC(intptr_t size) {
    ASSERT(Utils::IsAligned(size, kObjectAlignment));
    ASSERT(heap_ != Dart::vm_isolate()->heap());
    ASSERT(scavenging_);
    uword result = top_;
    intptr_t remaining = end_ - top_;

    // This allocation happens only in GC and only when copying objects to
    // the new to_ space. It must succeed.
    ASSERT(size <= remaining);
    ASSERT(to_->Contains(result));
    ASSERT((result & kObjectAlignmentMask) == object_alignment_);
    top_ += size;
    ASSERT(to_->Contains(top_) || (top_ == to_->end()));
    return result;
  }

  uword TryAllocateInTLAB(Thread* thread, intptr_t size) {
    ASSERT(Utils::IsAligned(size, kObjectAlignment));
    ASSERT(heap_ != Dart::vm_isolate()->heap());
    ASSERT(thread->IsMutatorThread());
    ASSERT(thread->isolate()->IsMutatorThreadScheduled());
#if defined(DEBUG)
    if (FLAG_gc_at_alloc) {
      ASSERT(!scavenging_);
      Scavenge();
    }
#endif
    uword top = thread->top();
    uword end = thread->end();
    uword result = top;
    intptr_t remaining = end - top;
    if (remaining < size) {
      return 0;
    }
    ASSERT(to_->Contains(result));
    ASSERT((result & kObjectAlignmentMask) == object_alignment_);
    top += size;
    ASSERT(to_->Contains(top) || (top == to_->end()));
    thread->set_top(top);
    return result;
  }

  // Collect the garbage in this scavenger.
  void Scavenge();

  // Promote all live objects.
  void Evacuate();

  uword top() { return top_; }
  uword end() { return end_; }

  void set_top(uword value) { top_ = value; }
  void set_end(uword value) {
    ASSERT(to_->end() == value);
    end_ = value;
  }

  int64_t UsedInWords() const {
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

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  void AddRegionsToObjectSet(ObjectSet* set) const;

  void WriteProtect(bool read_only);

  void AddGCTime(int64_t micros) { gc_time_micros_ += micros; }

  int64_t gc_time_micros() const { return gc_time_micros_; }

  void IncrementCollections() { collections_++; }

  intptr_t collections() const { return collections_; }

#ifndef PRODUCT
  void PrintToJSONObject(JSONObject* object) const;
#endif  // !PRODUCT

  void AllocateExternal(intptr_t size);
  void FreeExternal(intptr_t size);

  void FlushTLS() const;

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

  uword FirstObjectStart() const { return to_->start() | object_alignment_; }
  SemiSpace* Prologue(Isolate* isolate);
  void IterateStoreBuffers(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateObjectIdTable(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateRoots(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateWeakProperties(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateWeakReferences(Isolate* isolate, ScavengerVisitor* visitor);
  void IterateWeakRoots(Isolate* isolate, HandleVisitor* visitor);
  void ProcessToSpace(ScavengerVisitor* visitor);
  void EnqueueWeakProperty(RawWeakProperty* raw_weak);
  uword ProcessWeakProperty(RawWeakProperty* raw_weak,
                            ScavengerVisitor* visitor);
  void Epilogue(Isolate* isolate, SemiSpace* from);

  bool IsUnreachable(RawObject** p);

  // During a scavenge we need to remember the promoted objects.
  // This is implemented as a stack of objects at the end of the to space. As
  // object sizes are always greater than sizeof(uword) and promoted objects do
  // not consume space in the to space they leave enough room for this stack.
  void PushToPromotedStack(uword addr) {
    ASSERT(scavenging_);
    end_ -= sizeof(addr);
    ASSERT(end_ > top_);
    *reinterpret_cast<uword*>(end_) = addr;
  }
  uword PopFromPromotedStack() {
    ASSERT(scavenging_);
    uword result = *reinterpret_cast<uword*>(end_);
    end_ += sizeof(result);
    ASSERT(end_ <= to_->end());
    return result;
  }
  bool PromotedStackHasMore() const {
    ASSERT(scavenging_);
    return end_ < to_->end();
  }

  void UpdateMaxHeapCapacity();
  void UpdateMaxHeapUsage();

  void ProcessWeakReferences();

  intptr_t NewSizeInWords(intptr_t old_size_in_words) const;

  uword top_;
  uword end_;

  SemiSpace* to_;

  Heap* heap_;

  // A pointer to the first unscanned object.  Scanning completes when
  // this value meets the allocation top.
  uword resolved_top_;

  // Objects below this address have survived a scavenge.
  uword survivor_end_;

  intptr_t max_semi_capacity_in_words_;

  // All object are aligned to this value.
  uword object_alignment_;

  // Keep track whether a scavenge is currently running.
  bool scavenging_;

  // Keep track of pending weak properties discovered while scagenging.
  RawWeakProperty* delayed_weak_properties_;

  int64_t gc_time_micros_;
  intptr_t collections_;
  static const int kStatsHistoryCapacity = 2;
  RingBuffer<ScavengeStats, kStatsHistoryCapacity> stats_history_;

  // The total size of external data associated with objects in this scavenger.
  intptr_t external_size_;

  bool failed_to_promote_;

  friend class ScavengerVisitor;
  friend class ScavengerWeakVisitor;

  DISALLOW_COPY_AND_ASSIGN(Scavenger);
};

}  // namespace dart

#endif  // RUNTIME_VM_SCAVENGER_H_
