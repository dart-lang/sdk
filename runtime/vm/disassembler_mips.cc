// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)
#include "platform/assert.h"

namespace dart {

class MIPSDecoder : public ValueObject {
 public:
  MIPSDecoder(char* buffer, size_t buffer_size)
      : buffer_(buffer),
        buffer_size_(buffer_size),
        buffer_pos_(0) {
    buffer_[buffer_pos_] = '\0';
  }

  ~MIPSDecoder() {}

  // Writes one disassembled instruction into 'buffer' (0-terminated).
  // Returns true if the instruction was successfully decoded, false otherwise.
  void InstructionDecode(Instr* instr);

 private:
  // Bottleneck functions to print into the out_buffer.
  void Print(const char* str);

  // Printing of common values.
  void PrintRegister(Register reg);
  void PrintFRegister(FRegister reg);
  void PrintFormat(Instr* instr);

  int FormatRegister(Instr* instr, const char* format);
  int FormatFRegister(Instr* instr, const char* format);
  int FormatOption(Instr* instr, const char* format);
  void Format(Instr* instr, const char* format);
  void Unknown(Instr* instr);

  void DecodeSpecial(Instr* instr);
  void DecodeSpecial2(Instr* instr);
  void DecodeRegImm(Instr* instr);
  void DecodeCop1(Instr* instr);

  // Convenience functions.
  char* get_buffer() const { return buffer_; }
  char* current_position_in_buffer() { return buffer_ + buffer_pos_; }
  size_t remaining_size_in_buffer() { return buffer_size_ - buffer_pos_; }

  char* buffer_;  // Decode instructions into this buffer.
  size_t buffer_size_;  // The size of the character buffer.
  size_t buffer_pos_;  // Current character position in buffer.

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MIPSDecoder);
};


// Support for assertions in the MIPSDecoder formatting functions.
#define STRING_STARTS_WITH(string, compare_string) \
  (strncmp(string, compare_string, strlen(compare_string)) == 0)


// Append the str to the output buffer.
void MIPSDecoder::Print(const char* str) {
  char cur = *str++;
  while (cur != '\0' && (buffer_pos_ < (buffer_size_ - 1))) {
    buffer_[buffer_pos_++] = cur;
    cur = *str++;
  }
  buffer_[buffer_pos_] = '\0';
}


static const char* reg_names[kNumberOfCpuRegisters] = {
  "r0" , "r1" , "r2" , "r3" , "r4" , "r5" , "r6" , "r7" ,
  "r8" , "r9" , "r10", "r11", "r12", "r13", "r14", "r15",
  "r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23",
  "r24", "r25", "r26", "r27", "r28", "r29", "r30", "r31",
};


static const char* freg_names[kNumberOfFRegisters] = {
  "f0" , "f1" , "f2" , "f3" , "f4" , "f5" , "f6" , "f7" ,
  "f8" , "f9" , "f10", "f11", "f12", "f13", "f14", "f15",
  "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23",
  "f24", "f25", "f26", "f27", "f28", "f29", "f30", "f31",
};


void MIPSDecoder::PrintRegister(Register reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfCpuRegisters);
  Print(reg_names[reg]);
}


void MIPSDecoder::PrintFRegister(FRegister reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfFRegisters);
  Print(freg_names[reg]);
}


// Handle all register based formatting in these functions to reduce the
// complexity of FormatOption.
int MIPSDecoder::FormatRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'r');
  switch (format[1]) {
    case 's': {  // 'rs: Rs register
      PrintRegister(instr->RsField());
      return 2;
    }
    case 't': {  // 'rt: Rt register
      PrintRegister(instr->RtField());
      return 2;
    }
    case 'd': {  // 'rd: Rd register
      PrintRegister(instr->RdField());
      return 2;
    }
  }
  UNREACHABLE();
  return -1;
}


int MIPSDecoder::FormatFRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'f');
  switch (format[1]) {
    case 's': {  // 'fs: Fs register
      PrintFRegister(instr->FsField());
      return 2;
    }
    case 't': {  // 'ft: Ft register
      PrintFRegister(instr->FtField());
      return 2;
    }
    case 'd': {  // 'fd: Fd register
      PrintFRegister(instr->FdField());
      return 2;
    }
  }
  UNREACHABLE();
  return -1;
}


void MIPSDecoder::PrintFormat(Instr *instr) {
  switch (instr->FormatField()) {
    case FMT_S: {
      Print("s");
      break;
    }
    case FMT_D: {
      Print("d");
      break;
    }
    case FMT_W: {
      Print("w");
      break;
    }
    case FMT_L: {
      Print("l");
      break;
    }
    case FMT_PS: {
      Print("ps");
      break;
    }
    default: {
      Print("unknown");
      break;
    }
  }
}


// FormatOption takes a formatting string and interprets it based on
// the current instructions. The format string points to the first
// character of the option string (the option escape has already been
// consumed by the caller.)  FormatOption returns the number of
// characters that were consumed from the formatting string.
int MIPSDecoder::FormatOption(Instr* instr, const char* format) {
  switch (format[0]) {
    case 'c': {
      ASSERT(STRING_STARTS_WITH(format, "code"));
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                remaining_size_in_buffer(),
                                "%d", instr->BreakCodeField());
      return 4;
    }
    case 'h': {
      ASSERT(STRING_STARTS_WITH(format, "hint"));
      if (instr->SaField() == 0x10) {
        // The high bit of the SA field is the only one that means something for
        // JALR and JR. TODO(zra): Fill in the other cases for PREF if needed.
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   ".hb");
      } else if (instr->SaField() != 0) {
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                           remaining_size_in_buffer(),
                           ".unknown");
      }
      return 4;
    }
    case 'd': {
      ASSERT(STRING_STARTS_WITH(format, "dest"));
      int off = instr->SImmField() << 2;
      uword destination =
          reinterpret_cast<uword>(instr) + off + Instr::kInstrSize;
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 "%#" Px "",
                                 destination);
      return 4;
    }
    case 'i': {
      ASSERT(STRING_STARTS_WITH(format, "imm"));
      if (format[3] == 'u') {
        int32_t imm = instr->UImmField();
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "0x%x",
                                   imm);
      } else {
        ASSERT(STRING_STARTS_WITH(format, "imms"));
        int32_t imm = instr->SImmField();
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%d",
                                   imm);
      }
      return 4;
    }
    case 'r': {
      return FormatRegister(instr, format);
    }
    case 'f': {
      if (format[1] == 'm') {
        ASSERT(STRING_STARTS_WITH(format, "fmt"));
        PrintFormat(instr);
        return 3;
      } else {
        return FormatFRegister(instr, format);
      }
    }
    case 's': {
      ASSERT(STRING_STARTS_WITH(format, "sa"));
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 "%d",
                                 instr->SaField());
      return 2;
    }
    default: {
      UNREACHABLE();
    }
  }
  UNREACHABLE();
  return -1;
}


// Format takes a formatting string for a whole instruction and prints it into
// the output buffer. All escaped options are handed to FormatOption to be
// parsed further.
void MIPSDecoder::Format(Instr* instr, const char* format) {
  char cur = *format++;
  while ((cur != 0) && (buffer_pos_ < (buffer_size_ - 1))) {
    if (cur == '\'') {  // Single quote is used as the formatting escape.
      format += FormatOption(instr, format);
    } else {
      buffer_[buffer_pos_++] = cur;
    }
    cur = *format++;
  }
  buffer_[buffer_pos_]  = '\0';
}


// For currently unimplemented decodings the disassembler calls Unknown(instr)
// which will just print "unknown" of the instruction bits.
void MIPSDecoder::Unknown(Instr* instr) {
  Format(instr, "unknown");
}


void MIPSDecoder::DecodeSpecial(Instr* instr) {
  ASSERT(instr->OpcodeField() == SPECIAL);
  switch (instr->FunctionField()) {
    case ADDU: {
      Format(instr, "addu 'rd, 'rs, 'rt");
      break;
    }
    case AND: {
      Format(instr, "and 'rd, 'rs, 'rt");
      break;
    }
    case BREAK: {
      Format(instr, "break 'code");
      break;
    }
    case DIV: {
      Format(instr, "div 'rs, 'rt");
      break;
    }
    case DIVU: {
      Format(instr, "divu 'rs, 'rt");
      break;
    }
    case JALR: {
      Format(instr, "jalr'hint 'rd, 'rs");
      break;
    }
    case JR: {
      Format(instr, "jr'hint 'rs");
      break;
    }
    case MFHI: {
      Format(instr, "mfhi 'rd");
      break;
    }
    case MFLO: {
      Format(instr, "mflo 'rd");
      break;
    }
    case MOVCI: {
      if (instr->Bit(16)) {
        Format(instr, "movt 'rd, 'rs");
      } else {
        Format(instr, "movf 'rd, 'rs");
      }
      break;
    }
    case MOVN: {
      Format(instr, "movn 'rd, 'rs, 'rt");
      break;
    }
    case MOVZ: {
      Format(instr, "movz 'rd, 'rs, 'rt");
      break;
    }
    case MTHI: {
      Format(instr, "mthi 'rs");
      break;
    }
    case MTLO: {
      Format(instr, "mtlo 'rs");
      break;
    }
    case MULT: {
      Format(instr, "mult 'rs, 'rt");
      break;
    }
    case MULTU: {
      Format(instr, "multu 'rs, 'rt");
      break;
    }
    case NOR: {
      Format(instr, "nor 'rd, 'rs, 'rt");
      break;
    }
    case OR: {
      if (instr->RsField() == 0 && instr->RtField() == 0) {
        Format(instr, "mov 'rd, 0");
      } else if (instr->RsField() == R0) {
        Format(instr, "mov 'rd, 'rt");
      } else if (instr->RtField() == R0) {
        Format(instr, "mov 'rd, 'rs");
      } else {
        Format(instr, "or 'rd, 'rs, 'rt");
      }
      break;
    }
    case SLL: {
      if ((instr->RdField() == R0) &&
          (instr->RtField() == R0) &&
          (instr->SaField() == 0)) {
        Format(instr, "nop");
      } else {
        Format(instr, "sll 'rd, 'rt, 'sa");
      }
      break;
    }
    case SLLV: {
      Format(instr, "sllv 'rd, 'rt, 'rs");
      break;
    }
    case SLT: {
      Format(instr, "slt 'rd, 'rs, 'rt");
      break;
    }
    case SLTU: {
      Format(instr, "sltu 'rd, 'rs, 'rt");
      break;
    }
    case SRA: {
      if (instr->RsField() == 0) {
        Format(instr, "sra 'rd, 'rt, 'sa");
      } else {
        Unknown(instr);
      }
      break;
    }
    case SRAV: {
      Format(instr, "srav 'rd, 'rt, 'rs");
      break;
    }
    case SRL: {
      if (instr->RsField() == 0) {
        Format(instr, "srl 'rd, 'rt, 'sa");
      } else {
        Unknown(instr);
      }
      break;
    }
    case SRLV: {
      if (instr->SaField() == 0) {
        Format(instr, "srlv 'rd, 'rt, 'rs");
      } else {
        Unknown(instr);
      }
      break;
    }
    case SUBU: {
      Format(instr, "subu 'rd, 'rs, 'rt");
      break;
    }
    case XOR: {
      Format(instr, "xor 'rd, 'rs, 'rt");
      break;
    }
    default: {
      Unknown(instr);
      break;
    }
  }
}


void MIPSDecoder::DecodeSpecial2(Instr* instr) {
  ASSERT(instr->OpcodeField() == SPECIAL2);
  switch (instr->FunctionField()) {
    case MADD: {
      Format(instr, "madd 'rs, 'rt");
      break;
    }
    case MADDU: {
      Format(instr, "maddu 'rs, 'rt");
      break;
    }
    case CLO: {
      Format(instr, "clo 'rd, 'rs");
      break;
    }
    case CLZ: {
      Format(instr, "clz 'rd, 'rs");
      break;
    }
    default: {
      Unknown(instr);
      break;
    }
  }
}


void MIPSDecoder::DecodeRegImm(Instr* instr) {
  ASSERT(instr->OpcodeField() == REGIMM);
  switch (instr->RegImmFnField()) {
    case BGEZ: {
      Format(instr, "bgez 'rs, 'dest");
      break;
    }
    case BGEZAL: {
      Format(instr, "bgezal 'rs, 'dest");
      break;
    }
    case BLTZAL: {
      Format(instr, "bltzal 'rs, 'dest");
      break;
    }
    case BGEZL: {
      Format(instr, "bgezl 'rs, 'dest");
      break;
    }
    case BLTZ: {
      Format(instr, "bltz 'rs, 'dest");
      break;
    }
    case BLTZL: {
      Format(instr, "bltzl 'rs, 'dest");
      break;
    }
    default: {
      Unknown(instr);
      break;
    }
  }
}

void MIPSDecoder::DecodeCop1(Instr* instr) {
  ASSERT(instr->OpcodeField() == COP1);
  if (instr->HasFormat()) {
    // If the rs field is a valid format, then the function field identifies
    // the instruction.
    switch (instr->Cop1FunctionField()) {
      case COP1_ADD: {
        Format(instr, "add.'fmt 'fd, 'fs, 'ft");
        break;
      }
      case COP1_SUB: {
        Format(instr, "sub.'fmt 'fd, 'fs, 'ft");
        break;
      }
      case COP1_MUL: {
        Format(instr, "mul.'fmt 'fd, 'fs, 'ft");
        break;
      }
      case COP1_DIV: {
        Format(instr, "div.'fmt 'fd, 'fs, 'ft");
        break;
      }
      case COP1_SQRT: {
        Format(instr, "sqrt.'fmt 'fd, 'fs");
        break;
      }
      case COP1_MOV: {
        Format(instr, "mov.'fmt 'fd, 'fs");
        break;
      }
      case COP1_C_F: {
        Format(instr, "c.f.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_UN: {
        Format(instr, "c.un.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_EQ: {
        Format(instr, "c.eq.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_UEQ: {
        Format(instr, "c.ueq.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_OLT: {
        Format(instr, "c.olt.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_ULT: {
        Format(instr, "c.ult.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_OLE: {
        Format(instr, "c.ole.'fmt 'fs, 'ft");
        break;
      }
      case COP1_C_ULE: {
        Format(instr, "c.ule.'fmt 'fs, 'ft");
        break;
      }
      case COP1_CVT_D: {
        Format(instr, "cvt.d.'fmt 'fd, 'fs");
        break;
      }
      case COP1_CVT_W: {
        Format(instr, "cvt.w.'fmt 'fd, 'fs");
        break;
      }
      default: {
        Unknown(instr);
        break;
      }
    }
  } else {
    // If the rs field isn't a valid format, then it must be a sub-opcode.
    switch (instr->Cop1SubField()) {
      case COP1_MF: {
        if (instr->Bits(0, 11) != 0) {
          Unknown(instr);
        } else {
          Format(instr, "mfc1 'rt, 'fs");
        }
        break;
      }
      case COP1_MT: {
        if (instr->Bits(0, 11) != 0) {
          Unknown(instr);
        } else {
          Format(instr, "mtc1 'rt, 'fs");
        }
        break;
      }
      case COP1_BC: {
        ASSERT(instr->Bit(17) == 0);
        if (instr->Bit(16) == 1) {  // Branch on true.
          Format(instr, "bc1t 'dest");
        } else {  // Branch on false.
          Format(instr, "bc1f 'dest");
        }
        break;
      }
      default: {
        Unknown(instr);
        break;
      }
    }
  }
}

void MIPSDecoder::InstructionDecode(Instr* instr) {
  switch (instr->OpcodeField()) {
    case SPECIAL: {
      DecodeSpecial(instr);
      break;
    }
    case SPECIAL2: {
      DecodeSpecial2(instr);
      break;
    }
    case REGIMM: {
      DecodeRegImm(instr);
      break;
    }
    case COP1: {
      DecodeCop1(instr);
      break;
    }
    case ADDIU: {
      Format(instr, "addiu 'rt, 'rs, 'imms");
      break;
    }
    case ANDI: {
      Format(instr, "andi 'rt, 'rs, 'immu");
      break;
    }
    case BEQ: {
      Format(instr, "beq 'rs, 'rt, 'dest");
      break;
    }
    case BEQL: {
      Format(instr, "beql 'rs, 'rt, 'dest");
      break;
    }
    case BGTZ: {
      Format(instr, "bgtz 'rs, 'dest");
      break;
    }
    case BGTZL: {
      Format(instr, "bgtzl 'rs, 'dest");
      break;
    }
    case BLEZ: {
      Format(instr, "blez 'rs, 'dest");
      break;
    }
    case BLEZL: {
      Format(instr, "blezl 'rs, 'dest");
      break;
    }
    case BNE: {
      Format(instr, "bne 'rs, 'rt, 'dest");
      break;
    }
    case BNEL: {
      Format(instr, "bnel 'rs, 'rt, 'dest");
      break;
    }
    case LB: {
      Format(instr, "lb 'rt, 'imms('rs)");
      break;
    }
    case LBU: {
      Format(instr, "lbu 'rt, 'imms('rs)");
      break;
    }
    case LDC1: {
      Format(instr, "ldc1 'ft, 'imms('rs)");
      break;
    }
    case LH: {
      Format(instr, "lh 'rt, 'imms('rs)");
      break;
    }
    case LHU: {
      Format(instr, "lhu 'rt, 'imms('rs)");
      break;
    }
    case LUI: {
      Format(instr, "lui 'rt, 'immu");
      break;
    }
    case LW: {
      Format(instr, "lw 'rt, 'imms('rs)");
      break;
    }
    case LWC1: {
      Format(instr, "lwc1 'ft, 'imms('rs)");
      break;
    }
    case ORI: {
      Format(instr, "ori 'rt, 'rs, 'immu");
      break;
    }
    case SB: {
      Format(instr, "sb 'rt, 'imms('rs)");
      break;
    }
    case SLTI: {
      Format(instr, "slti 'rt, 'rs, 'imms");
      break;
    }
    case SLTIU: {
      Format(instr, "sltiu 'rt, 'rs, 'imms");
      break;
    }
    case SH: {
      Format(instr, "sh 'rt, 'imms('rs)");
      break;
    }
    case SDC1: {
      Format(instr, "sdc1 'ft, 'imms('rs)");
      break;
    }
    case SW: {
      Format(instr, "sw 'rt, 'imms('rs)");
      break;
    }
    case SWC1: {
      Format(instr, "swc1 'ft, 'imms('rs)");
      break;
    }
    case XORI: {
      Format(instr, "xori 'rt, 'rs, 'immu");
      break;
    }
    default: {
      Unknown(instr);
      break;
    }
  }
}


void Disassembler::DecodeInstruction(char* hex_buffer, intptr_t hex_size,
                                     char* human_buffer, intptr_t human_size,
                                     int* out_instr_len, uword pc) {
  MIPSDecoder decoder(human_buffer, human_size);
  Instr* instr = Instr::At(pc);
  decoder.InstructionDecode(instr);
  OS::SNPrint(hex_buffer, hex_size, "%08x", instr->InstructionBits());
  if (out_instr_len) {
    *out_instr_len = Instr::kInstrSize;
  }
}


void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter,
                               const Code::Comments& comments) {
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword pc = start;
  intptr_t comment_finger = 0;
  while (pc < end) {
    const intptr_t offset = pc - start;
    while (comment_finger < comments.Length() &&
           comments.PCOffsetAt(comment_finger) <= offset) {
      formatter->Print(
          "        ;; %s\n",
          String::Handle(comments.CommentAt(comment_finger)).ToCString());
      comment_finger++;
    }
    int instruction_length;
    DecodeInstruction(hex_buffer, sizeof(hex_buffer),
                      human_buffer, sizeof(human_buffer),
                      &instruction_length, pc);

    formatter->ConsumeInstruction(hex_buffer,
                                  sizeof(hex_buffer),
                                  human_buffer,
                                  sizeof(human_buffer),
                                  pc);
    pc += instruction_length;
  }

  return;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
