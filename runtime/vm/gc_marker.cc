// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_marker.h"

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
  MarkingVisitor(Heap* heap, PageSpace* page_space, MarkingStack* marking_stack)
      : heap_(heap),
        vm_heap_(Dart::vm_isolate()->heap()),
        page_space_(page_space),
        marking_stack_(marking_stack) {
    ASSERT(heap_ != vm_heap_);
  }

  MarkingStack* marking_stack() const { return marking_stack_; }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current);
    }
  }

 private:
  void MarkAndPush(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());
    ASSERT(page_space_->Contains(RawObject::ToAddr(raw_obj)));

    // Mark the object and push it on the marking stack.
    ASSERT(!raw_obj->IsMarked());
    RawClass* raw_class = raw_obj->ptr()->class_;
    raw_obj->SetMarkBit();
    marking_stack_->Push(raw_obj);

    // Update the number of used bytes on this page for fast accounting.
    HeapPage* page = PageSpace::PageFor(raw_obj);
    page->AddUsed(raw_obj->Size());

    // TODO(iposva): Should we mark the classes early?
    MarkObject(raw_class);
  }

  void MarkObject(RawObject* raw_obj) {
    // Fast exit if the raw object is a Smi.
    if (!raw_obj->IsHeapObject()) return;

    // Fast exit if the raw object is marked.
    if (raw_obj->IsMarked()) return;

    // Skip over new objects, but verify consistency of heap while at it.
    if (raw_obj->IsNewObject()) {
      // TODO(iposva): Add consistency check.
      return;
    }

    uword raw_addr = RawObject::ToAddr(raw_obj);
    // TODO(iposva): Premark vm_isolate objects, to avoid this extra check here.
    if (vm_heap_->Contains(raw_addr)) {
      return;
    }
    // TODO(iposva): merge old and code spaces.
    ASSERT(page_space_->Contains(raw_addr));
    MarkAndPush(raw_obj);
  }

  Heap* heap_;
  Heap* vm_heap_;
  PageSpace* page_space_;
  MarkingStack* marking_stack_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitor);
};


bool IsUnreachable(const RawObject* raw_obj) {
  if (!raw_obj->IsHeapObject()) {
    return false;
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
    WeakReference* queue = state->delayed_weak_references();
    if (queue == NULL) {
      // The delay queue is empty therefore no clean-up is required.
      return;
    }
    state->set_delayed_weak_references(NULL);
    while (queue != NULL) {
      WeakReference* reference = WeakReference::Pop(&queue);
      ASSERT(reference != NULL);
      bool is_unreachable = true;
      // Test each key object for reachability.  If a key object is
      // reachable, all value objects should be marked.
      for (intptr_t k = 0; k < reference->num_keys(); ++k) {
        if (!IsUnreachable(*reference->get_key(k))) {
          for (intptr_t v = 0; v < reference->num_values(); ++v) {
            visitor->VisitPointer(reference->get_value(v));
          }
          is_unreachable = false;
          delete reference;
          break;
        }
      }
      // If all key objects are unreachable put the reference on a
      // delay queue.  This reference will be revisited if another
      // reference is marked.
      if (is_unreachable) {
        state->DelayWeakReference(reference);
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
  if (state->delayed_weak_references() != NULL) {
    WeakReference* queue = state->delayed_weak_references();
    state->set_delayed_weak_references(NULL);
    while (queue != NULL) {
      delete WeakReference::Pop(&queue);
    }
  }
}


void GCMarker::DrainMarkingStack(Isolate* isolate,
                                 MarkingVisitor* visitor) {
  while (!visitor->marking_stack()->IsEmpty()) {
    RawObject* raw_obj = visitor->marking_stack()->Pop();
    raw_obj->VisitPointers(visitor);
  }
}


void GCMarker::MarkObjects(Isolate* isolate,
                           PageSpace* page_space,
                           bool invoke_api_callbacks) {
  MarkingStack marking_stack;
  Prologue(isolate, invoke_api_callbacks);
  MarkingVisitor mark(heap_, page_space, &marking_stack);
  IterateRoots(isolate, &mark, !invoke_api_callbacks);
  DrainMarkingStack(isolate, &mark);
  IterateWeakReferences(isolate, &mark);
  MarkingWeakVisitor mark_weak;
  IterateWeakRoots(isolate, &mark_weak, invoke_api_callbacks);
  Epilogue(isolate, invoke_api_callbacks);
}

}  // namespace dart
