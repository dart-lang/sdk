// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/incremental_compactor.h"

#include "platform/assert.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/heap/become.h"
#include "vm/heap/freelist.h"
#include "vm/heap/heap.h"
#include "vm/heap/pages.h"
#include "vm/log.h"
#include "vm/thread_barrier.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

void GCIncrementalCompactor::Prologue(PageSpace* old_space) {
  ASSERT(Thread::Current()->OwnsGCSafepoint());
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "StartIncrementalCompact");
  if (!SelectEvacuationCandidates(old_space)) {
    return;
  }
  CheckFreeLists(old_space);
}

bool GCIncrementalCompactor::Epilogue(PageSpace* old_space) {
  ASSERT(Thread::Current()->OwnsGCSafepoint());
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "FinishIncrementalCompact");
  if (!HasEvacuationCandidates(old_space)) {
    return false;
  }
  old_space->MakeIterable();
  CheckFreeLists(old_space);
  CheckPreEvacuate(old_space);
  Evacuate(old_space);
  CheckPostEvacuate(old_space);
  CheckFreeLists(old_space);
  FreeEvacuatedPages(old_space);
  VerifyAfterIncrementalCompaction(old_space);
  return true;
}

void GCIncrementalCompactor::Abort(PageSpace* old_space) {
  ASSERT(Thread::Current()->OwnsGCSafepoint());
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "AbortIncrementalCompact");

  {
    MonitorLocker ml(old_space->tasks_lock());
    switch (old_space->phase()) {
      case PageSpace::kDone:
        return;  // No incremental compact in progress.
      case PageSpace::kSweepingRegular:
      case PageSpace::kSweepingLarge:
        // No incremental compact in progress, the page list is incomplete, and
        // accessing page->next is a data race.
        return;
      case PageSpace::kMarking:
      case PageSpace::kAwaitingFinalization:
        break;  // Incremental compact may be in progress.
      default:
        UNREACHABLE();
    }
  }

  old_space->PauseConcurrentMarking();

  for (Page* page = old_space->pages_; page != nullptr; page = page->next()) {
    if (!page->is_evacuation_candidate()) continue;

    page->set_evacuation_candidate(false);

    uword start = page->object_start();
    uword end = page->object_end();
    uword current = start;
    while (current < end) {
      ObjectPtr obj = UntaggedObject::FromAddr(current);
      obj->untag()->ClearIsEvacuationCandidateUnsynchronized();
      current += obj->untag()->HeapSize();
    }
  }

  old_space->ResumeConcurrentMarking();
}

struct LiveBytes {
  Page* page;
  intptr_t live_bytes;
};

struct PrologueState {
  MallocGrowableArray<LiveBytes> pages;
  RelaxedAtomic<intptr_t> page_cursor;
  intptr_t page_limit;
  RelaxedAtomic<intptr_t> freelist_cursor;
  intptr_t freelist_limit;
};

class PrologueTask : public ThreadPool::Task {
 public:
  PrologueTask(ThreadBarrier* barrier,
               IsolateGroup* isolate_group,
               PageSpace* old_space,
               PrologueState* state)
      : barrier_(barrier),
        isolate_group_(isolate_group),
        old_space_(old_space),
        state_(state) {}

  void Run() {
    if (!barrier_->TryEnter()) {
      barrier_->Release();
      return;
    }

    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kIncrementalCompactorTask,
        /*bypass_safepoint=*/true);
    ASSERT(result);

    RunEnteredIsolateGroup();

    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

    barrier_->Sync();
    barrier_->Release();
  }

  void RunEnteredIsolateGroup() {
    MarkEvacuationCandidates();
    PruneFreeLists();
  }

  void MarkEvacuationCandidates() {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                  "MarkEvacuationCandidates");
    for (;;) {
      intptr_t page_index = state_->page_cursor.fetch_add(1);
      if (page_index >= state_->page_limit) break;
      Page* page = state_->pages[page_index].page;

      // Already set, otherwise a barrier would be needed before moving onto
      // freelists.
      ASSERT(page->is_evacuation_candidate());

      uword start = page->object_start();
      uword end = page->object_end();
      uword current = start;
      while (current < end) {
        ObjectPtr obj = UntaggedObject::FromAddr(current);
        intptr_t cid = obj->untag()->GetClassId();
        if (cid != kFreeListElement && cid != kForwardingCorpse) {
          obj->untag()->SetIsEvacuationCandidateUnsynchronized();
        }
        current += obj->untag()->HeapSize();
      }
    }
  }

  void PruneFreeLists() {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "PruneFreeLists");
    for (;;) {
      intptr_t chunk = state_->freelist_cursor.fetch_add(1);
      if (chunk >= state_->freelist_limit) break;
      intptr_t list_index = chunk / (FreeList::kNumLists + 1);
      intptr_t size_class_index = chunk % (FreeList::kNumLists + 1);
      FreeList* freelist = &old_space_->freelists_[list_index];

      // Empty bump-region, no need to prune this.
      ASSERT(freelist->top_ == freelist->end_);

      FreeListElement* current = freelist->free_lists_[size_class_index];
      freelist->free_lists_[size_class_index] = nullptr;
      while (current != nullptr) {
        FreeListElement* next = current->next();
        if (!Page::Of(current)->is_evacuation_candidate()) {
          current->set_next(freelist->free_lists_[size_class_index]);
          freelist->free_lists_[size_class_index] = current;
        }
        current = next;
      }
    }
  }

 private:
  ThreadBarrier* barrier_;
  IsolateGroup* isolate_group_;
  PageSpace* old_space_;
  PrologueState* state_;

  DISALLOW_COPY_AND_ASSIGN(PrologueTask);
};

bool GCIncrementalCompactor::SelectEvacuationCandidates(PageSpace* old_space) {
  // Only evacuate pages that are at least half empty.
  constexpr intptr_t kEvacuationThreshold = kPageSize / 2;

  // Evacuate no more than this amount of objects. This puts a bound on the
  // stop-the-world evacuate step that is similar to the existing longest
  // stop-the-world step of the scavenger.
  const intptr_t kMaxEvacuatedBytes =
      (old_space->heap_->new_space()->ThresholdInWords() << kWordSizeLog2) / 4;

  PrologueState state;
  {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                  "SelectEvacuationCandidates");
    for (Page* page = old_space->pages_; page != nullptr; page = page->next()) {
      if (page->is_never_evacuate()) continue;

      intptr_t live_bytes = page->live_bytes();
      if (live_bytes > kEvacuationThreshold) continue;

      state.pages.Add({page, live_bytes});
    }
    state.pages.Sort([](const LiveBytes* a, const LiveBytes* b) -> int {
      if (a->live_bytes < b->live_bytes) return -1;
      if (a->live_bytes > b->live_bytes) return 1;
      return 0;
    });

    intptr_t num_candidates = 0;
    intptr_t cumulative_live_bytes = 0;
    for (intptr_t i = 0; i < state.pages.length(); i++) {
      intptr_t live_bytes = state.pages[i].live_bytes;
      if (cumulative_live_bytes + live_bytes <= kMaxEvacuatedBytes) {
        num_candidates++;
        cumulative_live_bytes += live_bytes;
        state.pages[i].page->set_evacuation_candidate(true);
      }
    }

#if defined(SUPPORT_TIMELINE)
    tbes.SetNumArguments(2);
    tbes.FormatArgument(0, "cumulative_live_bytes", "%" Pd,
                        cumulative_live_bytes);
    tbes.FormatArgument(1, "num_candidates", "%" Pd, num_candidates);
#endif

    state.page_cursor = 0;
    state.page_limit = num_candidates;
    state.freelist_cursor =
        PageSpace::kDataFreelist * (FreeList::kNumLists + 1);
    state.freelist_limit =
        old_space->num_freelists_ * (FreeList::kNumLists + 1);

    if (num_candidates == 0) return false;
  }

  old_space->ReleaseBumpAllocation();

  IsolateGroup* isolate_group = IsolateGroup::Current();
  const intptr_t num_tasks =
      isolate_group->heap()->new_space()->NumScavengeWorkers();
  RELEASE_ASSERT(num_tasks > 0);
  ThreadBarrier* barrier = new ThreadBarrier(num_tasks, 1);
  for (intptr_t i = 0; i < num_tasks; i++) {
    if (i < (num_tasks - 1)) {
      // Begin compacting on a helper thread.
      bool result = Dart::thread_pool()->Run<PrologueTask>(
          barrier, isolate_group, old_space, &state);
      ASSERT(result);
    } else {
      // Last worker is the main thread.
      PrologueTask task(barrier, isolate_group, old_space, &state);
      task.RunEnteredIsolateGroup();
      barrier->Sync();
      barrier->Release();
    }
  }

  for (intptr_t i = PageSpace::kDataFreelist, n = old_space->num_freelists_;
       i < n; i++) {
    FreeList* freelist = &old_space->freelists_[i];
    ASSERT(freelist->top_ == freelist->end_);
    freelist->free_map_.Reset();
    for (intptr_t j = 0; j < FreeList::kNumLists; j++) {
      freelist->free_map_.Set(j, freelist->free_lists_[j] != nullptr);
    }
  }

  return true;
}

// Free lists should not contain any evacuation candidates.
void GCIncrementalCompactor::CheckFreeLists(PageSpace* old_space) {
#if defined(DEBUG)
  for (intptr_t i = 0, n = old_space->num_freelists_; i < n; i++) {
    FreeList* freelist = &old_space->freelists_[i];
    if (freelist->top_ < freelist->end_) {
      Page* page = Page::Of(freelist->top_);
      ASSERT(!page->is_evacuation_candidate());
    }
    for (intptr_t j = 0; j <= FreeList::kNumLists; j++) {
      FreeListElement* current = freelist->free_lists_[j];
      while (current != nullptr) {
        Page* page = Page::Of(reinterpret_cast<uword>(current));
        ASSERT(!page->is_evacuation_candidate());
        current = current->next();
      }
    }
  }
#endif
}

static void objcpy(void* dst, const void* src, size_t size) {
  uword* __restrict dst_cursor = reinterpret_cast<uword*>(dst);
  const uword* __restrict src_cursor = reinterpret_cast<const uword*>(src);
  do {
    uword a = *src_cursor++;
    uword b = *src_cursor++;
    *dst_cursor++ = a;
    *dst_cursor++ = b;
    size -= (2 * sizeof(uword));
  } while (size > 0);
}

bool GCIncrementalCompactor::HasEvacuationCandidates(PageSpace* old_space) {
  for (Page* page = old_space->pages_; page != nullptr; page = page->next()) {
    if (page->is_evacuation_candidate()) return true;
  }
  return false;
}

void GCIncrementalCompactor::CheckPreEvacuate(PageSpace* old_space) {
  if (!FLAG_verify_before_gc) return;

  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "CheckPreEvacuate");

  // Check evacuation candidate pages have evacuation candidate objects or free
  // space. I.e., we didn't allocate into it after selecting it as an evacuation
  // candidate.
  for (Page* page = old_space->pages_; page != nullptr; page = page->next()) {
    if (page->is_evacuation_candidate()) {
      uword start = page->object_start();
      uword end = page->object_end();
      uword current = start;
      while (current < end) {
        ObjectPtr obj = UntaggedObject::FromAddr(current);
        intptr_t size = obj->untag()->HeapSize();
        ASSERT(obj->untag()->IsEvacuationCandidate() ||
               obj->untag()->GetClassId() == kFreeListElement ||
               obj->untag()->GetClassId() == kForwardingCorpse);
        current += size;
      }
    }
  }

  // Check non-evac pages don't have evac candidates.
  for (Page* page = old_space->pages_; page != nullptr; page = page->next()) {
    if (!page->is_evacuation_candidate()) {
      uword start = page->object_start();
      uword end = page->object_end();
      uword current = start;
      while (current < end) {
        ObjectPtr obj = UntaggedObject::FromAddr(current);
        intptr_t size = obj->untag()->HeapSize();
        ASSERT(!obj->untag()->IsEvacuationCandidate());
        current += size;
      }
    }
  }
}

class IncrementalForwardingVisitor : public ObjectPointerVisitor,
                                     public PredicateObjectPointerVisitor,
                                     public ObjectVisitor,
                                     public HandleVisitor {
 public:
  explicit IncrementalForwardingVisitor(Thread* thread)
      : ObjectPointerVisitor(thread->isolate_group()), HandleVisitor(thread) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->untag()->IsMarked()) {
      obj->untag()->VisitPointers(this);
    }
  }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    PredicateVisitPointers(first, last);
  }
  bool PredicateVisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    bool has_new_target = false;
    for (ObjectPtr* ptr = first; ptr <= last; ptr++) {
      ObjectPtr target = *ptr;
      if (target->IsImmediateObject()) continue;
      if (target->IsNewObject()) {
        has_new_target = true;
        continue;
      }

      if (target->IsForwardingCorpse()) {
        ASSERT(!target->untag()->IsMarked());
        ASSERT(!target->untag()->IsEvacuationCandidate());
        uword addr = UntaggedObject::ToAddr(target);
        ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
        *ptr = forwarder->target();
      } else {
        ASSERT(target->untag()->IsMarked());
        ASSERT(!target->untag()->IsEvacuationCandidate());
      }
    }
    return has_new_target;
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    PredicateVisitCompressedPointers(heap_base, first, last);
  }
  bool PredicateVisitCompressedPointers(uword heap_base,
                                        CompressedObjectPtr* first,
                                        CompressedObjectPtr* last) override {
    bool has_new_target = false;
    for (CompressedObjectPtr* ptr = first; ptr <= last; ptr++) {
      ObjectPtr target = ptr->Decompress(heap_base);
      if (target->IsImmediateObject()) continue;
      if (target->IsNewObject()) {
        has_new_target = true;
        continue;
      }

      if (target->IsForwardingCorpse()) {
        ASSERT(!target->untag()->IsMarked());
        ASSERT(!target->untag()->IsEvacuationCandidate());
        uword addr = UntaggedObject::ToAddr(target);
        ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
        *ptr = forwarder->target();
      } else {
        ASSERT(target->untag()->IsMarked());
        ASSERT(!target->untag()->IsEvacuationCandidate());
      }
    }
    return has_new_target;
  }
#endif

  void VisitHandle(uword addr) override {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    ObjectPtr target = handle->ptr();
    if (target->IsHeapObject() && target->IsForwardingCorpse()) {
      uword addr = UntaggedObject::ToAddr(target);
      ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
      *handle->ptr_addr() = forwarder->target();
    }
  }

  void VisitTypedDataViewPointers(TypedDataViewPtr view,
                                  CompressedObjectPtr* first,
                                  CompressedObjectPtr* last) override {
    ObjectPtr old_backing = view->untag()->typed_data();
    VisitCompressedPointers(view->heap_base(), first, last);
    ObjectPtr new_backing = view->untag()->typed_data();

    const bool backing_moved = old_backing != new_backing;
    if (backing_moved) {
      typed_data_views_.Add(view);
    }
  }

  bool CanVisitSuspendStatePointers(SuspendStatePtr suspend_state) override {
    if ((suspend_state->untag()->pc() != 0) && !can_visit_stack_frames_) {
      // Visiting pointers of SuspendState objects with copied stack frame
      // needs to query stack map, which can touch other Dart objects
      // (such as GrowableObjectArray of InstructionsTable).
      // Those objects may have an inconsistent state during compaction,
      // so processing of SuspendState objects is postponed to the later
      // stage of compaction.
      suspend_states_.Add(suspend_state);
      return false;
    }
    return true;
  }

  void UpdateViews() {
    const intptr_t length = typed_data_views_.length();
    for (intptr_t i = 0; i < length; ++i) {
      auto raw_view = typed_data_views_[i];
      const classid_t cid = raw_view->untag()->typed_data()->GetClassId();
      // If we have external typed data we can simply return, since the backing
      // store lives in C-heap and will not move. Otherwise we have to update
      // the inner pointer.
      if (IsTypedDataClassId(cid)) {
        raw_view->untag()->RecomputeDataFieldForInternalTypedData();
      } else {
        ASSERT(IsExternalTypedDataClassId(cid));
      }
    }
  }

  void UpdateSuspendStates() {
    can_visit_stack_frames_ = true;
    const intptr_t length = suspend_states_.length();
    for (intptr_t i = 0; i < length; ++i) {
      auto suspend_state = suspend_states_[i];
      suspend_state->untag()->VisitPointers(this);
    }
  }

 private:
  bool can_visit_stack_frames_ = false;
  MallocGrowableArray<TypedDataViewPtr> typed_data_views_;
  MallocGrowableArray<SuspendStatePtr> suspend_states_;

  DISALLOW_COPY_AND_ASSIGN(IncrementalForwardingVisitor);
};

class StoreBufferForwardingVisitor : public ObjectPointerVisitor {
 public:
  StoreBufferForwardingVisitor(IsolateGroup* isolate_group,
                               IncrementalForwardingVisitor* visitor)
      : ObjectPointerVisitor(isolate_group), visitor_(visitor) {}

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    for (ObjectPtr* ptr = first; ptr <= last; ptr++) {
      ObjectPtr obj = *ptr;
      ASSERT(!obj->IsImmediateOrNewObject());

      if (obj->IsForwardingCorpse()) {
        ASSERT(!obj->untag()->IsMarked());
        ASSERT(!obj->untag()->IsEvacuationCandidate());
        uword addr = UntaggedObject::ToAddr(obj);
        ForwardingCorpse* forwarder = reinterpret_cast<ForwardingCorpse*>(addr);
        obj = forwarder->target();
        *ptr = obj;
      } else {
        ASSERT(obj->untag()->IsMarked());
        ASSERT(!obj->untag()->IsEvacuationCandidate());
      }

      visitor_->VisitObject(obj);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    UNREACHABLE();  // Store buffer blocks are not compressed.
  }
#endif

 private:
  IncrementalForwardingVisitor* visitor_;

  DISALLOW_COPY_AND_ASSIGN(StoreBufferForwardingVisitor);
};

class EpilogueState {
 public:
  EpilogueState(Page* evac_page,
                StoreBufferBlock* block,
                Page* new_page,
                Mutex* pages_lock)
      : evac_page_(evac_page),
        block_(block),
        new_page_(new_page),
        pages_lock_(pages_lock) {}

  bool NextEvacPage(Page** page) {
    // Needs to be the old_space pages lock since evacuation may also allocate
    // new pages and race with page->next_.
    MutexLocker ml(pages_lock_);
    while (evac_page_ != nullptr) {
      Page* current = evac_page_;
      evac_page_ = current->next();
      if (current->is_evacuation_candidate()) {
        *page = current;
        return true;
      }
    }
    return false;
  }

  bool NextBlock(StoreBufferBlock** block) {
    MutexLocker ml(pages_lock_);
    if (block_ != nullptr) {
      StoreBufferBlock* current = block_;
      block_ = current->next();
      current->set_next(nullptr);
      *block = current;
      return true;
    }
    return false;
  }

  bool NextNewPage(Page** page) {
    MutexLocker ml(pages_lock_);
    if (new_page_ != nullptr) {
      Page* current = new_page_;
      new_page_ = current->next();
      *page = current;
      return true;
    }
    return false;
  }

  bool TakeOOM() { return oom_slice_.exchange(false); }
  bool TakeWeakHandles() { return weak_handles_slice_.exchange(false); }
  bool TakeWeakTables() { return weak_tables_slice_.exchange(false); }
  bool TakeIdRing() { return id_ring_slice_.exchange(false); }
  bool TakeRoots() { return roots_slice_.exchange(false); }
  bool TakeResetProgressBars() {
    return reset_progress_bars_slice_.exchange(false);
  }

  void AddNewFreeSize(intptr_t size) { new_free_size_ += size; }
  intptr_t NewFreeSize() { return new_free_size_; }

 private:
  Page* evac_page_;
  StoreBufferBlock* block_;
  Page* new_page_;
  Mutex* pages_lock_;

  RelaxedAtomic<bool> oom_slice_ = {true};
  RelaxedAtomic<bool> weak_handles_slice_ = {true};
  RelaxedAtomic<bool> weak_tables_slice_ = {true};
  RelaxedAtomic<bool> id_ring_slice_ = {true};
  RelaxedAtomic<bool> roots_slice_ = {true};
  RelaxedAtomic<bool> reset_progress_bars_slice_ = {true};
  RelaxedAtomic<intptr_t> new_free_size_ = {0};
};

class EpilogueTask : public ThreadPool::Task {
 public:
  EpilogueTask(ThreadBarrier* barrier,
               IsolateGroup* isolate_group,
               PageSpace* old_space,
               FreeList* freelist,
               EpilogueState* state)
      : barrier_(barrier),
        isolate_group_(isolate_group),
        old_space_(old_space),
        freelist_(freelist),
        state_(state) {}

  void Run() {
    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kIncrementalCompactorTask,
        /*bypass_safepoint=*/true);
    ASSERT(result);

    RunEnteredIsolateGroup();

    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

    barrier_->Sync();
    barrier_->Release();
  }

  void RunEnteredIsolateGroup() {
    Thread* thread = Thread::Current();

    Evacuate();

    barrier_->Sync();

    IncrementalForwardingVisitor visitor(thread);
    if (state_->TakeOOM()) {
      old_space_->VisitRoots(&visitor);  // OOM reservation.
    }
    ForwardStoreBuffer(&visitor);
    ForwardRememberedCards(&visitor);
    ForwardNewSpace(&visitor);
    if (state_->TakeWeakHandles()) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "WeakPersistentHandles");
      isolate_group_->VisitWeakPersistentHandles(&visitor);
    }
    if (state_->TakeWeakTables()) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "WeakTables");
      isolate_group_->heap()->ForwardWeakTables(&visitor);
    }
#ifndef PRODUCT
    if (state_->TakeIdRing()) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "IdRing");
      isolate_group_->ForEachIsolate(
          [&](Isolate* isolate) {
            for (intptr_t i = 0; i < isolate->NumServiceIdZones(); ++i) {
              isolate->GetServiceIdZone(i)->VisitPointers(visitor);
            }
          },
          /*at_safepoint=*/true);
    }
#endif  // !PRODUCT

    barrier_->Sync();

    {
      // After forwarding the heap because visits each view's underyling buffer.
      TIMELINE_FUNCTION_GC_DURATION(thread, "Views");
      visitor.UpdateViews();
    }

    if (state_->TakeRoots()) {
      // After forwarding the heap because visiting the stack requires stackmaps
      // to already be forwarded.
      TIMELINE_FUNCTION_GC_DURATION(thread, "Roots");
      isolate_group_->VisitObjectPointers(
          &visitor, ValidationPolicy::kDontValidateFrames);
    }

    barrier_->Sync();

    {
      // After processing the object store because of the dependency on
      // canonicalized_stack_map_entries.
      TIMELINE_FUNCTION_GC_DURATION(thread, "SuspendStates");
      visitor.UpdateSuspendStates();
    }

    if (state_->TakeResetProgressBars()) {
      // After ForwardRememberedCards.
      old_space_->ResetProgressBars();
    }
  }

  void Evacuate() {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "Evacuate");

    old_space_->AcquireLock(freelist_);

    bool any_failed = false;
    intptr_t bytes_evacuated = 0;
    Page* page;
    while (state_->NextEvacPage(&page)) {
      ASSERT(page->is_evacuation_candidate());

      bool page_failed = false;
      uword start = page->object_start();
      uword end = page->object_end();
      uword current = start;
      while (current < end) {
        ObjectPtr obj = UntaggedObject::FromAddr(current);
        intptr_t size = obj->untag()->HeapSize();

        if (obj->untag()->IsMarked()) {
          uword copied = old_space_->TryAllocatePromoLocked(freelist_, size);
          if (copied == 0) {
            obj->untag()->ClearIsEvacuationCandidateUnsynchronized();
            page_failed = true;
            any_failed = true;
          } else {
            ASSERT(!Page::Of(copied)->is_evacuation_candidate());
            bytes_evacuated += size;
            objcpy(reinterpret_cast<void*>(copied),
                   reinterpret_cast<const void*>(current), size);
            ObjectPtr copied_obj = UntaggedObject::FromAddr(copied);

            copied_obj->untag()->ClearIsEvacuationCandidateUnsynchronized();
            if (IsTypedDataClassId(copied_obj->GetClassIdOfHeapObject())) {
              static_cast<TypedDataPtr>(copied_obj)
                  ->untag()
                  ->RecomputeDataField();
            }

            ForwardingCorpse::AsForwarder(current, size)
                ->set_target(copied_obj);
          }
        }

        current += size;
      }

      if (page_failed) {
        page->set_evacuation_candidate(false);
      }
    }

    old_space_->ReleaseLock(freelist_);
    old_space_->usage_.used_in_words -= (bytes_evacuated >> kWordSizeLog2);
#if defined(SUPPORT_TIMELINE)
    tbes.SetNumArguments(1);
    tbes.FormatArgument(0, "bytes_evacuated", "%" Pd, bytes_evacuated);
#endif

    if (any_failed) {
      OS::PrintErr("evacuation failed\n");
    }
  }

  void ForwardStoreBuffer(IncrementalForwardingVisitor* visitor) {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ForwardStoreBuffer");

    StoreBufferForwardingVisitor store_visitor(isolate_group_, visitor);
    StoreBuffer* store_buffer = isolate_group_->store_buffer();
    StoreBufferBlock* block;
    while (state_->NextBlock(&block)) {
      // Generated code appends to store buffers; tell MemorySanitizer.
      MSAN_UNPOISON(block, sizeof(*block));

      block->VisitObjectPointers(&store_visitor);

      store_buffer->PushBlock(block, StoreBuffer::kIgnoreThreshold);
    }
  }

  void ForwardRememberedCards(IncrementalForwardingVisitor* visitor) {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ForwardRememberedCards");
    for (Page* page = old_space_->large_pages_; page != nullptr;
         page = page->next()) {
      page->VisitRememberedCards(visitor, /*only_marked*/ true);
    }
  }

  void ForwardNewSpace(IncrementalForwardingVisitor* visitor) {
    TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ForwardNewSpace");
    Page* page;
    while (state_->NextNewPage(&page)) {
      intptr_t free = ForwardAndSweepNewPage(visitor, page);
      state_->AddNewFreeSize(free);
    }
  }

  DART_NOINLINE
  intptr_t ForwardAndSweepNewPage(IncrementalForwardingVisitor* visitor,
                                  Page* page) {
    ASSERT(!page->is_image());
    ASSERT(!page->is_old());
    ASSERT(!page->is_executable());

    uword start = page->object_start();
    uword end = page->object_end();
    uword current = start;
    intptr_t free = 0;
    while (current < end) {
      ObjectPtr raw_obj = UntaggedObject::FromAddr(current);
      ASSERT(Page::Of(raw_obj) == page);
      uword tags = raw_obj->untag()->tags();
      intptr_t obj_size = raw_obj->untag()->HeapSize(tags);
      if (UntaggedObject::IsMarked(tags)) {
        raw_obj->untag()->ClearMarkBitUnsynchronized();
        ASSERT(IsAllocatableInNewSpace(obj_size));
        raw_obj->untag()->VisitPointers(visitor);
      } else {
        uword free_end = current + obj_size;
        while (free_end < end) {
          ObjectPtr next_obj = UntaggedObject::FromAddr(free_end);
          tags = next_obj->untag()->tags();
          if (UntaggedObject::IsMarked(tags)) {
            // Reached the end of the free block.
            break;
          }
          // Expand the free block by the size of this object.
          free_end += next_obj->untag()->HeapSize(tags);
        }
        obj_size = free_end - current;
#if defined(DEBUG)
        memset(reinterpret_cast<void*>(current), Heap::kZapByte, obj_size);
#endif  // DEBUG
        FreeListElement::AsElementNew(current, obj_size);
        free += obj_size;
      }
      current += obj_size;
    }
    return free;
  }

 private:
  ThreadBarrier* barrier_;
  IsolateGroup* isolate_group_;
  PageSpace* old_space_;
  FreeList* freelist_;
  EpilogueState* state_;
};

void GCIncrementalCompactor::Evacuate(PageSpace* old_space) {
  IsolateGroup* isolate_group = IsolateGroup::Current();
  isolate_group->ReleaseStoreBuffers();
  EpilogueState state(
      old_space->pages_, isolate_group->store_buffer()->PopAll(),
      old_space->heap_->new_space()->head(), &old_space->pages_lock_);

  // This must use NumScavengeWorkers because that determines the number of
  // freelists available for workers.
  const intptr_t num_tasks =
      isolate_group->heap()->new_space()->NumScavengeWorkers();
  RELEASE_ASSERT(num_tasks > 0);
  ThreadBarrier* barrier = new ThreadBarrier(num_tasks, num_tasks);
  for (intptr_t i = 0; i < num_tasks; i++) {
    // Begin compacting on a helper thread.
    FreeList* freelist = old_space->DataFreeList(i);
    if (i < (num_tasks - 1)) {
      bool result = Dart::thread_pool()->Run<EpilogueTask>(
          barrier, isolate_group, old_space, freelist, &state);
      ASSERT(result);
    } else {
      // Last worker is the main thread.
      EpilogueTask task(barrier, isolate_group, old_space, freelist, &state);
      task.RunEnteredIsolateGroup();
      barrier->Sync();
      barrier->Release();
    }
  }

  old_space->heap_->new_space()->set_freed_in_words(state.NewFreeSize() >>
                                                    kWordSizeLog2);
}

void GCIncrementalCompactor::CheckPostEvacuate(PageSpace* old_space) {
  if (!FLAG_verify_after_gc) return;

  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "CheckPostEvacuate");

  // Check there are no remaining evac candidates
  for (Page* page = old_space->pages_; page != nullptr; page = page->next()) {
    uword start = page->object_start();
    uword end = page->object_end();
    uword current = start;
    while (current < end) {
      ObjectPtr obj = UntaggedObject::FromAddr(current);
      intptr_t size = obj->untag()->HeapSize();
      ASSERT(!obj->untag()->IsEvacuationCandidate() ||
             !obj->untag()->IsMarked());
      current += size;
    }
  }
}

void GCIncrementalCompactor::FreeEvacuatedPages(PageSpace* old_space) {
  Page* prev_page = nullptr;
  Page* page = old_space->pages_;
  while (page != nullptr) {
    Page* next_page = page->next();
    if (page->is_evacuation_candidate()) {
      old_space->FreePage(page, prev_page);
    } else {
      prev_page = page;
    }
    page = next_page;
  }
}

class VerifyAfterIncrementalCompactionVisitor : public ObjectVisitor,
                                                public ObjectPointerVisitor {
 public:
  VerifyAfterIncrementalCompactionVisitor()
      : ObjectVisitor(), ObjectPointerVisitor(IsolateGroup::Current()) {}

  void VisitObject(ObjectPtr obj) override {
    // New-space has been swept, but old-space has not.
    if (obj->IsNewObject()) {
      if (obj->untag()->GetClassId() != kFreeListElement) {
        current_ = obj;
        obj->untag()->VisitPointers(this);
      }
    } else {
      if (obj->untag()->IsMarked()) {
        current_ = obj;
        obj->untag()->VisitPointers(this);
      }
    }
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = *ptr;
      if (!obj->IsHeapObject()) continue;
      if (obj->IsForwardingCorpse() || obj->IsFreeListElement() ||
          (obj->IsOldObject() && !obj->untag()->IsMarked())) {
        OS::PrintErr("object=0x%" Px ", slot=0x%" Px ", value=0x%" Px "\n",
                     static_cast<uword>(current_), reinterpret_cast<uword>(ptr),
                     static_cast<uword>(obj));
        failed_ = true;
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = ptr->Decompress(heap_base);
      if (!obj->IsHeapObject()) continue;
      if (obj->IsForwardingCorpse() || obj->IsFreeListElement() ||
          (obj->IsOldObject() && !obj->untag()->IsMarked())) {
        OS::PrintErr("object=0x%" Px ", slot=0x%" Px ", value=0x%" Px "\n",
                     static_cast<uword>(current_), reinterpret_cast<uword>(ptr),
                     static_cast<uword>(obj));
        failed_ = true;
      }
    }
  }
#endif

  bool failed() const { return failed_; }

 private:
  ObjectPtr current_;
  bool failed_ = false;

  DISALLOW_COPY_AND_ASSIGN(VerifyAfterIncrementalCompactionVisitor);
};

void GCIncrementalCompactor::VerifyAfterIncrementalCompaction(
    PageSpace* old_space) {
  if (!FLAG_verify_after_gc) return;
  TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                "VerifyAfterIncrementalCompaction");
  VerifyAfterIncrementalCompactionVisitor visitor;
  old_space->heap_->VisitObjects(&visitor);
  if (visitor.failed()) {
    FATAL("verify after incremental compact");
  }
}

}  // namespace dart
