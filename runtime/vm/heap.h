// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_H_
#define RUNTIME_VM_HEAP_H_

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
class TimelineEventScope;
class VirtualMemory;

class Heap {
 public:
  enum Space {
    kNew,
    kOld,
    kCode,
  };

  enum WeakSelector { kPeers = 0, kHashes, kObjectIds, kNumWeakSelectors };

  enum ApiCallbacks { kIgnoreApiCallbacks, kInvokeApiCallbacks };

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

  void IterateObjects(ObjectVisitor* visitor) const;
  void IterateOldObjects(ObjectVisitor* visitor) const;
  void IterateOldObjectsNoEmbedderPages(ObjectVisitor* visitor) const;
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
  bool NeedsGarbageCollection() const {
    return old_space_.NeedsGarbageCollection();
  }

#if defined(DEBUG)
  void WaitForSweeperTasks();
#endif

  // Enables growth control on the page space heaps.  This should be
  // called before any user code is executed.
  void InitGrowthControl();
  void EnableGrowthControl() { SetGrowthControlState(true); }
  void DisableGrowthControl() { SetGrowthControlState(false); }
  void SetGrowthControlState(bool state);
  bool GrowthControlState();

  // Protect access to the heap. Note: Code pages are made
  // executable/non-executable when 'read_only' is true/false, respectively.
  void WriteProtect(bool read_only);
  void WriteProtectCode(bool read_only) {
    old_space_.WriteProtectCode(read_only);
  }

  // Accessors for inlined allocation in generated code.
  static intptr_t TopOffset(Space space);
  static intptr_t EndOffset(Space space);

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
  int64_t UsedInWords(Space space) const;
  int64_t CapacityInWords(Space space) const;
  int64_t ExternalInWords(Space space) const;
  // Return the amount of GCing in microseconds.
  int64_t GCTimeInMicros(Space space) const;

  intptr_t Collections(Space space) const;

  ObjectSet* CreateAllocatedObjectSet(Zone* zone,
                                      MarkExpectation mark_expectation) const;

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

  // Associate an id with an object (used when serializing an object).
  // A non-existant id is equal to 0.
  void SetObjectId(RawObject* raw_obj, intptr_t object_id) {
    ASSERT(Thread::Current()->IsMutatorThread());
    SetWeakEntry(raw_obj, kObjectIds, object_id);
  }
  intptr_t GetObjectId(RawObject* raw_obj) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    return GetWeakEntry(raw_obj, kObjectIds);
  }
  int64_t ObjectIdCount() const;
  void ResetObjectIdTable();

  // Used by the GC algorithms to propagate weak entries.
  intptr_t GetWeakEntry(RawObject* raw_obj, WeakSelector sel) const;
  void SetWeakEntry(RawObject* raw_obj, WeakSelector sel, intptr_t val);

  WeakTable* GetWeakTable(Space space, WeakSelector selector) const {
    if (space == kNew) {
      return new_weak_tables_[selector];
    }
    ASSERT(space == kOld);
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

  void UpdateGlobalMaxUsed();

  static bool IsAllocatableInNewSpace(intptr_t size) {
    return size <= kNewAllocatableSize;
  }

#ifndef PRODUCT
  void PrintToJSONObject(Space space, JSONObject* object) const;

  // The heap map contains the sizes and class ids for the objects in each page.
  void PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream) {
    old_space_.PrintHeapMapToJSONStream(isolate, stream);
  }
#endif  // PRODUCT

  Isolate* isolate() const { return isolate_; }

  Monitor* barrier() const { return barrier_; }
  Monitor* barrier_done() const { return barrier_done_; }

  void SetupExternalPage(void* pointer, uword size, bool is_executable) {
    old_space_.SetupExternalPage(pointer, size, is_executable);
  }

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

    enum { kDataEntries = 4 };

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

  // Visit all pointers. Caller must ensure concurrent sweeper is not running,
  // and the visitor must not allocate.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  // Visit all objects, including FreeListElement "objects". Caller must ensure
  // concurrent sweeper is not running, and the visitor must not allocate.
  void VisitObjects(ObjectVisitor* visitor) const;

  // Like Verify, but does not wait for concurrent sweeper, so caller must
  // ensure thread-safety.
  bool VerifyGC(MarkExpectation mark_expectation = kForbidMarked) const;

  // Helper functions for garbage collection.
  void CollectNewSpaceGarbage(Thread* thread,
                              ApiCallbacks api_callbacks,
                              GCReason reason);
  void CollectOldSpaceGarbage(Thread* thread,
                              ApiCallbacks api_callbacks,
                              GCReason reason);

  // GC stats collection.
  void RecordBeforeGC(Space space, GCReason reason);
  void RecordAfterGC(Space space);
  void PrintStats();
  void UpdateClassHeapStatsBeforeGC(Heap::Space space);
  void PrintStatsToTimeline(TimelineEventScope* event);

  // Updates gc in progress flags.
  bool BeginNewSpaceGC(Thread* thread);
  void EndNewSpaceGC();
  bool BeginOldSpaceGC(Thread* thread);
  void EndOldSpaceGC();

  void AddRegionsToObjectSet(ObjectSet* set) const;

  Isolate* isolate_;

  // The different spaces used for allocation.
  ALIGN8 Scavenger new_space_;
  PageSpace old_space_;

  WeakTable* new_weak_tables_[kNumWeakSelectors];
  WeakTable* old_weak_tables_[kNumWeakSelectors];

  Monitor* barrier_;
  Monitor* barrier_done_;

  // GC stats collection.
  GCStats stats_;

  // This heap is in read-only mode: No allocation is allowed.
  bool read_only_;

  // GC on the heap is in progress.
  Monitor gc_in_progress_monitor_;
  bool gc_new_space_in_progress_;
  bool gc_old_space_in_progress_;

  friend class Become;       // VisitObjectPointers
  friend class Precompiler;  // VisitObjects
  friend class ServiceEvent;
  friend class PageSpace;             // VerifyGC
  friend class IsolateReloadContext;  // VisitObjects

  DISALLOW_COPY_AND_ASSIGN(Heap);
};


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


// Note: During this scope, the code pages are non-executable.
class WritableVMIsolateScope : StackResource {
 public:
  explicit WritableVMIsolateScope(Thread* thread);
  ~WritableVMIsolateScope();
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_H_
