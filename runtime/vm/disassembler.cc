// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/assembler.h"
#include "vm/globals.h"
#include "vm/os.h"

namespace dart {

void DisassembleToStdout::ConsumeInstruction(char* hex_buffer,
                                             intptr_t hex_size,
                                             char* human_buffer,
                                             intptr_t human_size,
                                             uword pc) {
  static const int kHexColumnWidth = 18;
  uint8_t* pc_ptr = reinterpret_cast<uint8_t*>(pc);
  OS::Print("%p    %s", pc_ptr, hex_buffer);
  int hex_length = strlen(hex_buffer);
  if (hex_length < kHexColumnWidth) {
    for (int i = kHexColumnWidth - hex_length; i > 0; i--) {
      OS::Print(" ");
    }
  }
  OS::Print("%s", human_buffer);
  OS::Print("\n");
}


void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter) {
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword pc = start;
  while (pc < end) {
    int instruction_length = DecodeInstruction(hex_buffer,
                                               sizeof(hex_buffer),
                                               human_buffer,
                                               sizeof(human_buffer),
                                               pc);
    formatter->ConsumeInstruction(hex_buffer,
                                  sizeof(hex_buffer),
                                  human_buffer,
                                  sizeof(human_buffer),
                                  pc);
    pc += instruction_length;
  }
}


void Disassembler::DisassembleMemoryRegionRange(
    const MemoryRegion& instructions,
    uword from,
    uword to,
    DisassemblyFormatter *formatter) {
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword start = instructions.start();
  uword end = instructions.end();
  ASSERT((from >= start) && (to <= end) && (from <= to));
  uword pc = start;
  uword stop = Utils::Minimum(end, to);
  while (pc < stop) {
    int instruction_length = DecodeInstruction(hex_buffer,
                                               sizeof(hex_buffer),
                                               human_buffer,
                                               sizeof(human_buffer),
                                               pc);
    if (pc >= from) {
      formatter->ConsumeInstruction(hex_buffer,
                                    sizeof(hex_buffer),
                                    human_buffer,
                                    sizeof(human_buffer),
                                    pc);
    }
    pc += instruction_length;
  }
}

}  // namespace dart
