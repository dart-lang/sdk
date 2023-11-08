// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/verifier.h"

#include "platform/assert.h"
#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/heap/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"

namespace dart {

void VerifyObjectVisitor::VisitObject(ObjectPtr obj) {
  ASSERT(obj->IsHeapObject());
  uword addr = UntaggedObject::ToAddr(obj);
  if (obj->IsFreeListElement() || obj->IsForwardingCorpse()) {
    if (obj->IsOldObject() && obj->untag()->IsMarked()) {
      FATAL("Marked free list element encountered %#" Px "\n", addr);
    }
  } else {
    switch (mark_expectation_) {
      case kForbidMarked:
        if (obj->IsOldObject() && obj->untag()->IsMarked()) {
          FATAL("Marked object encountered %#" Px "\n", addr);
        }
        break;
      case kAllowMarked:
        break;
      case kRequireMarked:
        if (obj->IsOldObject() && !obj->untag()->IsMarked()) {
          FATAL("Unmarked object encountered %#" Px "\n", addr);
        }
        break;
    }
    allocated_set_->Add(obj);
  }
  obj->Validate(isolate_group_);
}

void VerifyPointersVisitor::VisitPointers(ObjectPtr* from, ObjectPtr* to) {
  for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
    ObjectPtr obj = *ptr;
    if (obj->IsHeapObject()) {
      if (!allocated_set_->Contains(obj)) {
        if (obj->IsInstructions() &&
            allocated_set_->Contains(Page::ToWritable(obj))) {
          continue;
        }
        FATAL("%s: Invalid pointer: *0x%" Px " = 0x%" Px "\n", msg_,
              reinterpret_cast<uword>(ptr), static_cast<uword>(obj));
      }
    }
  }
}

#if defined(DART_COMPRESSED_POINTERS)
void VerifyPointersVisitor::VisitCompressedPointers(uword heap_base,
                                                    CompressedObjectPtr* from,
                                                    CompressedObjectPtr* to) {
  for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
    ObjectPtr obj = ptr->Decompress(heap_base);
    if (obj->IsHeapObject()) {
      if (!allocated_set_->Contains(obj)) {
        if (obj->IsInstructions() &&
            allocated_set_->Contains(Page::ToWritable(obj))) {
          continue;
        }
        FATAL("%s: Invalid pointer: *0x%" Px " = 0x%" Px "\n", msg_,
              reinterpret_cast<uword>(ptr), static_cast<uword>(obj));
      }
    }
  }
}
#endif

void VerifyWeakPointersVisitor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  ObjectPtr raw_obj = handle->ptr();
  visitor_->VisitPointer(&raw_obj);
}

void VerifyPointersVisitor::VerifyPointers(const char* msg,
                                           MarkExpectation mark_expectation) {
  Thread* thread = Thread::Current();
  auto isolate_group = thread->isolate_group();
  HeapIterationScope iteration(thread);
  StackZone stack_zone(thread);
  ObjectSet* allocated_set = isolate_group->heap()->CreateAllocatedObjectSet(
      stack_zone.GetZone(), mark_expectation);

  VerifyPointersVisitor visitor(isolate_group, allocated_set, msg);
  // Visit all strongly reachable objects.
  iteration.IterateObjectPointers(&visitor, ValidationPolicy::kValidateFrames);
  VerifyWeakPointersVisitor weak_visitor(&visitor);

  // Visit weak handles and prologue weak handles.
  isolate_group->VisitWeakPersistentHandles(&weak_visitor);
}

}  // namespace dart
