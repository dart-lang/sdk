// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_marker.h"

#include <map>
#include <utility>
#include <vector>

#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/store_buffer.h"
#include "vm/thread_pool.h"
#include "vm/visitor.h"
#include "vm/object_id_ring.h"

namespace dart {

typedef StoreBufferBlock PointerBlock;  // TODO(koda): Rename to PointerBlock.
typedef StoreBuffer MarkingStack;  // TODO(koda): Create shared base class.

class DelaySet {
 private:
  typedef std::multimap<RawObject*, RawWeakProperty*> Map;
  typedef std::pair<RawObject*, RawWeakProperty*> MapEntry;

 public:
  DelaySet() : mutex_(new Mutex()) {}
  ~DelaySet() { delete mutex_; }

  // Returns 'true' if this inserted a new key (not just added a value).
  bool Insert(RawWeakProperty* raw_weak) {
    MutexLocker ml(mutex_);
    RawObject* raw_key = raw_weak->ptr()->key_;
    bool new_key = (delay_set_.find(raw_key) == delay_set_.end());
    delay_set_.insert(std::make_pair(raw_key, raw_weak));
    return new_key;
  }

  void ClearReferences() {
    MutexLocker ml(mutex_);
    for (Map::iterator it = delay_set_.begin(); it != delay_set_.end(); ++it) {
      WeakProperty::Clear(it->second);
    }
  }

  // Visit all values with a key equal to raw_obj.
  void VisitValuesForKey(RawObject* raw_obj, ObjectPointerVisitor* visitor) {
    // Extract the range into a temporary vector to iterate over it
    // while delay_set_ may be modified.
    std::vector<MapEntry> temp_copy;
    {
      MutexLocker ml(mutex_);
      std::pair<Map::iterator, Map::iterator> ret =
          delay_set_.equal_range(raw_obj);
      temp_copy.insert(temp_copy.end(), ret.first, ret.second);
      delay_set_.erase(ret.first, ret.second);
    }
    for (std::vector<MapEntry>::iterator it = temp_copy.begin();
         it != temp_copy.end(); ++it) {
      it->second->VisitPointers(visitor);
    }
  }

 private:
  Map delay_set_;
  Mutex* mutex_;
};


class MarkingVisitor : public ObjectPointerVisitor {
 public:
  MarkingVisitor(Isolate* isolate,
                 Heap* heap,
                 PageSpace* page_space,
                 MarkingStack* marking_stack,
                 DelaySet* delay_set,
                 bool visit_function_code)
      : ObjectPointerVisitor(isolate),
        thread_(Thread::Current()),
        heap_(heap),
        vm_heap_(Dart::vm_isolate()->heap()),
        class_table_(isolate->class_table()),
        page_space_(page_space),
        work_list_(marking_stack),
        delay_set_(delay_set),
        visiting_old_object_(NULL),
        visit_function_code_(visit_function_code),
        marked_bytes_(0) {
    ASSERT(heap_ != vm_heap_);
    ASSERT(thread_->isolate() == isolate);
  }

  uintptr_t marked_bytes() const { return marked_bytes_; }

  // Returns true if some non-zero amount of work was performed.
  bool DrainMarkingStack() {
    RawObject* raw_obj = work_list_.Pop();
    if (raw_obj == NULL) {
      ASSERT(visiting_old_object_ == NULL);
      return false;
    }
    do {
      VisitingOldObject(raw_obj);
      const intptr_t class_id = raw_obj->GetClassId();
      // Currently, classes are considered roots (see issue 18284), so at this
      // point, they should all be marked.
      ASSERT(isolate()->class_table()->At(class_id)->IsMarked());
      if (class_id != kWeakPropertyCid) {
        marked_bytes_ += raw_obj->VisitPointers(this);
      } else {
        RawWeakProperty* raw_weak = reinterpret_cast<RawWeakProperty*>(raw_obj);
        marked_bytes_ += raw_weak->Size();
        ProcessWeakProperty(raw_weak);
      }
      raw_obj = work_list_.Pop();
    } while (raw_obj != NULL);
    VisitingOldObject(NULL);
    return true;
  }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current, current);
    }
  }

  bool visit_function_code() const { return visit_function_code_; }

  virtual MallocGrowableArray<RawFunction*>* skipped_code_functions() {
    return &skipped_code_functions_;
  }

  // Returns the mark bit. Sets the watch bit if unmarked. (The prior value of
  // the watched bit is returned in 'watched_before' for validation purposes.)
  // TODO(koda): When synchronizing header bits, this goes in a single CAS loop.
  static bool EnsureWatchedIfWhite(RawObject* obj, bool* watched_before) {
    if (obj->IsMarked()) {
      return false;
    }
    if (!obj->IsWatched()) {
      *watched_before = false;
      obj->SetWatchedBitUnsynchronized();
    } else {
      *watched_before = true;
    }
    return true;
  }

  void ProcessWeakProperty(RawWeakProperty* raw_weak) {
    // The fate of the weak property is determined by its key.
    RawObject* raw_key = raw_weak->ptr()->key_;
    bool watched_before = false;
    if (raw_key->IsHeapObject() &&
        raw_key->IsOldObject() &&
        EnsureWatchedIfWhite(raw_key, &watched_before)) {
      // Key is white.  Delay the weak property.
      bool new_key = delay_set_->Insert(raw_weak);
      ASSERT(new_key == !watched_before);
    } else {
      // Key is gray or black.  Make the weak property black.
      raw_weak->VisitPointers(this);
    }
  }

  // Called when all marking is complete.
  void Finalize() {
    if (!visit_function_code_) {
      DetachCode();
    }
    work_list_.Finalize();
  }

  void VisitingOldObject(RawObject* obj) {
    ASSERT((obj == NULL) || obj->IsOldObject());
    visiting_old_object_ = obj;
  }

 private:
  class WorkList : public ValueObject {
   public:
    explicit WorkList(MarkingStack* marking_stack)
        : marking_stack_(marking_stack) {
      work_ = marking_stack_->PopEmptyBlock();
    }

    ~WorkList() {
      ASSERT(work_ == NULL);
      ASSERT(marking_stack_ == NULL);
    }

    // Returns NULL if no more work was found.
    RawObject* Pop() {
      ASSERT(work_ != NULL);
      if (work_->IsEmpty()) {
        // TODO(koda): Track over/underflow events and use in heuristics to
        // distribute work and prevent degenerate flip-flopping.
        PointerBlock* new_work = marking_stack_->PopNonEmptyBlock();
        if (new_work == NULL) {
          return NULL;
        }
        marking_stack_->PushBlock(work_, false);
        work_ = new_work;
      }
      return work_->Pop();
    }

    void Push(RawObject* raw_obj) {
      if (work_->IsFull()) {
        // TODO(koda): Track over/underflow events and use in heuristics to
        // distribute work and prevent degenerate flip-flopping.
        marking_stack_->PushBlock(work_, false);
        work_ = marking_stack_->PopEmptyBlock();
      }
      work_->Push(raw_obj);
    }

    void Finalize() {
      ASSERT(work_->IsEmpty());
      marking_stack_->PushBlock(work_, false);
      work_ = NULL;
      // Fail fast on attempts to mark after finalizing.
      marking_stack_ = NULL;
    }

   private:
    PointerBlock* work_;
    MarkingStack* marking_stack_;
  };

  void MarkAndPush(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT((FLAG_verify_before_gc || FLAG_verify_before_gc) ?
           page_space_->Contains(RawObject::ToAddr(raw_obj)) :
           true);

    // Mark the object and push it on the marking stack.
    ASSERT(!raw_obj->IsMarked());
    const bool is_watched = raw_obj->IsWatched();
    raw_obj->SetMarkBitUnsynchronized();
    raw_obj->ClearRememberedBitUnsynchronized();
    raw_obj->ClearWatchedBitUnsynchronized();
    if (is_watched) {
      delay_set_->VisitValuesForKey(raw_obj, this);
    }
    work_list_.Push(raw_obj);
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

    // Skip over new objects, but verify consistency of heap while at it.
    if (raw_obj->IsNewObject()) {
      // TODO(iposva): Add consistency check.
      if ((visiting_old_object_ != NULL) &&
          !visiting_old_object_->IsRemembered()) {
        ASSERT(p != NULL);
        visiting_old_object_->SetRememberedBitUnsynchronized();
        thread_->StoreBufferAddObjectGC(visiting_old_object_);
      }
      return;
    }
    if (RawObject::IsVariableSizeClassId(raw_obj->GetClassId())) {
      class_table_->UpdateLiveOld(raw_obj->GetClassId(), raw_obj->Size());
    } else {
      class_table_->UpdateLiveOld(raw_obj->GetClassId(), 0);
    }

    MarkAndPush(raw_obj);
  }

  void DetachCode() {
    intptr_t unoptimized_code_count = 0;
    intptr_t current_code_count = 0;
    for (int i = 0; i < skipped_code_functions_.length(); i++) {
      RawFunction* func = skipped_code_functions_[i];
      RawCode* code = func->ptr()->instructions_->ptr()->code_;
      if (!code->IsMarked()) {
        // If the code wasn't strongly visited through other references
        // after skipping the function's code pointer, then we disconnect the
        // code from the function.
        func->StorePointer(
            &(func->ptr()->instructions_),
            StubCode::LazyCompile_entry()->code()->ptr()->instructions_);
        if (FLAG_log_code_drop) {
          // NOTE: This code runs while GC is in progress and runs within
          // a NoHandleScope block. Hence it is not okay to use a regular Zone
          // or Scope handle. We use a direct stack handle so the raw pointer in
          // this handle is not traversed. The use of a handle is mainly to
          // be able to reuse the handle based code and avoid having to add
          // helper functions to the raw object interface.
          String name;
          name = func->ptr()->name_;
          ISL_Print("Detaching code: %s\n", name.ToCString());
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
      ISL_Print("  total detached current: %" Pd "\n", current_code_count);
      ISL_Print("  total detached unoptimized: %" Pd "\n",
                unoptimized_code_count);
    }
    // Clean up.
    skipped_code_functions_.Clear();
  }

  Thread* thread_;
  Heap* heap_;
  Heap* vm_heap_;
  ClassTable* class_table_;
  PageSpace* page_space_;
  WorkList work_list_;
  DelaySet* delay_set_;
  RawObject* visiting_old_object_;
  const bool visit_function_code_;
  MallocGrowableArray<RawFunction*> skipped_code_functions_;
  uintptr_t marked_bytes_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitor);
};


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
  MarkingWeakVisitor() : HandleVisitor(Isolate::Current()) {
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject* raw_obj = handle->raw();
    if (IsUnreachable(raw_obj)) {
      handle->UpdateUnreachable(isolate());
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(MarkingWeakVisitor);
};


void GCMarker::Prologue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks && (isolate->gc_prologue_callback() != NULL)) {
    (isolate->gc_prologue_callback())();
  }
  Thread::PrepareForGC();
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
                            bool visit_prologue_weak_persistent_handles) {
  isolate->VisitObjectPointers(visitor,
                               visit_prologue_weak_persistent_handles,
                               StackFrameIterator::kDontValidateFrames);
  heap_->new_space()->VisitObjectPointers(visitor);
}


void GCMarker::IterateWeakRoots(Isolate* isolate,
                                HandleVisitor* visitor,
                                bool visit_prologue_weak_persistent_handles) {
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  isolate->VisitWeakPersistentHandles(visitor,
                                      visit_prologue_weak_persistent_handles);
}


void GCMarker::IterateWeakReferences(Isolate* isolate,
                                     MarkingVisitor* visitor) {
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  while (true) {
    WeakReferenceSet* queue = state->delayed_weak_reference_sets();
    if (queue == NULL) {
      // The delay queue is empty therefore no clean-up is required.
      return;
    }
    state->set_delayed_weak_reference_sets(NULL);
    while (queue != NULL) {
      WeakReferenceSet* reference_set = WeakReferenceSet::Pop(&queue);
      ASSERT(reference_set != NULL);
      intptr_t num_keys = reference_set->num_keys();
      intptr_t num_values = reference_set->num_values();
      if ((num_keys == 1) && (num_values == 1) &&
          reference_set->SingletonKeyEqualsValue()) {
        // We do not have to process sets that have just one key/value pair
        // and the key and value are identical.
        continue;
      }
      bool is_unreachable = true;
      // Test each key object for reachability.  If a key object is
      // reachable, all value objects should be marked.
      for (intptr_t k = 0; k < num_keys; ++k) {
        if (!IsUnreachable(*reference_set->get_key(k))) {
          for (intptr_t v = 0; v < num_values; ++v) {
            visitor->VisitPointer(reference_set->get_value(v));
          }
          is_unreachable = false;
          // Since we have found a key object that is reachable and all
          // value objects have been marked we can break out of iterating
          // this set and move on to the next set.
          break;
        }
      }
      // If all key objects are unreachable put the reference on a
      // delay queue.  This reference will be revisited if another
      // reference is marked.
      if (is_unreachable) {
        state->DelayWeakReferenceSet(reference_set);
      }
    }
    if (!visitor->DrainMarkingStack()) {
      // Break out of the loop if there has been no forward process.
      // All key objects in the weak reference sets are unreachable
      // so we reset the weak reference sets queue.
      state->set_delayed_weak_reference_sets(NULL);
      break;
    }
  }
  ASSERT(state->delayed_weak_reference_sets() == NULL);
  // All weak reference sets are zone allocated and unmarked references which
  // were on the delay queue will be freed when the zone is released in the
  // epilog callback.
}


void GCMarker::ProcessWeakTables(PageSpace* page_space) {
  for (int sel = 0;
       sel < Heap::kNumWeakSelectors;
       sel++) {
    WeakTable* table = heap_->GetWeakTable(
        Heap::kOld, static_cast<Heap::WeakSelector>(sel));
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
  explicit ObjectIdRingClearPointerVisitor(Isolate* isolate) :
      ObjectPointerVisitor(isolate) {}


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
  ObjectIdRingClearPointerVisitor visitor(isolate);
  ObjectIdRing* ring = isolate->object_id_ring();
  ASSERT(ring != NULL);
  ring->VisitPointers(&visitor);
}


void GCMarker::MarkObjects(Isolate* isolate,
                           PageSpace* page_space,
                           bool invoke_api_callbacks,
                           bool collect_code) {
  const bool visit_function_code = !collect_code;
  Prologue(isolate, invoke_api_callbacks);
  // The API prologue/epilogue may create/destroy zones, so we must not
  // depend on zone allocations surviving beyond the epilogue callback.
  {
    StackZone zone(Thread::Current());
    MarkingStack marking_stack;
    DelaySet delay_set;
    MarkingVisitor mark(isolate, heap_, page_space, &marking_stack,
                        &delay_set, visit_function_code);
    IterateRoots(isolate, &mark, !invoke_api_callbacks);
    mark.DrainMarkingStack();
    IterateWeakReferences(isolate, &mark);
    MarkingWeakVisitor mark_weak;
    IterateWeakRoots(isolate, &mark_weak, invoke_api_callbacks);
    // TODO(koda): Add hand-over callback and centralize skipped code functions.
    marked_bytes_ = mark.marked_bytes();
    mark.Finalize();
    delay_set.ClearReferences();
    ProcessWeakTables(page_space);
    ProcessObjectIdTable(isolate);
  }
  Epilogue(isolate, invoke_api_callbacks);
}

}  // namespace dart
