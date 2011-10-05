// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/verifier.h"

#include "vm/assert.h"
#include "vm/dart.h"
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
      raw_obj->Validate();
    }
  }
}


void VerifyPointersVisitor::VerifyPointers() {
  NoGCScope no_gc;
  VerifyPointersVisitor visitor;
  Isolate::Current()->VisitObjectPointers(&visitor,
                                          StackFrameIterator::kValidateFrames);
}

}  // namespace dart
