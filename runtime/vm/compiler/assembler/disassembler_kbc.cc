// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_DYNAMIC_MODULES)

#include "vm/compiler/assembler/disassembler_kbc.h"

#include "platform/assert.h"
#include "vm/bytecode_reader.h"
#include "vm/constants_kbc.h"
#include "vm/zone_text_buffer.h"

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
                                  const KBCInstr* instr,
                                  uword base);
typedef void (*Fmt)(char** buf,
                    intptr_t* size,
                    const KBCInstr* instr,
                    uword base,
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
                   uword base,
                   int32_t value) {}

static void Fmttgt(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   uword base,
                   int32_t value) {
  const uword pc = reinterpret_cast<uword>(instr);
  if (pc == base) {
    // There's never a jump at the start of a bytecode function, so
    // use that to detect when we're outputting single instructions
    // not associated with a bytecode object (e.g., tracing the original
    // instruction for a breakpoint) and print the argument as a delta
    // instead of the target PC.
    FormatOperand(buf, size, "-> %" Pd32, value);
  } else {
    FormatOperand(buf, size, "-> %#" Px,
                  (FLAG_disassemble_relative ? pc - base : pc) + value);
  }
}

static void Fmtlit(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   uword base,
                   int32_t value) {
  FormatOperand(buf, size, "k%d", value);
}

static void Fmtreg(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   uword base,
                   int32_t value) {
  FormatOperand(buf, size, "r%d", value);
}

static void Fmtxeg(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   uword base,
                   int32_t value) {
  if (value < 0) {
    FormatOperand(buf, size, "FP[%d]", value);
  } else {
    Fmtreg(buf, size, instr, base, value);
  }
}

static void Fmtnum(char** buf,
                   intptr_t* size,
                   const KBCInstr* instr,
                   uword base,
                   int32_t value) {
  FormatOperand(buf, size, "#%d", value);
}

static void Apply(char** buf,
                  intptr_t* size,
                  const KBCInstr* instr,
                  uword base,
                  Fmt fmt,
                  int32_t value,
                  const char* suffix) {
  if (*size <= 0) {
    return;
  }

  fmt(buf, size, instr, base, value);
  if (*size > 0) {
    FormatOperand(buf, size, "%s", suffix);
  }
}

static void Format0(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    uword base,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {}

static void FormatA(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    uword base,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  Apply(&buf, &size, instr, base, op1, a, "");
}

static void FormatD(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    uword base,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t bc = KernelBytecode::DecodeD(instr);
  Apply(&buf, &size, instr, base, op1, bc, "");
}

static void FormatX(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    uword base,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t bc = KernelBytecode::DecodeX(instr);
  Apply(&buf, &size, instr, base, op1, bc, "");
}

static void FormatT(char* buf,
                    intptr_t size,
                    KernelBytecode::Opcode opcode,
                    const KBCInstr* instr,
                    uword base,
                    Fmt op1,
                    Fmt op2,
                    Fmt op3) {
  const int32_t x = KernelBytecode::DecodeT(instr);
  Apply(&buf, &size, instr, base, op1, x, "");
}

static void FormatA_E(char* buf,
                      intptr_t size,
                      KernelBytecode::Opcode opcode,
                      const KBCInstr* instr,
                      uword base,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  const int32_t e = KernelBytecode::DecodeE(instr);
  Apply(&buf, &size, instr, base, op1, a, ", ");
  Apply(&buf, &size, instr, base, op2, e, "");
}

static void FormatA_Y(char* buf,
                      intptr_t size,
                      KernelBytecode::Opcode opcode,
                      const KBCInstr* instr,
                      uword base,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  const int32_t y = KernelBytecode::DecodeY(instr);
  Apply(&buf, &size, instr, base, op1, a, ", ");
  Apply(&buf, &size, instr, base, op2, y, "");
}

static void FormatD_F(char* buf,
                      intptr_t size,
                      KernelBytecode::Opcode opcode,
                      const KBCInstr* instr,
                      uword base,
                      Fmt op1,
                      Fmt op2,
                      Fmt op3) {
  const int32_t d = KernelBytecode::DecodeD(instr);
  const int32_t f = KernelBytecode::DecodeF(instr);
  Apply(&buf, &size, instr, base, op1, d, ", ");
  Apply(&buf, &size, instr, base, op2, f, "");
}

static void FormatA_B_C(char* buf,
                        intptr_t size,
                        KernelBytecode::Opcode opcode,
                        const KBCInstr* instr,
                        uword base,
                        Fmt op1,
                        Fmt op2,
                        Fmt op3) {
  const int32_t a = KernelBytecode::DecodeA(instr);
  const int32_t b = KernelBytecode::DecodeB(instr);
  const int32_t c = KernelBytecode::DecodeC(instr);
  Apply(&buf, &size, instr, base, op1, a, ", ");
  Apply(&buf, &size, instr, base, op2, b, ", ");
  Apply(&buf, &size, instr, base, op3, c, "");
}

#define BYTECODE_FORMATTER(name, encoding, kind, op1, op2, op3)                \
  static void Format##name(char* buf, intptr_t size,                           \
                           KernelBytecode::Opcode opcode,                      \
                           const KBCInstr* instr, uword base) {                \
    Format##encoding(buf, size, opcode, instr, base, Fmt##op1, Fmt##op2,       \
                     Fmt##op3);                                                \
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
                                                   uword pc,
                                                   uword base) {
  const KBCInstr* instr = reinterpret_cast<const KBCInstr*>(pc);
  const KernelBytecode::Opcode opcode = KernelBytecode::DecodeOpcode(instr);
  const intptr_t instr_size = KernelBytecode::kInstructionSize[opcode];

  size_t name_size =
      Utils::SNPrint(human_buffer, human_size, "%-10s\t", kOpcodeNames[opcode]);
  human_buffer += name_size;
  human_size -= name_size;
  kFormatters[opcode](human_buffer, human_size, opcode, instr, base);

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
                                             uword base,
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
                      &object, pc, base);
    formatter->ConsumeInstruction(hex_buffer, sizeof(hex_buffer), human_buffer,
                                  sizeof(human_buffer), object,
                                  FLAG_disassemble_relative ? pc - base : pc);
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
  const Bytecode& bytecode = Bytecode::Handle(zone, function.GetBytecode());
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

  const PcDescriptors& descriptors =
      PcDescriptors::Handle(zone, bytecode.pc_descriptors());
  if (!descriptors.IsNull()) {
    THR_Print("PC Descriptors for function '%s' {\n", function_fullname);
    ZoneTextBuffer buffer(zone);
    descriptors.WriteToBuffer(&buffer, base);
    THR_Print("%s", buffer.buffer());
    THR_Print("}\n");
  }

  if (bytecode.HasSourcePositions()) {
    const Script& script = Script::Handle(zone, function.script());
    THR_Print("Source positions for function '%s' {\n", function_fullname);
    ZoneTextBuffer buffer(zone);
    PrintSourcePositions(zone, &buffer, base, bytecode, script);
    THR_Print("%s", buffer.buffer());
    THR_Print("}\n");
  }

  if (bytecode.HasLocalVariablesInfo()) {
    THR_Print("Local variable information for function '%s' {\n",
              function_fullname);
    ZoneTextBuffer buffer(zone);
    PrintLocalVariablesInfo(zone, &buffer, bytecode, base);
    THR_Print("%s", buffer.buffer());
    THR_Print("}\n");
  }

  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(zone, bytecode.exception_handlers());
  if (!handlers.IsNull()) {
    THR_Print("Exception Handlers for function '%s' {\n", function_fullname);
    ZoneTextBuffer buffer(zone);
    handlers.WriteToBuffer(&buffer, base);
    THR_Print("%s", buffer.buffer());
    THR_Print("}\n");
  }
#else
  UNREACHABLE();
#endif
}

// 4 bits per hex digit + 2 for "0x".
static const int kProgramCounterFieldWidth = (kBitsPerWord / 4) + 2;
static const int kUint32FieldWidth = 7;
// For bytecode, these are either:
// * real positions, which are a uint32_t source offset and thus a
//   max of 7 digits,
// * synthethic positions, which have a prefix of 'syn:' before a
//   source offset and thus a max of 11 characters, or
// * NoSource, which is written as "NoSource" (8).
static const int kSourcePositionFieldWidth = 11;
static const int kSourcePositionColumnWidths[] = {
    kProgramCounterFieldWidth,  // pc
    kSourcePositionFieldWidth,  // pos
    kUint32FieldWidth,          // line
    kUint32FieldWidth,          // col
};

void KernelBytecodeDisassembler::PrintSourcePositions(Zone* zone,
                                                      BaseTextBuffer* buffer,
                                                      uword base,
                                                      const Bytecode& bytecode,
                                                      const Script& script) {
  if (!bytecode.HasSourcePositions()) return;

  // "*" in a printf format specifier tells it to read the field width from
  // the printf argument list.
  buffer->Printf(" %-*s %*s %*s %*s yield\n", kSourcePositionColumnWidths[0],
                 "pc", kSourcePositionColumnWidths[1], "pos",
                 kSourcePositionColumnWidths[2], "line",
                 kSourcePositionColumnWidths[3], "col");
  bytecode::BytecodeSourcePositionsIterator iter(zone, bytecode);
  while (iter.MoveNext()) {
    buffer->Printf(" %#-*" Px "", kSourcePositionColumnWidths[0],
                   base + iter.PcOffset());
    const TokenPosition pos = iter.TokenPos();
    buffer->Printf(" %*s", kSourcePositionColumnWidths[1], pos.ToCString());
    intptr_t line = -1, column = -1;
    if (!script.IsNull() && script.GetTokenLocation(pos, &line, &column)) {
      buffer->Printf(" %*" Pd " %*" Pd "", kSourcePositionColumnWidths[2], line,
                     kSourcePositionColumnWidths[3], column);
    } else {
      buffer->Printf(" %*s %*s", kSourcePositionColumnWidths[2], "-",
                     kSourcePositionColumnWidths[3], "-");
    }
    if (iter.IsYieldPoint()) {
      buffer->AddString(" X");
    }
    buffer->AddString("\n");
  }
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
static const int kLocalVariableKindFieldWidth = strlen(
    bytecode::BytecodeLocalVariablesIterator::kKindNames
        [bytecode::BytecodeLocalVariablesIterator::kVariableDeclaration]);

static const int kLocalVariableColumnWidths[] = {
    kLocalVariableKindFieldWidth,  // kind
    kProgramCounterFieldWidth,     // start pc
    kProgramCounterFieldWidth,     // end pc
    kUint32FieldWidth,             // context level
    kUint32FieldWidth,             // index
    kSourcePositionFieldWidth,     // start token pos
    kSourcePositionFieldWidth,     // end token pos
    kSourcePositionFieldWidth,     // decl token pos
};
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

void KernelBytecodeDisassembler::PrintLocalVariablesInfo(
    Zone* zone,
    BaseTextBuffer* buffer,
    const Bytecode& bytecode,
    uword base) {
  if (!bytecode.HasLocalVariablesInfo()) return;

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // "*" in a printf format specifier tells it to read the field width from
  // the printf argument list.
  buffer->Printf(
      " %-*s %*s %*s %*s %*s %*s %*s %*s   name\n",
      kLocalVariableColumnWidths[0], "kind", kLocalVariableColumnWidths[1],
      "start pc", kLocalVariableColumnWidths[2], "end pc",
      kLocalVariableColumnWidths[3], "ctx", kLocalVariableColumnWidths[4],
      "index", kLocalVariableColumnWidths[5], "start",
      kLocalVariableColumnWidths[6], "end", kLocalVariableColumnWidths[7],
      "decl");
  auto& name = String::Handle(zone);
  auto& type = AbstractType::Handle(zone);
  bytecode::BytecodeLocalVariablesIterator iter(zone, bytecode);
  while (iter.MoveNext()) {
    buffer->Printf(" %-*s %#*" Px "", kLocalVariableColumnWidths[0],
                   iter.KindName(), kLocalVariableColumnWidths[1],
                   base + iter.StartPC());
    if (iter.IsVariableDeclaration() || iter.IsScope()) {
      buffer->Printf(" %#*" Px "", kLocalVariableColumnWidths[2],
                     base + iter.EndPC());
    } else {
      buffer->Printf(" %*s", kLocalVariableColumnWidths[2], "-");
    }
    if (iter.IsScope()) {
      buffer->Printf(" %*" Pd "", kLocalVariableColumnWidths[3],
                     iter.ContextLevel());
    } else {
      buffer->Printf(" %*s", kLocalVariableColumnWidths[3], "-");
    }
    if (iter.IsContextVariable() || iter.IsVariableDeclaration()) {
      buffer->Printf(" %*" Pd "", kLocalVariableColumnWidths[4], iter.Index());
    } else {
      buffer->Printf(" %*s", kLocalVariableColumnWidths[4], "-");
    }
    if (iter.IsVariableDeclaration() || iter.IsScope()) {
      buffer->Printf(" %*s %*s", kLocalVariableColumnWidths[5],
                     iter.StartTokenPos().ToCString(),
                     kLocalVariableColumnWidths[6],
                     iter.EndTokenPos().ToCString());

    } else {
      buffer->Printf(" %*s %*s", kLocalVariableColumnWidths[5], "-",
                     kLocalVariableColumnWidths[6], "-");
    }
    if (iter.IsVariableDeclaration()) {
      name = iter.Name();
      type = iter.Type();
      buffer->Printf(" %*s   %s: ", kLocalVariableColumnWidths[7],
                     iter.DeclarationTokenPos().ToCString(), name.ToCString());
      type.PrintName(Object::kInternalName, buffer);
      if (iter.IsCaptured()) {
        buffer->AddString(" (captured)");
      }
    } else {
      buffer->Printf(" %*s   %s", kLocalVariableColumnWidths[7], "-", "-");
    }
    buffer->AddString("\n");
  }
#else
  UNREACHABLE();
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart

#endif  // defined(DART_DYNAMIC_MODULES)
