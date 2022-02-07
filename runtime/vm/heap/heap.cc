// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/heap/heap.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/heap/pages.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/scavenger.h"
#include "vm/heap/verifier.h"
#include "vm/heap/weak_table.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/stack_frame.h"
#include "vm/tags.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"
#include "vm/virtual_memory.h"

namespace dart {

DEFINE_FLAG(bool, write_protect_vm_isolate, true, "Write protect vm_isolate.");
DEFINE_FLAG(bool,
            disable_heap_verification,
            false,
            "Explicitly disable heap verification.");

Heap::Heap(IsolateGroup* isolate_group,
           bool is_vm_isolate,
           intptr_t max_new_gen_semi_words,
           intptr_t max_old_gen_words)
    : isolate_group_(isolate_group),
      is_vm_isolate_(is_vm_isolate),
      new_space_(this, max_new_gen_semi_words),
      old_space_(this, max_old_gen_words),
      read_only_(false),
      last_gc_was_old_space_(false),
      assume_scavenge_will_fail_(false),
      gc_on_nth_allocation_(kNoForcedGarbageCollection) {
  UpdateGlobalMaxUsed();
  for (int sel = 0; sel < kNumWeakSelectors; sel++) {
    new_weak_tables_[sel] = new WeakTable();
    old_weak_tables_[sel] = new WeakTable();
  }
  stats_.num_ = 0;
}

Heap::~Heap() {
  for (int sel = 0; sel < kNumWeakSelectors; sel++) {
    delete new_weak_tables_[sel];
    delete old_weak_tables_[sel];
  }
}

uword Heap::AllocateNew(intptr_t size) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() == 0);
  CollectForDebugging();
  Thread* thread = Thread::Current();
  uword addr = new_space_.TryAllocate(thread, size);
  if (LIKELY(addr != 0)) {
    return addr;
  }
  if (!assume_scavenge_will_fail_ && new_space_.GrowthControlState()) {
    // This call to CollectGarbage might end up "reusing" a collection spawned
    // from a different thread and will be racing to allocate the requested
    // memory with other threads being released after the collection.
    CollectGarbage(kNew);

    addr = new_space_.TryAllocate(thread, size);
    if (LIKELY(addr != 0)) {
      return addr;
    }
  }

  // It is possible a GC doesn't clear enough space.
  // In that case, we must fall through and allocate into old space.
  return AllocateOld(size, OldPage::kData);
}

uword Heap::AllocateOld(intptr_t size, OldPage::PageType type) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() == 0);
  if (old_space_.GrowthControlState()) {
    CollectForDebugging();
    uword addr = old_space_.TryAllocate(size, type);
    if (addr != 0) {
      return addr;
    }
    Thread* thread = Thread::Current();
    // Wait for any GC tasks that are in progress.
    WaitForSweeperTasks(thread);
    addr = old_space_.TryAllocate(size, type);
    if (addr != 0) {
      return addr;
    }
    // All GC tasks finished without allocating successfully. Collect both
    // generations.
    CollectMostGarbage();
    addr = old_space_.TryAllocate(size, type);
    if (addr != 0) {
      return addr;
    }
    // Wait for all of the concurrent tasks to finish before giving up.
    WaitForSweeperTasks(thread);
    addr = old_space_.TryAllocate(size, type);
    if (addr != 0) {
      return addr;
    }
    // Force growth before attempting another synchronous GC.
    addr = old_space_.TryAllocate(size, type, PageSpace::kForceGrowth);
    if (addr != 0) {
      return addr;
    }
    // Before throwing an out-of-memory error try a synchronous GC.
    CollectAllGarbage(GCReason::kLowMemory);
    WaitForSweeperTasks(thread);
  }
  uword addr = old_space_.TryAllocate(size, type, PageSpace::kForceGrowth);
  if (addr != 0) {
    return addr;
  }

  if (old_space_.GrowthControlState()) {
    WaitForSweeperTasks(Thread::Current());
    old_space_.TryReleaseReservation();
  } else {
    // We may or may not be a safepoint, so we don't know how to wait for the
    // sweeper.
  }

  // Give up allocating this object.
  OS::PrintErr("Exhausted heap space, trying to allocate %" Pd " bytes.\n",
               size);
  return 0;
}

void Heap::AllocatedExternal(intptr_t size, Space space) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() == 0);
  if (space == kNew) {
    Isolate::Current()->AssertCurrentThreadIsMutator();
    new_space_.AllocatedExternal(size);
    if (new_space_.ExternalInWords() <= (4 * new_space_.CapacityInWords())) {
      return;
    }
    // Attempt to free some external allocation by a scavenge. (If the total
    // remains above the limit, next external alloc will trigger another.)
    CollectGarbage(GCType::kScavenge, GCReason::kExternal);
    // Promotion may have pushed old space over its limit. Fall through for old
    // space GC check.
  } else {
    ASSERT(space == kOld);
    old_space_.AllocatedExternal(size);
  }

  if (old_space_.ReachedHardThreshold()) {
    if (last_gc_was_old_space_) {
      CollectNewSpaceGarbage(Thread::Current(), GCReason::kFull);
    }
    CollectGarbage(GCType::kMarkSweep, GCReason::kExternal);
  } else {
    CheckStartConcurrentMarking(Thread::Current(), GCReason::kExternal);
  }
}

void Heap::FreedExternal(intptr_t size, Space space) {
  if (space == kNew) {
    new_space_.FreedExternal(size);
  } else {
    ASSERT(space == kOld);
    old_space_.FreedExternal(size);
  }
}

void Heap::PromotedExternal(intptr_t size) {
  new_space_.FreedExternal(size);
  old_space_.AllocatedExternal(size);
}

bool Heap::Contains(uword addr) const {
  return new_space_.Contains(addr) || old_space_.Contains(addr);
}

bool Heap::NewContains(uword addr) const {
  return new_space_.Contains(addr);
}

bool Heap::OldContains(uword addr) const {
  return old_space_.Contains(addr);
}

bool Heap::CodeContains(uword addr) const {
  return old_space_.Contains(addr, OldPage::kExecutable);
}

bool Heap::DataContains(uword addr) const {
  return old_space_.DataContains(addr);
}

void Heap::VisitObjects(ObjectVisitor* visitor) {
  new_space_.VisitObjects(visitor);
  old_space_.VisitObjects(visitor);
}

void Heap::VisitObjectsNoImagePages(ObjectVisitor* visitor) {
  new_space_.VisitObjects(visitor);
  old_space_.VisitObjectsNoImagePages(visitor);
}

void Heap::VisitObjectsImagePages(ObjectVisitor* visitor) const {
  old_space_.VisitObjectsImagePages(visitor);
}

HeapIterationScope::HeapIterationScope(Thread* thread, bool writable)
    : ThreadStackResource(thread),
      heap_(isolate_group()->heap()),
      old_space_(heap_->old_space()),
      writable_(writable) {
  isolate_group()->safepoint_handler()->SafepointThreads(thread,
                                                         SafepointLevel::kGC);

  {
    // It's not safe to iterate over old space when concurrent marking or
    // sweeping is in progress, or another thread is iterating the heap, so wait
    // for any such task to complete first.
    MonitorLocker ml(old_space_->tasks_lock());
#if defined(DEBUG)
    // We currently don't support nesting of HeapIterationScopes.
    ASSERT(old_space_->iterating_thread_ != thread);
#endif
    while ((old_space_->tasks() > 0) ||
           (old_space_->phase() != PageSpace::kDone)) {
      old_space_->AssistTasks(&ml);
      if (old_space_->phase() == PageSpace::kAwaitingFinalization) {
        ml.Exit();
        heap_->CollectOldSpaceGarbage(thread, GCType::kMarkSweep,
                                      GCReason::kFinalize);
        ml.Enter();
      }
      while (old_space_->tasks() > 0) {
        ml.Wait();
      }
    }
#if defined(DEBUG)
    ASSERT(old_space_->iterating_thread_ == NULL);
    old_space_->iterating_thread_ = thread;
#endif
    old_space_->set_tasks(1);
  }

  if (writable_) {
    heap_->WriteProtectCode(false);
  }
}

HeapIterationScope::~HeapIterationScope() {
  if (writable_) {
    heap_->WriteProtectCode(true);
  }

  {
    MonitorLocker ml(old_space_->tasks_lock());
#if defined(DEBUG)
    ASSERT(old_space_->iterating_thread_ == thread());
    old_space_->iterating_thread_ = NULL;
#endif
    ASSERT(old_space_->tasks() == 1);
    old_space_->set_tasks(0);
    ml.NotifyAll();
  }

  isolate_group()->safepoint_handler()->ResumeThreads(thread(),
                                                      SafepointLevel::kGC);
}

void HeapIterationScope::IterateObjects(ObjectVisitor* visitor) const {
  heap_->VisitObjects(visitor);
}

void HeapIterationScope::IterateObjectsNoImagePages(
    ObjectVisitor* visitor) const {
  heap_->new_space()->VisitObjects(visitor);
  heap_->old_space()->VisitObjectsNoImagePages(visitor);
}

void HeapIterationScope::IterateOldObjects(ObjectVisitor* visitor) const {
  old_space_->VisitObjects(visitor);
}

void HeapIterationScope::IterateOldObjectsNoImagePages(
    ObjectVisitor* visitor) const {
  old_space_->VisitObjectsNoImagePages(visitor);
}

void HeapIterationScope::IterateVMIsolateObjects(ObjectVisitor* visitor) const {
  Dart::vm_isolate_group()->heap()->VisitObjects(visitor);
}

void HeapIterationScope::IterateObjectPointers(
    ObjectPointerVisitor* visitor,
    ValidationPolicy validate_frames) {
  isolate_group()->VisitObjectPointers(visitor, validate_frames);
}

void HeapIterationScope::IterateStackPointers(
    ObjectPointerVisitor* visitor,
    ValidationPolicy validate_frames) {
  isolate_group()->VisitStackPointers(visitor, validate_frames);
}

void Heap::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  new_space_.VisitObjectPointers(visitor);
  old_space_.VisitObjectPointers(visitor);
}

InstructionsPtr Heap::FindObjectInCodeSpace(FindObjectVisitor* visitor) const {
  // Only executable pages can have RawInstructions objects.
  ObjectPtr raw_obj = old_space_.FindObject(visitor, OldPage::kExecutable);
  ASSERT((raw_obj == Object::null()) ||
         (raw_obj->GetClassId() == kInstructionsCid));
  return static_cast<InstructionsPtr>(raw_obj);
}

ObjectPtr Heap::FindOldObject(FindObjectVisitor* visitor) const {
  return old_space_.FindObject(visitor, OldPage::kData);
}

ObjectPtr Heap::FindNewObject(FindObjectVisitor* visitor) {
  return new_space_.FindObject(visitor);
}

ObjectPtr Heap::FindObject(FindObjectVisitor* visitor) {
  // The visitor must not allocate from the heap.
  NoSafepointScope no_safepoint_scope;
  ObjectPtr raw_obj = FindNewObject(visitor);
  if (raw_obj != Object::null()) {
    return raw_obj;
  }
  raw_obj = FindOldObject(visitor);
  if (raw_obj != Object::null()) {
    return raw_obj;
  }
  raw_obj = FindObjectInCodeSpace(visitor);
  return raw_obj;
}

void Heap::NotifyIdle(int64_t deadline) {
  Thread* thread = Thread::Current();
  TIMELINE_FUNCTION_GC_DURATION(thread, "NotifyIdle");
  {
    GcSafepointOperationScope safepoint_operation(thread);

    // Check if we want to collect new-space first, because if we want to
    // collect both new-space and old-space, the new-space collection should run
    // first to shrink the root set (make old-space GC faster) and avoid
    // intergenerational garbage (make old-space GC free more memory).
    if (new_space_.ShouldPerformIdleScavenge(deadline)) {
      CollectNewSpaceGarbage(thread, GCReason::kIdle);
    }

    // Check if we want to collect old-space, in decreasing order of cost.
    // Because we use a deadline instead of a timeout, we automatically take any
    // time used up by a scavenge into account when deciding if we can complete
    // a mark-sweep on time.
    if (old_space_.ShouldPerformIdleMarkCompact(deadline)) {
      // We prefer mark-compact over other old space GCs if we have enough time,
      // since it removes old space fragmentation and frees up most memory.
      // Blocks for O(heap), roughtly twice as costly as mark-sweep.
      CollectOldSpaceGarbage(thread, GCType::kMarkCompact, GCReason::kIdle);
    } else if (old_space_.ReachedHardThreshold()) {
      // Even though the following GC may exceed our idle deadline, we need to
      // ensure than that promotions during idle scavenges do not lead to
      // unbounded growth of old space. If a program is allocating only in new
      // space and all scavenges happen during idle time, then NotifyIdle will
      // be the only place that checks the old space allocation limit.
      // Compare the tail end of Heap::CollectNewSpaceGarbage.
      // Blocks for O(heap).
      CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kIdle);
    } else if (old_space_.ShouldStartIdleMarkSweep(deadline) ||
               old_space_.ReachedSoftThreshold()) {
      // If we have both work to do and enough time, start or finish GC.
      // If we have crossed the soft threshold, ignore time; the next old-space
      // allocation will trigger this work anyway, so we try to pay at least
      // some of that cost with idle time.
      // Blocks for O(roots).
      PageSpace::Phase phase;
      {
        MonitorLocker ml(old_space_.tasks_lock());
        phase = old_space_.phase();
      }
      if (phase == PageSpace::kAwaitingFinalization) {
        CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kFinalize);
      } else if (phase == PageSpace::kDone) {
        StartConcurrentMarking(thread, GCReason::kIdle);
      }
    }
  }

  old_space_.NotifyIdle(deadline);

  if (OS::GetCurrentMonotonicMicros() < deadline) {
    SemiSpace::DrainCache();
  }
}

void Heap::NotifyLowMemory() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "NotifyLowMemory");
  CollectMostGarbage(GCReason::kLowMemory);
}

void Heap::EvacuateNewSpace(Thread* thread, GCReason reason) {
  ASSERT(reason != GCReason::kOldSpace);
  ASSERT(reason != GCReason::kPromotion);
  ASSERT(reason != GCReason::kFinalize);
  if (thread->isolate_group() == Dart::vm_isolate_group()) {
    // The vm isolate cannot safely collect garbage due to unvisited read-only
    // handles and slots bootstrapped with RAW_NULL. Ignore GC requests to
    // trigger a nice out-of-memory message instead of a crash in the middle of
    // visiting pointers.
    return;
  }
  {
    GcSafepointOperationScope safepoint_operation(thread);
    RecordBeforeGC(GCType::kScavenge, reason);
    VMTagScope tagScope(thread, reason == GCReason::kIdle
                                    ? VMTag::kGCIdleTagId
                                    : VMTag::kGCNewSpaceTagId);
    TIMELINE_FUNCTION_GC_DURATION(thread, "EvacuateNewGeneration");
    new_space_.Evacuate(reason);
    RecordAfterGC(GCType::kScavenge);
    PrintStats();
#if defined(SUPPORT_TIMELINE)
    PrintStatsToTimeline(&tbes, reason);
#endif
    last_gc_was_old_space_ = false;
  }
}

void Heap::CollectNewSpaceGarbage(Thread* thread, GCReason reason) {
  NoActiveIsolateScope no_active_isolate_scope;
  ASSERT(reason != GCReason::kOldSpace);
  ASSERT(reason != GCReason::kPromotion);
  ASSERT(reason != GCReason::kFinalize);
  if (thread->isolate_group() == Dart::vm_isolate_group()) {
    // The vm isolate cannot safely collect garbage due to unvisited read-only
    // handles and slots bootstrapped with RAW_NULL. Ignore GC requests to
    // trigger a nice out-of-memory message instead of a crash in the middle of
    // visiting pointers.
    return;
  }
  {
    GcSafepointOperationScope safepoint_operation(thread);
    RecordBeforeGC(GCType::kScavenge, reason);
    {
      VMTagScope tagScope(thread, reason == GCReason::kIdle
                                      ? VMTag::kGCIdleTagId
                                      : VMTag::kGCNewSpaceTagId);
      TIMELINE_FUNCTION_GC_DURATION(thread, "CollectNewGeneration");
      new_space_.Scavenge(reason);
      RecordAfterGC(GCType::kScavenge);
      PrintStats();
#if defined(SUPPORT_TIMELINE)
      PrintStatsToTimeline(&tbes, reason);
#endif
      last_gc_was_old_space_ = false;
    }
    if (reason == GCReason::kNewSpace) {
      if (old_space_.ReachedHardThreshold()) {
        CollectOldSpaceGarbage(thread, GCType::kMarkSweep,
                               GCReason::kPromotion);
      } else {
        CheckStartConcurrentMarking(thread, GCReason::kPromotion);
      }
    }
  }
}

void Heap::CollectOldSpaceGarbage(Thread* thread,
                                  GCType type,
                                  GCReason reason) {
  NoActiveIsolateScope no_active_isolate_scope;

  ASSERT(type != GCType::kScavenge);
  ASSERT(reason != GCReason::kNewSpace);
  ASSERT(reason != GCReason::kStoreBuffer);
  if (FLAG_use_compactor) {
    type = GCType::kMarkCompact;
  }
  if (thread->isolate_group() == Dart::vm_isolate_group()) {
    // The vm isolate cannot safely collect garbage due to unvisited read-only
    // handles and slots bootstrapped with RAW_NULL. Ignore GC requests to
    // trigger a nice out-of-memory message instead of a crash in the middle of
    // visiting pointers.
    return;
  }
  {
    GcSafepointOperationScope safepoint_operation(thread);
    thread->isolate_group()->ForEachIsolate(
        [&](Isolate* isolate) {
          // Discard regexp backtracking stacks to further reduce memory usage.
          isolate->CacheRegexpBacktrackStack(nullptr);
        },
        /*at_safepoint=*/true);

    RecordBeforeGC(type, reason);
    VMTagScope tagScope(thread, reason == GCReason::kIdle
                                    ? VMTag::kGCIdleTagId
                                    : VMTag::kGCOldSpaceTagId);
    TIMELINE_FUNCTION_GC_DURATION(thread, "CollectOldGeneration");
    old_space_.CollectGarbage(type == GCType::kMarkCompact, true /* finish */);
    RecordAfterGC(type);
    PrintStats();
#if defined(SUPPORT_TIMELINE)
    PrintStatsToTimeline(&tbes, reason);
#endif

    // Some Code objects may have been collected so invalidate handler cache.
    thread->isolate_group()->ForEachIsolate(
        [&](Isolate* isolate) {
          isolate->handler_info_cache()->Clear();
          isolate->catch_entry_moves_cache()->Clear();
        },
        /*at_safepoint=*/true);
    last_gc_was_old_space_ = true;
    assume_scavenge_will_fail_ = false;
  }
}

void Heap::CollectGarbage(GCType type, GCReason reason) {
  Thread* thread = Thread::Current();
  switch (type) {
    case GCType::kScavenge:
      CollectNewSpaceGarbage(thread, reason);
      break;
    case GCType::kMarkSweep:
    case GCType::kMarkCompact:
      CollectOldSpaceGarbage(thread, type, reason);
      break;
    default:
      UNREACHABLE();
  }
}

void Heap::CollectGarbage(Space space) {
  Thread* thread = Thread::Current();
  if (space == kOld) {
    CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kOldSpace);
  } else {
    ASSERT(space == kNew);
    CollectNewSpaceGarbage(thread, GCReason::kNewSpace);
  }
}

void Heap::CollectMostGarbage(GCReason reason) {
  Thread* thread = Thread::Current();
  CollectNewSpaceGarbage(thread, reason);
  CollectOldSpaceGarbage(thread,
                         reason == GCReason::kLowMemory ? GCType::kMarkCompact
                                                        : GCType::kMarkSweep,
                         reason);
}

void Heap::CollectAllGarbage(GCReason reason) {
  Thread* thread = Thread::Current();

  // New space is evacuated so this GC will collect all dead objects
  // kept alive by a cross-generational pointer.
  EvacuateNewSpace(thread, reason);
  if (thread->is_marking()) {
    // If incremental marking is happening, we need to finish the GC cycle
    // and perform a follow-up GC to purge any "floating garbage" that may be
    // retained by the incremental barrier.
    CollectOldSpaceGarbage(thread, GCType::kMarkSweep, reason);
  }
  CollectOldSpaceGarbage(thread,
                         reason == GCReason::kLowMemory ? GCType::kMarkCompact
                                                        : GCType::kMarkSweep,
                         reason);
  WaitForSweeperTasks(thread);
}

void Heap::CheckStartConcurrentMarking(Thread* thread, GCReason reason) {
  {
    MonitorLocker ml(old_space_.tasks_lock());
    if (old_space_.phase() != PageSpace::kDone) {
      return;  // Busy.
    }
  }

  if (old_space_.ReachedSoftThreshold()) {
    // New-space objects are roots during old-space GC. This means that even
    // unreachable new-space objects prevent old-space objects they reference
    // from being collected during an old-space GC. Normally this is not an
    // issue because new-space GCs run much more frequently than old-space GCs.
    // If new-space allocation is low and direct old-space allocation is high,
    // which can happen in a program that allocates large objects and little
    // else, old-space can fill up with unreachable objects until the next
    // new-space GC. This check is the concurrent-marking equivalent to the
    // new-space GC before synchronous-marking in CollectMostGarbage.
    if (last_gc_was_old_space_) {
      CollectNewSpaceGarbage(thread, GCReason::kFull);
    }

    StartConcurrentMarking(thread, reason);
  }
}

void Heap::StartConcurrentMarking(Thread* thread, GCReason reason) {
  GcSafepointOperationScope safepoint_operation(thread);
  RecordBeforeGC(GCType::kStartConcurrentMark, reason);
  VMTagScope tagScope(thread, reason == GCReason::kIdle
                                  ? VMTag::kGCIdleTagId
                                  : VMTag::kGCOldSpaceTagId);
  TIMELINE_FUNCTION_GC_DURATION(thread, "StartConcurrentMarking");
  old_space_.CollectGarbage(/*compact=*/false, /*finalize=*/false);
  RecordAfterGC(GCType::kStartConcurrentMark);
  PrintStats();
#if defined(SUPPORT_TIMELINE)
  PrintStatsToTimeline(&tbes, reason);
#endif
}

void Heap::CheckFinishConcurrentMarking(Thread* thread) {
  bool ready;
  {
    MonitorLocker ml(old_space_.tasks_lock());
    ready = old_space_.phase() == PageSpace::kAwaitingFinalization;
  }
  if (ready) {
    CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kFinalize);
  }
}

void Heap::WaitForMarkerTasks(Thread* thread) {
  MonitorLocker ml(old_space_.tasks_lock());
  while ((old_space_.phase() == PageSpace::kMarking) ||
         (old_space_.phase() == PageSpace::kAwaitingFinalization)) {
    while (old_space_.phase() == PageSpace::kMarking) {
      ml.WaitWithSafepointCheck(thread);
    }
    if (old_space_.phase() == PageSpace::kAwaitingFinalization) {
      ml.Exit();
      CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kFinalize);
      ml.Enter();
    }
  }
}

void Heap::WaitForSweeperTasks(Thread* thread) {
  ASSERT(!thread->IsAtSafepoint());
  MonitorLocker ml(old_space_.tasks_lock());
  while (old_space_.tasks() > 0) {
    ml.WaitWithSafepointCheck(thread);
  }
}

void Heap::WaitForSweeperTasksAtSafepoint(Thread* thread) {
  ASSERT(thread->IsAtSafepoint());
  MonitorLocker ml(old_space_.tasks_lock());
  while (old_space_.tasks() > 0) {
    ml.Wait();
  }
}

void Heap::UpdateGlobalMaxUsed() {
  ASSERT(isolate_group_ != NULL);
  // We are accessing the used in words count for both new and old space
  // without synchronizing. The value of this metric is approximate.
  isolate_group_->GetHeapGlobalUsedMaxMetric()->SetValue(
      (UsedInWords(Heap::kNew) * kWordSize) +
      (UsedInWords(Heap::kOld) * kWordSize));
}

void Heap::InitGrowthControl() {
  new_space_.InitGrowthControl();
  old_space_.InitGrowthControl();
}

void Heap::SetGrowthControlState(bool state) {
  new_space_.SetGrowthControlState(state);
  old_space_.SetGrowthControlState(state);
}

bool Heap::GrowthControlState() {
  ASSERT(new_space_.GrowthControlState() == old_space_.GrowthControlState());
  return old_space_.GrowthControlState();
}

void Heap::WriteProtect(bool read_only) {
  read_only_ = read_only;
  new_space_.WriteProtect(read_only);
  old_space_.WriteProtect(read_only);
}

void Heap::Init(IsolateGroup* isolate_group,
                bool is_vm_isolate,
                intptr_t max_new_gen_words,
                intptr_t max_old_gen_words) {
  ASSERT(isolate_group->heap() == nullptr);
  std::unique_ptr<Heap> heap(new Heap(isolate_group, is_vm_isolate,
                                      max_new_gen_words, max_old_gen_words));
  isolate_group->set_heap(std::move(heap));
}

const char* Heap::RegionName(Space space) {
  switch (space) {
    case kNew:
      return "dart-newspace";
    case kOld:
      return "dart-oldspace";
    case kCode:
      return "dart-codespace";
    default:
      UNREACHABLE();
  }
}

void Heap::AddRegionsToObjectSet(ObjectSet* set) const {
  new_space_.AddRegionsToObjectSet(set);
  old_space_.AddRegionsToObjectSet(set);
  set->SortRegions();
}

void Heap::CollectOnNthAllocation(intptr_t num_allocations) {
  // Prevent generated code from using the TLAB fast path on next allocation.
  new_space_.AbandonRemainingTLABForDebugging(Thread::Current());
  gc_on_nth_allocation_ = num_allocations;
}

void Heap::CollectForDebugging() {
  if (gc_on_nth_allocation_ == kNoForcedGarbageCollection) return;
  if (Thread::Current()->IsAtSafepoint()) {
    // CollectAllGarbage is not supported when we are at a safepoint.
    // Allocating when at a safepoint is not a common case.
    return;
  }
  gc_on_nth_allocation_--;
  if (gc_on_nth_allocation_ == 0) {
    CollectAllGarbage(GCReason::kDebugging);
    gc_on_nth_allocation_ = kNoForcedGarbageCollection;
  } else {
    // Prevent generated code from using the TLAB fast path on next allocation.
    new_space_.AbandonRemainingTLABForDebugging(Thread::Current());
  }
}

ObjectSet* Heap::CreateAllocatedObjectSet(Zone* zone,
                                          MarkExpectation mark_expectation) {
  ObjectSet* allocated_set = new (zone) ObjectSet(zone);

  this->AddRegionsToObjectSet(allocated_set);
  Isolate* vm_isolate = Dart::vm_isolate();
  vm_isolate->group()->heap()->AddRegionsToObjectSet(allocated_set);

  {
    VerifyObjectVisitor object_visitor(isolate_group(), allocated_set,
                                       mark_expectation);
    this->VisitObjectsNoImagePages(&object_visitor);
  }
  {
    VerifyObjectVisitor object_visitor(isolate_group(), allocated_set,
                                       kRequireMarked);
    this->VisitObjectsImagePages(&object_visitor);
  }
  {
    // VM isolate heap is premarked.
    VerifyObjectVisitor vm_object_visitor(isolate_group(), allocated_set,
                                          kRequireMarked);
    vm_isolate->group()->heap()->VisitObjects(&vm_object_visitor);
  }

  return allocated_set;
}

bool Heap::Verify(MarkExpectation mark_expectation) {
  if (FLAG_disable_heap_verification) {
    return true;
  }
  HeapIterationScope heap_iteration_scope(Thread::Current());
  return VerifyGC(mark_expectation);
}

bool Heap::VerifyGC(MarkExpectation mark_expectation) {
  auto thread = Thread::Current();
  StackZone stack_zone(thread);

  ObjectSet* allocated_set =
      CreateAllocatedObjectSet(stack_zone.GetZone(), mark_expectation);
  VerifyPointersVisitor visitor(isolate_group(), allocated_set);
  VisitObjectPointers(&visitor);

  // Only returning a value so that Heap::Validate can be called from an ASSERT.
  return true;
}

void Heap::PrintSizes() const {
  OS::PrintErr(
      "New space (%" Pd64 "k of %" Pd64
      "k) "
      "Old space (%" Pd64 "k of %" Pd64 "k)\n",
      (UsedInWords(kNew) / KBInWords), (CapacityInWords(kNew) / KBInWords),
      (UsedInWords(kOld) / KBInWords), (CapacityInWords(kOld) / KBInWords));
}

int64_t Heap::UsedInWords(Space space) const {
  return space == kNew ? new_space_.UsedInWords() : old_space_.UsedInWords();
}

int64_t Heap::CapacityInWords(Space space) const {
  return space == kNew ? new_space_.CapacityInWords()
                       : old_space_.CapacityInWords();
}

int64_t Heap::ExternalInWords(Space space) const {
  return space == kNew ? new_space_.ExternalInWords()
                       : old_space_.ExternalInWords();
}

int64_t Heap::TotalUsedInWords() const {
  return UsedInWords(kNew) + UsedInWords(kOld);
}

int64_t Heap::TotalCapacityInWords() const {
  return CapacityInWords(kNew) + CapacityInWords(kOld);
}

int64_t Heap::TotalExternalInWords() const {
  return ExternalInWords(kNew) + ExternalInWords(kOld);
}

int64_t Heap::GCTimeInMicros(Space space) const {
  if (space == kNew) {
    return new_space_.gc_time_micros();
  }
  return old_space_.gc_time_micros();
}

intptr_t Heap::Collections(Space space) const {
  if (space == kNew) {
    return new_space_.collections();
  }
  return old_space_.collections();
}

const char* Heap::GCTypeToString(GCType type) {
  switch (type) {
    case GCType::kScavenge:
      return "Scavenge";
    case GCType::kStartConcurrentMark:
      return "StartCMark";
    case GCType::kMarkSweep:
      return "MarkSweep";
    case GCType::kMarkCompact:
      return "MarkCompact";
    default:
      UNREACHABLE();
      return "";
  }
}

const char* Heap::GCReasonToString(GCReason gc_reason) {
  switch (gc_reason) {
    case GCReason::kNewSpace:
      return "new space";
    case GCReason::kStoreBuffer:
      return "store buffer";
    case GCReason::kPromotion:
      return "promotion";
    case GCReason::kOldSpace:
      return "old space";
    case GCReason::kFinalize:
      return "finalize";
    case GCReason::kFull:
      return "full";
    case GCReason::kExternal:
      return "external";
    case GCReason::kIdle:
      return "idle";
    case GCReason::kLowMemory:
      return "low memory";
    case GCReason::kDebugging:
      return "debugging";
    case GCReason::kSendAndExit:
      return "send_and_exit";
    default:
      UNREACHABLE();
      return "";
  }
}

int64_t Heap::PeerCount() const {
  return new_weak_tables_[kPeers]->count() + old_weak_tables_[kPeers]->count();
}

void Heap::ResetCanonicalHashTable() {
  new_weak_tables_[kCanonicalHashes]->Reset();
  old_weak_tables_[kCanonicalHashes]->Reset();
}

void Heap::ResetObjectIdTable() {
  new_weak_tables_[kObjectIds]->Reset();
  old_weak_tables_[kObjectIds]->Reset();
}

intptr_t Heap::GetWeakEntry(ObjectPtr raw_obj, WeakSelector sel) const {
  if (!raw_obj->IsSmiOrOldObject()) {
    return new_weak_tables_[sel]->GetValue(raw_obj);
  }
  ASSERT(raw_obj->IsSmiOrOldObject());
  return old_weak_tables_[sel]->GetValue(raw_obj);
}

void Heap::SetWeakEntry(ObjectPtr raw_obj, WeakSelector sel, intptr_t val) {
  if (!raw_obj->IsSmiOrOldObject()) {
    new_weak_tables_[sel]->SetValue(raw_obj, val);
  } else {
    ASSERT(raw_obj->IsSmiOrOldObject());
    old_weak_tables_[sel]->SetValue(raw_obj, val);
  }
}

intptr_t Heap::SetWeakEntryIfNonExistent(ObjectPtr raw_obj,
                                         WeakSelector sel,
                                         intptr_t val) {
  if (!raw_obj->IsSmiOrOldObject()) {
    return new_weak_tables_[sel]->SetValueIfNonExistent(raw_obj, val);
  } else {
    ASSERT(raw_obj->IsSmiOrOldObject());
    return old_weak_tables_[sel]->SetValueIfNonExistent(raw_obj, val);
  }
}

void Heap::ForwardWeakEntries(ObjectPtr before_object, ObjectPtr after_object) {
  const auto before_space =
      !before_object->IsSmiOrOldObject() ? Heap::kNew : Heap::kOld;
  const auto after_space =
      !after_object->IsSmiOrOldObject() ? Heap::kNew : Heap::kOld;

  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    const auto selector = static_cast<Heap::WeakSelector>(sel);
    auto before_table = GetWeakTable(before_space, selector);
    intptr_t entry = before_table->RemoveValueExclusive(before_object);
    if (entry != 0) {
      auto after_table = GetWeakTable(after_space, selector);
      after_table->SetValueExclusive(after_object, entry);
    }
  }

  isolate_group()->ForEachIsolate(
      [&](Isolate* isolate) {
        auto before_table = !before_object->IsSmiOrOldObject()
                                ? isolate->forward_table_new()
                                : isolate->forward_table_old();
        if (before_table != nullptr) {
          intptr_t entry = before_table->RemoveValueExclusive(before_object);
          if (entry != 0) {
            auto after_table = !after_object->IsSmiOrOldObject()
                                   ? isolate->forward_table_new()
                                   : isolate->forward_table_old();
            ASSERT(after_table != nullptr);
            after_table->SetValueExclusive(after_object, entry);
          }
        }
      },
      /*at_safepoint=*/true);
}

void Heap::ForwardWeakTables(ObjectPointerVisitor* visitor) {
  // NOTE: This method is only used by the compactor, so there is no need to
  // process the `Heap::kNew` tables.
  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    WeakSelector selector = static_cast<Heap::WeakSelector>(sel);
    GetWeakTable(Heap::kOld, selector)->Forward(visitor);
  }

  // Isolates might have forwarding tables (used for during snapshoting in
  // isolate communication).
  isolate_group()->ForEachIsolate(
      [&](Isolate* isolate) {
        auto table_old = isolate->forward_table_old();
        if (table_old != nullptr) table_old->Forward(visitor);
      },
      /*at_safepoint=*/true);
}

#ifndef PRODUCT
void Heap::PrintToJSONObject(Space space, JSONObject* object) const {
  if (space == kNew) {
    new_space_.PrintToJSONObject(object);
  } else {
    old_space_.PrintToJSONObject(object);
  }
}

void Heap::PrintMemoryUsageJSON(JSONStream* stream) const {
  JSONObject obj(stream);
  PrintMemoryUsageJSON(&obj);
}

void Heap::PrintMemoryUsageJSON(JSONObject* jsobj) const {
  jsobj->AddProperty("type", "MemoryUsage");
  jsobj->AddProperty64("heapUsage", TotalUsedInWords() * kWordSize);
  jsobj->AddProperty64("heapCapacity", TotalCapacityInWords() * kWordSize);
  jsobj->AddProperty64("externalUsage", TotalExternalInWords() * kWordSize);
}
#endif  // PRODUCT

void Heap::RecordBeforeGC(GCType type, GCReason reason) {
  stats_.num_++;
  stats_.type_ = type;
  stats_.reason_ = reason;
  stats_.before_.micros_ = OS::GetCurrentMonotonicMicros();
  stats_.before_.new_ = new_space_.GetCurrentUsage();
  stats_.before_.old_ = old_space_.GetCurrentUsage();
  for (int i = 0; i < GCStats::kTimeEntries; i++)
    stats_.times_[i] = 0;
}

static double AvgCollectionPeriod(int64_t run_time, intptr_t collections) {
  if (collections <= 0 || run_time <= 0) {
    return 0.0;
  }
  return MicrosecondsToMilliseconds(run_time) /
         static_cast<double>(collections);
}

void Heap::RecordAfterGC(GCType type) {
  stats_.after_.micros_ = OS::GetCurrentMonotonicMicros();
  int64_t delta = stats_.after_.micros_ - stats_.before_.micros_;
  if (stats_.type_ == GCType::kScavenge) {
    new_space_.AddGCTime(delta);
    new_space_.IncrementCollections();
  } else {
    old_space_.AddGCTime(delta);
    old_space_.IncrementCollections();
  }
  stats_.after_.new_ = new_space_.GetCurrentUsage();
  stats_.after_.old_ = old_space_.GetCurrentUsage();
#ifndef PRODUCT
  // For now we'll emit the same GC events on all isolates.
  if (Service::gc_stream.enabled()) {
    isolate_group_->ForEachIsolate(
        [&](Isolate* isolate) {
          if (!Isolate::IsSystemIsolate(isolate)) {
            ServiceEvent event(isolate, ServiceEvent::kGC);
            event.set_gc_stats(&stats_);
            Service::HandleEvent(&event, /*enter_safepoint*/ false);
          }
        },
        /*at_safepoint=*/true);
  }
#endif  // !PRODUCT
  if (Dart::gc_event_callback() != nullptr) {
    isolate_group_->ForEachIsolate(
        [&](Isolate* isolate) {
          if (!Isolate::IsSystemIsolate(isolate)) {
            Dart_GCEvent event;
            auto isolate_id = Utils::CStringUniquePtr(
                OS::SCreate(nullptr, ISOLATE_SERVICE_ID_FORMAT_STRING,
                            isolate->main_port()),
                std::free);
            int64_t isolate_uptime_micros = isolate->UptimeMicros();

            event.isolate_id = isolate_id.get();
            event.type = GCTypeToString(stats_.type_);
            event.reason = GCReasonToString(stats_.reason_);

            // New space - Scavenger.
            {
              intptr_t new_space_collections = new_space_.collections();

              event.new_space.collections = new_space_collections;
              event.new_space.used =
                  stats_.after_.new_.used_in_words * kWordSize;
              event.new_space.capacity =
                  stats_.after_.new_.capacity_in_words * kWordSize;
              event.new_space.external =
                  stats_.after_.new_.external_in_words * kWordSize;
              event.new_space.time =
                  MicrosecondsToSeconds(new_space_.gc_time_micros());
              event.new_space.avg_collection_period = AvgCollectionPeriod(
                  isolate_uptime_micros, new_space_collections);
            }

            // Old space - Page.
            {
              intptr_t old_space_collections = old_space_.collections();

              event.old_space.collections = old_space_collections;
              event.old_space.used =
                  stats_.after_.old_.used_in_words * kWordSize;
              event.old_space.capacity =
                  stats_.after_.old_.capacity_in_words * kWordSize;
              event.old_space.external =
                  stats_.after_.old_.external_in_words * kWordSize;
              event.old_space.time =
                  MicrosecondsToSeconds(old_space_.gc_time_micros());
              event.old_space.avg_collection_period = AvgCollectionPeriod(
                  isolate_uptime_micros, old_space_collections);
            }

            (*Dart::gc_event_callback())(&event);
          }
        },
        /*at_safepoint=*/true);
  }
}

void Heap::PrintStats() {
#if !defined(PRODUCT)
  if (!FLAG_verbose_gc) return;

  if ((FLAG_verbose_gc_hdr != 0) &&
      (((stats_.num_ - 1) % FLAG_verbose_gc_hdr) == 0)) {
    OS::PrintErr(
        "[              |                          |     |       |      "
        "| new gen     | new gen     | new gen "
        "| old gen       | old gen       | old gen     "
        "| sweep | safe- | roots/| stbuf/| tospc/| weaks/  ]\n"
        "[ GC isolate   | space (reason)           | GC# | start | time "
        "| used (MB)   | capacity MB | external"
        "| used (MB)     | capacity (MB) | external MB "
        "| thread| point |marking| reset | sweep |swplrge  ]\n"
        "[              |                          |     |  (s)  | (ms) "
        "|before| after|before| after| b4 |aftr"
        "| before| after | before| after |before| after"
        "| (ms)  | (ms)  | (ms)  | (ms)  | (ms)  | (ms)    ]\n");
  }

  // clang-format off
  OS::PrintErr(
    "[ %-13.13s, %11s(%12s), "  // GC(isolate-group), type(reason)
    "%4" Pd ", "  // count
    "%6.2f, "  // start time
    "%5.1f, "  // total time
    "%5.1f, %5.1f, "  // new gen: in use before/after
    "%5.1f, %5.1f, "   // new gen: capacity before/after
    "%3.1f, %3.1f, "   // new gen: external before/after
    "%6.1f, %6.1f, "   // old gen: in use before/after
    "%6.1f, %6.1f, "   // old gen: capacity before/after
    "%5.1f, %5.1f, "   // old gen: external before/after
    "%6.2f, %6.2f, %6.2f, %6.2f, %6.2f, %6.2f, "  // times
    "]\n",  // End with a comma to make it easier to import in spreadsheets.
    isolate_group()->source()->name,
    GCTypeToString(stats_.type_),
    GCReasonToString(stats_.reason_),
    stats_.num_,
    MicrosecondsToSeconds(isolate_group_->UptimeMicros()),
    MicrosecondsToMilliseconds(stats_.after_.micros_ -
                               stats_.before_.micros_),
    WordsToMB(stats_.before_.new_.used_in_words),
    WordsToMB(stats_.after_.new_.used_in_words),
    WordsToMB(stats_.before_.new_.capacity_in_words),
    WordsToMB(stats_.after_.new_.capacity_in_words),
    WordsToMB(stats_.before_.new_.external_in_words),
    WordsToMB(stats_.after_.new_.external_in_words),
    WordsToMB(stats_.before_.old_.used_in_words),
    WordsToMB(stats_.after_.old_.used_in_words),
    WordsToMB(stats_.before_.old_.capacity_in_words),
    WordsToMB(stats_.after_.old_.capacity_in_words),
    WordsToMB(stats_.before_.old_.external_in_words),
    WordsToMB(stats_.after_.old_.external_in_words),
    MicrosecondsToMilliseconds(stats_.times_[0]),
    MicrosecondsToMilliseconds(stats_.times_[1]),
    MicrosecondsToMilliseconds(stats_.times_[2]),
    MicrosecondsToMilliseconds(stats_.times_[3]),
    MicrosecondsToMilliseconds(stats_.times_[4]),
    MicrosecondsToMilliseconds(stats_.times_[5]));
  // clang-format on
#endif  // !defined(PRODUCT)
}

void Heap::PrintStatsToTimeline(TimelineEventScope* event, GCReason reason) {
#if defined(SUPPORT_TIMELINE)
  if ((event == NULL) || !event->enabled()) {
    return;
  }
  intptr_t arguments = event->GetNumArguments();
  event->SetNumArguments(arguments + 13);
  event->CopyArgument(arguments + 0, "Reason", GCReasonToString(reason));
  event->FormatArgument(arguments + 1, "Before.New.Used (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.before_.new_.used_in_words));
  event->FormatArgument(arguments + 2, "After.New.Used (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.after_.new_.used_in_words));
  event->FormatArgument(arguments + 3, "Before.Old.Used (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.before_.old_.used_in_words));
  event->FormatArgument(arguments + 4, "After.Old.Used (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.after_.old_.used_in_words));

  event->FormatArgument(arguments + 5, "Before.New.Capacity (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.before_.new_.capacity_in_words));
  event->FormatArgument(arguments + 6, "After.New.Capacity (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.after_.new_.capacity_in_words));
  event->FormatArgument(arguments + 7, "Before.Old.Capacity (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.before_.old_.capacity_in_words));
  event->FormatArgument(arguments + 8, "After.Old.Capacity (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.after_.old_.capacity_in_words));

  event->FormatArgument(arguments + 9, "Before.New.External (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.before_.new_.external_in_words));
  event->FormatArgument(arguments + 10, "After.New.External (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.after_.new_.external_in_words));
  event->FormatArgument(arguments + 11, "Before.Old.External (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.before_.old_.external_in_words));
  event->FormatArgument(arguments + 12, "After.Old.External (kB)", "%" Pd "",
                        RoundWordsToKB(stats_.after_.old_.external_in_words));
#endif  // defined(SUPPORT_TIMELINE)
}

Heap::Space Heap::SpaceForExternal(intptr_t size) const {
  // If 'size' would be a significant fraction of new space, then use old.
  static const int kExtNewRatio = 16;
  if (size > (CapacityInWords(Heap::kNew) * kWordSize) / kExtNewRatio) {
    return Heap::kOld;
  } else {
    return Heap::kNew;
  }
}

NoHeapGrowthControlScope::NoHeapGrowthControlScope()
    : ThreadStackResource(Thread::Current()) {
  Heap* heap = isolate_group()->heap();
  current_growth_controller_state_ = heap->GrowthControlState();
  heap->DisableGrowthControl();
}

NoHeapGrowthControlScope::~NoHeapGrowthControlScope() {
  Heap* heap = isolate_group()->heap();
  heap->SetGrowthControlState(current_growth_controller_state_);
}

WritableVMIsolateScope::WritableVMIsolateScope(Thread* thread)
    : ThreadStackResource(thread) {
  if (FLAG_write_protect_code && FLAG_write_protect_vm_isolate) {
    Dart::vm_isolate_group()->heap()->WriteProtect(false);
  }
}

WritableVMIsolateScope::~WritableVMIsolateScope() {
  ASSERT(Dart::vm_isolate_group()->heap()->UsedInWords(Heap::kNew) == 0);
  if (FLAG_write_protect_code && FLAG_write_protect_vm_isolate) {
    Dart::vm_isolate_group()->heap()->WriteProtect(true);
  }
}

WritableCodePages::WritableCodePages(Thread* thread,
                                     IsolateGroup* isolate_group)
    : StackResource(thread), isolate_group_(isolate_group) {
  isolate_group_->heap()->WriteProtectCode(false);
}

WritableCodePages::~WritableCodePages() {
  isolate_group_->heap()->WriteProtectCode(true);
}

}  // namespace dart
