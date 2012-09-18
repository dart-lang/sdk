// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_marker.h"

#include <map>
#include <utility>

#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/isolate.h"
#include "vm/pages.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/visitor.h"

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
                 MarkingStack* marking_stack)
      : ObjectPointerVisitor(isolate),
        heap_(heap),
        vm_heap_(Dart::vm_isolate()->heap()),
        page_space_(page_space),
        marking_stack_(marking_stack),
        update_store_buffers_(false) {
    ASSERT(heap_ != vm_heap_);
  }

  MarkingStack* marking_stack() const { return marking_stack_; }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current, current);
    }
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
  }

  void set_update_store_buffers(bool val) { update_store_buffers_ = val; }

 private:
  void MarkAndPush(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT((FLAG_verify_before_gc || FLAG_verify_before_gc) ?
           page_space_->Contains(RawObject::ToAddr(raw_obj)) :
           true);

    // Mark the object and push it on the marking stack.
    ASSERT(!raw_obj->IsMarked());
    RawClass* raw_class = isolate()->class_table()->At(raw_obj->GetClassId());
    raw_obj->SetMarkBit();
    if (raw_obj->IsWatched()) {
      std::pair<DelaySet::iterator, DelaySet::iterator> ret;
      // Visit all elements with a key equal to raw_obj.
      ret = delay_set_.equal_range(raw_obj);
      for (DelaySet::iterator it = ret.first; it != ret.second; ++it) {
        it->second->VisitPointers(this);
      }
      delay_set_.erase(ret.first, ret.second);
      raw_obj->ClearWatchedBit();
    }
    marking_stack_->Push(raw_obj);

    // Update the number of used bytes on this page for fast accounting.
    HeapPage* page = PageSpace::PageFor(raw_obj);
    page->AddUsed(raw_obj->Size());

    // TODO(iposva): Should we mark the classes early?
    MarkObject(raw_class, NULL);
  }

  void MarkObject(RawObject* raw_obj, RawObject** p) {
    // Fast exit if the raw object is a Smi.
    if (!raw_obj->IsHeapObject()) return;

    // Fast exit if the raw object is marked.
    if (raw_obj->IsMarked()) return;

    // Skip over new objects, but verify consistency of heap while at it.
    if (raw_obj->IsNewObject()) {
      // TODO(iposva): Add consistency check.
      if (update_store_buffers_) {
        ASSERT(p != NULL);
        isolate()->store_buffer()->AddPointer(reinterpret_cast<uword>(p));
      }
      return;
    }

    // TODO(iposva): merge old and code spaces.
    MarkAndPush(raw_obj);
  }

  Heap* heap_;
  Heap* vm_heap_;
  PageSpace* page_space_;
  MarkingStack* marking_stack_;
  typedef std::multimap<RawObject*, RawWeakProperty*> DelaySet;
  DelaySet delay_set_;
  bool update_store_buffers_;

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
  MarkingWeakVisitor() {
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    RawObject* raw_obj = handle->raw();
    if (IsUnreachable(raw_obj)) {
      FinalizablePersistentHandle::Finalize(handle);
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(MarkingWeakVisitor);
};


void GCMarker::Prologue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks) {
    isolate->gc_prologue_callbacks().Invoke();
  }
  // The store buffers will be rebuilt as part of marking, reset them now.
  isolate->store_buffer()->Reset();
  isolate->store_buffer_block()->Reset();
}


void GCMarker::Epilogue(Isolate* isolate, bool invoke_api_callbacks) {
  if (invoke_api_callbacks) {
    isolate->gc_epilogue_callbacks().Invoke();
  }
}


void GCMarker::IterateRoots(Isolate* isolate,
                            ObjectPointerVisitor* visitor,
                            bool visit_prologue_weak_persistent_handles) {
  isolate->VisitObjectPointers(visitor,
                               visit_prologue_weak_persistent_handles,
                               StackFrameIterator::kDontValidateFrames);
  heap_->IterateNewPointers(visitor);
  heap_->IterateCodePointers(visitor);
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
      bool is_unreachable = true;
      // Test each key object for reachability.  If a key object is
      // reachable, all value objects should be marked.
      for (intptr_t k = 0; k < reference_set->num_keys(); ++k) {
        if (!IsUnreachable(*reference_set->get_key(k))) {
          for (intptr_t v = 0; v < reference_set->num_values(); ++v) {
            visitor->VisitPointer(reference_set->get_value(v));
          }
          is_unreachable = false;
          delete reference_set;
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
      break;
    }
  }
  // Deallocate any unmarked references on the delay queue.
  if (state->delayed_weak_reference_sets() != NULL) {
    WeakReferenceSet* queue = state->delayed_weak_reference_sets();
    state->set_delayed_weak_reference_sets(NULL);
    while (queue != NULL) {
      delete WeakReferenceSet::Pop(&queue);
    }
  }
}


void GCMarker::DrainMarkingStack(Isolate* isolate,
                                 MarkingVisitor* visitor) {
  visitor->set_update_store_buffers(true);
  while (!visitor->marking_stack()->IsEmpty()) {
    RawObject* raw_obj = visitor->marking_stack()->Pop();
    if (raw_obj->GetClassId() != kWeakPropertyCid) {
      raw_obj->VisitPointers(visitor);
    } else {
      RawWeakProperty* raw_weak = reinterpret_cast<RawWeakProperty*>(raw_obj);
      ProcessWeakProperty(raw_weak, visitor);
    }
  }
  visitor->set_update_store_buffers(false);
}


void GCMarker::ProcessWeakProperty(RawWeakProperty* raw_weak,
                                   MarkingVisitor* visitor) {
  // The fate of the weak property is determined by its key.
  RawObject* raw_key = raw_weak->ptr()->key_;
  if (!raw_key->IsMarked()) {
    // Key is white.  Delay the weak property.
    visitor->DelayWeakProperty(raw_weak);
  } else {
    // Key is gray or black.  Make the weak property black.
    raw_weak->VisitPointers(visitor);
  }
}


void GCMarker::ProcessPeerReferents(PageSpace* page_space) {
  PageSpace::PeerTable* peer_table = page_space->GetPeerTable();
  PageSpace::PeerTable::iterator it = peer_table->begin();
  while (it != peer_table->end()) {
    RawObject* raw_obj = it->first;
    ASSERT(raw_obj->IsHeapObject());
    if (raw_obj->IsMarked()) {
      // The object has survived.  Do nothing.
      ++it;
    } else {
      // The object has become garbage.  Remove its record.
      peer_table->erase(it++);
    }
  }
}


void GCMarker::MarkObjects(Isolate* isolate,
                           PageSpace* page_space,
                           bool invoke_api_callbacks) {
  MarkingStack marking_stack;
  Prologue(isolate, invoke_api_callbacks);
  MarkingVisitor mark(isolate, heap_, page_space, &marking_stack);
  IterateRoots(isolate, &mark, !invoke_api_callbacks);
  DrainMarkingStack(isolate, &mark);
  IterateWeakReferences(isolate, &mark);
  MarkingWeakVisitor mark_weak;
  IterateWeakRoots(isolate, &mark_weak, invoke_api_callbacks);
  mark.Finalize();
  ProcessPeerReferents(page_space);
  Epilogue(isolate, invoke_api_callbacks);
}

}  // namespace dart
