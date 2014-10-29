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
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/visitor.h"
#include "vm/object_id_ring.h"

namespace dart {

// A simple chunked marking stack.
class MarkingStack : public ValueObject {
 public:
  MarkingStack()
      : head_(new MarkingStackChunk()),
        empty_chunks_(NULL),
        marking_stack_(NULL),
        top_(0) {
    marking_stack_ = head_->MarkingStackChunkMemory();
  }

  ~MarkingStack() {
    // TODO(iposva): Consider caching a couple emtpy marking stack chunks.
    ASSERT(IsEmpty());
    delete head_;
    MarkingStackChunk* next;
    while (empty_chunks_ != NULL) {
      next = empty_chunks_->next();
      delete empty_chunks_;
      empty_chunks_ = next;
    }
  }

  bool IsEmpty() const {
    return IsMarkingStackChunkEmpty() && (head_->next() == NULL);
  }

  void Push(RawObject* value) {
    ASSERT(!IsMarkingStackChunkFull());
    marking_stack_[top_] = value;
    top_++;
    if (IsMarkingStackChunkFull()) {
      MarkingStackChunk* new_chunk;
      if (empty_chunks_ == NULL) {
        new_chunk = new MarkingStackChunk();
      } else {
        new_chunk = empty_chunks_;
        empty_chunks_ = new_chunk->next();
      }
      new_chunk->set_next(head_);
      head_ = new_chunk;
      marking_stack_ = head_->MarkingStackChunkMemory();
      top_ = 0;
    }
  }

  RawObject* Pop() {
    ASSERT(head_ != NULL);
    ASSERT(!IsEmpty());
    if (IsMarkingStackChunkEmpty()) {
      MarkingStackChunk* empty_chunk = head_;
      head_ = head_->next();
      empty_chunk->set_next(empty_chunks_);
      empty_chunks_ = empty_chunk;
      marking_stack_ = head_->MarkingStackChunkMemory();
      top_ = MarkingStackChunk::kMarkingStackChunkSize;
    }
    top_--;
    return marking_stack_[top_];
  }

 private:
  class MarkingStackChunk {
   public:
    MarkingStackChunk() : next_(NULL) {}
    ~MarkingStackChunk() {}

    RawObject** MarkingStackChunkMemory() {
      return &memory_[0];
    }

    MarkingStackChunk* next() const { return next_; }
    void set_next(MarkingStackChunk* value) { next_ = value; }

    static const uint32_t kMarkingStackChunkSize = 1024;

   private:
    RawObject* memory_[kMarkingStackChunkSize];
    MarkingStackChunk* next_;

    DISALLOW_COPY_AND_ASSIGN(MarkingStackChunk);
  };

  bool IsMarkingStackChunkFull() const {
    return top_ == MarkingStackChunk::kMarkingStackChunkSize;
  }

  bool IsMarkingStackChunkEmpty() const {
    return top_ == 0;
  }

  MarkingStackChunk* head_;
  MarkingStackChunk* empty_chunks_;
  RawObject** marking_stack_;
  uint32_t top_;

  DISALLOW_COPY_AND_ASSIGN(MarkingStack);
};


class MarkingVisitor : public ObjectPointerVisitor {
 public:
  MarkingVisitor(Isolate* isolate,
                 Heap* heap,
                 PageSpace* page_space,
                 MarkingStack* marking_stack,
                 bool visit_function_code)
      : ObjectPointerVisitor(isolate),
        heap_(heap),
        vm_heap_(Dart::vm_isolate()->heap()),
        class_table_(isolate->class_table()),
        page_space_(page_space),
        marking_stack_(marking_stack),
        visiting_old_object_(NULL),
        visit_function_code_(visit_function_code) {
    ASSERT(heap_ != vm_heap_);
  }

  MarkingStack* marking_stack() const { return marking_stack_; }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current, current);
    }
  }

  bool visit_function_code() const { return visit_function_code_; }

  GrowableArray<RawFunction*>* skipped_code_functions() {
    return &skipped_code_functions_;
  }

  void DelayWeakProperty(RawWeakProperty* raw_weak) {
    RawObject* raw_key = raw_weak->ptr()->key_;
    DelaySet::iterator it = delay_set_.find(raw_key);
    if (it != delay_set_.end()) {
      ASSERT(raw_key->IsWatched());
    } else {
      ASSERT(!raw_key->IsWatched());
      raw_key->SetWatchedBit();
    }
    delay_set_.insert(std::make_pair(raw_key, raw_weak));
  }

  void Finalize() {
    DelaySet::iterator it = delay_set_.begin();
    for (; it != delay_set_.end(); ++it) {
      WeakProperty::Clear(it->second);
    }
    if (!visit_function_code_) {
      DetachCode();
    }
  }

  void VisitingOldObject(RawObject* obj) {
    ASSERT((obj == NULL) || obj->IsOldObject());
    visiting_old_object_ = obj;
  }

 private:
  void MarkAndPush(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT((FLAG_verify_before_gc || FLAG_verify_before_gc) ?
           page_space_->Contains(RawObject::ToAddr(raw_obj)) :
           true);

    // Mark the object and push it on the marking stack.
    ASSERT(!raw_obj->IsMarked());
    raw_obj->SetMarkBit();
    raw_obj->ClearRememberedBit();
    if (raw_obj->IsWatched()) {
      std::pair<DelaySet::iterator, DelaySet::iterator> ret;
      // Visit all elements with a key equal to raw_obj.
      ret = delay_set_.equal_range(raw_obj);
      // Create a copy of the range in a temporary vector to iterate over it
      // while delay_set_ may be modified.
      std::vector<DelaySetEntry> temp_copy(ret.first, ret.second);
      delay_set_.erase(ret.first, ret.second);
      for (std::vector<DelaySetEntry>::iterator it = temp_copy.begin();
           it != temp_copy.end(); ++it) {
        it->second->VisitPointers(this);
      }
      raw_obj->ClearWatchedBit();
    }
    marking_stack_->Push(raw_obj);
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
        visiting_old_object_->SetRememberedBit();
        isolate()->store_buffer()->AddObjectGC(visiting_old_object_);
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
    for (int i = 0; i < skipped_code_functions_.length(); i++) {
      RawFunction* func = skipped_code_functions_[i];
      RawCode* code = func->ptr()->instructions_->ptr()->code_;
      if (!code->IsMarked()) {
        // If the code wasn't strongly visited through other references
        // after skipping the function's code pointer, then we disconnect the
        // code from the function.
        StubCode* stub_code = isolate()->stub_code();
        func->ptr()->instructions_ =
            stub_code->LazyCompile_entry()->code()->ptr()->instructions_;
        func->ptr()->unoptimized_code_ = Code::null();
        if (FLAG_log_code_drop) {
          // NOTE: This code runs while GC is in progress and runs within
          // a NoHandleScope block. Hence it is not okay to use a regular Zone
          // or Scope handle. We use a direct stack handle so the raw pointer in
          // this handle is not traversed. The use of a handle is mainly to
          // be able to reuse the handle based code and avoid having to add
          // helper functions to the raw object interface.
          String name;
          name = func->ptr()->name_;
          OS::Print("Detaching code: %s\n", name.ToCString());
        }
      }
    }
  }

  Heap* heap_;
  Heap* vm_heap_;
  ClassTable* class_table_;
  PageSpace* page_space_;
  MarkingStack* marking_stack_;
  RawObject* visiting_old_object_;
  typedef std::multimap<RawObject*, RawWeakProperty*> DelaySet;
  typedef std::pair<RawObject*, RawWeakProperty*> DelaySetEntry;
  DelaySet delay_set_;
  const bool visit_function_code_;
  GrowableArray<RawFunction*> skipped_code_functions_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitor);
};


bool IsUnreachable(const RawObject* raw_obj) {
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
  heap_->IterateNewPointers(visitor);
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
    if (!visitor->marking_stack()->IsEmpty()) {
      DrainMarkingStack(isolate, visitor);
    } else {
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


void GCMarker::DrainMarkingStack(Isolate* isolate,
                                 MarkingVisitor* visitor) {
  while (!visitor->marking_stack()->IsEmpty()) {
    RawObject* raw_obj = visitor->marking_stack()->Pop();
    visitor->VisitingOldObject(raw_obj);
    const intptr_t class_id = raw_obj->GetClassId();
    // Currently, classes are considered roots (see issue 18284), so at this
    // point, they should all be marked.
    ASSERT(isolate->class_table()->At(class_id)->IsMarked());
    if (class_id != kWeakPropertyCid) {
      marked_bytes_ += raw_obj->VisitPointers(visitor);
    } else {
      RawWeakProperty* raw_weak = reinterpret_cast<RawWeakProperty*>(raw_obj);
      marked_bytes_ += raw_weak->Size();
      ProcessWeakProperty(raw_weak, visitor);
    }
  }
  visitor->VisitingOldObject(NULL);
}


void GCMarker::ProcessWeakProperty(RawWeakProperty* raw_weak,
                                   MarkingVisitor* visitor) {
  // The fate of the weak property is determined by its key.
  RawObject* raw_key = raw_weak->ptr()->key_;
  if (raw_key->IsHeapObject() &&
      raw_key->IsOldObject() &&
      !raw_key->IsMarked()) {
    // Key is white.  Delay the weak property.
    visitor->DelayWeakProperty(raw_weak);
  } else {
    // Key is gray or black.  Make the weak property black.
    raw_weak->VisitPointers(visitor);
  }
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
  MarkingStack marking_stack;
  Prologue(isolate, invoke_api_callbacks);
  MarkingVisitor mark(
      isolate, heap_, page_space, &marking_stack, visit_function_code);
  IterateRoots(isolate, &mark, !invoke_api_callbacks);
  DrainMarkingStack(isolate, &mark);
  IterateWeakReferences(isolate, &mark);
  MarkingWeakVisitor mark_weak;
  IterateWeakRoots(isolate, &mark_weak, invoke_api_callbacks);
  mark.Finalize();
  ProcessWeakTables(page_space);
  ProcessObjectIdTable(isolate);

  Epilogue(isolate, invoke_api_callbacks);
}

}  // namespace dart
