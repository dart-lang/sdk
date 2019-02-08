// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/marker.h"

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

// Collects a list of RawFunction whose code_ or unoptimized_code_ slots were
// treated as weak (not visited) during marking because they had low usage.
// These slots (and the corresponding entry_point_ caches) must be cleared after
// marking if the target RawCode were not otherwise marked. (--collect-code)
class SkippedCodeFunctions {
 public:
  SkippedCodeFunctions() {}

  void Add(RawFunction* func) {
    // With concurrent mark, we hold raw pointers across safepoints.
    ASSERT(func->IsOldObject());

    skipped_code_functions_.Add(func);
  }

  void DetachCode() {
#if defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    Thread* thread = Thread::Current();
    StackZone zone(thread);  // For log prints.
    HANDLESCOPE(thread);

    intptr_t unoptimized_code_count = 0;
    intptr_t current_code_count = 0;
    for (int i = 0; i < skipped_code_functions_.length(); i++) {
      RawFunction* func = skipped_code_functions_[i];
      RawCode* code = func->ptr()->code_;
      if (!code->IsMarked()) {
        // If the code wasn't strongly visited through other references
        // after skipping the function's code pointer, then we disconnect the
        // code from the function.
        if (FLAG_enable_interpreter && Function::HasBytecode(func)) {
          func->StorePointer(&(func->ptr()->code_),
                             StubCode::InterpretCall().raw());
          uword entry_point = StubCode::InterpretCall().EntryPoint();
          func->ptr()->entry_point_ = entry_point;
          func->ptr()->unchecked_entry_point_ = entry_point;
        } else {
          func->StorePointer(&(func->ptr()->code_),
                             StubCode::LazyCompile().raw());
          uword entry_point = StubCode::LazyCompile().EntryPoint();
          func->ptr()->entry_point_ = entry_point;
          func->ptr()->unchecked_entry_point_ = entry_point;
        }
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
  MallocGrowableArray<RawFunction*> skipped_code_functions_;

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
      // Generated code appends to marking stacks; tell MemorySanitizer.
      MSAN_UNPOISON(work_, sizeof(*work_));
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

  void AbandonWork() {
    marking_stack_->PushBlock(work_);
    work_ = NULL;
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
                     MarkingStack* deferred_marking_stack,
                     SkippedCodeFunctions* skipped_code_functions)
      : ObjectPointerVisitor(isolate),
        thread_(Thread::Current()),
#ifndef PRODUCT
        num_classes_(isolate->class_table()->Capacity()),
        class_stats_count_(new intptr_t[num_classes_]),
        class_stats_size_(new intptr_t[num_classes_]),
#endif  // !PRODUCT
        page_space_(page_space),
        work_list_(marking_stack),
        deferred_work_list_(deferred_marking_stack),
        delayed_weak_properties_(NULL),
        skipped_code_functions_(skipped_code_functions),
        marked_bytes_(0),
        marked_micros_(0) {
    ASSERT(thread_->isolate() == isolate);
#ifndef PRODUCT
    for (intptr_t i = 0; i < num_classes_; i++) {
      class_stats_count_[i] = 0;
      class_stats_size_[i] = 0;
    }
#endif  // !PRODUCT
  }

  ~MarkingVisitorBase() {
    delete skipped_code_functions_;
#ifndef PRODUCT
    delete[] class_stats_count_;
    delete[] class_stats_size_;
#endif  // !PRODUCT
  }

  uintptr_t marked_bytes() const { return marked_bytes_; }
  int64_t marked_micros() const { return marked_micros_; }
  void AddMicros(int64_t micros) { marked_micros_ += micros; }

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
        cur_weak->VisitPointersNonvirtual(this);
      } else {
        // Requeue this weak property to be handled later.
        EnqueueWeakProperty(cur_weak);
      }
      // Advance to next weak property in the queue.
      cur_weak = reinterpret_cast<RawWeakProperty*>(next_weak);
    }
    return marked;
  }

  void DrainMarkingStack() {
    RawObject* raw_obj = work_list_.Pop();
    if ((raw_obj == NULL) && ProcessPendingWeakProperties()) {
      raw_obj = work_list_.Pop();
    }

    if (raw_obj == NULL) {
      return;
    }

    do {
      do {
        // First drain the marking stacks.
        const intptr_t class_id = raw_obj->GetClassId();

        intptr_t size;
        if (class_id != kWeakPropertyCid) {
          size = raw_obj->VisitPointersNonvirtual(this);
        } else {
          RawWeakProperty* raw_weak = static_cast<RawWeakProperty*>(raw_obj);
          size = ProcessWeakProperty(raw_weak);
        }
        marked_bytes_ += size;
        NOT_IN_PRODUCT(UpdateLiveOld(class_id, size));

        raw_obj = work_list_.Pop();
      } while (raw_obj != NULL);

      // Marking stack is empty.
      ProcessPendingWeakProperties();

      // Check whether any further work was pushed either by other markers or
      // by the handling of weak properties.
      raw_obj = work_list_.Pop();
    } while (raw_obj != NULL);
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current);
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
      return raw_weak->HeapSize();
    }
    // Key is gray or black. Make the weak property black.
    return raw_weak->VisitPointersNonvirtual(this);
  }

  void FinalizeInstructions() {
    RawObject* raw_obj;
    while ((raw_obj = deferred_work_list_.Pop()) != NULL) {
      ASSERT(raw_obj->IsInstructions());
      RawInstructions* instr = static_cast<RawInstructions*>(raw_obj);
      if (TryAcquireMarkBit(instr)) {
        intptr_t size = instr->HeapSize();
        marked_bytes_ += size;
        NOT_IN_PRODUCT(UpdateLiveOld(kInstructionsCid, size));
      }
    }
    deferred_work_list_.Finalize();
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

  void AbandonWork() {
    work_list_.AbandonWork();
    deferred_work_list_.AbandonWork();
  }

 private:
  void PushMarked(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT(raw_obj->IsOldObject());

    // Push the marked object on the marking stack.
    ASSERT(raw_obj->IsMarked());
    work_list_.Push(raw_obj);
  }

  static bool TryAcquireMarkBit(RawObject* raw_obj) {
    // While it might seem this is redundant with TryAcquireMarkBit, we must
    // do this check first to avoid attempting an atomic::fetch_and on the
    // read-only vm-isolate or image pages, which can fault even if there is no
    // change in the value.
    if (raw_obj->IsMarked()) return false;

    if (!sync) {
      raw_obj->SetMarkBitUnsynchronized();
      return true;
    } else {
      return raw_obj->TryAcquireMarkBit();
    }
  }

  void MarkObject(RawObject* raw_obj) {
    // Fast exit if the raw object is a Smi.
    if (raw_obj->IsSmiOrNewObject()) {
      return;
    }

    intptr_t class_id = raw_obj->GetClassId();
    ASSERT(class_id != kFreeListElement);

    if (sync && UNLIKELY(class_id == kInstructionsCid)) {
      // If this is the concurrent marker, instruction pages may be
      // non-writable.
      deferred_work_list_.Push(raw_obj);
      return;
    }

    if (!TryAcquireMarkBit(raw_obj)) {
      // Already marked.
      return;
    }

    PushMarked(raw_obj);
  }

#ifndef PRODUCT
  void UpdateLiveOld(intptr_t class_id, intptr_t size) {
    ASSERT(class_id < num_classes_);
    class_stats_count_[class_id] += 1;
    class_stats_size_[class_id] += size;
  }
#endif  // !PRODUCT

  Thread* thread_;
#ifndef PRODUCT
  intptr_t num_classes_;
  intptr_t* class_stats_count_;
  intptr_t* class_stats_size_;
#endif  // !PRODUCT
  PageSpace* page_space_;
  MarkerWorkList work_list_;
  MarkerWorkList deferred_work_list_;
  RawWeakProperty* delayed_weak_properties_;
  SkippedCodeFunctions* skipped_code_functions_;
  uintptr_t marked_bytes_;
  int64_t marked_micros_;

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
  explicit MarkingWeakVisitor(Thread* thread)
      : HandleVisitor(thread), class_table_(thread->isolate()->class_table()) {}

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject* raw_obj = handle->raw();
    if (IsUnreachable(raw_obj)) {
      handle->UpdateUnreachable(thread()->isolate());
    } else {
#ifndef PRODUCT
      intptr_t cid = raw_obj->GetClassIdMayBeSmi();
      intptr_t size = handle->external_size();
      if (raw_obj->IsSmiOrOldObject()) {
        class_table_->UpdateLiveOldExternal(cid, size);
      } else {
        class_table_->UpdateLiveNewExternal(cid, size);
      }
#endif  // !PRODUCT
    }
  }

 private:
  ClassTable* class_table_;

  DISALLOW_COPY_AND_ASSIGN(MarkingWeakVisitor);
};

void GCMarker::Prologue() {
  isolate_->ReleaseStoreBuffers();

#ifndef DART_PRECOMPILED_RUNTIME
  if (isolate_->IsMutatorThreadScheduled()) {
    Interpreter* interpreter = isolate_->mutator_thread()->interpreter();
    if (interpreter != NULL) {
      interpreter->MajorGC();
    }
  }
#endif
}

void GCMarker::Epilogue() {
  // Filter collected objects from the remembered set.
  StoreBuffer* store_buffer = isolate_->store_buffer();
  StoreBufferBlock* reading = store_buffer->Blocks();
  StoreBufferBlock* writing = store_buffer->PopNonFullBlock();
  while (reading != NULL) {
    StoreBufferBlock* next = reading->next();
    // Generated code appends to store buffers; tell MemorySanitizer.
    MSAN_UNPOISON(reading, sizeof(*reading));
    while (!reading->IsEmpty()) {
      RawObject* raw_object = reading->Pop();
      ASSERT(!raw_object->IsForwardingCorpse());
      ASSERT(raw_object->IsRemembered());
      if (raw_object->IsMarked()) {
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

enum RootSlices {
  kIsolate = 0,
  kNewSpace = 1,
  kNumRootSlices = 2,
};

void GCMarker::ResetRootSlices() {
  root_slices_not_started_ = kNumRootSlices;
  root_slices_not_finished_ = kNumRootSlices;
}

void GCMarker::IterateRoots(ObjectPointerVisitor* visitor) {
  for (;;) {
    intptr_t task =
        AtomicOperations::FetchAndDecrement(&root_slices_not_started_) - 1;
    if (task < 0) {
      return;  // No more tasks.
    }

    switch (task) {
      case kIsolate: {
        TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ProcessRoots");
        isolate_->VisitObjectPointers(visitor,
                                      ValidationPolicy::kDontValidateFrames);
        break;
      }
      case kNewSpace: {
        TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ProcessNewSpace");
        heap_->new_space()->VisitObjectPointers(visitor);
        break;
      }
      default:
        FATAL1("%" Pd, task);
        UNREACHABLE();
    }

    intptr_t remaining =
        AtomicOperations::FetchAndDecrement(&root_slices_not_finished_) - 1;
    if (remaining == 0) {
      MonitorLocker ml(&root_slices_monitor_);
      ml.Notify();
      return;
    }
  }
}

void GCMarker::IterateWeakRoots(HandleVisitor* visitor) {
  ApiState* state = isolate_->api_state();
  ASSERT(state != NULL);
  isolate_->VisitWeakPersistentHandles(visitor);
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

void GCMarker::ProcessObjectIdTable() {
#ifndef PRODUCT
  if (!FLAG_support_service) {
    return;
  }
  ObjectIdRingClearPointerVisitor visitor(isolate_);
  ObjectIdRing* ring = isolate_->object_id_ring();
  ASSERT(ring != NULL);
  ring->VisitPointers(&visitor);
#endif  // !PRODUCT
}

class ParallelMarkTask : public ThreadPool::Task {
 public:
  ParallelMarkTask(GCMarker* marker,
                   Isolate* isolate,
                   MarkingStack* marking_stack,
                   ThreadBarrier* barrier,
                   SyncMarkingVisitor* visitor,
                   uintptr_t* num_busy)
      : marker_(marker),
        isolate_(isolate),
        marking_stack_(marking_stack),
        barrier_(barrier),
        visitor_(visitor),
        num_busy_(num_busy) {}

  virtual void Run() {
    bool result =
        Thread::EnterIsolateAsHelper(isolate_, Thread::kMarkerTask, true);
    ASSERT(result);
    {
      TIMELINE_FUNCTION_GC_DURATION(Thread::Current(), "ParallelMark");
      int64_t start = OS::GetCurrentMonotonicMicros();

      // Phase 1: Iterate over roots and drain marking stack in tasks.
      marker_->IterateRoots(visitor_);

      bool more_to_mark = false;
      do {
        do {
          visitor_->DrainMarkingStack();

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
        more_to_mark = visitor_->ProcessPendingWeakProperties();
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

      visitor_->FinalizeInstructions();

      // Phase 2: Weak processing and follow-up marking on main thread.
      barrier_->Sync();

      // Phase 3: Finalize results from all markers (detach code, etc.).
      int64_t stop = OS::GetCurrentMonotonicMicros();
      visitor_->AddMicros(stop - start);
      if (FLAG_log_marker_tasks) {
        THR_Print("Task marked %" Pd " bytes in %" Pd64 " micros.\n",
                  visitor_->marked_bytes(), visitor_->marked_micros());
      }
      marker_->FinalizeResultsFrom(visitor_);

      delete visitor_;
    }
    Thread::ExitIsolateAsHelper(true);

    // This task is done. Notify the original thread.
    barrier_->Exit();
  }

 private:
  GCMarker* marker_;
  Isolate* isolate_;
  MarkingStack* marking_stack_;
  ThreadBarrier* barrier_;
  SyncMarkingVisitor* visitor_;
  uintptr_t* num_busy_;

  DISALLOW_COPY_AND_ASSIGN(ParallelMarkTask);
};

class ConcurrentMarkTask : public ThreadPool::Task {
 public:
  ConcurrentMarkTask(GCMarker* marker,
                     Isolate* isolate,
                     PageSpace* page_space,
                     SyncMarkingVisitor* visitor)
      : marker_(marker),
        isolate_(isolate),
        page_space_(page_space),
        visitor_(visitor) {
#if defined(DEBUG)
    MonitorLocker ml(page_space_->tasks_lock());
    ASSERT(page_space_->phase() == PageSpace::kMarking);
#endif
  }

  virtual void Run() {
    bool result =
        Thread::EnterIsolateAsHelper(isolate_, Thread::kMarkerTask, true);
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

    isolate_->ScheduleInterrupts(Thread::kVMInterrupt);
    // Exit isolate cleanly *before* notifying it, to avoid shutdown race.
    Thread::ExitIsolateAsHelper(true);
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
  Isolate* isolate_;
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

GCMarker::GCMarker(Isolate* isolate, Heap* heap)
    : isolate_(isolate),
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
  if (isolate_->marking_stack() != NULL) {
    isolate_->DisableIncrementalBarrier();
    for (intptr_t i = 0; i < FLAG_marker_tasks; i++) {
      visitors_[i]->AbandonWork();
      delete visitors_[i];
    }
  }
  delete[] visitors_;
}

void GCMarker::StartConcurrentMark(PageSpace* page_space, bool collect_code) {
  isolate_->EnableIncrementalBarrier(&marking_stack_, &deferred_marking_stack_);

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

  ResetRootSlices();
  for (intptr_t i = 0; i < num_tasks; i++) {
    ASSERT(visitors_[i] == NULL);
    SkippedCodeFunctions* skipped_code_functions =
        collect_code ? new SkippedCodeFunctions() : NULL;
    visitors_[i] = new SyncMarkingVisitor(isolate_, page_space, &marking_stack_,
                                          &deferred_marking_stack_,
                                          skipped_code_functions);

    // Begin marking on a helper thread.
    bool result = Dart::thread_pool()->Run(
        new ConcurrentMarkTask(this, isolate_, page_space, visitors_[i]));
    ASSERT(result);
  }

  // Wait for roots to be marked before exiting safepoint.
  MonitorLocker ml(&root_slices_monitor_);
  while (root_slices_not_finished_ > 0) {
    ml.Wait();
  }
}

void GCMarker::MarkObjects(PageSpace* page_space, bool collect_code) {
  if (isolate_->marking_stack() != NULL) {
    isolate_->DisableIncrementalBarrier();
  }

  Prologue();
  {
    Thread* thread = Thread::Current();
    const int num_tasks = FLAG_marker_tasks;
    if (num_tasks == 0) {
      TIMELINE_FUNCTION_GC_DURATION(thread, "Mark");
      int64_t start = OS::GetCurrentMonotonicMicros();
      // Mark everything on main thread.
      SkippedCodeFunctions* skipped_code_functions =
          collect_code ? new SkippedCodeFunctions() : NULL;
      UnsyncMarkingVisitor mark(isolate_, page_space, &marking_stack_,
                                &deferred_marking_stack_,
                                skipped_code_functions);
      ResetRootSlices();
      IterateRoots(&mark);
      mark.DrainMarkingStack();
      mark.FinalizeInstructions();
      {
        TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakHandles");
        MarkingWeakVisitor mark_weak(thread);
        IterateWeakRoots(&mark_weak);
      }
      // All marking done; detach code, etc.
      int64_t stop = OS::GetCurrentMonotonicMicros();
      mark.AddMicros(stop - start);
      FinalizeResultsFrom(&mark);
    } else {
      ThreadBarrier barrier(num_tasks + 1, heap_->barrier(),
                            heap_->barrier_done());
      ResetRootSlices();
      // Used to coordinate draining among tasks; all start out as 'busy'.
      uintptr_t num_busy = num_tasks;
      // Phase 1: Iterate over roots and drain marking stack in tasks.
      for (intptr_t i = 0; i < num_tasks; ++i) {
        SyncMarkingVisitor* visitor;
        if (visitors_[i] != NULL) {
          visitor = visitors_[i];
          visitors_[i] = NULL;
        } else {
          SkippedCodeFunctions* skipped_code_functions =
              collect_code ? new SkippedCodeFunctions() : NULL;
          visitor = new SyncMarkingVisitor(
              isolate_, page_space, &marking_stack_, &deferred_marking_stack_,
              skipped_code_functions);
        }

        bool result = Dart::thread_pool()->Run(new ParallelMarkTask(
            this, isolate_, &marking_stack_, &barrier, visitor, &num_busy));
        ASSERT(result);
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
        TIMELINE_FUNCTION_GC_DURATION(thread, "ProcessWeakHandles");
        MarkingWeakVisitor mark_weak(thread);
        IterateWeakRoots(&mark_weak);
      }
      barrier.Sync();

      // Phase 3: Finalize results from all markers (detach code, etc.).
      barrier.Exit();
    }
    ProcessWeakTables(page_space);
    ProcessObjectIdTable();
  }
  Epilogue();
}

}  // namespace dart
