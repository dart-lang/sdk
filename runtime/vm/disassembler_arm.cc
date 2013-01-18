// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)
#include "platform/assert.h"

namespace dart {

int Disassembler::DecodeInstruction(char* hex_buffer, intptr_t hex_size,
                                    char* human_buffer, intptr_t human_size,
                                    uword pc) {
  UNIMPLEMENTED();
  return 0;
}


void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter,
                               const Code::Comments& comments) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
