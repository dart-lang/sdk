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
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    kHeapSamplingData,
#endif
    kNumWeakSelectors
  };

  // States for a state machine that represents the worst-case set of GCs
  // that an unreachable object could survive before begin collected:
  // a new-space object that is involved with a cycle with an old-space object
  // is copied to survivor space, then promoted during concurrent marking,
  // and finally proven unreachable in the next round of old-gen marking.
  // We ignore the case of unreachable-but-not-yet-collected objects being
  // made reachable again by allInstances.
  enum LeakCountState {
    kInitial = 0,
    kFirstScavenge,
    kSecondScavenge,
    kMarkingStart,
  };

  // Pattern for unused new space and swept old space.
  static constexpr uint8_t kZapByte = 0xf3;

  ~Heap();

  Scavenger* new_space() { return &new_space_; }
  PageSpace* old_space() { return &old_space_; }

  uword Allocate(Thread* thread, intptr_t size, Space space) {
    ASSERT(!read_only_);
    switch (space) {
      case kNew:
        // Do not attempt to allocate very large objects in new space.
        if (!IsAllocatableInNewSpace(size)) {
          return AllocateOld(thread, size, /*executable*/ false);
        }
        return AllocateNew(thread, size);
      case kOld:
        return AllocateOld(thread, size, /*executable*/ false);
      case kCode:
        return AllocateOld(thread, size, /*executable*/ true);
      default:
        UNREACHABLE();
    }
    return 0;
  }

  // Tracks an external allocation. Returns false without tracking the
  // allocation if it will make the total external size exceed
  // kMaxAddrSpaceInWords.
  bool AllocatedExternal(intptr_t size, Space space);
  void FreedExternal(intptr_t size, Space space);
  // Move external size from new to old space. Does not by itself trigger GC.
  void PromotedExternal(intptr_t size);
  void CheckExternalGC(Thread* thread);

  // Heap contains the specified address.
  bool Contains(uword addr) const;
  bool NewContains(uword addr) const;
  bool OldContains(uword addr) const;
  bool CodeContains(uword addr) const;
  bool DataContains(uword addr) const;

  void NotifyIdle(int64_t deadline);
  void NotifyDestroyed();

  Dart_PerformanceMode mode() const { return mode_; }
  Dart_PerformanceMode SetMode(Dart_PerformanceMode mode);

  // Collect a single generation.
  void CollectGarbage(Thread* thread, GCType type, GCReason reason);

  // Collect both generations by performing a scavenge followed by a
  // mark-sweep. This function may not collect all unreachable objects. Because
  // mark-sweep treats new space as roots, a cycle between unreachable old and
  // new objects will not be collected until the new objects are promoted.
  // Verification based on heap iteration should instead use CollectAllGarbage.
  void CollectMostGarbage(GCReason reason = GCReason::kFull,
                          bool compact = false);

  // Collect both generations by performing an evacuation followed by a
  // mark-sweep. If incremental marking was in progress, perform another
  // mark-sweep. This function will collect all unreachable objects, including
  // those in inter-generational cycles or stored during incremental marking.
  void CollectAllGarbage(GCReason reason = GCReason::kFull,
                         bool compact = false);

  void CheckCatchUp(Thread* thread);
  void CheckConcurrentMarking(Thread* thread, GCReason reason, intptr_t size);
  void StartConcurrentMarking(Thread* thread, GCReason reason);
  void WaitForMarkerTasks(Thread* thread);
  void WaitForSweeperTasks(Thread* thread);
  void WaitForSweeperTasksAtSafepoint(Thread* thread);

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

  // Verify that all pointers in the heap point to the heap.
  bool Verify(const char* msg,
              MarkExpectation mark_expectation = kForbidMarked);

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

  // Associate a peer with an object.  A nonexistent peer is equal to nullptr.
  void SetPeer(ObjectPtr raw_obj, void* peer) {
    SetWeakEntry(raw_obj, kPeers, reinterpret_cast<intptr_t>(peer));
  }
  void* GetPeer(ObjectPtr raw_obj) const {
    return reinterpret_cast<void*>(GetWeakEntry(raw_obj, kPeers));
  }
  int64_t PeerCount() const;

#if !defined(HASH_IN_OBJECT_HEADER)
  // Associate an identity hashCode with an object. An nonexistent hashCode
  // is equal to 0.
  intptr_t SetHashIfNotSet(ObjectPtr raw_obj, intptr_t hash) {
    return SetWeakEntryIfNonExistent(raw_obj, kIdentityHashes, hash);
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
    ASSERT(Thread::Current()->IsDartMutatorThread());
    SetWeakEntry(raw_obj, kObjectIds, object_id);
  }
  intptr_t GetObjectId(ObjectPtr raw_obj) const {
    ASSERT(Thread::Current()->IsDartMutatorThread());
    return GetWeakEntry(raw_obj, kObjectIds);
  }
  void ResetObjectIdTable();

  void SetLoadingUnit(ObjectPtr raw_obj, intptr_t unit_id) {
    ASSERT(Thread::Current()->IsDartMutatorThread());
    SetWeakEntry(raw_obj, kLoadingUnits, unit_id);
  }
  intptr_t GetLoadingUnit(ObjectPtr raw_obj) const {
    ASSERT(Thread::Current()->IsDartMutatorThread());
    return GetWeakEntry(raw_obj, kLoadingUnits);
  }

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  void SetHeapSamplingData(ObjectPtr obj, void* data) {
    SetWeakEntry(obj, kHeapSamplingData, reinterpret_cast<intptr_t>(data));
  }
#endif

  // Used by the GC algorithms to propagate weak entries.
  intptr_t GetWeakEntry(ObjectPtr raw_obj, WeakSelector sel) const;
  void SetWeakEntry(ObjectPtr raw_obj, WeakSelector sel, intptr_t val);
  intptr_t SetWeakEntryIfNonExistent(ObjectPtr raw_obj,
                                     WeakSelector sel,
                                     intptr_t val);

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

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  void ReportSurvivingAllocations(Dart_HeapSamplingReportCallback callback,
                                  void* context) {
    new_weak_tables_[kHeapSamplingData]->ReportSurvivingAllocations(callback,
                                                                    context);
    old_weak_tables_[kHeapSamplingData]->ReportSurvivingAllocations(callback,
                                                                    context);
  }
#endif

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
  void PrintHeapMapToJSONStream(IsolateGroup* isolate_group,
                                JSONStream* stream) {
    old_space_.PrintHeapMapToJSONStream(isolate_group, stream);
  }

  intptr_t ReachabilityBarrier() { return stats_.reachability_barrier_; }
#endif  // PRODUCT

  IsolateGroup* isolate_group() const { return isolate_group_; }
  bool is_vm_isolate() const { return is_vm_isolate_; }

  void SetupImagePage(void* pointer, uword size, bool is_executable) {
    old_space_.SetupImagePage(pointer, size, is_executable);
  }

  static constexpr intptr_t kNewAllocatableSize = 256 * KB;
  static constexpr intptr_t kAllocatablePageSize = 64 * KB;

  Space SpaceForExternal(intptr_t size) const;

  void CollectOnNthAllocation(intptr_t num_allocations);

 private:
  class GCStats : public ValueObject {
   public:
    GCStats() {}
    intptr_t num_;
    GCType type_;
    GCReason reason_;
    LeakCountState state_;  // State to track finalization of GCed object.
    intptr_t reachability_barrier_;  // Tracks reachability of GCed objects.

    class Data : public ValueObject {
     public:
      Data() {}
      int64_t micros_;
      SpaceUsage new_;
      SpaceUsage old_;
      intptr_t store_buffer_;

     private:
      DISALLOW_COPY_AND_ASSIGN(Data);
    };

    Data before_;
    Data after_;

   private:
    DISALLOW_COPY_AND_ASSIGN(GCStats);
  };

  Heap(IsolateGroup* isolate_group,
       bool is_vm_isolate,
       intptr_t max_new_gen_semi_words,  // Max capacity of new semi-space.
       intptr_t max_old_gen_words);

  uword AllocateNew(Thread* thread, intptr_t size);
  uword AllocateOld(Thread* thread, intptr_t size, bool executable);

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
  bool VerifyGC(const char* msg,
                MarkExpectation mark_expectation = kForbidMarked);

  // Helper functions for garbage collection.
  void CollectNewSpaceGarbage(Thread* thread, GCType type, GCReason reason);
  void CollectOldSpaceGarbage(Thread* thread, GCType type, GCReason reason);

  // GC stats collection.
  void RecordBeforeGC(GCType type, GCReason reason);
  void RecordAfterGC(GCType type);
  void PrintStats();
  void PrintStatsToTimeline(TimelineEventScope* event, GCReason reason);

  void AddRegionsToObjectSet(ObjectSet* set) const;

  // Trigger major GC if 'gc_on_nth_allocation_' is set.
  void CollectForDebugging(Thread* thread);

  IsolateGroup* isolate_group_;
  bool is_vm_isolate_;

  // The different spaces used for allocation.
  Scavenger new_space_;
  PageSpace old_space_;

  WeakTable* new_weak_tables_[kNumWeakSelectors];
  WeakTable* old_weak_tables_[kNumWeakSelectors];

  // GC stats collection.
  GCStats stats_;

  RelaxedAtomic<Dart_PerformanceMode> mode_ = {Dart_PerformanceMode_Default};

  // This heap is in read-only mode: No allocation is allowed.
  bool read_only_;

  bool last_gc_was_old_space_;
  bool assume_scavenge_will_fail_;

  static constexpr intptr_t kNoForcedGarbageCollection = -1;

  // Whether the next heap allocation (new or old) should trigger
  // CollectAllGarbage. Used within unit tests for testing GC on certain
  // sensitive codepaths.
  intptr_t gc_on_nth_allocation_;

  friend class Become;       // VisitObjectPointers
  friend class GCCompactor;  // VisitObjectPointers
  friend class Precompiler;  // VisitObjects
  friend class ServiceEvent;
  friend class Scavenger;             // VerifyGC
  friend class PageSpace;             // VerifyGC
  friend class ProgramReloadContext;  // VisitObjects
  friend class ClassFinalizer;        // VisitObjects
  friend class HeapIterationScope;    // VisitObjects
  friend class GCMarker;              // VisitObjects
  friend class ProgramVisitor;        // VisitObjectsImagePages
  friend class Serializer;            // VisitObjectsImagePages
  friend class HeapTestHelper;
  friend class GCTestHelper;

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

class ForceGrowthScope : public ThreadStackResource {
 public:
  explicit ForceGrowthScope(Thread* thread);
  ~ForceGrowthScope();

 private:
  DISALLOW_COPY_AND_ASSIGN(ForceGrowthScope);
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
  WritableCodePages(Thread* thread, IsolateGroup* isolate_group);
  ~WritableCodePages();

 private:
  IsolateGroup* isolate_group_;
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
    thread->heap()->CollectGarbage(thread, GCType::kScavenge,
                                   GCReason::kDebugging);
  }

  // Fully collect old gen and wait for the sweeper to finish. The normal call
  // to CollectGarbage(Heap::kOld) may leave so-called "floating garbage",
  // objects that were seen by the incremental barrier but later made
  // unreachable, and this can perturb some tests.
  static void CollectOldSpace() {
    Thread* thread = Thread::Current();
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    if (thread->is_marking()) {
      thread->heap()->CollectGarbage(thread, GCType::kMarkSweep,
                                     GCReason::kDebugging);
    }
    thread->heap()->CollectGarbage(thread, GCType::kMarkSweep,
                                   GCReason::kDebugging);
    WaitForGCTasks();
  }

  static void CollectAllGarbage(bool compact = false) {
    Thread* thread = Thread::Current();
    ASSERT(thread->execution_state() == Thread::kThreadInVM);
    thread->heap()->CollectAllGarbage(GCReason::kDebugging, compact);
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
