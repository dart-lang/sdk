// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/disassembler.h"

#include "vm/assert.h"

namespace dart {

int Disassembler::DecodeInstruction(char* hexa_buffer, intptr_t hexa_size,
                                    char* human_buffer, intptr_t human_size,
                                    uword pc) {
  UNIMPLEMENTED();
  return 0;
}


const char* Disassembler::RegisterName(Register reg) {
  UNIMPLEMENTED();
  return NULL;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
