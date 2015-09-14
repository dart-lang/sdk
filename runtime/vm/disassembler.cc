// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/assembler.h"
#include "vm/globals.h"
#include "vm/il_printer.h"
#include "vm/json_stream.h"
#include "vm/log.h"
#include "vm/os.h"


namespace dart {

void DisassembleToStdout::ConsumeInstruction(char* hex_buffer,
                                             intptr_t hex_size,
                                             char* human_buffer,
                                             intptr_t human_size,
                                             uword pc) {
  static const int kHexColumnWidth = 23;
  uint8_t* pc_ptr = reinterpret_cast<uint8_t*>(pc);
  THR_Print("%p    %s", pc_ptr, hex_buffer);
  int hex_length = strlen(hex_buffer);
  if (hex_length < kHexColumnWidth) {
    for (int i = kHexColumnWidth - hex_length; i > 0; i--) {
      THR_Print(" ");
    }
  }
  THR_Print("%s", human_buffer);
  THR_Print("\n");
}


void DisassembleToStdout::Print(const char* format, ...) {
  va_list args;
  va_start(args, format);
  THR_VPrint(format, args);
  va_end(args);
}


void DisassembleToJSONStream::ConsumeInstruction(char* hex_buffer,
                                                 intptr_t hex_size,
                                                 char* human_buffer,
                                                 intptr_t human_size,
                                                 uword pc) {
  // Instructions are represented as three consecutive values in a JSON array.
  // All three are strings. The first is the address of the instruction,
  // the second is the hex string of the code, and the final is a human
  // readable string.
  jsarr_.AddValueF("%" Pp "", pc);
  jsarr_.AddValue(hex_buffer);
  jsarr_.AddValue(human_buffer);
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
  // Instructions are represented as three consecutive values in a JSON array.
  // All three are strings. Comments only use the third slot. See above comment
  // for more information.
  jsarr_.AddValue("");
  jsarr_.AddValue("");
  jsarr_.AddValue(p);
  free(p);
}


class FindAddrVisitor : public FindObjectVisitor {
 public:
  explicit FindAddrVisitor(uword addr)
      : FindObjectVisitor(Isolate::Current()), addr_(addr) { }
  virtual ~FindAddrVisitor() { }

  virtual uword filter_addr() const { return addr_; }

  // Check if object matches find condition.
  virtual bool FindObject(RawObject* obj) const {
    return obj == reinterpret_cast<RawObject*>(addr_);
  }

 private:
  const uword addr_;

  DISALLOW_COPY_AND_ASSIGN(FindAddrVisitor);
};


bool Disassembler::CanFindOldObject(uword addr) {
  FindAddrVisitor visitor(addr);
  NoSafepointScope no_safepoint;
  return Isolate::Current()->heap()->FindOldObject(&visitor) != Object::null();
}


void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter,
                               const Code& code) {
  const Code::Comments& comments =
      code.IsNull() ? Code::Comments::New(0) : code.comments();
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword pc = start;
  intptr_t comment_finger = 0;
  GrowableArray<Function*> inlined_functions;
  while (pc < end) {
    const intptr_t offset = pc - start;
    const intptr_t old_comment_finger = comment_finger;
    while (comment_finger < comments.Length() &&
           comments.PCOffsetAt(comment_finger) <= offset) {
      formatter->Print(
          "        ;; %s\n",
          String::Handle(comments.CommentAt(comment_finger)).ToCString());
      comment_finger++;
    }
    if (old_comment_finger != comment_finger) {
      char str[4000];
      BufferFormatter f(str, sizeof(str));
      // Comment emitted, emit inlining information.
      code.GetInlinedFunctionsAt(offset, &inlined_functions);
      // Skip top scope function printing (last entry in 'inlined_functions').
      bool first = true;
      for (intptr_t i = inlined_functions.length() - 2; i >= 0; i--) {
        const char* name = inlined_functions[i]->ToQualifiedCString();
        if (first) {
          f.Print("        ;; Inlined [%s", name);
          first = false;
        } else {
          f.Print(" -> %s", name);
        }
      }
      if (!first) {
        f.Print("]\n");
        formatter->Print(str);
      }
    }
    int instruction_length;
    DecodeInstruction(hex_buffer,
                      sizeof(hex_buffer),
                      human_buffer,
                      sizeof(human_buffer),
                      &instruction_length, pc);
    formatter->ConsumeInstruction(hex_buffer,
                                  sizeof(hex_buffer),
                                  human_buffer,
                                  sizeof(human_buffer),
                                  pc);
    pc += instruction_length;
  }
}

}  // namespace dart
