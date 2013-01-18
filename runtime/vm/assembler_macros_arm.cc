// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler_macros.h"

namespace dart {

void AssemblerMacros::TryAllocate(Assembler* assembler,
                                  const Class& cls,
                                  Label* failure,
                                  bool near_jump,
                                  Register instance_reg) {
  UNIMPLEMENTED();
}


void AssemblerMacros::EnterDartFrame(Assembler* assembler,
                                     intptr_t frame_size) {
  UNIMPLEMENTED();
}


void AssemblerMacros::EnterStubFrame(Assembler* assembler) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM

