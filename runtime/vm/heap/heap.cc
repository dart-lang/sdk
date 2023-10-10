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
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  Dart_HeapSamplingDeleteCallback cleanup =
      HeapProfileSampler::delete_callback();
  if (cleanup != nullptr) {
    new_weak_tables_[kHeapSamplingData]->CleanupValues(cleanup);
    old_weak_tables_[kHeapSamplingData]->CleanupValues(cleanup);
  }
#endif

  for (int sel = 0; sel < kNumWeakSelectors; sel++) {
    delete new_weak_tables_[sel];
    delete old_weak_tables_[sel];
  }
}

uword Heap::AllocateNew(Thread* thread, intptr_t size) {
  ASSERT(thread->no_safepoint_scope_depth() == 0);
  CollectForDebugging(thread);
  uword addr = new_space_.TryAllocate(thread, size);
  if (LIKELY(addr != 0)) {
    return addr;
  }
  if (!assume_scavenge_will_fail_ && !thread->force_growth()) {
    GcSafepointOperationScope safepoint_operation(thread);

    // Another thread may have won the race to the safepoint and performed a GC
    // before this thread acquired the safepoint. Retry the allocation under the
    // safepoint to avoid back-to-back GC.
    addr = new_space_.TryAllocate(thread, size);
    if (addr != 0) {
      return addr;
    }

    CollectGarbage(thread, GCType::kScavenge, GCReason::kNewSpace);

    addr = new_space_.TryAllocate(thread, size);
    if (LIKELY(addr != 0)) {
      return addr;
    }
  }

  // It is possible a GC doesn't clear enough space.
  // In that case, we must fall through and allocate into old space.
  return AllocateOld(thread, size, /*exec*/ false);
}

uword Heap::AllocateOld(Thread* thread, intptr_t size, bool is_exec) {
  ASSERT(thread->no_safepoint_scope_depth() == 0);

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  if (HeapProfileSampler::enabled()) {
    thread->heap_sampler().SampleOldSpaceAllocation(size);
  }
#endif

  if (!thread->force_growth()) {
    CollectForDebugging(thread);
    uword addr = old_space_.TryAllocate(size, is_exec);
    if (addr != 0) {
      return addr;
    }
    // Wait for any GC tasks that are in progress.
    WaitForSweeperTasks(thread);
    addr = old_space_.TryAllocate(size, is_exec);
    if (addr != 0) {
      return addr;
    }
    GcSafepointOperationScope safepoint_operation(thread);
    // Another thread may have won the race to the safepoint and performed a GC
    // before this thread acquired the safepoint. Retry the allocation under the
    // safepoint to avoid back-to-back GC.
    addr = old_space_.TryAllocate(size, is_exec);
    if (addr != 0) {
      return addr;
    }
    // All GC tasks finished without allocating successfully. Collect both
    // generations.
    CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kOldSpace);
    addr = old_space_.TryAllocate(size, is_exec);
    if (addr != 0) {
      return addr;
    }
    // Wait for all of the concurrent tasks to finish before giving up.
    WaitForSweeperTasksAtSafepoint(thread);
    addr = old_space_.TryAllocate(size, is_exec);
    if (addr != 0) {
      return addr;
    }
    // Force growth before attempting another synchronous GC.
    addr = old_space_.TryAllocate(size, is_exec, PageSpace::kForceGrowth);
    if (addr != 0) {
      return addr;
    }
    // Before throwing an out-of-memory error try a synchronous GC.
    CollectOldSpaceGarbage(thread, GCType::kMarkCompact, GCReason::kOldSpace);
    WaitForSweeperTasksAtSafepoint(thread);
  }
  uword addr = old_space_.TryAllocate(size, is_exec, PageSpace::kForceGrowth);
  if (addr != 0) {
    return addr;
  }

  if (!thread->force_growth()) {
    WaitForSweeperTasks(thread);
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

bool Heap::AllocatedExternal(intptr_t size, Space space) {
  if (space == kNew) {
    if (!new_space_.AllocatedExternal(size)) {
      return false;
    }
  } else {
    ASSERT(space == kOld);
    if (!old_space_.AllocatedExternal(size)) {
      return false;
    }
  }

  Thread* thread = Thread::Current();
  if ((thread->no_callback_scope_depth() == 0) && !thread->force_growth()) {
    CheckExternalGC(thread);
  } else {
    // Check delayed until Dart_TypedDataRelease/~ForceGrowthScope.
  }
  return true;
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

void Heap::CheckExternalGC(Thread* thread) {
  ASSERT(thread->no_safepoint_scope_depth() == 0);
  ASSERT(thread->no_callback_scope_depth() == 0);
  ASSERT(!thread->force_growth());

  if (mode_ == Dart_PerformanceMode_Latency) {
    return;
  }

  if (new_space_.ExternalInWords() >= (4 * new_space_.CapacityInWords())) {
    // Attempt to free some external allocation by a scavenge. (If the total
    // remains above the limit, next external alloc will trigger another.)
    CollectGarbage(thread, GCType::kScavenge, GCReason::kExternal);
    // Promotion may have pushed old space over its limit. Fall through for old
    // space GC check.
  }

  if (old_space_.ReachedHardThreshold()) {
    CollectGarbage(thread, GCType::kMarkSweep, GCReason::kExternal);
  } else {
    CheckConcurrentMarking(thread, GCReason::kExternal, 0);
  }
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
  return old_space_.CodeContains(addr);
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
    ASSERT(old_space_->iterating_thread_ == nullptr);
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
    old_space_->iterating_thread_ = nullptr;
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
      CollectNewSpaceGarbage(thread, GCType::kScavenge, GCReason::kIdle);
    }

    // Check if we want to collect old-space, in decreasing order of cost.
    // Because we use a deadline instead of a timeout, we automatically take any
    // time used up by a scavenge into account when deciding if we can complete
    // a mark-sweep on time.
    if (old_space_.ShouldPerformIdleMarkCompact(deadline)) {
      // We prefer mark-compact over other old space GCs if we have enough time,
      // since it removes old space fragmentation and frees up most memory.
      // Blocks for O(heap), roughly twice as costly as mark-sweep.
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

  if (FLAG_mark_when_idle) {
    old_space_.IncrementalMarkWithTimeBudget(deadline);
  }

  if (OS::GetCurrentMonotonicMicros() < deadline) {
    Page::ClearCache();
  }
}

void Heap::NotifyDestroyed() {
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "NotifyDestroyed");
  CollectAllGarbage(GCReason::kDestroyed, /*compact=*/true);
  Page::ClearCache();
}

Dart_PerformanceMode Heap::SetMode(Dart_PerformanceMode new_mode) {
  Dart_PerformanceMode old_mode = mode_.exchange(new_mode);
  if ((old_mode == Dart_PerformanceMode_Latency) &&
      (new_mode == Dart_PerformanceMode_Default)) {
    CheckCatchUp(Thread::Current());
  }
  return old_mode;
}

void Heap::CollectNewSpaceGarbage(Thread* thread,
                                  GCType type,
                                  GCReason reason) {
  NoActiveIsolateScope no_active_isolate_scope(thread);
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
    RecordBeforeGC(type, reason);
    {
      VMTagScope tagScope(thread, reason == GCReason::kIdle
                                      ? VMTag::kGCIdleTagId
                                      : VMTag::kGCNewSpaceTagId);
      TIMELINE_FUNCTION_GC_DURATION(thread, "CollectNewGeneration");
      new_space_.Scavenge(thread, type, reason);
      RecordAfterGC(type);
      PrintStats();
#if defined(SUPPORT_TIMELINE)
      PrintStatsToTimeline(&tbes, reason);
#endif
    }
    if (type == GCType::kScavenge && reason == GCReason::kNewSpace) {
      if (old_space_.ReachedHardThreshold()) {
        CollectOldSpaceGarbage(thread, GCType::kMarkSweep,
                               GCReason::kPromotion);
      } else {
        CheckConcurrentMarking(thread, GCReason::kPromotion, 0);
      }
    }
  }
}

void Heap::CollectOldSpaceGarbage(Thread* thread,
                                  GCType type,
                                  GCReason reason) {
  NoActiveIsolateScope no_active_isolate_scope(thread);

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
    if (reason == GCReason::kFinalize) {
      MonitorLocker ml(old_space_.tasks_lock());
      if (old_space_.phase() != PageSpace::kAwaitingFinalization) {
        return;  // Lost race.
      }
    }

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
    old_space_.CollectGarbage(thread, /*compact=*/type == GCType::kMarkCompact,
                              /*finalize=*/true);
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
    assume_scavenge_will_fail_ = false;
  }
}

void Heap::CollectGarbage(Thread* thread, GCType type, GCReason reason) {
  switch (type) {
    case GCType::kScavenge:
    case GCType::kEvacuate:
      CollectNewSpaceGarbage(thread, type, reason);
      break;
    case GCType::kMarkSweep:
    case GCType::kMarkCompact:
      CollectOldSpaceGarbage(thread, type, reason);
      break;
    default:
      UNREACHABLE();
  }
}

void Heap::CollectAllGarbage(GCReason reason, bool compact) {
  Thread* thread = Thread::Current();
  if (thread->is_marking()) {
    // If incremental marking is happening, we need to finish the GC cycle
    // and perform a follow-up GC to purge any "floating garbage" that may be
    // retained by the incremental barrier.
    CollectOldSpaceGarbage(thread, GCType::kMarkSweep, reason);
  }
  CollectOldSpaceGarbage(
      thread, compact ? GCType::kMarkCompact : GCType::kMarkSweep, reason);
}

void Heap::CheckCatchUp(Thread* thread) {
  ASSERT(!thread->force_growth());
  if (old_space()->ReachedHardThreshold()) {
    CollectGarbage(thread, GCType::kMarkSweep, GCReason::kCatchUp);
  } else {
    CheckConcurrentMarking(thread, GCReason::kCatchUp, 0);
  }
}

void Heap::CheckConcurrentMarking(Thread* thread,
                                  GCReason reason,
                                  intptr_t size) {
  ASSERT(!thread->force_growth());

  PageSpace::Phase phase;
  {
    MonitorLocker ml(old_space_.tasks_lock());
    phase = old_space_.phase();
  }

  switch (phase) {
    case PageSpace::kMarking:
      if (mode_ != Dart_PerformanceMode_Latency) {
        old_space_.IncrementalMarkWithSizeBudget(size);
      }
      return;
    case PageSpace::kSweepingLarge:
    case PageSpace::kSweepingRegular:
      return;  // Busy.
    case PageSpace::kAwaitingFinalization:
      CollectOldSpaceGarbage(thread, GCType::kMarkSweep, GCReason::kFinalize);
      return;
    case PageSpace::kDone:
      if (old_space_.ReachedSoftThreshold()) {
        StartConcurrentMarking(thread, reason);
      }
      return;
    default:
      UNREACHABLE();
  }
}

void Heap::StartConcurrentMarking(Thread* thread, GCReason reason) {
  GcSafepointOperationScope safepoint_operation(thread);
  RecordBeforeGC(GCType::kStartConcurrentMark, reason);
  VMTagScope tagScope(thread, reason == GCReason::kIdle
                                  ? VMTag::kGCIdleTagId
                                  : VMTag::kGCOldSpaceTagId);
  TIMELINE_FUNCTION_GC_DURATION(thread, "StartConcurrentMarking");
  old_space_.CollectGarbage(thread, /*compact=*/false, /*finalize=*/false);
  RecordAfterGC(GCType::kStartConcurrentMark);
  PrintStats();
#if defined(SUPPORT_TIMELINE)
  PrintStatsToTimeline(&tbes, reason);
#endif
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
  ASSERT(!thread->OwnsGCSafepoint());
  MonitorLocker ml(old_space_.tasks_lock());
  while ((old_space_.phase() == PageSpace::kSweepingLarge) ||
         (old_space_.phase() == PageSpace::kSweepingRegular)) {
    ml.WaitWithSafepointCheck(thread);
  }
}

void Heap::WaitForSweeperTasksAtSafepoint(Thread* thread) {
  ASSERT(thread->OwnsGCSafepoint());
  MonitorLocker ml(old_space_.tasks_lock());
  while ((old_space_.phase() == PageSpace::kSweepingLarge) ||
         (old_space_.phase() == PageSpace::kSweepingRegular)) {
    ml.Wait();
  }
}

void Heap::UpdateGlobalMaxUsed() {
  ASSERT(isolate_group_ != nullptr);
  // We are accessing the used in words count for both new and old space
  // without synchronizing. The value of this metric is approximate.
  isolate_group_->GetHeapGlobalUsedMaxMetric()->SetValue(
      (UsedInWords(Heap::kNew) * kWordSize) +
      (UsedInWords(Heap::kOld) * kWordSize));
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

void Heap::CollectForDebugging(Thread* thread) {
  if (gc_on_nth_allocation_ == kNoForcedGarbageCollection) return;
  if (thread->OwnsGCSafepoint()) {
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
    new_space_.AbandonRemainingTLABForDebugging(thread);
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

bool Heap::Verify(const char* msg, MarkExpectation mark_expectation) {
  if (FLAG_disable_heap_verification) {
    return true;
  }
  HeapIterationScope heap_iteration_scope(Thread::Current());
  return VerifyGC(msg, mark_expectation);
}

bool Heap::VerifyGC(const char* msg, MarkExpectation mark_expectation) {
  ASSERT(msg != nullptr);
  auto thread = Thread::Current();
  StackZone stack_zone(thread);

  ObjectSet* allocated_set =
      CreateAllocatedObjectSet(stack_zone.GetZone(), mark_expectation);
  VerifyPointersVisitor visitor(isolate_group(), allocated_set, msg);
  VisitObjectPointers(&visitor);

  // Only returning a value so that Heap::Validate can be called from an ASSERT.
  return true;
}

void Heap::PrintSizes() const {
  OS::PrintErr(
      "New space (%" Pd "k of %" Pd "k) "
      "Old space (%" Pd "k of %" Pd "k)\n",
      (UsedInWords(kNew) / KBInWords), (CapacityInWords(kNew) / KBInWords),
      (UsedInWords(kOld) / KBInWords), (CapacityInWords(kOld) / KBInWords));
}

intptr_t Heap::UsedInWords(Space space) const {
  return space == kNew ? new_space_.UsedInWords() : old_space_.UsedInWords();
}

intptr_t Heap::CapacityInWords(Space space) const {
  return space == kNew ? new_space_.CapacityInWords()
                       : old_space_.CapacityInWords();
}

intptr_t Heap::ExternalInWords(Space space) const {
  return space == kNew ? new_space_.ExternalInWords()
                       : old_space_.ExternalInWords();
}

intptr_t Heap::TotalUsedInWords() const {
  return UsedInWords(kNew) + UsedInWords(kOld);
}

intptr_t Heap::TotalCapacityInWords() const {
  return CapacityInWords(kNew) + CapacityInWords(kOld);
}

intptr_t Heap::TotalExternalInWords() const {
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
    case GCType::kEvacuate:
      return "Evacuate";
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
    case GCReason::kDestroyed:
      return "destroyed";
    case GCReason::kDebugging:
      return "debugging";
    case GCReason::kCatchUp:
      return "catch-up";
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
  if (raw_obj->IsImmediateOrOldObject()) {
    return old_weak_tables_[sel]->GetValue(raw_obj);
  } else {
    return new_weak_tables_[sel]->GetValue(raw_obj);
  }
}

void Heap::SetWeakEntry(ObjectPtr raw_obj, WeakSelector sel, intptr_t val) {
  if (raw_obj->IsImmediateOrOldObject()) {
    old_weak_tables_[sel]->SetValue(raw_obj, val);
  } else {
    new_weak_tables_[sel]->SetValue(raw_obj, val);
  }
}

intptr_t Heap::SetWeakEntryIfNonExistent(ObjectPtr raw_obj,
                                         WeakSelector sel,
                                         intptr_t val) {
  if (raw_obj->IsImmediateOrOldObject()) {
    return old_weak_tables_[sel]->SetValueIfNonExistent(raw_obj, val);
  } else {
    return new_weak_tables_[sel]->SetValueIfNonExistent(raw_obj, val);
  }
}

void Heap::ForwardWeakEntries(ObjectPtr before_object, ObjectPtr after_object) {
  const auto before_space =
      before_object->IsImmediateOrOldObject() ? Heap::kOld : Heap::kNew;
  const auto after_space =
      after_object->IsImmediateOrOldObject() ? Heap::kOld : Heap::kNew;

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
        auto before_table = before_object->IsImmediateOrOldObject()
                                ? isolate->forward_table_old()
                                : isolate->forward_table_new();
        if (before_table != nullptr) {
          intptr_t entry = before_table->RemoveValueExclusive(before_object);
          if (entry != 0) {
            auto after_table = after_object->IsImmediateOrOldObject()
                                   ? isolate->forward_table_old()
                                   : isolate->forward_table_new();
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

  // Isolates might have forwarding tables (used for during snapshotting in
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
  stats_.before_.store_buffer_ = isolate_group_->store_buffer()->Size();
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
  stats_.after_.store_buffer_ = isolate_group_->store_buffer()->Size();
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
}

void Heap::PrintStats() {
  if (!FLAG_verbose_gc) return;

  if ((FLAG_verbose_gc_hdr != 0) &&
      (((stats_.num_ - 1) % FLAG_verbose_gc_hdr) == 0)) {
    OS::PrintErr(
        "[              |                          |     |       |      | new "
        "gen     | new gen     | new gen | old gen       | old gen       | old "
        "gen     |  store  | delta used   ]\n"
        "[ GC isolate   | space (reason)           | GC# | start | time | used "
        "(MB)   | capacity MB | external| used (MB)     | capacity (MB) | "
        "external MB |  buffer | new  | old   ]\n"
        "[              |                          |     |  (s)  | (ms) "
        "|before| after|before| after| b4 |aftr| before| after | before| after "
        "|before| after| b4 |aftr| (MB) | (MB)  ]\n");
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
    "%3" Pd ", %3" Pd ", "   // store buffer: before/after
    "%5.1f, %6.1f, "   // delta used: new gen/old gen
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
    stats_.before_.store_buffer_,
    stats_.after_.store_buffer_,
    WordsToMB(stats_.after_.new_.used_in_words -
              stats_.before_.new_.used_in_words),
    WordsToMB(stats_.after_.old_.used_in_words -
              stats_.before_.old_.used_in_words));
  // clang-format on
}

void Heap::PrintStatsToTimeline(TimelineEventScope* event, GCReason reason) {
#if defined(SUPPORT_TIMELINE)
  if ((event == nullptr) || !event->enabled()) {
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
  const int kExtNewRatio = 16;
  if (size > (new_space_.ThresholdInWords() * kWordSize) / kExtNewRatio) {
    return Heap::kOld;
  } else {
    return Heap::kNew;
  }
}

ForceGrowthScope::ForceGrowthScope(Thread* thread)
    : ThreadStackResource(thread) {
  thread->IncrementForceGrowthScopeDepth();
}

ForceGrowthScope::~ForceGrowthScope() {
  thread()->DecrementForceGrowthScopeDepth();
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
