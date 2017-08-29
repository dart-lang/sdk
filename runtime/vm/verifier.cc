// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/verifier.h"

#include "platform/assert.h"
#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/freelist.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"

namespace dart {

void VerifyObjectVisitor::VisitObject(RawObject* raw_obj) {
  if (raw_obj->IsHeapObject()) {
    uword raw_addr = RawObject::ToAddr(raw_obj);
    if (raw_obj->IsFreeListElement() || raw_obj->IsForwardingCorpse()) {
      if (raw_obj->IsMarked()) {
        FATAL1("Marked free list element encountered %#" Px "\n", raw_addr);
      }
    } else {
      switch (mark_expectation_) {
        case kForbidMarked:
          if (raw_obj->IsMarked()) {
            FATAL1("Marked object encountered %#" Px "\n", raw_addr);
          }
          break;
        case kAllowMarked:
          break;
        case kRequireMarked:
          if (!raw_obj->IsMarked()) {
            FATAL1("Unmarked object encountered %#" Px "\n", raw_addr);
          }
          break;
      }
    }
  }
  allocated_set_->Add(raw_obj);
  raw_obj->Validate(isolate_);
}

void VerifyPointersVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    RawObject* raw_obj = *current;
    if (raw_obj->IsHeapObject()) {
      if (!allocated_set_->Contains(raw_obj)) {
        uword raw_addr = RawObject::ToAddr(raw_obj);
        FATAL1("Invalid object pointer encountered %#" Px "\n", raw_addr);
      }
    }
  }
}

void VerifyWeakPointersVisitor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  RawObject* raw_obj = handle->raw();
  visitor_->VisitPointer(&raw_obj);
}

void VerifyPointersVisitor::VerifyPointers(MarkExpectation mark_expectation) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  HeapIterationScope iteration(thread);
  StackZone stack_zone(thread);
  ObjectSet* allocated_set = isolate->heap()->CreateAllocatedObjectSet(
      stack_zone.GetZone(), mark_expectation);

  VerifyPointersVisitor visitor(isolate, allocated_set);
  // Visit all strongly reachable objects.
  iteration.IterateObjectPointers(&visitor,
                                  StackFrameIterator::kValidateFrames);
  VerifyWeakPointersVisitor weak_visitor(&visitor);
  // Visit weak handles and prologue weak handles.
  isolate->VisitWeakPersistentHandles(&weak_visitor);
}

#if defined(DEBUG)
VerifyCanonicalVisitor::VerifyCanonicalVisitor(Thread* thread)
    : thread_(thread), instanceHandle_(Instance::Handle(thread->zone())) {}

void VerifyCanonicalVisitor::VisitObject(RawObject* obj) {
  if ((obj->GetClassId() >= kInstanceCid) &&
      (obj->GetClassId() != kTypeArgumentsCid)) {
    if (obj->IsCanonical()) {
      instanceHandle_ ^= obj;
      const bool is_canonical = instanceHandle_.CheckIsCanonical(thread_);
      if (!is_canonical) {
        OS::PrintErr("Instance `%s` is not canonical!\n",
                     instanceHandle_.ToCString());
      }
      ASSERT(is_canonical);
    }
  }
}
#endif  // defined(DEBUG)

}  // namespace dart
