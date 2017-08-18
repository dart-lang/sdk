// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_marker.h"

#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/object_id_ring.h"
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/store_buffer.h"
#include "vm/thread_barrier.h"
#include "vm/thread_pool.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

namespace dart {

class SkippedCodeFunctions : public ZoneAllocated {
 public:
  SkippedCodeFunctions() {}

  void Add(RawFunction* func) { skipped_code_functions_.Add(func); }

  void DetachCode() {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    intptr_t unoptimized_code_count = 0;
    intptr_t current_code_count = 0;
    for (int i = 0; i < skipped_code_functions_.length(); i++) {
      RawFunction* func = skipped_code_functions_[i];
      RawCode* code = func->ptr()->code_;
      if (!code->IsMarked()) {
        // If the code wasn't strongly visited through other references
        // after skipping the function's code pointer, then we disconnect the
        // code from the function.
        func->StorePointer(&(func->ptr()->code_),
                           StubCode::LazyCompile_entry()->code());
        uword entry_point = StubCode::LazyCompile_entry()->EntryPoint();
        func->ptr()->entry_point_ = entry_point;
        if (FLAG_log_code_drop) {
          // NOTE: This code runs while GC is in progress and runs within
          // a NoHandleScope block. Hence it is not okay to use a regular Zone
          // or Scope handle. We use a direct stack handle so the raw pointer in
          // this handle is not traversed. The use of a handle is mainly to
          // be able to reuse the handle based code and avoid having to add
          // helper functions to the raw object interface.
          String name;
          name = func->ptr()->name_;
          THR_Print("Detaching code: %s\n", name.ToCString());
          current_code_count++;
        }
      }

      code = func->ptr()->unoptimized_code_;
      if (!code->IsMarked()) {
        // If the code wasn't strongly visited through other references
        // after skipping the function's code pointer, then we disconnect the
        // code from the function.
        func->StorePointer(&(func->ptr()->unoptimized_code_), Code::null());
        if (FLAG_log_code_drop) {
          unoptimized_code_count++;
        }
      }
    }
    if (FLAG_log_code_drop) {
      THR_Print("  total detached current: %" Pd "\n", current_code_count);
      THR_Print("  total detached unoptimized: %" Pd "\n",
                unoptimized_code_count);
    }
    // Clean up.
    skipped_code_functions_.Clear();
#endif  // !DART_PRECOMPILED_RUNTIME
  }

 private:
  GrowableArray<RawFunction*> skipped_code_functions_;

  DISALLOW_COPY_AND_ASSIGN(SkippedCodeFunctions);
};

class MarkerWorkList : public ValueObject {
 public:
  explicit MarkerWorkList(MarkingStack* marking_stack)
      : marking_stack_(marking_stack) {
    work_ = marking_stack_->PopEmptyBlock();
  }

  ~MarkerWorkList() {
    ASSERT(work_ == NULL);
    ASSERT(marking_stack_ == NULL);
  }

  // Returns NULL if no more work was found.
  RawObject* Pop() {
    ASSERT(work_ != NULL);
    if (work_->IsEmpty()) {
      // TODO(koda): Track over/underflow events and use in heuristics to
      // distribute work and prevent degenerate flip-flopping.
      MarkingStack::Block* new_work = marking_stack_->PopNonEmptyBlock();
      if (new_work == NULL) {
        return NULL;
      }
      marking_stack_->PushBlock(work_);
      work_ = new_work;
    }
    return work_->Pop();
  }

  void Push(RawObject* raw_obj) {
    if (work_->IsFull()) {
      // TODO(koda): Track over/underflow events and use in heuristics to
      // distribute work and prevent degenerate flip-flopping.
      marking_stack_->PushBlock(work_);
      work_ = marking_stack_->PopEmptyBlock();
    }
    work_->Push(raw_obj);
  }

  void Finalize() {
    ASSERT(work_->IsEmpty());
    marking_stack_->PushBlock(work_);
    work_ = NULL;
    // Fail fast on attempts to mark after finalizing.
    marking_stack_ = NULL;
  }

 private:
  MarkingStack::Block* work_;
  MarkingStack* marking_stack_;
};

template <bool sync>
class MarkingVisitorBase : public ObjectPointerVisitor {
 public:
  MarkingVisitorBase(Isolate* isolate,
                     PageSpace* page_space,
                     MarkingStack* marking_stack,
                     SkippedCodeFunctions* skipped_code_functions)
      : ObjectPointerVisitor(isolate),
        thread_(Thread::Current()),
#ifndef PRODUCT
        class_stats_count_(isolate->class_table()->NumCids()),
        class_stats_size_(isolate->class_table()->NumCids()),
#endif  // !PRODUCT
        page_space_(page_space),
        work_list_(marking_stack),
        delayed_weak_properties_(NULL),
        visiting_old_object_(NULL),
        skipped_code_functions_(skipped_code_functions),
        marked_bytes_(0) {
    ASSERT(thread_->isolate() == isolate);
#ifndef PRODUCT
    class_stats_count_.SetLength(isolate->class_table()->NumCids());
    class_stats_size_.SetLength(isolate->class_table()->NumCids());
    for (intptr_t i = 0; i < class_stats_count_.length(); ++i) {
      class_stats_count_[i] = 0;
      class_stats_size_[i] = 0;
    }
#endif  // !PRODUCT
  }

  uintptr_t marked_bytes() const { return marked_bytes_; }

#ifndef PRODUCT
  intptr_t live_count(intptr_t class_id) {
    return class_stats_count_[class_id];
  }

  intptr_t live_size(intptr_t class_id) { return class_stats_size_[class_id]; }
#endif  // !PRODUCT

  bool ProcessPendingWeakProperties() {
    bool marked = false;
    RawWeakProperty* cur_weak = delayed_weak_properties_;
    delayed_weak_properties_ = NULL;
    while (cur_weak != NULL) {
      uword next_weak = cur_weak->ptr()->next_;
      RawObject* raw_key = cur_weak->ptr()->key_;
      // Reset the next pointer in the weak property.
      cur_weak->ptr()->next_ = 0;
      if (raw_key->IsMarked()) {
        RawObject* raw_val = cur_weak->ptr()->value_;
        marked = marked || (raw_val->IsHeapObject() && !raw_val->IsMarked());

        // The key is marked so we make sure to properly visit all pointers
        // originating from this weak property.
        VisitingOldObject(cur_weak);
        cur_weak->VisitPointersNonvirtual(this);
      } else {
        // Requeue this weak property to be handled later.
        EnqueueWeakProperty(cur_weak);
      }
      // Advance to next weak property in the queue.
      cur_weak = reinterpret_cast<RawWeakProperty*>(next_weak);
    }
    VisitingOldObject(NULL);
    return marked;
  }

  void DrainMarkingStack() {
    RawObject* raw_obj = work_list_.Pop();
    if ((raw_obj == NULL) && ProcessPendingWeakProperties()) {
      raw_obj = work_list_.Pop();
    }

    if (raw_obj == NULL) {
      ASSERT(visiting_old_object_ == NULL);
      return;
    }
    do {
      do {
        // First drain the marking stacks.
        VisitingOldObject(raw_obj);
        const intptr_t class_id = raw_obj->GetClassId();
        if (class_id != kWeakPropertyCid) {
          marked_bytes_ += raw_obj->VisitPointersNonvirtual(this);
        } else {
          RawWeakProperty* raw_weak =
              reinterpret_cast<RawWeakProperty*>(raw_obj);
          marked_bytes_ += ProcessWeakProperty(raw_weak);
        }
        raw_obj = work_list_.Pop();
      } while (raw_obj != NULL);

      // Marking stack is empty.
      ProcessPendingWeakProperties();

      // Check whether any further work was pushed either by other markers or
      // by the handling of weak properties.
      raw_obj = work_list_.Pop();
    } while (raw_obj != NULL);
    VisitingOldObject(NULL);
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current, current);
    }
  }

  bool visit_function_code() const { return skipped_code_functions_ == NULL; }

  virtual void add_skipped_code_function(RawFunction* func) {
    ASSERT(!visit_function_code());
    skipped_code_functions_->Add(func);
  }

  void EnqueueWeakProperty(RawWeakProperty* raw_weak) {
    ASSERT(raw_weak->IsHeapObject());
    ASSERT(raw_weak->IsOldObject());
    ASSERT(raw_weak->IsWeakProperty());
    ASSERT(raw_weak->IsMarked());
    ASSERT(raw_weak->ptr()->next_ == 0);
    raw_weak->ptr()->next_ = reinterpret_cast<uword>(delayed_weak_properties_);
    delayed_weak_properties_ = raw_weak;
  }

  intptr_t ProcessWeakProperty(RawWeakProperty* raw_weak) {
    // The fate of the weak property is determined by its key.
    RawObject* raw_key = raw_weak->ptr()->key_;
    if (raw_key->IsHeapObject() && raw_key->IsOldObject() &&
        !raw_key->IsMarked()) {
      // Key was white. Enqueue the weak property.
      EnqueueWeakProperty(raw_weak);
      return raw_weak->Size();
    }
    // Key is gray or black. Make the weak property black.
    return raw_weak->VisitPointersNonvirtual(this);
  }

  // Called when all marking is complete.
  void Finalize() {
    work_list_.Finalize();
    // Detach code from functions.
    if (skipped_code_functions_ != NULL) {
      skipped_code_functions_->DetachCode();
    }
    // Clear pending weak properties.
    RawWeakProperty* cur_weak = delayed_weak_properties_;
    delayed_weak_properties_ = NULL;
    intptr_t weak_properties_cleared = 0;
    while (cur_weak != NULL) {
      uword next_weak = cur_weak->ptr()->next_;
      cur_weak->ptr()->next_ = 0;
      RELEASE_ASSERT(!cur_weak->ptr()->key_->IsMarked());
      WeakProperty::Clear(cur_weak);
      weak_properties_cleared++;
      // Advance to next weak property in the queue.
      cur_weak = reinterpret_cast<RawWeakProperty*>(next_weak);
    }
  }

  void VisitingOldObject(RawObject* obj) {
    ASSERT((obj == NULL) || obj->IsOldObject());
    visiting_old_object_ = obj;
  }

 private:
  void PushMarked(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT((FLAG_verify_gc_contains)
               ? page_space_->Contains(RawObject::ToAddr(raw_obj))
               : true);

    // Push the marked object on the marking stack.
    ASSERT(raw_obj->IsMarked());
    // We acquired the mark bit => no other task is modifying the header.
    // TODO(koda): For concurrent mutator, this needs synchronization. Consider
    // clearing these bits already in the CAS for the mark bit.
    raw_obj->ClearRememberedBitUnsynchronized();
    work_list_.Push(raw_obj);
  }

  static bool TryAcquireMarkBit(RawObject* raw_obj) {
    if (!sync) {
      if (raw_obj->IsMarked()) return false;
      raw_obj->SetMarkBitUnsynchronized();
      return true;
    }
    return raw_obj->TryAcquireMarkBit();
  }

  void MarkObject(RawObject* raw_obj, RawObject** p) {
    // Fast exit if the raw object is a Smi.
    if (!raw_obj->IsHeapObject()) {
      return;
    }

    // Fast exit if the raw object is marked.
    if (raw_obj->IsMarked()) {
      return;
    }

    // TODO(koda): Investigate performance impact of alternative branching:
    // if (smi or new) <-- can be done as single compare + conditional jump
    //   if (smi) return;
    //   else ...
    // if (marked) return;
    // ...
    if (raw_obj->IsNewObject()) {
      ProcessNewSpaceObject(raw_obj, p);
      return;
    }

    if (!TryAcquireMarkBit(raw_obj)) {
      // Already marked.
      return;
    }

#ifndef PRODUCT
    if (RawObject::IsVariableSizeClassId(raw_obj->GetClassId())) {
      UpdateLiveOld(raw_obj->GetClassId(), raw_obj->Size());
    } else {
      UpdateLiveOld(raw_obj->GetClassId(), 0);
    }
#endif  // !PRODUCT

    PushMarked(raw_obj);
  }

  static bool TryAcquireRememberedBit(RawObject* raw_obj) {
    if (!sync) {
      if (raw_obj->IsRemembered()) return false;
      raw_obj->SetRememberedBitUnsynchronized();
      return true;
    }
    return raw_obj->TryAcquireRememberedBit();
  }

  void ProcessNewSpaceObject(RawObject* raw_obj, RawObject** p) {
    // TODO(iposva): Add consistency check.
    if ((visiting_old_object_ != NULL) &&
        TryAcquireRememberedBit(visiting_old_object_)) {
      // NOTE: We pass in the pointer to the address we are visiting
      // allows us to get a distance from the object start. At some
      // point we might want to store exact addresses in store buffers
      // for locations far enough from the header, so that we do not
      // need to walk big objects only to find the single new
      // reference in the last word during scavenge. This doesn't seem
      // to be a problem though currently.
      ASSERT(p != NULL);
      thread_->StoreBufferAddObjectGC(visiting_old_object_);
    }
  }

#ifndef PRODUCT
  void UpdateLiveOld(intptr_t class_id, intptr_t size) {
    // TODO(koda): Support growing the array once mutator runs concurrently.
    ASSERT(class_id < class_stats_count_.length());
    class_stats_count_[class_id] += 1;
    class_stats_size_[class_id] += size;
  }
#endif  // !PRODUCT

  Thread* thread_;
#ifndef PRODUCT
  GrowableArray<intptr_t> class_stats_count_;
  GrowableArray<intptr_t> class_stats_size_;
#endif  // !PRODUCT
  PageSpace* page_space_;
  MarkerWorkList work_list_;
  RawWeakProperty* delayed_weak_properties_;
  RawObject* visiting_old_object_;
  SkippedCodeFunctions* skipped_code_functions_;
  uintptr_t marked_bytes_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitorBase);
};

typedef MarkingVisitorBase<false> UnsyncMarkingVisitor;
typedef MarkingVisitorBase<true> SyncMarkingVisitor;

static bool IsUnreachable(const RawObject* raw_obj) {
  if (!raw_obj->IsHeapObject()) {
    return false;
  }
  if (raw_obj == Object::null()) {
    return true;
  }
  if (!raw_obj->IsOldObject()) {
    return false;
  }
  return !raw_obj->IsMarked();
}

class MarkingWeakVisitor : public HandleVisitor {
 public:
  explicit MarkingWeakVisitor(Thread* thread) : HandleVisitor(thread) {}

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject* raw_obj = handle->raw();
    if (IsUnreachable(raw_obj)) {
      handle->UpdateUnreachable(thread()->isolate());
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(MarkingWeakVisitor);
};

void GCMarker::Prologue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks && (isolate->gc_prologue_callback() != NULL)) {
    (isolate->gc_prologue_callback())();
  }
  isolate->PrepareForGC();
  // The store buffers will be rebuilt as part of marking, reset them now.
  isolate->store_buffer()->Reset();
}

void GCMarker::Epilogue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks && (isolate->gc_epilogue_callback() != NULL)) {
    (isolate->gc_epilogue_callback())();
  }
}

void GCMarker::IterateRoots(Isolate* isolate,
                            ObjectPointerVisitor* visitor,
                            intptr_t slice_index,
                            intptr_t num_slices) {
  ASSERT(0 <= slice_index && slice_index < num_slices);
  if ((slice_index == 0) || (num_slices <= 1)) {
    isolate->VisitObjectPointers(visitor,
                                 StackFrameIterator::kDontValidateFrames);
  }
  if ((slice_index == 1) || (num_slices <= 1)) {
    heap_->new_space()->VisitObjectPointers(visitor);
  }

  // For now, we just distinguish two parts of the root set, so any remaining
  // slices are empty.
}

void GCMarker::IterateWeakRoots(Isolate* isolate, HandleVisitor* visitor) {
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  isolate->VisitWeakPersistentHandles(visitor);
}

void GCMarker::ProcessWeakTables(PageSpace* page_space) {
  for (int sel = 0; sel < Heap::kNumWeakSelectors; sel++) {
    WeakTable* table =
        heap_->GetWeakTable(Heap::kOld, static_cast<Heap::WeakSelector>(sel));
    intptr_t size = table->size();
    for (intptr_t i = 0; i < size; i++) {
      if (table->IsValidEntryAt(i)) {
        RawObject* raw_obj = table->ObjectAt(i);
        ASSERT(raw_obj->IsHeapObject());
        if (!raw_obj->IsMarked()) {
          table->InvalidateAt(i);
        }
      }
    }
  }
}

class ObjectIdRingClearPointerVisitor : public ObjectPointerVisitor {
 public:
  explicit ObjectIdRingClearPointerVisitor(Isolate* isolate)
      : ObjectPointerVisitor(isolate) {}

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      RawObject* raw_obj = *current;
      ASSERT(raw_obj->IsHeapObject());
      if (raw_obj->IsOldObject() && !raw_obj->IsMarked()) {
        // Object has become garbage. Replace it will null.
        *current = Object::null();
      }
    }
  }
};

void GCMarker::ProcessObjectIdTable(Isolate* isolate) {
#ifndef PRODUCT
  if (!FLAG_support_service) {
    return;
  }
  ObjectIdRingClearPointerVisitor visitor(isolate);
  ObjectIdRing* ring = isolate->object_id_ring();
  ASSERT(ring != NULL);
  ring->VisitPointers(&visitor);
#endif  // !PRODUCT
}

class MarkTask : public ThreadPool::Task {
 public:
  MarkTask(GCMarker* marker,
           Isolate* isolate,
           Heap* heap,
           PageSpace* page_space,
           MarkingStack* marking_stack,
           ThreadBarrier* barrier,
           bool collect_code,
           intptr_t task_index,
           intptr_t num_tasks,
           uintptr_t* num_busy)
      : marker_(marker),
        isolate_(isolate),
        heap_(heap),
        page_space_(page_space),
        marking_stack_(marking_stack),
        barrier_(barrier),
        collect_code_(collect_code),
        task_index_(task_index),
        num_tasks_(num_tasks),
        num_busy_(num_busy) {}

  virtual void Run() {
    bool result =
        Thread::EnterIsolateAsHelper(isolate_, Thread::kMarkerTask, true);
    ASSERT(result);
    {
      Thread* thread = Thread::Current();
      TIMELINE_FUNCTION_GC_DURATION(thread, "MarkTask");
      StackZone stack_zone(thread);
      Zone* zone = stack_zone.GetZone();
      SkippedCodeFunctions* skipped_code_functions =
          collect_code_ ? new (zone) SkippedCodeFunctions() : NULL;
      SyncMarkingVisitor visitor(isolate_, page_space_, marking_stack_,
                                 skipped_code_functions);
      // Phase 1: Iterate over roots and drain marking stack in tasks.
      marker_->IterateRoots(isolate_, &visitor, task_index_, num_tasks_);

      bool more_to_mark = false;
      do {
        do {
          visitor.DrainMarkingStack();

          // I can't find more work right now. If no other task is busy,
          // then there will never be more work (NB: 1 is *before* decrement).
          if (AtomicOperations::FetchAndDecrement(num_busy_) == 1) break;

          // Wait for some work to appear.
          // TODO(iposva): Replace busy-waiting with a solution using Monitor,
          // and redraw the boundaries between stack/visitor/task as needed.
          while (marking_stack_->IsEmpty() &&
                 AtomicOperations::LoadRelaxed(num_busy_) > 0) {
          }

          // If no tasks are busy, there will never be more work.
          if (AtomicOperations::LoadRelaxed(num_busy_) == 0) break;

          // I saw some work; get busy and compete for it.
          AtomicOperations::FetchAndIncrement(num_busy_);
        } while (true);
        // Wait for all markers to stop.
        barrier_->Sync();
#if defined(DEBUG)
        ASSERT(AtomicOperations::LoadRelaxed(num_busy_) == 0);
        // Caveat: must not allow any marker to continue past the barrier
        // before we checked num_busy, otherwise one of them might rush
        // ahead and increment it.
        barrier_->Sync();
#endif
        // Check if we have any pending properties with marked keys.
        // Those might have been marked by another marker.
        more_to_mark = visitor.ProcessPendingWeakProperties();
        if (more_to_mark) {
          // We have more work to do. Notify others.
          AtomicOperations::FetchAndIncrement(num_busy_);
        }

        // Wait for all other markers to finish processing their pending
        // weak properties and decide if they need to continue marking.
        // Caveat: we need two barriers here to make this decision in lock step
        // between all markers and the main thread.
        barrier_->Sync();
        if (!more_to_mark && (AtomicOperations::LoadRelaxed(num_busy_) > 0)) {
          // All markers continue to mark as long as any single marker has
          // some work to do.
          AtomicOperations::FetchAndIncrement(num_busy_);
          more_to_mark = true;
        }
        barrier_->Sync();
      } while (more_to_mark);

      // Phase 2: Weak processing and follow-up marking on main thread.
      barrier_->Sync();

      // Phase 3: Finalize results from all markers (detach code, etc.).
      if (FLAG_log_marker_tasks) {
        THR_Print("Task %" Pd " marked %" Pd " bytes.\n", task_index_,
                  visitor.marked_bytes());
      }
      marker_->FinalizeResultsFrom(&visitor);
    }
    Thread::ExitIsolateAsHelper(true);

    // This task is done. Notify the original thread.
    barrier_->Exit();
  }

 private:
  GCMarker* marker_;
  Isolate* isolate_;
  Heap* heap_;
  PageSpace* page_space_;
  MarkingStack* marking_stack_;
  ThreadBarrier* barrier_;
  bool collect_code_;
  const intptr_t task_index_;
  const intptr_t num_tasks_;
  uintptr_t* num_busy_;

  DISALLOW_COPY_AND_ASSIGN(MarkTask);
};

template <class MarkingVisitorType>
void GCMarker::FinalizeResultsFrom(MarkingVisitorType* visitor) {
  {
    MutexLocker ml(&stats_mutex_);
    marked_bytes_ += visitor->marked_bytes();
#ifndef PRODUCT
    // Class heap stats are not themselves thread-safe yet, so we update the
    // stats while holding stats_mutex_.
    ClassTable* table = heap_->isolate()->class_table();
    for (intptr_t i = 0; i < table->NumCids(); ++i) {
      const intptr_t count = visitor->live_count(i);
      if (count > 0) {
        const intptr_t size = visitor->live_size(i);
        table->UpdateLiveOld(i, size, count);
      }
    }
#endif  // !PRODUCT
  }
  visitor->Finalize();
}

void GCMarker::MarkObjects(Isolate* isolate,
                           PageSpace* page_space,
                           bool invoke_api_callbacks,
                           bool collect_code) {
  Prologue(isolate, invoke_api_callbacks);
  // The API prologue/epilogue may create/destroy zones, so we must not
  // depend on zone allocations surviving beyond the epilogue callback.
  {
    Thread* thread = Thread::Current();
    StackZone stack_zone(thread);
    Zone* zone = stack_zone.GetZone();
    MarkingStack marking_stack;
    marked_bytes_ = 0;
    const int num_tasks = FLAG_marker_tasks;
    if (num_tasks == 0) {
      // Mark everything on main thread.
      SkippedCodeFunctions* skipped_code_functions =
          collect_code ? new (zone) SkippedCodeFunctions() : NULL;
      UnsyncMarkingVisitor mark(isolate, page_space, &marking_stack,
                                skipped_code_functions);
      IterateRoots(isolate, &mark, 0, 1);
      mark.DrainMarkingStack();
      {
        TIMELINE_FUNCTION_GC_DURATION(thread, "WeakHandleProcessing");
        MarkingWeakVisitor mark_weak(thread);
        IterateWeakRoots(isolate, &mark_weak);
      }
      // All marking done; detach code, etc.
      FinalizeResultsFrom(&mark);
    } else {
      ThreadBarrier barrier(num_tasks + 1, heap_->barrier(),
                            heap_->barrier_done());
      // Used to coordinate draining among tasks; all start out as 'busy'.
      uintptr_t num_busy = num_tasks;
      // Phase 1: Iterate over roots and drain marking stack in tasks.
      for (intptr_t i = 0; i < num_tasks; ++i) {
        MarkTask* mark_task =
            new MarkTask(this, isolate, heap_, page_space, &marking_stack,
                         &barrier, collect_code, i, num_tasks, &num_busy);
        ThreadPool* pool = Dart::thread_pool();
        pool->Run(mark_task);
      }
      bool more_to_mark = false;
      do {
        // Wait for all markers to stop.
        barrier.Sync();
#if defined(DEBUG)
        ASSERT(AtomicOperations::LoadRelaxed(&num_busy) == 0);
        // Caveat: must not allow any marker to continue past the barrier
        // before we checked num_busy, otherwise one of them might rush
        // ahead and increment it.
        barrier.Sync();
#endif

        // Wait for all markers to go through weak properties and verify
        // that there are no more objects to mark.
        // Note: we need to have two barriers here because we want all markers
        // and main thread to make decisions in lock step.
        barrier.Sync();
        more_to_mark = AtomicOperations::LoadRelaxed(&num_busy) > 0;
        barrier.Sync();
      } while (more_to_mark);

      // Phase 2: Weak processing on main thread.
      {
        TIMELINE_FUNCTION_GC_DURATION(thread, "WeakHandleProcessing");
        MarkingWeakVisitor mark_weak(thread);
        IterateWeakRoots(isolate, &mark_weak);
      }
      barrier.Sync();

      // Phase 3: Finalize results from all markers (detach code, etc.).
      barrier.Exit();
    }
    ProcessWeakTables(page_space);
    ProcessObjectIdTable(isolate);
  }
  Epilogue(isolate, invoke_api_callbacks);
}

}  // namespace dart
