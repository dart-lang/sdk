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

void VerifyObjectVisitor::VisitObject(ObjectPtr raw_obj) {
  if (raw_obj->IsHeapObject()) {
    uword raw_addr = ObjectLayout::ToAddr(raw_obj);
    if (raw_obj->IsFreeListElement() || raw_obj->IsForwardingCorpse()) {
      if (raw_obj->IsOldObject() && raw_obj->ptr()->IsMarked()) {
        FATAL1("Marked free list element encountered %#" Px "\n", raw_addr);
      }
    } else {
      switch (mark_expectation_) {
        case kForbidMarked:
          if (raw_obj->IsOldObject() && raw_obj->ptr()->IsMarked()) {
            FATAL1("Marked object encountered %#" Px "\n", raw_addr);
          }
          break;
        case kAllowMarked:
          break;
        case kRequireMarked:
          if (raw_obj->IsOldObject() && !raw_obj->ptr()->IsMarked()) {
            FATAL1("Unmarked object encountered %#" Px "\n", raw_addr);
          }
          break;
      }
    }
  }
  allocated_set_->Add(raw_obj);
  raw_obj->Validate(isolate_group_);
}

void VerifyPointersVisitor::VisitPointers(ObjectPtr* first, ObjectPtr* last) {
  for (ObjectPtr* current = first; current <= last; current++) {
    ObjectPtr raw_obj = *current;
    if (raw_obj->IsHeapObject()) {
      if (!allocated_set_->Contains(raw_obj)) {
        if (raw_obj->IsInstructions() &&
            allocated_set_->Contains(OldPage::ToWritable(raw_obj))) {
          continue;
        }
        FATAL2("Invalid object pointer encountered %#" Px ": %#" Px "\n",
               reinterpret_cast<uword>(current), static_cast<uword>(raw_obj));
      }
    }
  }
}

void VerifyWeakPointersVisitor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  ObjectPtr raw_obj = handle->raw();
  visitor_->VisitPointer(&raw_obj);
}

void VerifyPointersVisitor::VerifyPointers(MarkExpectation mark_expectation) {
  Thread* thread = Thread::Current();
  auto isolate_group = thread->isolate_group();
  HeapIterationScope iteration(thread);
  StackZone stack_zone(thread);
  ObjectSet* allocated_set = isolate_group->heap()->CreateAllocatedObjectSet(
      stack_zone.GetZone(), mark_expectation);

  VerifyPointersVisitor visitor(isolate_group, allocated_set);
  // Visit all strongly reachable objects.
  iteration.IterateObjectPointers(&visitor, ValidationPolicy::kValidateFrames);
  VerifyWeakPointersVisitor weak_visitor(&visitor);

  // Visit weak handles and prologue weak handles.
  isolate_group->VisitWeakPersistentHandles(&weak_visitor);
}

#if defined(DEBUG)
VerifyCanonicalVisitor::VerifyCanonicalVisitor(Thread* thread)
    : thread_(thread), instanceHandle_(Instance::Handle(thread->zone())) {}

void VerifyCanonicalVisitor::VisitObject(ObjectPtr obj) {
  // The caller of this function is walking heap pages using the
  // ExclusivePageIterator - which holds the pages lock.
  //
  // If we allow handle verification, then any assignment to a handle will call
  // `heap()->Contains()` for heap objects, which in return is implemented by
  // walking pages using ExclusivePageIterator, which can cause a deadlock.
  //
  // Therefore we disable the handle verification here.
  const bool old_verify_flag = FLAG_verify_handles;
  FLAG_verify_handles = false;

  // TODO(dartbug.com/36097): The heap walk can encounter canonical objects of
  // other isolates. We should either scan live objects from the roots of each
  // individual isolate, or wait until we are ready to share constants across
  // isolates.
  if (!FLAG_enable_isolate_groups || FLAG_precompiled_mode) {
    if ((obj->GetClassId() >= kInstanceCid) &&
        (obj->GetClassId() != kTypeArgumentsCid)) {
      if (obj->ptr()->IsCanonical()) {
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
  FLAG_verify_handles = old_verify_flag;
}
#endif  // defined(DEBUG)

}  // namespace dart
