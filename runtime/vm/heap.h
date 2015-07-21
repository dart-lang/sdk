// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HEAP_H_
#define VM_HEAP_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/pages.h"
#include "vm/scavenger.h"
#include "vm/spaces.h"
#include "vm/verifier.h"
#include "vm/weak_table.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;
class ObjectSet;
class ServiceEvent;
class VirtualMemory;

DECLARE_FLAG(bool, verbose_gc);
DECLARE_FLAG(bool, verify_before_gc);
DECLARE_FLAG(bool, verify_after_gc);
DECLARE_FLAG(bool, gc_at_alloc);

class Heap {
 public:
  enum Space {
    kNew,
    kOld,
    kCode,
    // TODO(koda): Harmonize all old-space allocation and get rid of this.
    kPretenured,
  };

  enum WeakSelector {
    kPeers = 0,
    kHashes,
    kNumWeakSelectors
  };

  enum ApiCallbacks {
    kIgnoreApiCallbacks,
    kInvokeApiCallbacks
  };

  enum GCReason {
    kNewSpace,
    kPromotion,
    kOldSpace,
    kFull,
    kGCAtAlloc,
    kGCTestCase,
  };

#if defined(DEBUG)
  // Pattern for unused new space and swept old space.
  static const uint64_t kZap64Bits = 0xf3f3f3f3f3f3f3f3;
  static const uint32_t kZap32Bits = 0xf3f3f3f3;
  static const uint8_t kZapByte = 0xf3;
#endif  // DEBUG

  ~Heap();

  Scavenger* new_space() { return &new_space_; }
  PageSpace* old_space() { return &old_space_; }

  uword Allocate(intptr_t size, Space space) {
    ASSERT(!read_only_);
    switch (space) {
      case kNew:
        // Do not attempt to allocate very large objects in new space.
        if (!IsAllocatableInNewSpace(size)) {
          return AllocateOld(size, HeapPage::kData);
        }
        return AllocateNew(size);
      case kOld:
        return AllocateOld(size, HeapPage::kData);
      case kCode:
        return AllocateOld(size, HeapPage::kExecutable);
      case kPretenured:
        return AllocatePretenured(size);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  // Track external data.
  void AllocateExternal(intptr_t size, Space space);
  void FreeExternal(intptr_t size, Space space);
  // Move external size from new to old space. Does not by itself trigger GC.
  void PromoteExternal(intptr_t size);

  // Heap contains the specified address.
  bool Contains(uword addr) const;
  bool NewContains(uword addr) const;
  bool OldContains(uword addr) const;
  bool CodeContains(uword addr) const;
  bool StubCodeContains(uword addr) const;

  void IterateObjects(ObjectVisitor* visitor) const;
  void IterateOldObjects(ObjectVisitor* visitor) const;
  void IterateObjectPointers(ObjectVisitor* visitor) const;

  // Find an object by visiting all pointers in the specified heap space,
  // the 'visitor' is used to determine if an object is found or not.
  // The 'visitor' function should be set up to return true if the
  // object is found, traversal through the heap space stops at that
  // point.
  // The 'visitor' function should return false if the object is not found,
  // traversal through the heap space continues.
  // Returns null object if nothing is found.
  RawInstructions* FindObjectInCodeSpace(FindObjectVisitor* visitor) const;
  RawObject* FindOldObject(FindObjectVisitor* visitor) const;
  RawObject* FindNewObject(FindObjectVisitor* visitor) const;
  RawObject* FindObject(FindObjectVisitor* visitor) const;

  void CollectGarbage(Space space);
  void CollectGarbage(Space space, ApiCallbacks api_callbacks, GCReason reason);
  void CollectAllGarbage();

  // Enables growth control on the page space heaps.  This should be
  // called before any user code is executed.
  void EnableGrowthControl() { SetGrowthControlState(true); }
  void DisableGrowthControl() { SetGrowthControlState(false); }
  void SetGrowthControlState(bool state);
  bool GrowthControlState();

  // Protect access to the heap.
  void WriteProtect(bool read_only);
  void WriteProtectCode(bool read_only) {
    old_space_.WriteProtectCode(read_only);
  }

  // Accessors for inlined allocation in generated code.
  uword TopAddress(Space space);
  static intptr_t TopOffset(Space space);
  uword EndAddress(Space space);
  static intptr_t EndOffset(Space space);
  static Space SpaceForAllocation(intptr_t class_id);

  // Initialize the heap and register it with the isolate.
  static void Init(Isolate* isolate,
                   intptr_t max_new_gen_words,
                   intptr_t max_old_gen_words,
                   intptr_t max_external_words);

  // Verify that all pointers in the heap point to the heap.
  bool Verify(MarkExpectation mark_expectation = kForbidMarked) const;

  // Print heap sizes.
  void PrintSizes() const;

  // Return amount of memory used and capacity in a space, excluding external.
  intptr_t UsedInWords(Space space) const;
  intptr_t CapacityInWords(Space space) const;
  intptr_t ExternalInWords(Space space) const;
  // Return the amount of GCing in microseconds.
  int64_t GCTimeInMicros(Space space) const;

  intptr_t Collections(Space space) const;

  ObjectSet* CreateAllocatedObjectSet(MarkExpectation mark_expectation) const;

  static const char* GCReasonToString(GCReason gc_reason);

  // Associate a peer with an object.  A non-existent peer is equal to NULL.
  void SetPeer(RawObject* raw_obj, void* peer) {
    SetWeakEntry(raw_obj, kPeers, reinterpret_cast<intptr_t>(peer));
  }
  void* GetPeer(RawObject* raw_obj) const {
    return reinterpret_cast<void*>(GetWeakEntry(raw_obj, kPeers));
  }
  int64_t PeerCount() const;

  // Associate an identity hashCode with an object. An non-existent hashCode
  // is equal to 0.
  void SetHash(RawObject* raw_obj, intptr_t hash) {
    SetWeakEntry(raw_obj, kHashes, hash);
  }
  intptr_t GetHash(RawObject* raw_obj) const {
    return GetWeakEntry(raw_obj, kHashes);
  }
  int64_t HashCount() const;

  // Used by the GC algorithms to propagate weak entries.
  intptr_t GetWeakEntry(RawObject* raw_obj, WeakSelector sel) const;
  void SetWeakEntry(RawObject* raw_obj, WeakSelector sel, intptr_t val);

  WeakTable* GetWeakTable(Space space, WeakSelector selector) const {
    if (space == kNew) {
      return new_weak_tables_[selector];
    }
    ASSERT(space ==kOld);
    return old_weak_tables_[selector];
  }
  void SetWeakTable(Space space, WeakSelector selector, WeakTable* value) {
    if (space == kNew) {
      new_weak_tables_[selector] = value;
    } else {
      ASSERT(space == kOld);
      old_weak_tables_[selector] = value;
    }
  }

  // Stats collection.
  void RecordTime(int id, int64_t micros) {
    ASSERT((id >= 0) && (id < GCStats::kDataEntries));
    stats_.times_[id] = micros;
  }

  void RecordData(int id, intptr_t value) {
    ASSERT((id >= 0) && (id < GCStats::kDataEntries));
    stats_.data_[id] = value;
  }

  bool gc_in_progress() const { return gc_in_progress_; }

  static bool IsAllocatableInNewSpace(intptr_t size) {
    return size <= kNewAllocatableSize;
  }

  void PrintToJSONObject(Space space, JSONObject* object) const;

  // The heap map contains the sizes and class ids for the objects in each page.
  void PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream) {
    return old_space_.PrintHeapMapToJSONStream(isolate, stream);
  }

  Isolate* isolate() const { return isolate_; }

  bool ShouldPretenure(intptr_t class_id) const;

 private:
  class GCStats : public ValueObject {
   public:
    GCStats() {}
    intptr_t num_;
    Heap::Space space_;
    Heap::GCReason reason_;

    class Data : public ValueObject {
     public:
      Data() {}
      int64_t micros_;
      SpaceUsage new_;
      SpaceUsage old_;
     private:
      DISALLOW_COPY_AND_ASSIGN(Data);
    };

    enum {
      kDataEntries = 4
    };

    Data before_;
    Data after_;
    int64_t times_[kDataEntries];
    intptr_t data_[kDataEntries];

   private:
    DISALLOW_COPY_AND_ASSIGN(GCStats);
  };

  static const intptr_t kNewAllocatableSize = 256 * KB;

  Heap(Isolate* isolate,
       intptr_t max_new_gen_semi_words,  // Max capacity of new semi-space.
       intptr_t max_old_gen_words,
       intptr_t max_external_words);

  uword AllocateNew(intptr_t size);
  uword AllocateOld(intptr_t size, HeapPage::PageType type);
  uword AllocatePretenured(intptr_t size);

  // Visit all pointers. Caller must ensure concurrent sweeper is not running,
  // and the visitor must not allocate.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  // Visit all objects, including FreeListElement "objects". Caller must ensure
  // concurrent sweeper is not running, and the visitor must not allocate.
  void VisitObjects(ObjectVisitor* visitor) const;

  // Like Verify, but does not wait for concurrent sweeper, so caller must
  // ensure thread-safety.
  bool VerifyGC(MarkExpectation mark_expectation = kForbidMarked) const;

  // GC stats collection.
  void RecordBeforeGC(Space space, GCReason reason);
  void RecordAfterGC();
  void PrintStats();
  void UpdateClassHeapStatsBeforeGC(Heap::Space space);
  void UpdatePretenurePolicy();

  // If this heap is non-empty, updates start and end to the smallest range that
  // contains both the original [start, end) and the [lowest, highest) addresses
  // of this heap.
  void GetMergedAddressRange(uword* start, uword* end) const;

  Isolate* isolate_;

  // The different spaces used for allocation.
  Scavenger new_space_;
  PageSpace old_space_;

  WeakTable* new_weak_tables_[kNumWeakSelectors];
  WeakTable* old_weak_tables_[kNumWeakSelectors];

  // GC stats collection.
  GCStats stats_;

  // This heap is in read-only mode: No allocation is allowed.
  bool read_only_;

  // GC on the heap is in progress.
  bool gc_in_progress_;

  int pretenure_policy_;

  friend class ServiceEvent;
  friend class PageSpace;  // VerifyGC
  DISALLOW_COPY_AND_ASSIGN(Heap);
};


// Within a NoSafepointScope, the thread must not reach any safepoint. Used
// around code that manipulates raw object pointers directly without handles.
#if defined(DEBUG)
class NoSafepointScope : public StackResource {
 public:
  NoSafepointScope();
  ~NoSafepointScope();
 private:
  DISALLOW_COPY_AND_ASSIGN(NoSafepointScope);
};
#else  // defined(DEBUG)
class NoSafepointScope : public ValueObject {
 public:
  NoSafepointScope() {}
 private:
  DISALLOW_COPY_AND_ASSIGN(NoSafepointScope);
};
#endif  // defined(DEBUG)


class HeapIterationScope : public StackResource {
 public:
  HeapIterationScope();
  ~HeapIterationScope();
 private:
  NoSafepointScope no_safepoint_scope_;
  PageSpace* old_space_;

  DISALLOW_COPY_AND_ASSIGN(HeapIterationScope);
};


class NoHeapGrowthControlScope : public StackResource {
 public:
  NoHeapGrowthControlScope();
  ~NoHeapGrowthControlScope();
 private:
  bool current_growth_controller_state_;
  DISALLOW_COPY_AND_ASSIGN(NoHeapGrowthControlScope);
};

}  // namespace dart

#endif  // VM_HEAP_H_
