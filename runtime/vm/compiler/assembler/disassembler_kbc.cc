// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/disassembler_kbc.h"

#include "platform/assert.h"
#include "vm/compiler/frontend/bytecode_reader.h"
#include "vm/constants_kbc.h"
#include "vm/cpu.h"
#include "vm/instructions.h"

namespace dart {

static const char* kOpcodeNames[] = {
#define BYTECODE_NAME(name, encoding, kind, op1, op2, op3) #name,
    KERNEL_BYTECODES_LIST(BYTECODE_NAME)
#undef BYTECODE_NAME
};

static const size_t kOpcodeCount =
    sizeof(kOpcodeNames) / sizeof(kOpcodeNames[0]);
static_assert(kOpcodeCount <= 256, "Opcode should fit into a byte");

typedef void (*BytecodeFormatter)(char* buffer,
                                  intptr_t size,
                                  KernelBytecode::Opcode opcode,
                                  const KBCInstr* instr);
typedef void (*Fmt)(char** buf,
                    intptr_t* size,
                    const KBCInstr* instr,
                    int32_t value);

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

static void Fmt___(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   int32_t value) {}

static void Fmttgt(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   int32_t value) {
  if (FLAG_disassemble_relative) {
    FormatOperand(buf, size, "-> %" Pd, value);
  } else {
    FormatOperand(buf, size, "-> %" Px, instr + value);
  }
}

static void Fmtlit(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   int32_t value) {
  FormatOperand(buf, size, "k%d", value);
}

static void Fmtreg(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   int32_t value) {
  FormatOperand(buf, size, "r%d", value);
}

static void Fmtxeg(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   int32_t value) {
  if (value < 0) {
    FormatOperand(buf, size, "FP[%d]", value);
  } else {
    Fmtreg(buf, size, instr, value);
  }
}

static void Fmtnum(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   int32_t value) {
  FormatOperand(buf, size, "#%d", value);
}

static void Apply(char** buf,
                  intptr_t* size,
                  const KBCInstr* instr,
                  Fmt fmt,
                  int32_t value,
                  const char* suffix) {
  if (*size <= 0) {
    return;
  }

  fmt(buf, size, instr, value);
  if (*size > 0) {
    FormatOperand(buf, size, "%s", suffix);
  }
}

static void Format0(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {}

static void FormatA(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  Apply(&buf, &size, instr, op1, a, "");
}

static void FormatD(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t bc = KernelBytecode::DecodeD(instr);
  Apply(&buf, &size, instr, op1, bc, "");
}

static void FormatX(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t bc = KernelBytecode::DecodeX(instr);
  Apply(&buf, &size, instr, op1, bc, "");
}

static void FormatT(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t x = KernelBytecode::DecodeT(instr);
  Apply(&buf, &size, instr, op1, x, "");
}

static void FormatA_E(char* buf,
                      intptr_t size,
                      KernelBytecode::Opcode opcode,
                      const KBCInstr* instr,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  const int32_t e = KernelBytecode::DecodeE(instr);
  Apply(&buf, &size, instr, op1, a, ", ");
  Apply(&buf, &size, instr, op2, e, "");
}

static void FormatA_Y(char* buf,
                      intptr_t size,
                      KernelBytecode::Opcode opcode,
                      const KBCInstr* instr,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  const int32_t y = KernelBytecode::DecodeY(instr);
  Apply(&buf, &size, instr, op1, a, ", ");
  Apply(&buf, &size, instr, op2, y, "");
}

static void FormatD_F(char* buf,
                      intptr_t size,
                      KernelBytecode::Opcode opcode,
                      const KBCInstr* instr,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t d = KernelBytecode::DecodeD(instr);
  const int32_t f = KernelBytecode::DecodeF(instr);
  Apply(&buf, &size, instr, op1, d, ", ");
  Apply(&buf, &size, instr, op2, f, "");
}

static void FormatA_B_C(char* buf,
                        intptr_t size,
                        KernelBytecode::Opcode opcode,
                        const KBCInstr* instr,
                        Fmt op1,
                        Fmt op2,
                        Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  const int32_t b = KernelBytecode::DecodeB(instr);
  const int32_t c = KernelBytecode::DecodeC(instr);
  Apply(&buf, &size, instr, op1, a, ", ");
  Apply(&buf, &size, instr, op2, b, ", ");
  Apply(&buf, &size, instr, op3, c, "");
}

#define BYTECODE_FORMATTER(name, encoding, kind, op1, op2, op3)                \
  static void Format##name(char* buf, intptr_t size,                           \
                           KernelBytecode::Opcode opcode,                      \
                           const KBCInstr* instr) {                            \
    Format##encoding(buf, size, opcode, instr, Fmt##op1, Fmt##op2, Fmt##op3);  \
  }
KERNEL_BYTECODES_LIST(BYTECODE_FORMATTER)
#undef BYTECODE_FORMATTER

static const BytecodeFormatter kFormatters[] = {
#define BYTECODE_FORMATTER(name, encoding, kind, op1, op2, op3) &Format##name,
    KERNEL_BYTECODES_LIST(BYTECODE_FORMATTER)
#undef BYTECODE_FORMATTER
};

static intptr_t GetConstantPoolIndex(const KBCInstr* instr) {
  switch (KernelBytecode::DecodeOpcode(instr)) {
    case KernelBytecode::kLoadConstant:
    case KernelBytecode::kLoadConstant_Wide:
    case KernelBytecode::kInstantiateTypeArgumentsTOS:
    case KernelBytecode::kInstantiateTypeArgumentsTOS_Wide:
    case KernelBytecode::kAssertAssignable:
    case KernelBytecode::kAssertAssignable_Wide:
      return KernelBytecode::DecodeE(instr);

    case KernelBytecode::kPushConstant:
    case KernelBytecode::kPushConstant_Wide:
    case KernelBytecode::kInitLateField:
    case KernelBytecode::kInitLateField_Wide:
    case KernelBytecode::kStoreStaticTOS:
    case KernelBytecode::kStoreStaticTOS_Wide:
    case KernelBytecode::kLoadStatic:
    case KernelBytecode::kLoadStatic_Wide:
    case KernelBytecode::kAllocate:
    case KernelBytecode::kAllocate_Wide:
    case KernelBytecode::kAllocateClosure:
    case KernelBytecode::kAllocateClosure_Wide:
    case KernelBytecode::kInstantiateType:
    case KernelBytecode::kInstantiateType_Wide:
    case KernelBytecode::kDirectCall:
    case KernelBytecode::kDirectCall_Wide:
    case KernelBytecode::kUncheckedDirectCall:
    case KernelBytecode::kUncheckedDirectCall_Wide:
    case KernelBytecode::kInterfaceCall:
    case KernelBytecode::kInterfaceCall_Wide:
    case KernelBytecode::kInstantiatedInterfaceCall:
    case KernelBytecode::kInstantiatedInterfaceCall_Wide:
    case KernelBytecode::kUncheckedClosureCall:
    case KernelBytecode::kUncheckedClosureCall_Wide:
    case KernelBytecode::kUncheckedInterfaceCall:
    case KernelBytecode::kUncheckedInterfaceCall_Wide:
    case KernelBytecode::kDynamicCall:
    case KernelBytecode::kDynamicCall_Wide:
      return KernelBytecode::DecodeD(instr);

    default:
      return -1;
  }
}

static bool GetLoadedObjectAt(uword pc,
                              const ObjectPool& object_pool,
                              Object* obj) {
  const KBCInstr* instr = reinterpret_cast<const KBCInstr*>(pc);
  const intptr_t index = GetConstantPoolIndex(instr);
  if (index >= 0) {
    if (object_pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject) {
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
  const KBCInstr* instr = reinterpret_cast<const KBCInstr*>(pc);
  const KernelBytecode::Opcode opcode = KernelBytecode::DecodeOpcode(instr);
  const intptr_t instr_size = KernelBytecode::kInstructionSize[opcode];

  size_t name_size =
      Utils::SNPrint(human_buffer, human_size, "%-10s\t", kOpcodeNames[opcode]);
  human_buffer += name_size;
  human_size -= name_size;
  kFormatters[opcode](human_buffer, human_size, opcode, instr);

  const intptr_t kCharactersPerByte = 3;
  if (hex_size > instr_size * kCharactersPerByte) {
    for (intptr_t i = 0; i < instr_size; ++i) {
      Utils::SNPrint(hex_buffer + (i * kCharactersPerByte),
                     hex_size - (i * kCharactersPerByte), " %02x", instr[i]);
    }
  }
  if (out_instr_size != nullptr) {
    *out_instr_size = instr_size;
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
                                  sizeof(human_buffer), object,
                                  FLAG_disassemble_relative ? pc - start : pc);
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
  const uword start = bytecode.PayloadStart();
  const uword base = FLAG_disassemble_relative ? 0 : start;
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

  if (bytecode.HasSourcePositions()) {
    THR_Print("Source positions for function '%s' {\n", function_fullname);
    // 4 bits per hex digit + 2 for "0x".
    const int addr_width = (kBitsPerWord / 4) + 2;
    // "*" in a printf format specifier tells it to read the field width from
    // the printf argument list.
    THR_Print("%-*s\tpos\tline\tcolumn\tyield\n", addr_width, "pc");
    const Script& script = Script::Handle(zone, function.script());
    kernel::BytecodeSourcePositionsIterator iter(zone, bytecode);
    while (iter.MoveNext()) {
      TokenPosition pos = iter.TokenPos();
      intptr_t line = -1, column = -1;
      script.GetTokenLocation(pos, &line, &column);
      THR_Print("%#-*" Px "\t%s\t%" Pd "\t%" Pd "\t%s\n", addr_width,
                base + iter.PcOffset(), pos.ToCString(), line, column,
                iter.IsYieldPoint() ? "yield" : "");
    }
    THR_Print("}\n");
  }

  if (FLAG_print_variable_descriptors && bytecode.HasLocalVariablesInfo()) {
    THR_Print("Local variables info for function '%s' {\n", function_fullname);
    kernel::BytecodeLocalVariablesIterator iter(zone, bytecode);
    while (iter.MoveNext()) {
      switch (iter.Kind()) {
        case kernel::BytecodeLocalVariablesIterator::kScope: {
          THR_Print("scope 0x%" Px "-0x%" Px " pos %s-%s\tlev %" Pd "\n",
                    base + iter.StartPC(), base + iter.EndPC(),
                    iter.StartTokenPos().ToCString(),
                    iter.EndTokenPos().ToCString(), iter.ContextLevel());
        } break;
        case kernel::BytecodeLocalVariablesIterator::kVariableDeclaration: {
          THR_Print("var   0x%" Px "-0x%" Px " pos %s-%s\tidx %" Pd
                    "\tdecl %s\t%s %s %s\n",
                    base + iter.StartPC(), base + iter.EndPC(),
                    iter.StartTokenPos().ToCString(),
                    iter.EndTokenPos().ToCString(), iter.Index(),
                    iter.DeclarationTokenPos().ToCString(),
                    String::Handle(
                        zone, AbstractType::Handle(zone, iter.Type()).Name())
                        .ToCString(),
                    String::Handle(zone, iter.Name()).ToCString(),
                    iter.IsCaptured() ? "captured" : "");
        } break;
        case kernel::BytecodeLocalVariablesIterator::kContextVariable: {
          THR_Print("ctxt  0x%" Px "\tidx %" Pd "\n", base + iter.StartPC(),
                    iter.Index());
        } break;
      }
    }
    THR_Print("}\n");

    THR_Print("Local variable descriptors for function '%s' {\n",
              function_fullname);
    const auto& var_descriptors =
        LocalVarDescriptors::Handle(zone, bytecode.GetLocalVarDescriptors());
    THR_Print("%s}\n", var_descriptors.ToCString());
  }

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
