// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_marker.h"

#include "vm/allocation.h"
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
        marking_stack_(marking_stack) {}

  MarkingStack* marking_stack() const { return marking_stack_; }

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; current++) {
      MarkObject(*current);
    }
  }

 private:
  void MarkAndPush(RawObject* raw_obj) {
    ASSERT(raw_obj->IsHeapObject());

    // Mark the object and push it on the marking stack.
    ASSERT(!raw_obj->IsMarked());
    RawClass* raw_class = raw_obj->ptr()->class_;
    raw_obj->SetMarkBit();
    marking_stack_->Push(raw_obj);

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
    // ASSERT(page_space_->Contains(raw_addr));

    MarkAndPush(raw_obj);
  }

  Heap* heap_;
  Heap* vm_heap_;
  PageSpace* page_space_;
  MarkingStack* marking_stack_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(MarkingVisitor);
};


void GCMarker::Prologue(Isolate* isolate) {
  // Nothing to do at the moment.
}


void GCMarker::IterateRoots(Isolate* isolate, MarkingVisitor* visitor) {
  isolate->VisitObjectPointers(visitor,
                               StackFrameIterator::kDontValidateFrames);
  heap_->IterateNewPointers(visitor);
}


void GCMarker::DrainMarkingStack(Isolate* isolate, MarkingVisitor* visitor) {
  while (!visitor->marking_stack()->IsEmpty()) {
    RawObject* raw_obj = visitor->marking_stack()->Pop();
    raw_obj->VisitPointers(visitor);
  }
}


void GCMarker::MarkObjects(Isolate* isolate, PageSpace* page_space) {
  MarkingStack marking_stack;
  Prologue(isolate);
  MarkingVisitor mark(heap_, page_space, &marking_stack);
  IterateRoots(isolate, &mark);
  DrainMarkingStack(isolate, &mark);
}

}  // namespace dart
