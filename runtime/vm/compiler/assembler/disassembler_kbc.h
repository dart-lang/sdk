// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_KBC_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_KBC_H_

#include "vm/globals.h"
#if defined(DART_DYNAMIC_MODULES)

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
                          uword base,
                          DisassemblyFormatter* formatter,
                          const Bytecode& bytecode);

  static void Disassemble(uword start,
                          uword end,
                          uword base,
                          DisassemblyFormatter* formatter) {
    Disassemble(start, end, base, formatter, Bytecode::Handle());
  }

  static void Disassemble(uword start,
                          uword end,
                          DisassemblyFormatter* formatter,
                          const Bytecode& bytecode) {
    ASSERT(!bytecode.IsNull());
    Disassemble(
        start, end,
        bytecode.ContainsInstructionAt(start) ? bytecode.PayloadStart() : start,
        formatter, bytecode);
  }

  static void Disassemble(uword start, uword end, const Bytecode& bytecode) {
    ASSERT(!bytecode.IsNull());
#if !defined(PRODUCT)
    DisassembleToStdout stdout_formatter;
    LogBlock lb;
    Disassemble(start, end, &stdout_formatter, bytecode);
#else
    UNREACHABLE();
#endif
  }

  static void Disassemble(uword start, uword end, uword base) {
#if !defined(PRODUCT)
    DisassembleToStdout stdout_formatter;
    LogBlock lb;
    Disassemble(start, end, base, &stdout_formatter);
#else
    UNREACHABLE();
#endif
  }

  static void Disassemble(uword start, uword end) {
    Disassemble(start, end, start);
  }

  static void Disassemble(uword start,
                          uword end,
                          char* buffer,
                          uintptr_t buffer_size) {
#if !defined(PRODUCT)
    DisassembleToMemory memory_formatter(buffer, buffer_size);
    LogBlock lb;
    Disassemble(start, end, start, &memory_formatter);
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
                                uword pc,
                                uword base);

  static void Disassemble(const Function& function);

  static void PrintSourcePositions(Zone* zone,
                                   BaseTextBuffer* buffer,
                                   uword base,
                                   const Bytecode& bytecode,
                                   const Script& script);

  static void PrintLocalVariablesInfo(Zone* zone,
                                      BaseTextBuffer* buffer,
                                      const Bytecode& bytecode,
                                      uword base);

 private:
  static const int kHexadecimalBufferSize = 32;
  static const int kUserReadableBufferSize = 256;
};

}  // namespace dart

#endif  // defined(DART_DYNAMIC_MODULES)

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_DISASSEMBLER_KBC_H_
