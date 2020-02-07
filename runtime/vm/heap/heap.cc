// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/heap.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/flags.h"
#include "vm/heap/become.h"
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

Heap::Heap(Isolate* isolate,
           intptr_t max_new_gen_semi_words,
           intptr_t max_old_gen_words)
    : isolate_(isolate),
      new_space_(this, max_new_gen_semi_words),
      old_space_(this, max_old_gen_words),
      barrier_(),
      barrier_done_(),
      read_only_(false),
      gc_new_space_in_progress_(false),
      gc_old_space_in_progress_(false),
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

void Heap::MakeTLABIterable(Thread* thread) {
  uword start = thread->top();
  uword end = thread->end();
  ASSERT(end >= start);
  intptr_t size = end - start;
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  if (size >= kObjectAlignment) {
    // ForwardingCorpse(forwarding to default null) will work as filler.
    ForwardingCorpse::AsForwarder(start, size);
    ASSERT(RawObject::FromAddr(start)->HeapSize() == size);
  }
}

void Heap::AbandonRemainingTLAB(Thread* thread) {
  MakeTLABIterable(thread);
  thread->set_top(0);
  thread->set_end(0);
}

uword Heap::AllocateNew(intptr_t size) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() == 0);
  CollectForDebugging();
  Thread* thread = Thread::Current();
  uword addr = new_space_.TryAllocateInTLAB(thread, size);
  if (addr != 0) {
    return addr;
  }

  intptr_t tlab_size = GetTLABSize();
  if ((tlab_size > 0) && (size > tlab_size)) {
    return AllocateOld(size, HeapPage::kData);
  }

  AbandonRemainingTLAB(thread);
  if (tlab_size > 0) {
    uword tlab_top = new_space_.TryAllocateNewTLAB(thread, tlab_size);
    if (tlab_top != 0) {
      addr = new_space_.TryAllocateInTLAB(thread, size);
      if (addr != 0) {  // but "leftover" TLAB could end smaller than tlab_size
        return addr;
      }
      // Abandon "leftover" TLAB as well so we can start from scratch.
      AbandonRemainingTLAB(thread);
    }
  }

  ASSERT(!thread->HasActiveTLAB());

  // This call to CollectGarbage might end up "reusing" a collection spawned
  // from a different thread and will be racing to allocate the requested
  // memory with other threads being released after the collection.
  CollectGarbage(kNew);

  uword tlab_top = new_space_.TryAllocateNewTLAB(thread, tlab_size);
  if (tlab_top != 0) {
    addr = new_space_.TryAllocateInTLAB(thread, size);
    // It is possible a GC doesn't clear enough space.
    // In that case, we must fall through and allocate into old space.
    if (addr != 0) {
      return addr;
    }
  }
  return AllocateOld(size, HeapPage::kData);
}

uword Heap::AllocateOld(intptr_t size, HeapPage::PageType type) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() == 0);
  CollectForDebugging();
  uword addr = old_space_.TryAllocate(size, type);
  if (addr != 0) {
    return addr;
  }
  // If we are in the process of running a sweep, wait for the sweeper to free
  // memory.
  Thread* thread = Thread::Current();
  if (old_space_.GrowthControlState()) {
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
    CollectAllGarbage(kLowMemory);
    WaitForSweeperTasks(thread);
  }
  addr = old_space_.TryAllocate(size, type, PageSpace::kForceGrowth);
  if (addr != 0) {
    return addr;
  }
  // Give up allocating this object.
  OS::PrintErr("Exhausted heap space, trying to allocate %" Pd " bytes.\n",
               size);
  return 0;
}

void Heap::AllocateExternal(intptr_t cid, intptr_t size, Space space) {
  ASSERT(Thread::Current()->no_safepoint_scope_depth() == 0);
  if (space == kNew) {
    isolate()->AssertCurrentThreadIsMutator();
    new_space_.AllocateExternal(cid, size);
    if (new_space_.ExternalInWords() <= (4 * new_space_.CapacityInWords())) {
      return;
    }
    // Attempt to free some external allocation by a scavenge. (If the total
    // remains above the limit, next external alloc will trigger another.)
    CollectGarbage(kScavenge, kExternal);
    // Promotion may have pushed old space over its limit. Fall through for old
    // space GC check.
  } else {
    ASSERT(space == kOld);
    old_space_.AllocateExternal(cid, size);
  }

  if (old_space_.NeedsGarbageCollection()) {
    CollectGarbage(kMarkSweep, kExternal);
  } else {
    CheckStartConcurrentMarking(Thread::Current(), kExternal);
  }
}

void Heap::FreeExternal(intptr_t size, Space space) {
  if (space == kNew) {
    new_space_.FreeExternal(size);
  } else {
    ASSERT(space == kOld);
    old_space_.FreeExternal(size);
  }
}

void Heap::PromoteExternal(intptr_t cid, intptr_t size) {
  new_space_.FreeExternal(size);
  old_space_.PromoteExternal(cid, size);
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
  return old_space_.Contains(addr, HeapPage::kExecutable);
}

bool Heap::DataContains(uword addr) const {
  return old_space_.DataContains(addr);
}

void Heap::VisitObjects(ObjectVisitor* visitor) const {
  new_space_.VisitObjects(visitor);
  old_space_.VisitObjects(visitor);
}

void Heap::VisitObjectsNoImagePages(ObjectVisitor* visitor) const {
  new_space_.VisitObjects(visitor);
  old_space_.VisitObjectsNoImagePages(visitor);
}

void Heap::VisitObjectsImagePages(ObjectVisitor* visitor) const {
  old_space_.VisitObjectsImagePages(visitor);
}

HeapIterationScope::HeapIterationScope(Thread* thread, bool writable)
    : ThreadStackResource(thread),
      heap_(isolate()->heap()),
      old_space_(heap_->old_space()),
      writable_(writable) {
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
      if (old_space_->phase() == PageSpace::kAwaitingFinalization) {
        ml.Exit();
        heap_->CollectOldSpaceGarbage(thread, Heap::kMarkSweep,
                                      Heap::kFinalize);
        ml.Enter();
      }
      while (old_space_->tasks() > 0) {
        ml.WaitWithSafepointCheck(thread);
      }
    }
#if defined(DEBUG)
    ASSERT(old_space_->iterating_thread_ == NULL);
    old_space_->iterating_thread_ = thread;
#endif
    old_space_->set_tasks(1);
  }

  isolate()->safepoint_handler()->SafepointThreads(thread);

  if (writable_) {
    heap_->WriteProtectCode(false);
  }
}

HeapIterationScope::~HeapIterationScope() {
  if (writable_) {
    heap_->WriteProtectCode(true);
  }

  isolate()->safepoint_handler()->ResumeThreads(thread());

  MonitorLocker ml(old_space_->tasks_lock());
#if defined(DEBUG)
  ASSERT(old_space_->iterating_thread_ == thread());
  old_space_->iterating_thread_ = NULL;
#endif
  ASSERT(old_space_->tasks() == 1);
  old_space_->set_tasks(0);
  ml.NotifyAll();
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
  Dart::vm_isolate()->heap()->VisitObjects(visitor);
}

void HeapIterationScope::IterateObjectPointers(
    ObjectPointerVisitor* visitor,
    ValidationPolicy validate_frames) {
  isolate()->VisitObjectPointers(visitor, validate_frames);
}

void HeapIterationScope::IterateStackPointers(
    ObjectPointerVisitor* visitor,
    ValidationPolicy validate_frames) {
  isolate()->VisitStackPointers(visitor, validate_frames);
}

void Heap::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  new_space_.VisitObjectPointers(visitor);
  old_space_.VisitObjectPointers(visitor);
}

RawInstructions* Heap::FindObjectInCodeSpace(FindObjectVisitor* visitor) const {
  // Only executable pages can have RawInstructions objects.
  RawObject* raw_obj = old_space_.FindObject(visitor, HeapPage::kExecutable);
  ASSERT((raw_obj == Object::null()) ||
         (raw_obj->GetClassId() == kInstructionsCid));
  return reinterpret_cast<RawInstructions*>(raw_obj);
}

RawObject* Heap::FindOldObject(FindObjectVisitor* visitor) const {
  return old_space_.FindObject(visitor, HeapPage::kData);
}

RawObject* Heap::FindNewObject(FindObjectVisitor* visitor) const {
  return new_space_.FindObject(visitor);
}

RawObject* Heap::FindObject(FindObjectVisitor* visitor) const {
  // The visitor must not allocate from the heap.
  NoSafepointScope no_safepoint_scope;
  RawObject* raw_obj = FindNewObject(visitor);
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

bool Heap::BeginNewSpaceGC(Thread* thread) {
  MonitorLocker ml(&gc_in_progress_monitor_);
  bool start_gc_on_thread = true;
  while (gc_new_space_in_progress_ || gc_old_space_in_progress_) {
    start_gc_on_thread = !gc_new_space_in_progress_;
    ml.WaitWithSafepointCheck(thread);
  }
  if (start_gc_on_thread) {
    gc_new_space_in_progress_ = true;
    return true;
  }
  return false;
}

void Heap::EndNewSpaceGC() {
  MonitorLocker ml(&gc_in_progress_monitor_);
  ASSERT(gc_new_space_in_progress_);
  gc_new_space_in_progress_ = false;
  ml.NotifyAll();
}

bool Heap::BeginOldSpaceGC(Thread* thread) {
  MonitorLocker ml(&gc_in_progress_monitor_);
  bool start_gc_on_thread = true;
  while (gc_new_space_in_progress_ || gc_old_space_in_progress_) {
    start_gc_on_thread = !gc_old_space_in_progress_;
    ml.WaitWithSafepointCheck(thread);
  }
  if (start_gc_on_thread) {
    gc_old_space_in_progress_ = true;
    return true;
  }
  return false;
}

void Heap::EndOldSpaceGC() {
  MonitorLocker ml(&gc_in_progress_monitor_);
  ASSERT(gc_old_space_in_progress_);
  gc_old_space_in_progress_ = false;
  ml.NotifyAll();
}

void Heap::NotifyIdle(int64_t deadline) {
  Thread* thread = Thread::Current();
  if (new_space_.ShouldPerformIdleScavenge(deadline)) {
    TIMELINE_FUNCTION_GC_DURATION(thread, "IdleGC");
    CollectNewSpaceGarbage(thread, kIdle);
  }
  // Because we use a deadline instead of a timeout, we automatically take any
  // time used up by a scavenge into account when deciding if we can complete
  // a mark-sweep on time.
  if (old_space_.ShouldPerformIdleMarkCompact(deadline)) {
    TIMELINE_FUNCTION_GC_DURATION(thread, "IdleGC");
    CollectOldSpaceGarbage(thread, kMarkCompact, kIdle);
  } else if (old_space_.ShouldStartIdleMarkSweep(deadline)) {
    PageSpace::Phase phase;
    {
      MonitorLocker ml(old_space_.tasks_lock());
      phase = old_space_.phase();
    }
    if (phase == PageSpace::kAwaitingFinalization) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "IdleGC");
      CollectOldSpaceGarbage(thread, Heap::kMarkSweep, Heap::kFinalize);
    } else if (phase == PageSpace::kDone) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "IdleGC");
      StartConcurrentMarking(thread);
    }
  } else if (old_space_.NeedsGarbageCollection()) {
    // Even though the following GC may exceed our idle deadline, we need to
    // ensure than that promotions during idle scavenges do not lead to
    // unbounded growth of old space. If a program is allocating only in new
    // space and all scavenges happen during idle time, then NotifyIdle will be
    // the only place that checks the old space allocation limit.
    // Compare the tail end of Heap::CollectNewSpaceGarbage.
    CollectOldSpaceGarbage(thread, kMarkSweep, kIdle);  // Blocks for O(heap)
  } else {
    CheckStartConcurrentMarking(thread, kIdle);  // Blocks for up to O(roots)
  }
}

void Heap::NotifyLowMemory() {
  CollectMostGarbage(kLowMemory);
}

void Heap::EvacuateNewSpace(Thread* thread, GCReason reason) {
  ASSERT((reason != kOldSpace) && (reason != kPromotion));
  if (thread->isolate() == Dart::vm_isolate()) {
    // The vm isolate cannot safely collect garbage due to unvisited read-only
    // handles and slots bootstrapped with RAW_NULL. Ignore GC requests to
    // trigger a nice out-of-memory message instead of a crash in the middle of
    // visiting pointers.
    return;
  }
  if (BeginNewSpaceGC(thread)) {
    RecordBeforeGC(kScavenge, reason);
    VMTagScope tagScope(thread, reason == kIdle ? VMTag::kGCIdleTagId
                                                : VMTag::kGCNewSpaceTagId);
    TIMELINE_FUNCTION_GC_DURATION(thread, "EvacuateNewGeneration");
    new_space_.Evacuate();
    RecordAfterGC(kScavenge);
    PrintStats();
    NOT_IN_PRODUCT(PrintStatsToTimeline(&tbes, reason));
    EndNewSpaceGC();
  }
}

void Heap::CollectNewSpaceGarbage(Thread* thread, GCReason reason) {
  ASSERT((reason != kOldSpace) && (reason != kPromotion));
  if (thread->isolate() == Dart::vm_isolate()) {
    // The vm isolate cannot safely collect garbage due to unvisited read-only
    // handles and slots bootstrapped with RAW_NULL. Ignore GC requests to
    // trigger a nice out-of-memory message instead of a crash in the middle of
    // visiting pointers.
    return;
  }
  if (BeginNewSpaceGC(thread)) {
    RecordBeforeGC(kScavenge, reason);
    {
      VMTagScope tagScope(thread, reason == kIdle ? VMTag::kGCIdleTagId
                                                  : VMTag::kGCNewSpaceTagId);
      TIMELINE_FUNCTION_GC_DURATION_BASIC(thread, "CollectNewGeneration");
      new_space_.Scavenge();
      RecordAfterGC(kScavenge);
      PrintStats();
      NOT_IN_PRODUCT(PrintStatsToTimeline(&tbes, reason));
      EndNewSpaceGC();
    }
    if (reason == kNewSpace) {
      if (old_space_.NeedsGarbageCollection()) {
        CollectOldSpaceGarbage(thread, kMarkSweep, kPromotion);
      } else {
        CheckStartConcurrentMarking(thread, kPromotion);
      }
    }
  }
}

void Heap::CollectOldSpaceGarbage(Thread* thread,
                                  GCType type,
                                  GCReason reason) {
  ASSERT(reason != kNewSpace);
  ASSERT(type != kScavenge);
  if (FLAG_use_compactor) {
    type = kMarkCompact;
  }
  if (thread->isolate() == Dart::vm_isolate()) {
    // The vm isolate cannot safely collect garbage due to unvisited read-only
    // handles and slots bootstrapped with RAW_NULL. Ignore GC requests to
    // trigger a nice out-of-memory message instead of a crash in the middle of
    // visiting pointers.
    return;
  }
  if (BeginOldSpaceGC(thread)) {
    RecordBeforeGC(type, reason);
    VMTagScope tagScope(thread, reason == kIdle ? VMTag::kGCIdleTagId
                                                : VMTag::kGCOldSpaceTagId);
    TIMELINE_FUNCTION_GC_DURATION_BASIC(thread, "CollectOldGeneration");
    old_space_.CollectGarbage(type == kMarkCompact, true /* finish */);
    RecordAfterGC(type);
    PrintStats();
    NOT_IN_PRODUCT(PrintStatsToTimeline(&tbes, reason));
    // Some Code objects may have been collected so invalidate handler cache.
    thread->isolate()->handler_info_cache()->Clear();
    thread->isolate()->catch_entry_moves_cache()->Clear();
    EndOldSpaceGC();
  }
}

void Heap::CollectGarbage(GCType type, GCReason reason) {
  Thread* thread = Thread::Current();
  switch (type) {
    case kScavenge:
      CollectNewSpaceGarbage(thread, reason);
      break;
    case kMarkSweep:
    case kMarkCompact:
      CollectOldSpaceGarbage(thread, type, reason);
      break;
    default:
      UNREACHABLE();
  }
}

void Heap::CollectGarbage(Space space) {
  Thread* thread = Thread::Current();
  if (space == kOld) {
    CollectOldSpaceGarbage(thread, kMarkSweep, kOldSpace);
  } else {
    ASSERT(space == kNew);
    CollectNewSpaceGarbage(thread, kNewSpace);
  }
}

void Heap::CollectMostGarbage(GCReason reason) {
  Thread* thread = Thread::Current();
  CollectNewSpaceGarbage(thread, reason);
  CollectOldSpaceGarbage(
      thread, reason == kLowMemory ? kMarkCompact : kMarkSweep, reason);
}

void Heap::CollectAllGarbage(GCReason reason) {
  Thread* thread = Thread::Current();

  // New space is evacuated so this GC will collect all dead objects
  // kept alive by a cross-generational pointer.
  EvacuateNewSpace(thread, reason);
  if (thread->is_marking()) {
    // If incremental marking is happening, we need to finish the GC cycle
    // and perform a follow-up GC to pruge any "floating garbage" that may be
    // retained by the incremental barrier.
    CollectOldSpaceGarbage(thread, kMarkSweep, reason);
  }
  CollectOldSpaceGarbage(
      thread, reason == kLowMemory ? kMarkCompact : kMarkSweep, reason);
  WaitForSweeperTasks(thread);
}

void Heap::CheckStartConcurrentMarking(Thread* thread, GCReason reason) {
  {
    MonitorLocker ml(old_space_.tasks_lock());
    if (old_space_.phase() != PageSpace::kDone) {
      return;  // Busy.
    }
  }

  if (old_space_.AlmostNeedsGarbageCollection()) {
    StartConcurrentMarking(thread);
  }
}

void Heap::StartConcurrentMarking(Thread* thread) {
  if (BeginOldSpaceGC(thread)) {
    TIMELINE_FUNCTION_GC_DURATION_BASIC(thread, "StartConcurrentMarking");
    old_space_.CollectGarbage(/*compact=*/false, /*finalize=*/false);
    EndOldSpaceGC();
  }
}

void Heap::CheckFinishConcurrentMarking(Thread* thread) {
  bool ready;
  {
    MonitorLocker ml(old_space_.tasks_lock());
    ready = old_space_.phase() == PageSpace::kAwaitingFinalization;
  }
  if (ready) {
    CollectOldSpaceGarbage(thread, Heap::kMarkSweep, Heap::kFinalize);
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
      CollectOldSpaceGarbage(thread, Heap::kMarkSweep, Heap::kFinalize);
      ml.Enter();
    }
  }
}

void Heap::WaitForSweeperTasks(Thread* thread) {
  MonitorLocker ml(old_space_.tasks_lock());
  while (old_space_.tasks() > 0) {
    ml.WaitWithSafepointCheck(thread);
  }
}

void Heap::UpdateGlobalMaxUsed() {
#if !defined(PRODUCT)
  ASSERT(isolate_ != NULL);
  // We are accessing the used in words count for both new and old space
  // without synchronizing. The value of this metric is approximate.
  isolate_->GetHeapGlobalUsedMaxMetric()->SetValue(
      (UsedInWords(Heap::kNew) * kWordSize) +
      (UsedInWords(Heap::kOld) * kWordSize));
#endif  // !defined(PRODUCT)
}

void Heap::InitGrowthControl() {
  old_space_.InitGrowthControl();
}

void Heap::SetGrowthControlState(bool state) {
  old_space_.SetGrowthControlState(state);
}

bool Heap::GrowthControlState() {
  return old_space_.GrowthControlState();
}

void Heap::WriteProtect(bool read_only) {
  read_only_ = read_only;
  new_space_.WriteProtect(read_only);
  old_space_.WriteProtect(read_only);
}

void Heap::Init(Isolate* isolate,
                intptr_t max_new_gen_words,
                intptr_t max_old_gen_words) {
  ASSERT(isolate->heap() == NULL);
  Heap* heap = new Heap(isolate, max_new_gen_words, max_old_gen_words);
  isolate->set_heap(heap);
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
}

void Heap::CollectOnNthAllocation(intptr_t num_allocations) {
  // Prevent generated code from using the TLAB fast path on next allocation.
  AbandonRemainingTLAB(Thread::Current());
  gc_on_nth_allocation_ = num_allocations;
}

void Heap::CollectForDebugging() {
  if (gc_on_nth_allocation_ == kNoForcedGarbageCollection) return;
  gc_on_nth_allocation_--;
  if (gc_on_nth_allocation_ == 0) {
    CollectAllGarbage(kDebugging);
    gc_on_nth_allocation_ = kNoForcedGarbageCollection;
  } else {
    // Prevent generated code from using the TLAB fast path on next allocation.
    AbandonRemainingTLAB(Thread::Current());
  }
}

ObjectSet* Heap::CreateAllocatedObjectSet(
    Zone* zone,
    MarkExpectation mark_expectation) const {
  ObjectSet* allocated_set = new (zone) ObjectSet(zone);

  this->AddRegionsToObjectSet(allocated_set);
  {
    VerifyObjectVisitor object_visitor(isolate(), allocated_set,
                                       mark_expectation);
    this->VisitObjectsNoImagePages(&object_visitor);
  }
  {
    VerifyObjectVisitor object_visitor(isolate(), allocated_set,
                                       kRequireMarked);
    this->VisitObjectsImagePages(&object_visitor);
  }

  Isolate* vm_isolate = Dart::vm_isolate();
  vm_isolate->heap()->AddRegionsToObjectSet(allocated_set);
  {
    // VM isolate heap is premarked.
    VerifyObjectVisitor vm_object_visitor(isolate(), allocated_set,
                                          kRequireMarked);
    vm_isolate->heap()->VisitObjects(&vm_object_visitor);
  }

  return allocated_set;
}

bool Heap::Verify(MarkExpectation mark_expectation) const {
  HeapIterationScope heap_iteration_scope(Thread::Current());
  return VerifyGC(mark_expectation);
}

bool Heap::VerifyGC(MarkExpectation mark_expectation) const {
  StackZone stack_zone(Thread::Current());

  // Change the new space's top_ with the more up-to-date thread's view of top_
  new_space_.MakeNewSpaceIterable();

  ObjectSet* allocated_set =
      CreateAllocatedObjectSet(stack_zone.GetZone(), mark_expectation);
  VerifyPointersVisitor visitor(isolate(), allocated_set);
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
    case kScavenge:
      return "Scavenge";
    case kMarkSweep:
      return "MarkSweep";
    case kMarkCompact:
      return "MarkCompact";
    default:
      UNREACHABLE();
      return "";
  }
}

const char* Heap::GCReasonToString(GCReason gc_reason) {
  switch (gc_reason) {
    case kNewSpace:
      return "new space";
    case kPromotion:
      return "promotion";
    case kOldSpace:
      return "old space";
    case kFinalize:
      return "finalize";
    case kFull:
      return "full";
    case kExternal:
      return "external";
    case kIdle:
      return "idle";
    case kLowMemory:
      return "low memory";
    case kDebugging:
      return "debugging";
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

intptr_t Heap::GetWeakEntry(RawObject* raw_obj, WeakSelector sel) const {
  if (raw_obj->IsNewObject()) {
    return new_weak_tables_[sel]->GetValue(raw_obj);
  }
  ASSERT(raw_obj->IsOldObject());
  return old_weak_tables_[sel]->GetValue(raw_obj);
}

void Heap::SetWeakEntry(RawObject* raw_obj, WeakSelector sel, intptr_t val) {
  if (raw_obj->IsNewObject()) {
    new_weak_tables_[sel]->SetValue(raw_obj, val);
  } else {
    ASSERT(raw_obj->IsOldObject());
    old_weak_tables_[sel]->SetValue(raw_obj, val);
  }
}

void Heap::ForwardWeakEntries(RawObject* before_object,
                              RawObject* after_object) {
  const auto before_space =
      before_object->IsNewObject() ? Heap::kNew : Heap::kOld;
  const auto after_space =
      after_object->IsNewObject() ? Heap::kNew : Heap::kOld;

  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    const auto selector = static_cast<Heap::WeakSelector>(sel);
    auto before_table = GetWeakTable(before_space, selector);
    intptr_t entry = before_table->RemoveValueExclusive(before_object);
    if (entry != 0) {
      auto after_table = GetWeakTable(after_space, selector);
      after_table->SetValueExclusive(after_object, entry);
    }
  }

  // We only come here during hot reload, in which case we assume that none of
  // the isolates is in the middle of sending messages.
  RELEASE_ASSERT(isolate()->forward_table_new() == nullptr);
  RELEASE_ASSERT(isolate()->forward_table_old() == nullptr);
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
  auto table_old = isolate()->forward_table_old();
  if (table_old != nullptr) table_old->Forward(visitor);
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
  ASSERT((type == kScavenge && gc_new_space_in_progress_) ||
         (type == kMarkSweep && gc_old_space_in_progress_) ||
         (type == kMarkCompact && gc_old_space_in_progress_));
  stats_.num_++;
  stats_.type_ = type;
  stats_.reason_ = reason;
  stats_.before_.micros_ = OS::GetCurrentMonotonicMicros();
  stats_.before_.new_ = new_space_.GetCurrentUsage();
  stats_.before_.old_ = old_space_.GetCurrentUsage();
  for (int i = 0; i < GCStats::kTimeEntries; i++)
    stats_.times_[i] = 0;
  for (int i = 0; i < GCStats::kDataEntries; i++)
    stats_.data_[i] = 0;
}

void Heap::RecordAfterGC(GCType type) {
  stats_.after_.micros_ = OS::GetCurrentMonotonicMicros();
  int64_t delta = stats_.after_.micros_ - stats_.before_.micros_;
  if (stats_.type_ == kScavenge) {
    new_space_.AddGCTime(delta);
    new_space_.IncrementCollections();
  } else {
    old_space_.AddGCTime(delta);
    old_space_.IncrementCollections();
  }
  stats_.after_.new_ = new_space_.GetCurrentUsage();
  stats_.after_.old_ = old_space_.GetCurrentUsage();
  ASSERT((type == kScavenge && gc_new_space_in_progress_) ||
         (type == kMarkSweep && gc_old_space_in_progress_) ||
         (type == kMarkCompact && gc_old_space_in_progress_));
#ifndef PRODUCT
  if (Service::gc_stream.enabled() &&
      !Isolate::IsVMInternalIsolate(isolate())) {
    ServiceEvent event(isolate(), ServiceEvent::kGC);
    event.set_gc_stats(&stats_);
    Service::HandleEvent(&event);
  }
#endif  // !PRODUCT
}

void Heap::PrintStats() {
#if !defined(PRODUCT)
  if (!FLAG_verbose_gc) return;

  if ((FLAG_verbose_gc_hdr != 0) &&
      (((stats_.num_ - 1) % FLAG_verbose_gc_hdr) == 0)) {
    OS::PrintErr(
        "[              |                      |     |       |      "
        "| new gen     | new gen     | new gen "
        "| old gen       | old gen       | old gen     "
        "| sweep | safe- | roots/| stbuf/| tospc/| weaks/|               ]\n"
        "[ GC isolate   | space (reason)       | GC# | start | time "
        "| used (kB)   | capacity kB | external"
        "| used (kB)     | capacity (kB) | external kB "
        "| thread| point |marking| reset | sweep |swplrge| data          ]\n"
        "[              |                      |     |  (s)  | (ms) "
        "|before| after|before| after| b4 |aftr"
        "| before| after | before| after |before| after"
        "| (ms)  | (ms)  | (ms)  | (ms)  | (ms)  | (ms)  |               ]\n");
  }

  // clang-format off
  OS::PrintErr(
    "[ %-13.13s, %10s(%9s), "  // GC(isolate), type(reason)
    "%4" Pd ", "  // count
    "%6.2f, "  // start time
    "%5.1f, "  // total time
    "%5" Pd ", %5" Pd ", "  // new gen: in use before/after
    "%5" Pd ", %5" Pd ", "  // new gen: capacity before/after
    "%3" Pd ", %3" Pd ", "  // new gen: external before/after
    "%6" Pd ", %6" Pd ", "  // old gen: in use before/after
    "%6" Pd ", %6" Pd ", "  // old gen: capacity before/after
    "%5" Pd ", %5" Pd ", "  // old gen: external before/after
    "%6.2f, %6.2f, %6.2f, %6.2f, %6.2f, %6.2f, "  // times
    "%" Pd ", %" Pd ", %" Pd ", %" Pd ", "  // data
    "]\n",  // End with a comma to make it easier to import in spreadsheets.
    isolate()->name(),
    GCTypeToString(stats_.type_),
    GCReasonToString(stats_.reason_),
    stats_.num_,
    MicrosecondsToSeconds(isolate()->UptimeMicros()),
    MicrosecondsToMilliseconds(stats_.after_.micros_ -
                               stats_.before_.micros_),
    RoundWordsToKB(stats_.before_.new_.used_in_words),
    RoundWordsToKB(stats_.after_.new_.used_in_words),
    RoundWordsToKB(stats_.before_.new_.capacity_in_words),
    RoundWordsToKB(stats_.after_.new_.capacity_in_words),
    RoundWordsToKB(stats_.before_.new_.external_in_words),
    RoundWordsToKB(stats_.after_.new_.external_in_words),
    RoundWordsToKB(stats_.before_.old_.used_in_words),
    RoundWordsToKB(stats_.after_.old_.used_in_words),
    RoundWordsToKB(stats_.before_.old_.capacity_in_words),
    RoundWordsToKB(stats_.after_.old_.capacity_in_words),
    RoundWordsToKB(stats_.before_.old_.external_in_words),
    RoundWordsToKB(stats_.after_.old_.external_in_words),
    MicrosecondsToMilliseconds(stats_.times_[0]),
    MicrosecondsToMilliseconds(stats_.times_[1]),
    MicrosecondsToMilliseconds(stats_.times_[2]),
    MicrosecondsToMilliseconds(stats_.times_[3]),
    MicrosecondsToMilliseconds(stats_.times_[4]),
    MicrosecondsToMilliseconds(stats_.times_[5]),
    stats_.data_[0],
    stats_.data_[1],
    stats_.data_[2],
    stats_.data_[3]);
  // clang-format on
#endif  // !defined(PRODUCT)
}

void Heap::PrintStatsToTimeline(TimelineEventScope* event, GCReason reason) {
#if !defined(PRODUCT)
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
#endif  // !defined(PRODUCT)
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
  Heap* heap = isolate()->heap();
  current_growth_controller_state_ = heap->GrowthControlState();
  heap->DisableGrowthControl();
}

NoHeapGrowthControlScope::~NoHeapGrowthControlScope() {
  Heap* heap = isolate()->heap();
  heap->SetGrowthControlState(current_growth_controller_state_);
}

WritableVMIsolateScope::WritableVMIsolateScope(Thread* thread)
    : ThreadStackResource(thread) {
  if (FLAG_write_protect_code && FLAG_write_protect_vm_isolate) {
    Dart::vm_isolate()->heap()->WriteProtect(false);
  }
}

WritableVMIsolateScope::~WritableVMIsolateScope() {
  ASSERT(Dart::vm_isolate()->heap()->UsedInWords(Heap::kNew) == 0);
  if (FLAG_write_protect_code && FLAG_write_protect_vm_isolate) {
    Dart::vm_isolate()->heap()->WriteProtect(true);
  }
}

WritableCodePages::WritableCodePages(Thread* thread, Isolate* isolate)
    : StackResource(thread), isolate_(isolate) {
  isolate_->heap()->WriteProtectCode(false);
}

WritableCodePages::~WritableCodePages() {
  isolate_->heap()->WriteProtectCode(true);
}

}  // namespace dart
