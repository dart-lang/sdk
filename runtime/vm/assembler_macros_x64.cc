// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler_macros.h"

#include "vm/assembler.h"

namespace dart {

DECLARE_FLAG(bool, inline_alloc);

#define __ assembler->

// Static.
void AssemblerMacros::TryAllocate(Assembler* assembler,
                                  const Class& cls,
                                  Label* failure,
                                  bool near_jump,
                                  Register instance_reg) {
  ASSERT(failure != NULL);
  if (FLAG_inline_alloc) {
    Heap* heap = Isolate::Current()->heap();
    const intptr_t instance_size = cls.instance_size();
    __ movq(TMP, Immediate(heap->TopAddress()));
    __ movq(instance_reg, Address(TMP, 0));
    __ addq(instance_reg, Immediate(instance_size));
    // instance_reg: potential next object start.
    __ movq(TMP, Immediate(heap->EndAddress()));
    __ cmpq(instance_reg, Address(TMP, 0));
    __ j(ABOVE_EQUAL, failure, near_jump);
    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    __ movq(TMP, Immediate(heap->TopAddress()));
    __ movq(Address(TMP, 0), instance_reg);
    ASSERT(instance_size >= kHeapObjectTag);
    __ subq(instance_reg, Immediate(instance_size - kHeapObjectTag));
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    __ movq(FieldAddress(instance_reg, Object::tags_offset()), Immediate(tags));
  } else {
    __ jmp(failure);
  }
}


void AssemblerMacros::EnterDartFrame(Assembler* assembler,
                                     intptr_t frame_size) {
  const intptr_t offset = assembler->CodeSize();
  __ EnterFrame(0);
  Label dart_entry;
  __ call(&dart_entry);
  __ Bind(&dart_entry);
  // Adjust saved PC for any intrinsic code that could have been generated
  // before a frame is created.
  if (offset != 0) {
    __ addq(Address(RSP, 0), Immediate(-offset));
  }
  if (frame_size != 0) {
    __ subq(RSP, Immediate(frame_size));
  }
}


void AssemblerMacros::EnterStubFrame(Assembler* assembler) {
  __ EnterFrame(0);
  __ pushq(Immediate(0));  // Push 0 in the saved PC area for stub frames.
}

#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
