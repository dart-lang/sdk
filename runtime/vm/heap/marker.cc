// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/marker.h"

#include "platform/atomic.h"
#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/heap/pages.h"
#include "vm/heap/pointer_block.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/object_id_ring.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/thread_barrier.h"
#include "vm/thread_pool.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

template <bool sync>
class MarkingVisitorBase : public ObjectPointerVisitor {
 public:
  MarkingVisitorBase(IsolateGroup* isolate_group,
                     PageSpace* page_space,
                     MarkingStack* marking_stack,
                     MarkingStack* deferred_marking_stack)
      : ObjectPointerVisitor(isolate_group),
        thread_(Thread::Current()),
        page_space_(page_space),
        work_list_(marking_stack),
        deferred_work_list_(deferred_marking_stack),
        delayed_weak_properties_(WeakProperty::null()),
        marked_bytes_(0),
        marked_micros_(0) {
    ASSERT(thread_->isolate_group() == isolate_group);
  }
  ~MarkingVisitorBase() {}

  uintptr_t marked_bytes() const { return marked_bytes_; }
  int64_t marked_micros() const { return marked_micros_; }
  void AddMicros(int64_t micros) { marked_micros_ += micros; }

  bool ProcessPendingWeakProperties() {
    bool marked = false;
    WeakPropertyPtr cur_weak = delayed_weak_properties_;
    delayed_weak_properties_ = WeakProperty::null();
    while (cur_weak != WeakProperty::null()) {
      WeakPropertyPtr next_weak = cur_weak->ptr()->next_;
      ObjectPtr raw_key = cur_weak->ptr()->key_;
      // Reset the next pointer in the weak property.
      cur_weak->ptr()->next_ = WeakProperty::null();
      if (raw_key->ptr()->IsMarked()) {
        ObjectPtr raw_val = cur_weak->ptr()->value_;
        marked =
            marked || (raw_val->IsHeapObject() && !raw_val->ptr()->IsMarked());

        // The key is marked so we make sure to properly visit all pointers
        // originating from this weak property.
        cur_weak->ptr()->VisitPointersNonvirtual(this);
      } else {
        // Requeue this weak property to be handled later.
        EnqueueWeakProperty(cur_weak);
      }
      // Advance to next weak property in the queue.
      cur_weak = next_weak;
    }
    return marked;
  }

  void DrainMarkingStack() {
    ObjectPtr raw_obj = work_list_.Pop();
    if ((raw_obj == nullptr) && ProcessPendingWeakProperties()) {
      raw_obj = work_list_.Pop();
    }

    if (raw_obj == nullptr) {
      return;
    }

    do {
      do {
        // First drain the marking stacks.
        const intptr_t class_id = raw_obj->GetClassId();

        intptr_t size;
        if (class_id != kWeakPropertyCid) {
          size = raw_obj->ptr()->VisitPointersNonvirtual(this);
        } else {
          WeakPropertyPtr raw_weak = static_cast<WeakPropertyPtr>(raw_obj);
          size = ProcessWeakProperty(raw_weak, /* did_mark */ true);
        }
        marked_bytes_ += size;

        raw_obj = work_list_.Pop();
      } while (raw_obj != nullptr);

      // Marking stack is empty.
      ProcessPendingWeakProperties();

      // Check whether any further work was pushed either by other markers or
      // by the handling of weak properties.
      raw_obj = work_list_.Pop();
    } while (raw_obj != nullptr);
  }

  // Races: The concurrent marker is racing with the mutator, but this race is
  // harmless. The concurrent marker will only visit objects that were created
  // before the marker started. It will ignore all new-space objects based on
  // pointer alignment, and it will ignore old-space objects created after the
  // marker started because old-space objects allocated while marking is in
  // progress are allocated black (mark bit set). When visiting object slots,
  // the marker can see either the value it had when marking started (because
  // spawning the marker task creates acq-rel ordering) or any value later
  // stored into that slot. Because pointer slots always contain pointers (i.e.,
  // we don't do any in-place unboxing like V8), any value we read from the slot
  // is safe.
  NO_SANITIZE_THREAD
  ObjectPtr LoadPointerIgnoreRace(ObjectPtr* ptr) { return *ptr; }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
    for (ObjectPtr* current = first; current <= last; current++) {
      MarkObject(LoadPointerIgnoreRace(current));
    }
  }

  void EnqueueWeakProperty(WeakPropertyPtr raw_weak) {
    ASSERT(raw_weak->IsHeapObject());
    ASSERT(raw_weak->IsOldObject());
    ASSERT(raw_weak->IsWeakProperty());
    ASSERT(raw_weak->ptr()->IsMarked());
    ASSERT(raw_weak->ptr()->next_ == WeakProperty::null());
    raw_weak->ptr()->next_ = delayed_weak_properties_;
    delayed_weak_properties_ = raw_weak;
  }

  intptr_t ProcessWeakProperty(WeakPropertyPtr raw_weak, bool did_mark) {
    // The fate of the weak property is determined by its key.
    ObjectPtr raw_key = LoadPointerIgnoreRace(&raw_weak->ptr()->key_);
    if (raw_key->IsHeapObject() && raw_key->IsOldObject() &&
        !raw_key->ptr()->IsMarked()) {
      // Key was white. Enqueue the weak property.
      if (did_mark) {
        EnqueueWeakProperty(raw_weak);
      }
      return raw_weak->ptr()->HeapSize();
    }
    // Key is gray or black. Make the weak property black.
    return raw_weak->ptr()->VisitPointersNonvirtual(this);
  }

  void ProcessDeferredMarking() {
    ObjectPtr raw_obj;
    while ((raw_obj = deferred_work_list_.Pop()) != nullptr) {
      ASSERT(raw_obj->IsHeapObject() && raw_obj->IsOldObject());
      // N.B. We are scanning the object even if it is already marked.
      bool did_mark = TryAcquireMarkBit(raw_obj);
      const intptr_t class_id = raw_obj->GetClassId();
      intptr_t size;
      if (class_id != kWeakPropertyCid) {
        size = raw_obj->ptr()->VisitPointersNonvirtual(this);
      } else {
        WeakPropertyPtr raw_weak = static_cast<WeakPropertyPtr>(raw_obj);
        size = ProcessWeakProperty(raw_weak, did_mark);
      }
      // Add the size only if we win the marking race to prevent
      // double-counting.
      if (did_mark) {
        marked_bytes_ += size;
      }
    }
  }

  void FinalizeDeferredMarking() {
    ProcessDeferredMarking();
    deferred_work_list_.Finalize();
  }

  // Called when all marking is complete.
  void Finalize() {
    work_list_.Finalize();
    // Clear pending weak properties.
    WeakPropertyPtr cur_weak = delayed_weak_properties_;
    delayed_weak_properties_ = WeakProperty::null();
    intptr_t weak_properties_cleared = 0;
    while (cur_weak != WeakProperty::null()) {
      WeakPropertyPtr next_weak = cur_weak->ptr()->next_;
      cur_weak->ptr()->next_ = WeakProperty::null();
      RELEASE_ASSERT(!cur_weak->ptr()->key_->ptr()->IsMarked());
      WeakProperty::Clear(cur_weak);
      weak_properties_cleared++;
      // Advance to next weak property in the queue.
      cur_weak = next_weak;
    }
  }

  void AbandonWork() {
    work_list_.AbandonWork();
    deferred_work_list_.AbandonWork();
  }

 private:
  void PushMarked(ObjectPtr raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT(raw_obj->IsOldObject());

    // Push the marked object on the marking stack.
    ASSERT(raw_obj->ptr()->IsMarked());
    work_list_.Push(raw_obj);
  }

  static bool TryAcquireMarkBit(ObjectPtr raw_obj) {
    if (FLAG_write_protect_code && raw_obj->IsInstructions()) {
      // A non-writable alias mapping may exist for instruction pages.
      raw_obj = OldPage::ToWritable(raw_obj);
    }
    if (!sync) {
      raw_obj->ptr()->SetMarkBitUnsynchronized();
      return true;
    } else {
      return raw_obj->ptr()->TryAcquireMarkBit();
    }
  }

  DART_FORCE_INLINE
  void MarkObject(ObjectPtr raw_obj) {
    // Fast exit if the raw object is immediate or in new space. No memory
    // access.
    if (raw_obj->IsSmiOrNewObject()) {
      return;
    }

    // While it might seem this is redundant with TryAcquireMarkBit, we must
    // do this check first to avoid attempting an atomic::fetch_and on the
    // read-only vm-isolate or image pages, which can fault even if there is no
    // change in the value.
    // Doing this before checking for an Instructions object avoids
    // unnecessary queueing of pre-marked objects.
    // Race: The concurrent marker may observe a pointer into a heap page that
    // was allocated after the concurrent marker started. It can read either a
    // zero or the header of an object allocated black, both of which appear
    // marked.
    if (raw_obj->ptr()->IsMarkedIgnoreRace()) {
      return;
    }

    intptr_t class_id = raw_obj->GetClassId();
    ASSERT(class_id != kFreeListElement);

    if (sync && UNLIKELY(class_id == kInstructionsCid)) {
      // If this is the concurrent marker, this object may be non-writable due
      // to W^X (--write-protect-code).
      deferred_work_list_.Push(raw_obj);
      return;
    }

    if (!TryAcquireMarkBit(raw_obj)) {
      // Already marked.
      return;
    }

    PushMarked(raw_obj);
  }

  Thread* thread_;
  PageSpace* page_space_;
  MarkerWorkList work_list_;
  MarkerWorkList deferred_work_list_;
  WeakPropertyPtr delayed_weak_properties_;
  uintptr_t marked_bytes_;
  int64_t marked_micros_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitorBase);
};

typedef MarkingVisitorBase<false> UnsyncMarkingVisitor;
typedef MarkingVisitorBase<true> SyncMarkingVisitor;

static bool IsUnreachable(const ObjectPtr raw_obj) {
  if (!raw_obj->IsHeapObject()) {
    return false;
  }
  if (raw_obj == Object::null()) {
    return true;
  }
  if (!raw_obj->IsOldObject()) {
    return false;
  }
  return !raw_obj->ptr()->IsMarked();
}

class MarkingWeakVisitor : public HandleVisitor {
 public:
  explicit MarkingWeakVisitor(Thread* thread)
      : HandleVisitor(thread),
        class_table_(thread->isolate_group()->shared_class_table()) {}

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    ObjectPtr raw_obj = handle->raw();
    if (IsUnreachable(raw_obj)) {
      handle->UpdateUnreachable(thread()->isolate_group());
    }
  }

 private:
  SharedClassTable* class_table_;

  DISALLOW_COPY_AND_ASSIGN(MarkingWeakVisitor);
};

void GCMarker::Prologue() {
  isolate_group_->ReleaseStoreBuffers();
}

void GCMarker::Epilogue() {}

enum RootSlices {
  kIsolate = 0,
  kNumFixedRootSlices = 1,
};

void GCMarker::ResetSlices() {
  ASSERT(Thread::Current()->IsAtSafepoint());

  root_slices_started_ = 0;
  root_slices_finished_ = 0;
  root_slices_count_ = kNumFixedRootSlices;
  new_page_ = heap_->new_space()->head();
  for (NewPage* p = new_page_; p != nullptr; p = p->next()) {
    root_slices_count_++;
  }

  weak_slices_started_ = 0;
}

void GCMarker::IterateRoots(ObjectPointerVisitor* visitor) {
  for (;;) {
    intptr_t slice = root_slices_started_.fetch_add(1);
    if (slice >= root_slices_count_) {
      break;  // No more slices.
    }

    switch (slice) {
      case kIsolate: {
        TIMELINE_FUNCTION_GC_DURATION(Thread::Current(),
                                      "ProcessIsolateGroupRoots");
        isolate_group_->VisitObjectPointers(
            visitor, ValidationPolicy::kDontValidateFrames);
        break;
      }
      default: {
        NewPage* page;
        {
          MonitorLocker ml(&root_slices_monitor_);
          page = new_page_;
          ASSERT(page != nullptr);
          new_page_ = page->next();
        }
        TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ProcessNewSpace");
        page->VisitObjectPointers(visitor);
      }
    }

    MonitorLocker ml(&root_slices_monitor_);
    root_slices_finished_++;
    if (root_slices_finished_ == root_slices_count_) {
      ml.Notify();
    }
  }
}

enum WeakSlices {
  kWeakHandles = 0,
  kWeakTables,
  kObjectIdRing,
  kRememberedSet,
  kNumWeakSlices,
};

void GCMarker::IterateWeakRoots(Thread* thread) {
  for (;;) {
    intptr_t slice = weak_slices_started_.fetch_add(1);
    if (slice >= kNumWeakSlices) {
      return;  // No more slices.
    }

    switch (slice) {
      case kWeakHandles:
        ProcessWeakHandles(thread);
        break;
      case kWeakTables:
        ProcessWeakTables(thread);
        break;
      case kObjectIdRing:
        ProcessObjectIdTable(thread);
        break;
      case kRememberedSet:
        ProcessRememberedSet(thread);
        break;
      default:
        UNREACHABLE();
    }
  }
}

void GCMarker::ProcessWeakHandles(Thread* thread) {
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakHandles");
  MarkingWeakVisitor visitor(thread);
  ApiState* state = isolate_group_->api_state();
  ASSERT(state != NULL);
  isolate_group_->VisitWeakPersistentHandles(&visitor);
}

void GCMarker::ProcessWeakTables(Thread* thread) {
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakTables");
  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    WeakTable* table =
        heap_->GetWeakTable(Heap::kOld, static_cast<Heap::WeakSelector>(sel));
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAtExclusive(i)) {
        ObjectPtr raw_obj = table->ObjectAtExclusive(i);
        if (raw_obj->IsHeapObject() && !raw_obj->ptr()->IsMarked()) {
          table->InvalidateAtExclusive(i);
        }
      }
    }
  }
}

void GCMarker::ProcessRememberedSet(Thread* thread) {
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessRememberedSet");
  // Filter collected objects from the remembered set.
  StoreBuffer* store_buffer = isolate_group_->store_buffer();
  StoreBufferBlock* reading = store_buffer->TakeBlocks();
  StoreBufferBlock* writing = store_buffer->PopNonFullBlock();
  while (reading != NULL) {
    StoreBufferBlock* next = reading->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(reading, sizeof(*reading));
    while (!reading->IsEmpty()) {
      ObjectPtr raw_object = reading->Pop();
      ASSERT(!raw_object->IsForwardingCorpse());
      ASSERT(raw_object->ptr()->IsRemembered());
      if (raw_object->ptr()->IsMarked()) {
        writing->Push(raw_object);
        if (writing->IsFull()) {
          store_buffer->PushBlock(writing, StoreBuffer::kIgnoreThreshold);
          writing = store_buffer->PopNonFullBlock();
        }
      }
    }
    reading->Reset();
    // Return the emptied block for recycling (no need to check threshold).
    store_buffer->PushBlock(reading, StoreBuffer::kIgnoreThreshold);
    reading = next;
  }
  store_buffer->PushBlock(writing, StoreBuffer::kIgnoreThreshold);
}

class ObjectIdRingClearPointerVisitor : public ObjectPointerVisitor {
 public:
  explicit ObjectIdRingClearPointerVisitor(IsolateGroup* isolate_group)
      : ObjectPointerVisitor(isolate_group) {}

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
    for (ObjectPtr* current = first; current <= last; current++) {
      ObjectPtr raw_obj = *current;
      ASSERT(raw_obj->IsHeapObject());
      if (raw_obj->IsOldObject() && !raw_obj->ptr()->IsMarked()) {
        // Object has become garbage. Replace it will null.
        *current = Object::null();
      }
    }
  }
};

void GCMarker::ProcessObjectIdTable(Thread* thread) {
#ifndef PRODUCT
  TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessObjectIdTable");
  ObjectIdRingClearPointerVisitor visitor(isolate_group_);
  isolate_group_->VisitObjectIdRingPointers(&visitor);
#endif  // !PRODUCT
}

class ParallelMarkTask : public ThreadPool::Task {
 public:
  ParallelMarkTask(GCMarker* marker,
                   IsolateGroup* isolate_group,
                   MarkingStack* marking_stack,
                   ThreadBarrier* barrier,
                   SyncMarkingVisitor* visitor,
                   RelaxedAtomic<uintptr_t>* num_busy)
      : marker_(marker),
        isolate_group_(isolate_group),
        marking_stack_(marking_stack),
        barrier_(barrier),
        visitor_(visitor),
        num_busy_(num_busy) {}

  virtual void Run() {
    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kMarkerTask, /*bypass_safepoint=*/true);
    ASSERT(result);

    RunEnteredIsolateGroup();

    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);

    // This task is done. Notify the original thread.
    barrier_->Exit();
  }

  void RunEnteredIsolateGroup() {
    {
      Thread* thread = Thread::Current();
      TIMELINE_FUNCTION_GC_DURATION(thread, "ParallelMark");
      int64_t start = OS::GetCurrentMonotonicMicros();

      // Phase 1: Iterate over roots and drain marking stack in tasks.
      marker_->IterateRoots(visitor_);

      visitor_->ProcessDeferredMarking();

      bool more_to_mark = false;
      do {
        do {
          visitor_->DrainMarkingStack();

          // I can't find more work right now. If no other task is busy,
          // then there will never be more work (NB: 1 is *before* decrement).
          if (num_busy_->fetch_sub(1u) == 1) break;

          // Wait for some work to appear.
          // TODO(40695): Replace busy-waiting with a solution using Monitor,
          // and redraw the boundaries between stack/visitor/task as needed.
          while (marking_stack_->IsEmpty() && num_busy_->load() > 0) {
          }

          // If no tasks are busy, there will never be more work.
          if (num_busy_->load() == 0) break;

          // I saw some work; get busy and compete for it.
          num_busy_->fetch_add(1u);
        } while (true);
        // Wait for all markers to stop.
        barrier_->Sync();
#if defined(DEBUG)
        ASSERT(num_busy_->load() == 0);
        // Caveat: must not allow any marker to continue past the barrier
        // before we checked num_busy, otherwise one of them might rush
        // ahead and increment it.
        barrier_->Sync();
#endif
        // Check if we have any pending properties with marked keys.
        // Those might have been marked by another marker.
        more_to_mark = visitor_->ProcessPendingWeakProperties();
        if (more_to_mark) {
          // We have more work to do. Notify others.
          num_busy_->fetch_add(1u);
        }

        // Wait for all other markers to finish processing their pending
        // weak properties and decide if they need to continue marking.
        // Caveat: we need two barriers here to make this decision in lock step
        // between all markers and the main thread.
        barrier_->Sync();
        if (!more_to_mark && (num_busy_->load() > 0)) {
          // All markers continue to mark as long as any single marker has
          // some work to do.
          num_busy_->fetch_add(1u);
          more_to_mark = true;
        }
        barrier_->Sync();
      } while (more_to_mark);

      // Phase 2: deferred marking.
      visitor_->FinalizeDeferredMarking();
      barrier_->Sync();

      // Phase 3: Weak processing.
      marker_->IterateWeakRoots(thread);
      barrier_->Sync();

      // Phase 4: Gather statistics from all markers.
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor_->AddMicros(stop - start);
      if (FLAG_log_marker_tasks) {
        THR_Print("Task marked %" Pd " bytes in %" Pd64 " micros.\n",
                  visitor_->marked_bytes(), visitor_->marked_micros());
      }
      marker_->FinalizeResultsFrom(visitor_);

      delete visitor_;
    }
  }

 private:
  GCMarker* marker_;
  IsolateGroup* isolate_group_;
  MarkingStack* marking_stack_;
  ThreadBarrier* barrier_;
  SyncMarkingVisitor* visitor_;
  RelaxedAtomic<uintptr_t>* num_busy_;

  DISALLOW_COPY_AND_ASSIGN(ParallelMarkTask);
};

class ConcurrentMarkTask : public ThreadPool::Task {
 public:
  ConcurrentMarkTask(GCMarker* marker,
                     IsolateGroup* isolate_group,
                     PageSpace* page_space,
                     SyncMarkingVisitor* visitor)
      : marker_(marker),
        isolate_group_(isolate_group),
        page_space_(page_space),
        visitor_(visitor) {
#if defined(DEBUG)
    MonitorLocker ml(page_space_->tasks_lock());
    ASSERT(page_space_->phase() == PageSpace::kMarking);
#endif
  }

  virtual void Run() {
    bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kMarkerTask, /*bypass_safepoint=*/true);
    ASSERT(result);
    {
      TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ConcurrentMark");
      int64_t start = OS::GetCurrentMonotonicMicros();

      marker_->IterateRoots(visitor_);

      visitor_->DrainMarkingStack();
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor_->AddMicros(stop - start);
      if (FLAG_log_marker_tasks) {
        THR_Print("Task marked %" Pd " bytes in %" Pd64 " micros.\n",
                  visitor_->marked_bytes(), visitor_->marked_micros());
      }
    }

    // Exit isolate cleanly *before* notifying it, to avoid shutdown race.
    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/true);
    // This marker task is done. Notify the original isolate.
    {
      MonitorLocker ml(page_space_->tasks_lock());
      page_space_->set_tasks(page_space_->tasks() - 1);
      page_space_->set_concurrent_marker_tasks(
          page_space_->concurrent_marker_tasks() - 1);
      ASSERT(page_space_->phase() == PageSpace::kMarking);
      if (page_space_->concurrent_marker_tasks() == 0) {
        page_space_->set_phase(PageSpace::kAwaitingFinalization);
      }
      ml.NotifyAll();
    }
  }

 private:
  GCMarker* marker_;
  IsolateGroup* isolate_group_;
  PageSpace* page_space_;
  SyncMarkingVisitor* visitor_;

  DISALLOW_COPY_AND_ASSIGN(ConcurrentMarkTask);
};

template <class MarkingVisitorType>
void GCMarker::FinalizeResultsFrom(MarkingVisitorType* visitor) {
  {
    MutexLocker ml(&stats_mutex_);
    marked_bytes_ += visitor->marked_bytes();
    marked_micros_ += visitor->marked_micros();
  }
  visitor->Finalize();
}

intptr_t GCMarker::MarkedWordsPerMicro() const {
  intptr_t marked_words_per_job_micro;
  if (marked_micros_ == 0) {
    marked_words_per_job_micro = marked_words();  // Prevent division by zero.
  } else {
    marked_words_per_job_micro = marked_words() / marked_micros_;
  }
  if (marked_words_per_job_micro == 0) {
    marked_words_per_job_micro = 1;  // Prevent division by zero.
  }
  intptr_t jobs = FLAG_marker_tasks;
  if (jobs == 0) {
    jobs = 1;  // Marking on main thread is still one job.
  }
  return marked_words_per_job_micro * jobs;
}

GCMarker::GCMarker(IsolateGroup* isolate_group, Heap* heap)
    : isolate_group_(isolate_group),
      heap_(heap),
      marking_stack_(),
      visitors_(),
      marked_bytes_(0),
      marked_micros_(0) {
  visitors_ = new SyncMarkingVisitor*[FLAG_marker_tasks];
  for (intptr_t i = 0; i < FLAG_marker_tasks; i++) {
    visitors_[i] = NULL;
  }
}

GCMarker::~GCMarker() {
  // Cleanup in case isolate shutdown happens after starting the concurrent
  // marker and before finalizing.
  if (isolate_group_->marking_stack() != NULL) {
    isolate_group_->DisableIncrementalBarrier();
    for (intptr_t i = 0; i < FLAG_marker_tasks; i++) {
      visitors_[i]->AbandonWork();
      delete visitors_[i];
    }
  }
  delete[] visitors_;
}

void GCMarker::StartConcurrentMark(PageSpace* page_space) {
  isolate_group_->EnableIncrementalBarrier(&marking_stack_,
                                           &deferred_marking_stack_);

  const intptr_t num_tasks = FLAG_marker_tasks;

  {
    // Bulk increase task count before starting any task, instead of
    // incrementing as each task is started, to prevent a task which
    // races ahead from falsly beleiving it was the last task to complete.
    MonitorLocker ml(page_space->tasks_lock());
    ASSERT(page_space->phase() == PageSpace::kDone);
    page_space->set_phase(PageSpace::kMarking);
    page_space->set_tasks(page_space->tasks() + num_tasks);
    page_space->set_concurrent_marker_tasks(
        page_space->concurrent_marker_tasks() + num_tasks);
  }

  ResetSlices();
  for (intptr_t i = 0; i < num_tasks; i++) {
    ASSERT(visitors_[i] == NULL);
    visitors_[i] = new SyncMarkingVisitor(
        isolate_group_, page_space, &marking_stack_, &deferred_marking_stack_);

    // Begin marking on a helper thread.
    bool result = Dart::thread_pool()->Run<ConcurrentMarkTask>(
        this, isolate_group_, page_space, visitors_[i]);
    ASSERT(result);
  }

  isolate_group_->DeferredMarkLiveTemporaries();

  // Wait for roots to be marked before exiting safepoint.
  MonitorLocker ml(&root_slices_monitor_);
  while (root_slices_finished_ != root_slices_count_) {
    ml.Wait();
  }
}

void GCMarker::MarkObjects(PageSpace* page_space) {
  if (isolate_group_->marking_stack() != NULL) {
    isolate_group_->DisableIncrementalBarrier();
  }

  Prologue();
  {
    Thread* thread = Thread::Current();
    const int num_tasks = FLAG_marker_tasks;
    if (num_tasks == 0) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "Mark");
      int64_t start = OS::GetCurrentMonotonicMicros();
      // Mark everything on main thread.
      UnsyncMarkingVisitor mark(isolate_group_, page_space, &marking_stack_,
                                &deferred_marking_stack_);
      ResetSlices();
      IterateRoots(&mark);
      mark.ProcessDeferredMarking();
      mark.DrainMarkingStack();
      mark.FinalizeDeferredMarking();
      IterateWeakRoots(thread);
      // All marking done; detach code, etc.
      int64_t stop = OS::GetCurrentMonotonicMicros();
      mark.AddMicros(stop - start);
      FinalizeResultsFrom(&mark);
    } else {
      ThreadBarrier barrier(num_tasks, heap_->barrier(), heap_->barrier_done());
      ResetSlices();
      // Used to coordinate draining among tasks; all start out as 'busy'.
      RelaxedAtomic<uintptr_t> num_busy(num_tasks);
      // Phase 1: Iterate over roots and drain marking stack in tasks.
      for (intptr_t i = 0; i < num_tasks; ++i) {
        SyncMarkingVisitor* visitor;
        if (visitors_[i] != NULL) {
          visitor = visitors_[i];
          visitors_[i] = NULL;
        } else {
          visitor =
              new SyncMarkingVisitor(isolate_group_, page_space,
                                     &marking_stack_, &deferred_marking_stack_);
        }
        if (i < (num_tasks - 1)) {
          // Begin marking on a helper thread.
          bool result = Dart::thread_pool()->Run<ParallelMarkTask>(
              this, isolate_group_, &marking_stack_, &barrier, visitor,
              &num_busy);
          ASSERT(result);
        } else {
          // Last worker is the main thread.
          ParallelMarkTask task(this, isolate_group_, &marking_stack_, &barrier,
                                visitor, &num_busy);
          task.RunEnteredIsolateGroup();
          barrier.Exit();
        }
      }
    }
  }
  Epilogue();
}

}  // namespace dart
