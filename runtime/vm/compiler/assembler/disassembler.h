// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_H_

#include "vm/allocation.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/globals.h"
#include "vm/log.h"

namespace dart {

// Forward declaration.
class MemoryRegion;
class JSONArray;

// Disassembly formatter interface, which consumes the
// disassembled instructions in any desired form.
class DisassemblyFormatter {
 public:
  DisassemblyFormatter() {}
  virtual ~DisassemblyFormatter() {}

  // Consume the decoded instruction at the given pc.
  virtual void ConsumeInstruction(const Code& code,
                                  char* hex_buffer,
                                  intptr_t hex_size,
                                  char* human_buffer,
                                  intptr_t human_size,
                                  Object* object,
                                  uword pc) = 0;

  // Print a formatted message.
  virtual void Print(const char* format, ...) = 0;
};

// Basic disassembly formatter that outputs the disassembled instruction
// to stdout.
class DisassembleToStdout : public DisassemblyFormatter {
 public:
  DisassembleToStdout() : DisassemblyFormatter() {}
  ~DisassembleToStdout() {}

  virtual void ConsumeInstruction(const Code& code,
                                  char* hex_buffer,
                                  intptr_t hex_size,
                                  char* human_buffer,
                                  intptr_t human_size,
                                  Object* object,
                                  uword pc);

  virtual void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

 private:
  DISALLOW_ALLOCATION()
  DISALLOW_COPY_AND_ASSIGN(DisassembleToStdout);
};

// Disassemble into a JSONStream.
class DisassembleToJSONStream : public DisassemblyFormatter {
 public:
  explicit DisassembleToJSONStream(const JSONArray& jsarr)
      : DisassemblyFormatter(), jsarr_(jsarr) {}
  ~DisassembleToJSONStream() {}

  virtual void ConsumeInstruction(const Code& code,
                                  char* hex_buffer,
                                  intptr_t hex_size,
                                  char* human_buffer,
                                  intptr_t human_size,
                                  Object* object,
                                  uword pc);

  virtual void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

 private:
  const JSONArray& jsarr_;
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(DisassembleToJSONStream);
};

// Disassemble instructions.
class Disassembler : public AllStatic {
 public:
  // Disassemble instructions between start and end.
  // (The assumption is that start is at a valid instruction).
  // Return true if all instructions were successfully decoded, false otherwise.
  static void Disassemble(uword start,
                          uword end,
                          DisassemblyFormatter* formatter,
                          const Code& code);

  static void Disassemble(uword start,
                          uword end,
                          DisassemblyFormatter* formatter) {
    Disassemble(start, end, formatter, Code::Handle());
  }

  static void Disassemble(uword start, uword end, const Code& code) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    DisassembleToStdout stdout_formatter;
    LogBlock lb;
    Disassemble(start, end, &stdout_formatter, code);
#else
    UNREACHABLE();
#endif
  }

  static void Disassemble(uword start, uword end) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    DisassembleToStdout stdout_formatter;
    LogBlock lb;
    Disassemble(start, end, &stdout_formatter);
#else
    UNREACHABLE();
#endif
  }

  // Decodes one instruction.
  // Writes a hexadecimal representation into the hex_buffer and a
  // human-readable representation into the human_buffer.
  // Writes the length of the decoded instruction in bytes in out_instr_len.
  static void DecodeInstruction(char* hex_buffer,
                                intptr_t hex_size,
                                char* human_buffer,
                                intptr_t human_size,
                                int* out_instr_len,
                                const Code& code,
                                Object** object,
                                uword pc);

  static void DisassembleCode(const Function& function,
                              const Code& code,
                              bool optimized);

 private:
  static void DisassembleCodeHelper(const char* function_fullname,
                                    const Code& code,
                                    bool optimized);

  static const int kHexadecimalBufferSize = 32;
  static const int kUserReadableBufferSize = 256;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_H_
