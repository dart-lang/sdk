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
#include "vm/raw_object.h"
#include "vm/stack_frame.h"

namespace dart {

DEFINE_FLAG(bool, verify_on_transition, false, "Verify on dart <==> VM.");


void VerifyPointersVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    RawObject* raw_obj = *current;
    if (raw_obj->IsHeapObject()) {
      uword obj_addr = RawObject::ToAddr(raw_obj);
      if (!Isolate::Current()->heap()->Contains(obj_addr) &&
          !Dart::vm_isolate()->heap()->Contains(obj_addr)) {
        FATAL1("Invalid object pointer encountered 0x%lx\n", obj_addr);
      }
      raw_obj->Validate(isolate_);
    }
  }
}


void VerifyWeakPointersVisitor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  RawObject* raw_obj = handle->raw();
  visitor_->VisitPointer(&raw_obj);
}


void VerifyPointersVisitor::VerifyPointers() {
  NoGCScope no_gc;
  Isolate* isolate = Isolate::Current();
  VerifyPointersVisitor visitor(isolate);
  // Visit all strongly reachable objects.
  isolate->VisitObjectPointers(&visitor,
                               false,  // skip prologue weak handles
                               StackFrameIterator::kValidateFrames);
  VerifyWeakPointersVisitor weak_visitor(&visitor);
  // Visit weak handles and prologue weak handles.
  isolate->VisitWeakPersistentHandles(&weak_visitor,
                                      true);  // visit prologue weak handles
}

}  // namespace dart
