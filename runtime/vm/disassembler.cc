// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/assembler.h"
#include "vm/globals.h"
#include "vm/os.h"
#include "vm/json_stream.h"

namespace dart {

void DisassembleToStdout::ConsumeInstruction(char* hex_buffer,
                                             intptr_t hex_size,
                                             char* human_buffer,
                                             intptr_t human_size,
                                             uword pc) {
  static const int kHexColumnWidth = 23;
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


void DisassembleToStdout::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  OS::VFPrint(stdout, format, args);
  va_end(args);
}


void DisassembleToJSONStream::ConsumeInstruction(char* hex_buffer,
                                                 intptr_t hex_size,
                                                 char* human_buffer,
                                                 intptr_t human_size,
                                                 uword pc) {
  uint8_t* pc_ptr = reinterpret_cast<uint8_t*>(pc);
  stream_->OpenObject();
  stream_->PrintProperty("type", "DisassembledInstruction");
  stream_->PrintfProperty("pc", "%p", pc_ptr);
  stream_->PrintProperty("hex", hex_buffer);
  stream_->PrintProperty("human", human_buffer);
  stream_->CloseObject();
}


void DisassembleToJSONStream::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len+1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len, format, args);
  va_end(args);
  ASSERT(len == len2);
  for (intptr_t i = 0; i < len; i++) {
    if (p[i] == '\n' || p[i] == '\r') {
      p[i] = ' ';
    }
  }
  stream_->OpenObject();
  stream_->PrintProperty("type", "DisassembledInstructionComment");
  stream_->PrintProperty("comment", p);
  stream_->CloseObject();
  free(p);
}

}  // namespace dart
