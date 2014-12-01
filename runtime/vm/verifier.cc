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

DEFINE_FLAG(bool, verify_on_transition, false, "Verify on dart <==> VM.");


void VerifyObjectVisitor::VisitObject(RawObject* raw_obj) {
  if (raw_obj->IsHeapObject()) {
    switch (mark_expectation_) {
     case kForbidMarked:
      if (raw_obj->IsMarked()) {
        uword raw_addr = RawObject::ToAddr(raw_obj);
        FATAL1("Marked object encountered %#" Px "\n", raw_addr);
      }
      break;
     case kAllowMarked:
      break;
     case kRequireMarked:
      if (!raw_obj->IsMarked()) {
        uword raw_addr = RawObject::ToAddr(raw_obj);
        FATAL1("Unmarked object encountered %#" Px "\n", raw_addr);
      }
      break;
    }
  }
  allocated_set_->Add(raw_obj);
  raw_obj->Validate(isolate());
}


void VerifyPointersVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    VerifiedMemory::Verify(reinterpret_cast<uword>(current), kWordSize);
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
  NoGCScope no_gc;
  Isolate* isolate = Isolate::Current();
  ObjectSet* allocated_set =
      isolate->heap()->CreateAllocatedObjectSet(mark_expectation);
  VerifyPointersVisitor visitor(isolate, allocated_set);
  // Visit all strongly reachable objects.
  isolate->VisitObjectPointers(&visitor,
                               false,  // skip prologue weak handles
                               StackFrameIterator::kValidateFrames);
  VerifyWeakPointersVisitor weak_visitor(&visitor);
  // Visit weak handles and prologue weak handles.
  isolate->VisitWeakPersistentHandles(&weak_visitor,
                                      true);  // visit prologue weak handles
  delete allocated_set;
}

}  // namespace dart
