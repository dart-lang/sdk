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
                                  Register class_reg,
                                  Label* failure,
                                  Register instance_reg) {
#if defined(DEBUG)
  __ Untested("AssemblerMacros::TryAllocate");
  Label ok;
  __ LoadObject(instance_reg, cls);
  __ cmpl(instance_reg, class_reg);
  __ j(EQUAL, &ok, Assembler::kNearJump);
  __ Stop("AssemblerMacros::TryAllocate, wrong arguments");
  __ Bind(&ok);
#endif
  ASSERT(failure != NULL);
  ASSERT(class_reg != instance_reg);
  if (FLAG_inline_alloc) {
    Heap* heap = Isolate::Current()->heap();
    const intptr_t instance_size = cls.instance_size();
    __ movq(instance_reg, Address::Absolute(heap->TopAddress()));
    __ addq(instance_reg, Immediate(instance_size));
    // instance_reg: potential next object start.
    __ cmpq(instance_reg, Address::Absolute(heap->EndAddress()));
    __ j(ABOVE_EQUAL, failure, Assembler::kNearJump);
    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    __ movq(Address::Absolute(heap->TopAddress()), instance_reg);
    ASSERT(instance_size >= kHeapObjectTag);
    __ subq(instance_reg, Immediate(instance_size - kHeapObjectTag));
    __ movq(FieldAddress(instance_reg, Instance::class_offset()), class_reg);
  } else {
    __ jmp(failure);
  }
}

#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
