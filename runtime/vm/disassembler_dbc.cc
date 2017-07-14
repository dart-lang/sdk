// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "platform/assert.h"
#include "vm/constants_dbc.h"
#include "vm/cpu.h"
#include "vm/instructions.h"

namespace dart {

static const char* kOpcodeNames[] = {
#define BYTECODE_NAME(name, encoding, op1, op2, op3) #name,
    BYTECODES_LIST(BYTECODE_NAME)
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
  intptr_t written = OS::SNPrint(*buf, *size, fmt, value);
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

#define BYTECODE_FORMATTER(name, encoding, op1, op2, op3)                      \
  static void Format##name(char* buf, intptr_t size, uword pc, uint32_t op) {  \
    Format##encoding(buf, size, pc, op, Fmt##op1, Fmt##op2, Fmt##op3);         \
  }
BYTECODES_LIST(BYTECODE_FORMATTER)
#undef BYTECODE_FORMATTER

static const BytecodeFormatter kFormatters[] = {
#define BYTECODE_FORMATTER(name, encoding, op1, op2, op3) &Format##name,
    BYTECODES_LIST(BYTECODE_FORMATTER)
#undef BYTECODE_FORMATTER
};

void Disassembler::DecodeInstruction(char* hex_buffer,
                                     intptr_t hex_size,
                                     char* human_buffer,
                                     intptr_t human_size,
                                     int* out_instr_size,
                                     const Code& code,
                                     Object** object,
                                     uword pc) {
  const uint32_t instr = *reinterpret_cast<uint32_t*>(pc);
  const uint8_t opcode = instr & 0xFF;
  ASSERT(opcode < kOpcodeCount);
  size_t name_size =
      OS::SNPrint(human_buffer, human_size, "%-10s\t", kOpcodeNames[opcode]);

  human_buffer += name_size;
  human_size -= name_size;
  kFormatters[opcode](human_buffer, human_size, pc, instr);

  OS::SNPrint(hex_buffer, hex_size, "%08x", instr);
  if (out_instr_size) {
    *out_instr_size = sizeof(uint32_t);
  }

  *object = NULL;
  if (!code.IsNull()) {
    *object = &Object::Handle();
    if (!DecodeLoadObjectFromPoolOrThread(pc, code, *object)) {
      *object = NULL;
    }
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
