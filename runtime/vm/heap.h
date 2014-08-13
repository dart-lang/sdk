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
#include "vm/weak_table.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectPointerVisitor;
class ObjectSet;
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

  // Default allocation sizes in MB for the old gen and code heaps.
  static const intptr_t kHeapSizeInMWords = 128;
  static const intptr_t kHeapSizeInMB = kHeapSizeInMWords * kWordSize;
  static const intptr_t kCodeHeapSizeInMB = 18;

  ~Heap();

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
      default:
        UNREACHABLE();
    }
    return 0;
  }

  uword TryAllocate(
      intptr_t size,
      Space space,
      PageSpace::GrowthPolicy growth_policy = PageSpace::kControlGrowth) {
    ASSERT(!read_only_);
    switch (space) {
      case kNew:
        return new_space_->TryAllocate(size);
      case kOld:
        return old_space_->TryAllocate(size,
                                       HeapPage::kData,
                                       growth_policy);
      case kCode:
        return old_space_->TryAllocate(size,
                                       HeapPage::kExecutable,
                                       growth_policy);
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

  // Visit all pointers.
  void IteratePointers(ObjectPointerVisitor* visitor) const;

  // Visit all pointers in the space.
  void IterateNewPointers(ObjectPointerVisitor* visitor) const;
  void IterateOldPointers(ObjectPointerVisitor* visitor) const;

  // Visit all objects.
  void IterateObjects(ObjectVisitor* visitor) const;

  // Visit all object in the space.
  void IterateNewObjects(ObjectVisitor* visitor) const;
  void IterateOldObjects(ObjectVisitor* visitor) const;

  // Find an object by visiting all pointers in the specified heap space,
  // the 'visitor' is used to determine if an object is found or not.
  // The 'visitor' function should be set up to return true if the
  // object is found, traversal through the heap space stops at that
  // point.
  // The 'visitor' function should return false if the object is not found,
  // traversal through the heap space continues.
  // Returns null object if nothing is found. Must be called within a NoGCScope.
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
    old_space_->WriteProtectCode(read_only);
  }

  // Accessors for inlined allocation in generated code.
  uword TopAddress();
  uword EndAddress();
  static intptr_t new_space_offset() { return OFFSET_OF(Heap, new_space_); }
  uword NewSpaceAddress() const { return reinterpret_cast<uword>(new_space_); }

  // Initialize the heap and register it with the isolate.
  static void Init(Isolate* isolate,
                   intptr_t max_new_gen_words,
                   intptr_t max_old_gen_words);

  // Verify that all pointers in the heap point to the heap.
  bool Verify() const;

  // Print heap sizes.
  void PrintSizes() const;

  // Return amount of memory used and capacity in a space, excluding external.
  intptr_t UsedInWords(Space space) const;
  intptr_t CapacityInWords(Space space) const;
  intptr_t ExternalInWords(Space space) const;
  // Return the amount of GCing in microseconds.
  int64_t GCTimeInMicros(Space space) const;

  intptr_t Collections(Space space) const;

  ObjectSet* CreateAllocatedObjectSet() const;

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
  void PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream) const {
    return old_space_->PrintHeapMapToJSONStream(isolate, stream);
  }

  Isolate* isolate() const { return isolate_; }

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
       intptr_t max_old_gen_words);

  uword AllocateNew(intptr_t size);
  uword AllocateOld(intptr_t size, HeapPage::PageType type);

  // GC stats collection.
  void RecordBeforeGC(Space space, GCReason reason);
  void RecordAfterGC();
  void PrintStats();
  void UpdateClassHeapStatsBeforeGC(Heap::Space space);

  // If this heap is non-empty, updates start and end to the smallest range that
  // contains both the original [start, end) and the [lowest, highest) addresses
  // of this heap.
  void GetMergedAddressRange(uword* start, uword* end) const;

  Isolate* isolate_;

  // The different spaces used for allocation.
  Scavenger* new_space_;
  PageSpace* old_space_;

  WeakTable* new_weak_tables_[kNumWeakSelectors];
  WeakTable* old_weak_tables_[kNumWeakSelectors];

  // GC stats collection.
  GCStats stats_;

  // This heap is in read-only mode: No allocation is allowed.
  bool read_only_;

  // GC on the heap is in progress.
  bool gc_in_progress_;

  friend class GCEvent;
  friend class GCTestHelper;
  DISALLOW_COPY_AND_ASSIGN(Heap);
};


class GCEvent {
 public:
  explicit GCEvent(const Heap::GCStats& stats)
      : stats_(stats) {}
  void PrintJSON(JSONStream* js) const;
 private:
  const Heap::GCStats& stats_;
};


#if defined(DEBUG)
class NoGCScope : public StackResource {
 public:
  NoGCScope();
  ~NoGCScope();
 private:
  DISALLOW_COPY_AND_ASSIGN(NoGCScope);
};
#else  // defined(DEBUG)
class NoGCScope : public ValueObject {
 public:
  NoGCScope() {}
 private:
  DISALLOW_COPY_AND_ASSIGN(NoGCScope);
};
#endif  // defined(DEBUG)


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
