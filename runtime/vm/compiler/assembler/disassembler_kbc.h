// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_KBC_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_KBC_H_

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/disassembler.h"

namespace dart {

// Disassemble instructions.
class KernelBytecodeDisassembler : public AllStatic {
 public:
  // Disassemble instructions between start and end.
  // (The assumption is that start is at a valid instruction).
  // Return true if all instructions were successfully decoded, false otherwise.
  static void Disassemble(uword start,
                          uword end,
                          DisassemblyFormatter* formatter,
                          const Bytecode& bytecode);

  static void Disassemble(uword start,
                          uword end,
                          DisassemblyFormatter* formatter) {
    Disassemble(start, end, formatter, Bytecode::Handle());
  }

  static void Disassemble(uword start, uword end, const Bytecode& bytecode) {
#if !defined(PRODUCT)
    DisassembleToStdout stdout_formatter;
    LogBlock lb;
    Disassemble(start, end, &stdout_formatter, bytecode);
#else
    UNREACHABLE();
#endif
  }

  static void Disassemble(uword start, uword end) {
#if !defined(PRODUCT)
    DisassembleToStdout stdout_formatter;
    LogBlock lb;
    Disassemble(start, end, &stdout_formatter);
#else
    UNREACHABLE();
#endif
  }

  static void Disassemble(uword start,
                          uword end,
                          char* buffer,
                          uintptr_t buffer_size) {
#if !defined(PRODUCT)
    DisassembleToMemory memory_formatter(buffer, buffer_size);
    LogBlock lb;
    Disassemble(start, end, &memory_formatter);
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
                                const Bytecode& bytecode,
                                Object** object,
                                uword pc);

  static void Disassemble(const Function& function);

 private:
  static const int kHexadecimalBufferSize = 32;
  static const int kUserReadableBufferSize = 256;
};

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_KBC_H_
