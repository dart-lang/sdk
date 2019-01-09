// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/disassembler_kbc.h"

#include "platform/assert.h"
#include "vm/constants_kbc.h"
#include "vm/cpu.h"
#include "vm/instructions.h"

namespace dart {

static const char* kOpcodeNames[] = {
#define BYTECODE_NAME(name, encoding, op1, op2, op3) #name,
    KERNEL_BYTECODES_LIST(BYTECODE_NAME)
#undef BYTECODE_NAME
};

static const size_t kOpcodeCount =
    sizeof(kOpcodeNames) / sizeof(kOpcodeNames[0]);

typedef void (*BytecodeFormatter)(char* buffer,
                                  intptr_t size,
                                  uword pc,
                                  uint32_t bc);
typedef void (*Fmt)(char** buf, intptr_t* size, uword pc, int32_t value);

template <typename ValueType>
void FormatOperand(char** buf,
                   intptr_t* size,
                   const char* fmt,
                   ValueType value) {
  intptr_t written = Utils::SNPrint(*buf, *size, fmt, value);
  if (written < *size) {
    *buf += written;
    *size += written;
  } else {
    *size = -1;
  }
}

static void Fmt___(char** buf, intptr_t* size, uword pc, int32_t value) {}

static void Fmttgt(char** buf, intptr_t* size, uword pc, int32_t value) {
  FormatOperand(buf, size, "-> %" Px, pc + (value << 2));
}

static void Fmtlit(char** buf, intptr_t* size, uword pc, int32_t value) {
  FormatOperand(buf, size, "k%d", value);
}

static void Fmtreg(char** buf, intptr_t* size, uword pc, int32_t value) {
  FormatOperand(buf, size, "r%d", value);
}

static void Fmtxeg(char** buf, intptr_t* size, uword pc, int32_t value) {
  if (value < 0) {
    FormatOperand(buf, size, "FP[%d]", value);
  } else {
    Fmtreg(buf, size, pc, value);
  }
}

static void Fmtnum(char** buf, intptr_t* size, uword pc, int32_t value) {
  FormatOperand(buf, size, "#%d", value);
}

static void Apply(char** buf,
                  intptr_t* size,
                  uword pc,
                  Fmt fmt,
                  int32_t value,
                  const char* suffix) {
  if (*size <= 0) {
    return;
  }

  fmt(buf, size, pc, value);
  if (*size > 0) {
    FormatOperand(buf, size, "%s", suffix);
  }
}

static void Format0(char* buf,
                    intptr_t size,
                    uword pc,
                    uint32_t op,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {}

static void FormatT(char* buf,
                    intptr_t size,
                    uword pc,
                    uint32_t op,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t x = static_cast<int32_t>(op) >> 8;
  Apply(&buf, &size, pc, op1, x, "");
}

static void FormatA(char* buf,
                    intptr_t size,
                    uword pc,
                    uint32_t op,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t a = (op & 0xFF00) >> 8;
  Apply(&buf, &size, pc, op1, a, "");
}

static void FormatA_D(char* buf,
                      intptr_t size,
                      uword pc,
                      uint32_t op,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t a = (op & 0xFF00) >> 8;
  const int32_t bc = op >> 16;
  Apply(&buf, &size, pc, op1, a, ", ");
  Apply(&buf, &size, pc, op2, bc, "");
}

static void FormatA_X(char* buf,
                      intptr_t size,
                      uword pc,
                      uint32_t op,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t a = (op & 0xFF00) >> 8;
  const int32_t bc = static_cast<int32_t>(op) >> 16;
  Apply(&buf, &size, pc, op1, a, ", ");
  Apply(&buf, &size, pc, op2, bc, "");
}

static void FormatX(char* buf,
                    intptr_t size,
                    uword pc,
                    uint32_t op,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t bc = static_cast<int32_t>(op) >> 16;
  Apply(&buf, &size, pc, op1, bc, "");
}

static void FormatD(char* buf,
                    intptr_t size,
                    uword pc,
                    uint32_t op,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t bc = op >> 16;
  Apply(&buf, &size, pc, op1, bc, "");
}

static void FormatA_B_C(char* buf,
                        intptr_t size,
                        uword pc,
                        uint32_t op,
                        Fmt op1,
                        Fmt op2,
                        Fmt op3) {
  const int32_t a = (op >> 8) & 0xFF;
  const int32_t b = (op >> 16) & 0xFF;
  const int32_t c = (op >> 24) & 0xFF;
  Apply(&buf, &size, pc, op1, a, ", ");
  Apply(&buf, &size, pc, op2, b, ", ");
  Apply(&buf, &size, pc, op3, c, "");
}

// TODO(alexmarkov) This format is currently unused. Restore it if needed, or
// remove it once bytecode instruction set is finalized.
//
// static void FormatA_B_Y(char* buf,
//                        intptr_t size,
//                        uword pc,
//                        uint32_t op,
//                        Fmt op1,
//                        Fmt op2,
//                        Fmt op3) {
//  const int32_t a = (op >> 8) & 0xFF;
//  const int32_t b = (op >> 16) & 0xFF;
//  const int32_t y = static_cast<int8_t>((op >> 24) & 0xFF);
//  Apply(&buf, &size, pc, op1, a, ", ");
//  Apply(&buf, &size, pc, op2, b, ", ");
//  Apply(&buf, &size, pc, op3, y, "");
// }

#define BYTECODE_FORMATTER(name, encoding, op1, op2, op3)                      \
  static void Format##name(char* buf, intptr_t size, uword pc, uint32_t op) {  \
    Format##encoding(buf, size, pc, op, Fmt##op1, Fmt##op2, Fmt##op3);         \
  }
KERNEL_BYTECODES_LIST(BYTECODE_FORMATTER)
#undef BYTECODE_FORMATTER

static const BytecodeFormatter kFormatters[] = {
#define BYTECODE_FORMATTER(name, encoding, op1, op2, op3) &Format##name,
    KERNEL_BYTECODES_LIST(BYTECODE_FORMATTER)
#undef BYTECODE_FORMATTER
};

static bool HasLoadFromPool(KBCInstr instr) {
  switch (KernelBytecode::DecodeOpcode(instr)) {
    case KernelBytecode::kLoadConstant:
    case KernelBytecode::kPushConstant:
    case KernelBytecode::kIndirectStaticCall:
    case KernelBytecode::kInterfaceCall:
    case KernelBytecode::kDynamicCall:
    case KernelBytecode::kStoreStaticTOS:
    case KernelBytecode::kPushStatic:
    case KernelBytecode::kAllocate:
    case KernelBytecode::kInstantiateType:
    case KernelBytecode::kInstantiateTypeArgumentsTOS:
    case KernelBytecode::kAssertAssignable:
      return true;
    default:
      return false;
  }
}

static bool GetLoadedObjectAt(uword pc,
                              const ObjectPool& object_pool,
                              Object* obj) {
  KBCInstr instr = KernelBytecode::At(pc);
  if (HasLoadFromPool(instr)) {
    uint16_t index = KernelBytecode::DecodeD(instr);
    if (object_pool.TypeAt(index) == ObjectPool::kTaggedObject) {
      *obj = object_pool.ObjectAt(index);
      return true;
    }
  }
  return false;
}

void KernelBytecodeDisassembler::DecodeInstruction(char* hex_buffer,
                                                   intptr_t hex_size,
                                                   char* human_buffer,
                                                   intptr_t human_size,
                                                   int* out_instr_size,
                                                   const Bytecode& bytecode,
                                                   Object** object,
                                                   uword pc) {
  const uint32_t instr = *reinterpret_cast<uint32_t*>(pc);
  const uint8_t opcode = instr & 0xFF;
  ASSERT(opcode < kOpcodeCount);
  size_t name_size =
      Utils::SNPrint(human_buffer, human_size, "%-10s\t", kOpcodeNames[opcode]);

  human_buffer += name_size;
  human_size -= name_size;
  kFormatters[opcode](human_buffer, human_size, pc, instr);

  Utils::SNPrint(hex_buffer, hex_size, "%08x", instr);
  if (out_instr_size) {
    *out_instr_size = sizeof(uint32_t);
  }

  *object = NULL;
  if (!bytecode.IsNull()) {
    *object = &Object::Handle();
    const ObjectPool& pool = ObjectPool::Handle(bytecode.object_pool());
    if (!GetLoadedObjectAt(pc, pool, *object)) {
      *object = NULL;
    }
  }
}

void KernelBytecodeDisassembler::Disassemble(uword start,
                                             uword end,
                                             DisassemblyFormatter* formatter,
                                             const Bytecode& bytecode) {
#if !defined(PRODUCT)
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword pc = start;
  GrowableArray<const Function*> inlined_functions;
  GrowableArray<TokenPosition> token_positions;
  while (pc < end) {
    int instruction_length;
    Object* object;
    DecodeInstruction(hex_buffer, sizeof(hex_buffer), human_buffer,
                      sizeof(human_buffer), &instruction_length, bytecode,
                      &object, pc);
    formatter->ConsumeInstruction(hex_buffer, sizeof(hex_buffer), human_buffer,
                                  sizeof(human_buffer), object, pc);
    pc += instruction_length;
  }
#else
  UNREACHABLE();
#endif
}

void KernelBytecodeDisassembler::Disassemble(const Function& function) {
#if !defined(PRODUCT)
  ASSERT(function.HasBytecode());
  const char* function_fullname = function.ToFullyQualifiedCString();
  Zone* zone = Thread::Current()->zone();
  const Bytecode& bytecode = Bytecode::Handle(zone, function.bytecode());
  THR_Print("Bytecode for function '%s' {\n", function_fullname);
  uword start = bytecode.PayloadStart();
  DisassembleToStdout stdout_formatter;
  LogBlock lb;
  Disassemble(start, start + bytecode.Size(), &stdout_formatter, bytecode);
  THR_Print("}\n");

  const ObjectPool& object_pool =
      ObjectPool::Handle(zone, bytecode.object_pool());
  object_pool.DebugPrint();

  THR_Print("PC Descriptors for function '%s' {\n", function_fullname);
  PcDescriptors::PrintHeaderString();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone, bytecode.pc_descriptors());
  THR_Print("%s}\n", descriptors.ToCString());

  THR_Print("Exception Handlers for function '%s' {\n", function_fullname);
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(zone, bytecode.exception_handlers());
  THR_Print("%s}\n", handlers.ToCString());
#else
  UNREACHABLE();
#endif
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
