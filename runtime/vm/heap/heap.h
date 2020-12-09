// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_HEAP_H_
#define RUNTIME_VM_HEAP_HEAP_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include "include/dart_tools_api.h"

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/heap/pages.h"
#include "vm/heap/scavenger.h"
#include "vm/heap/spaces.h"
#include "vm/heap/weak_table.h"
#include "vm/isolate.h"

namespace dart {

// Forward declarations.
class Isolate;
class IsolateGroup;
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

  enum WeakSelector {
    kPeers = 0,
#if !defined(HASH_IN_OBJECT_HEADER)
    kIdentityHashes,
#endif
    kCanonicalHashes,
    kObjectIds,
    kLoadingUnits,
    kNumWeakSelectors
  };

  enum GCType {
    kScavenge,
    kMarkSweep,
    kMarkCompact,
  };

  enum GCReason {
    kNewSpace,     // New space is full.
    kPromotion,    // Old space limit crossed after a scavenge.
    kOldSpace,     // Old space limit crossed.
    kFinalize,     // Concurrent marking finished.
    kFull,         // Heap::CollectAllGarbage
    kExternal,     // Dart_NewFinalizableHandle Dart_NewWeakPersistentHandle
    kIdle,         // Dart_NotifyIdle
    kLowMemory,    // Dart_NotifyLowMemory
    kDebugging,    // service request, etc.
    kSendAndExit,  // SendPort.sendAndExit
  };

  // Pattern for unused new space and swept old space.
  static const uint8_t kZapByte = 0xf3;

  ~Heap();

  Scavenger* new_space() { return &new_space_; }
  PageSpace* old_space() { return &old_space_; }

  uword Allocate(intptr_t size, Space space) {
    ASSERT(!read_only_);
    switch (space) {
      case kNew:
        // Do not attempt to allocate very large objects in new space.
        if (!IsAllocatableInNewSpace(size)) {
          return AllocateOld(size, OldPage::kData);
        }
        return AllocateNew(size);
      case kOld:
        return AllocateOld(size, OldPage::kData);
      case kCode:
        return AllocateOld(size, OldPage::kExecutable);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  // Track external data.
  void AllocatedExternal(intptr_t size, Space space);
  void FreedExternal(intptr_t size, Space space);
  // Move external size from new to old space. Does not by itself trigger GC.
  void PromotedExternal(intptr_t size);

  // Heap contains the specified address.
  bool Contains(uword addr) const;
  bool NewContains(uword addr) const;
  bool OldContains(uword addr) const;
  bool CodeContains(uword addr) const;
  bool DataContains(uword addr) const;

  // Find an object by visiting all pointers in the specified heap space,
  // the 'visitor' is used to determine if an object is found or not.
  // The 'visitor' function should be set up to return true if the
  // object is found, traversal through the heap space stops at that
  // point.
  // The 'visitor' function should return false if the object is not found,
  // traversal through the heap space continues.
  // Returns null object if nothing is found.
  InstructionsPtr FindObjectInCodeSpace(FindObjectVisitor* visitor) const;
  ObjectPtr FindOldObject(FindObjectVisitor* visitor) const;
  ObjectPtr FindNewObject(FindObjectVisitor* visitor);
  ObjectPtr FindObject(FindObjectVisitor* visitor);

  void HintFreed(intptr_t size);
  void NotifyIdle(int64_t deadline);
  void NotifyLowMemory();

  // Collect a single generation.
  void CollectGarbage(Space space);
  void CollectGarbage(GCType type, GCReason reason);

  // Collect both generations by performing a scavenge followed by a
  // mark-sweep. This function may not collect all unreachable objects. Because
  // mark-sweep treats new space as roots, a cycle between unreachable old and
  // new objects will not be collected until the new objects are promoted.
  // Verification based on heap iteration should instead use CollectAllGarbage.
  void CollectMostGarbage(GCReason reason = kFull);

  // Collect both generations by performing an evacuation followed by a
  // mark-sweep. If incremental marking was in progress, perform another
  // mark-sweep. This function will collect all unreachable objects, including
  // those in inter-generational cycles or stored during incremental marking.
  void CollectAllGarbage(GCReason reason = kFull);

  void CheckStartConcurrentMarking(Thread* thread, GCReason reason);
  void StartConcurrentMarking(Thread* thread);
  void CheckFinishConcurrentMarking(Thread* thread);
  void WaitForMarkerTasks(Thread* thread);
  void WaitForSweeperTasks(Thread* thread);
  void WaitForSweeperTasksAtSafepoint(Thread* thread);

  // Enables growth control on the page space heaps.  This should be
  // called before any user code is executed.
  void InitGrowthControl();
  void DisableGrowthControl() { SetGrowthControlState(false); }
  void SetGrowthControlState(bool state);
  bool GrowthControlState();

  // Protect access to the heap. Note: Code pages are made
  // executable/non-executable when 'read_only' is true/false, respectively.
  void WriteProtect(bool read_only);
  void WriteProtectCode(bool read_only) {
    old_space_.WriteProtectCode(read_only);
  }

  // Initialize the heap and register it with the isolate.
  static void Init(IsolateGroup* isolate_group,
                   bool is_vm_isolate,
                   intptr_t max_new_gen_words,
                   intptr_t max_old_gen_words);

  // Returns a suitable name for a VM region in the heap.
  static const char* RegionName(Space space);

  // Verify that all pointers in the heap point to the heap.
  bool Verify(MarkExpectation mark_expectation = kForbidMarked);

  // Print heap sizes.
  void PrintSizes() const;

  // Return amount of memory used and capacity in a space, excluding external.
  int64_t UsedInWords(Space space) const;
  int64_t CapacityInWords(Space space) const;
  int64_t ExternalInWords(Space space) const;

  int64_t TotalUsedInWords() const;
  int64_t TotalCapacityInWords() const;
  int64_t TotalExternalInWords() const;
  // Return the amount of GCing in microseconds.
  int64_t GCTimeInMicros(Space space) const;

  intptr_t Collections(Space space) const;

  ObjectSet* CreateAllocatedObjectSet(Zone* zone,
                                      MarkExpectation mark_expectation);

  static const char* GCTypeToString(GCType type);
  static const char* GCReasonToString(GCReason reason);

  // Associate a peer with an object.  A non-existent peer is equal to NULL.
  void SetPeer(ObjectPtr raw_obj, void* peer) {
    SetWeakEntry(raw_obj, kPeers, reinterpret_cast<intptr_t>(peer));
  }
  void* GetPeer(ObjectPtr raw_obj) const {
    return reinterpret_cast<void*>(GetWeakEntry(raw_obj, kPeers));
  }
  int64_t PeerCount() const;

#if !defined(HASH_IN_OBJECT_HEADER)
  // Associate an identity hashCode with an object. An non-existent hashCode
  // is equal to 0.
  void SetHash(ObjectPtr raw_obj, intptr_t hash) {
    SetWeakEntry(raw_obj, kIdentityHashes, hash);
  }
  intptr_t GetHash(ObjectPtr raw_obj) const {
    return GetWeakEntry(raw_obj, kIdentityHashes);
  }
#endif

  void SetCanonicalHash(ObjectPtr raw_obj, intptr_t hash) {
    SetWeakEntry(raw_obj, kCanonicalHashes, hash);
  }
  intptr_t GetCanonicalHash(ObjectPtr raw_obj) const {
    return GetWeakEntry(raw_obj, kCanonicalHashes);
  }
  void ResetCanonicalHashTable();

  // Associate an id with an object (used when serializing an object).
  // A non-existant id is equal to 0.
  void SetObjectId(ObjectPtr raw_obj, intptr_t object_id) {
    ASSERT(Thread::Current()->IsMutatorThread());
    SetWeakEntry(raw_obj, kObjectIds, object_id);
  }
  intptr_t GetObjectId(ObjectPtr raw_obj) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    return GetWeakEntry(raw_obj, kObjectIds);
  }
  void ResetObjectIdTable();

  void SetLoadingUnit(ObjectPtr raw_obj, intptr_t object_id) {
    ASSERT(Thread::Current()->IsMutatorThread());
    SetWeakEntry(raw_obj, kLoadingUnits, object_id);
  }
  intptr_t GetLoadingUnit(ObjectPtr raw_obj) const {
    ASSERT(Thread::Current()->IsMutatorThread());
    return GetWeakEntry(raw_obj, kLoadingUnits);
  }

  // Used by the GC algorithms to propagate weak entries.
  intptr_t GetWeakEntry(ObjectPtr raw_obj, WeakSelector sel) const;
  void SetWeakEntry(ObjectPtr raw_obj, WeakSelector sel, intptr_t val);

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

  void ForwardWeakEntries(ObjectPtr before_object, ObjectPtr after_object);
  void ForwardWeakTables(ObjectPointerVisitor* visitor);

  // Stats collection.
  void RecordTime(int id, int64_t micros) {
    ASSERT((id >= 0) && (id < GCStats::kTimeEntries));
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
  static bool IsAllocatableViaFreeLists(intptr_t size) {
    return size < kAllocatablePageSize;
  }

#ifndef PRODUCT
  void PrintToJSONObject(Space space, JSONObject* object) const;

  // Returns a JSON object with total memory usage statistics for both new and
  // old space combined.
  void PrintMemoryUsageJSON(JSONStream* stream) const;
  void PrintMemoryUsageJSON(JSONObject* jsobj) const;

  // The heap map contains the sizes and class ids for the objects in each page.
  void PrintHeapMapToJSONStream(Isolate* isolate, JSONStream* stream) {
    old_space_.PrintHeapMapToJSONStream(isolate, stream);
  }
#endif  // PRODUCT

  IsolateGroup* isolate_group() const { return isolate_group_; }
  bool is_vm_isolate() const { return is_vm_isolate_; }

  Monitor* barrier() const { return &barrier_; }
  Monitor* barrier_done() const { return &barrier_done_; }

  void SetupImagePage(void* pointer, uword size, bool is_executable) {
    old_space_.SetupImagePage(pointer, size, is_executable);
  }

  static const intptr_t kNewAllocatableSize = 256 * KB;
  static const intptr_t kAllocatablePageSize = 64 * KB;

  Space SpaceForExternal(intptr_t size) const;

  void CollectOnNthAllocation(intptr_t num_allocations);

 private:
  class GCStats : public ValueObject {
   public:
    GCStats() {}
    intptr_t num_;
    Heap::GCType type_;
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

    enum { kTimeEntries = 6 };
    enum { kDataEntries = 4 };

    Data before_;
    Data after_;
    int64_t times_[kTimeEntries];
    intptr_t data_[kDataEntries];

   private:
    DISALLOW_COPY_AND_ASSIGN(GCStats);
  };

  Heap(IsolateGroup* isolate_group,
       bool is_vm_isolate,
       intptr_t max_new_gen_semi_words,  // Max capacity of new semi-space.
       intptr_t max_old_gen_words);

  uword AllocateNew(intptr_t size);
  uword AllocateOld(intptr_t size, OldPage::PageType type);

  // Visit all pointers. Caller must ensure concurrent sweeper is not running,
  // and the visitor must not allocate.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Visit all objects, including FreeListElement "objects". Caller must ensure
  // concurrent sweeper is not running, and the visitor must not allocate.
  void VisitObjects(ObjectVisitor* visitor);
  void VisitObjectsNoImagePages(ObjectVisitor* visitor);
  void VisitObjectsImagePages(ObjectVisitor* visitor) const;

  // Like Verify, but does not wait for concurrent sweeper, so caller must
  // ensure thread-safety.
  bool VerifyGC(MarkExpectation mark_expectation = kForbidMarked);

  // Helper functions for garbage collection.
  void CollectNewSpaceGarbage(Thread* thread, GCReason reason);
  void CollectOldSpaceGarbage(Thread* thread, GCType type, GCReason reason);
  void EvacuateNewSpace(Thread* thread, GCReason reason);

  // GC stats collection.
  void RecordBeforeGC(GCType type, GCReason reason);
  void RecordAfterGC(GCType type);
  void PrintStats();
  void PrintStatsToTimeline(TimelineEventScope* event, GCReason reason);

  void AddRegionsToObjectSet(ObjectSet* set) const;

  // Trigger major GC if 'gc_on_nth_allocation_' is set.
  void CollectForDebugging();

  IsolateGroup* isolate_group_;
  bool is_vm_isolate_;

  // The different spaces used for allocation.
  Scavenger new_space_;
  PageSpace old_space_;

  WeakTable* new_weak_tables_[kNumWeakSelectors];
  WeakTable* old_weak_tables_[kNumWeakSelectors];

  mutable Monitor barrier_;
  mutable Monitor barrier_done_;

  // GC stats collection.
  GCStats stats_;

  // This heap is in read-only mode: No allocation is allowed.
  bool read_only_;

  bool last_gc_was_old_space_;
  bool assume_scavenge_will_fail_;

  static const intptr_t kNoForcedGarbageCollection = -1;

  // Whether the next heap allocation (new or old) should trigger
  // CollectAllGarbage. Used within unit tests for testing GC on certain
  // sensitive codepaths.
  intptr_t gc_on_nth_allocation_;

  friend class Become;       // VisitObjectPointers
  friend class GCCompactor;  // VisitObjectPointers
  friend class Precompiler;  // VisitObjects
  friend class Unmarker;     // VisitObjects
  friend class ServiceEvent;
  friend class Scavenger;             // VerifyGC
  friend class PageSpace;             // VerifyGC
  friend class IsolateReloadContext;  // VisitObjects
  friend class ClassFinalizer;        // VisitObjects
  friend class HeapIterationScope;    // VisitObjects
  friend class ProgramVisitor;        // VisitObjectsImagePages
  friend class Serializer;            // VisitObjectsImagePages
  friend class HeapTestHelper;
  friend class MetricsTestHelper;

  DISALLOW_COPY_AND_ASSIGN(Heap);
};

class HeapIterationScope : public ThreadStackResource {
 public:
  explicit HeapIterationScope(Thread* thread, bool writable = false);
  ~HeapIterationScope();

  void IterateObjects(ObjectVisitor* visitor) const;
  void IterateObjectsNoImagePages(ObjectVisitor* visitor) const;
  void IterateOldObjects(ObjectVisitor* visitor) const;
  void IterateOldObjectsNoImagePages(ObjectVisitor* visitor) const;

  void IterateVMIsolateObjects(ObjectVisitor* visitor) const;

  void IterateObjectPointers(ObjectPointerVisitor* visitor,
                             ValidationPolicy validate_frames);
  void IterateStackPointers(ObjectPointerVisitor* visitor,
                            ValidationPolicy validate_frames);

 private:
  Heap* heap_;
  PageSpace* old_space_;
  bool writable_;

  DISALLOW_COPY_AND_ASSIGN(HeapIterationScope);
};

class NoHeapGrowthControlScope : public ThreadStackResource {
 public:
  NoHeapGrowthControlScope();
  ~NoHeapGrowthControlScope();

 private:
  bool current_growth_controller_state_;
  DISALLOW_COPY_AND_ASSIGN(NoHeapGrowthControlScope);
};

// Note: During this scope all pages are writable and the code pages are
// non-executable.
class WritableVMIsolateScope : ThreadStackResource {
 public:
  explicit WritableVMIsolateScope(Thread* thread);
  ~WritableVMIsolateScope();
};

class WritableCodePages : StackResource {
 public:
  explicit WritableCodePages(Thread* thread, Isolate* isolate);
  ~WritableCodePages();

 private:
  Isolate* isolate_;
};

#if defined(TESTING)
class GCTestHelper : public AllStatic {
 public:
  // Collect new gen without triggering any side effects. The normal call to
  // CollectGarbage(Heap::kNew) could potentially trigger an old gen collection
  // if there is enough promotion, and this can perturb some tests.
  static void CollectNewSpace() {
    Thread* thread = Thread::Current();
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    thread->heap()->new_space()->Scavenge();
  }

  // Fully collect old gen and wait for the sweeper to finish. The normal call
  // to CollectGarbage(Heap::kOld) may leave so-called "floating garbage",
  // objects that were seen by the incremental barrier but later made
  // unreachable, and this can perturb some tests.
  static void CollectOldSpace() {
    Thread* thread = Thread::Current();
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    if (thread->is_marking()) {
      thread->heap()->CollectGarbage(Heap::kMarkSweep, Heap::kDebugging);
    }
    thread->heap()->CollectGarbage(Heap::kMarkSweep, Heap::kDebugging);
    WaitForGCTasks();
  }

  static void CollectAllGarbage() {
    Thread* thread = Thread::Current();
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    thread->heap()->CollectAllGarbage(Heap::kDebugging);
  }

  static void WaitForGCTasks() {
    Thread* thread = Thread::Current();
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    thread->heap()->WaitForMarkerTasks(thread);
    thread->heap()->WaitForSweeperTasks(thread);
  }
};
#endif  // TESTING

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_HEAP_H_
