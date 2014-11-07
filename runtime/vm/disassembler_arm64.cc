// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)
#include "platform/assert.h"

namespace dart {

class ARM64Decoder : public ValueObject {
 public:
  ARM64Decoder(char* buffer, size_t buffer_size)
      : buffer_(buffer),
        buffer_size_(buffer_size),
        buffer_pos_(0) {
    buffer_[buffer_pos_] = '\0';
  }

  ~ARM64Decoder() {}

  // Writes one disassembled instruction into 'buffer' (0-terminated).
  // Returns true if the instruction was successfully decoded, false otherwise.
  void InstructionDecode(uword pc);

 private:
  // Bottleneck functions to print into the out_buffer.
  void Print(const char* str);

  // Printing of common values.
  void PrintRegister(int reg, R31Type r31t);
  void PrintVRegister(int reg);
  void PrintShiftExtendRm(Instr* instr);
  void PrintMemOperand(Instr* instr);
  void PrintPairMemOperand(Instr* instr);
  void PrintS(Instr* instr);
  void PrintCondition(Instr* instr);

  // Handle formatting of instructions and their options.
  int FormatRegister(Instr* instr, const char* option);
  int FormatVRegister(Instr*instr, const char* option);
  int FormatOption(Instr* instr, const char* format);
  void Format(Instr* instr, const char* format);
  void Unknown(Instr* instr);

  // Decode instructions.
  #define DECODE_OP(op)                                                        \
    void Decode##op(Instr* instr);
  APPLY_OP_LIST(DECODE_OP)
  #undef DECODE_OP


  // Convenience functions.
  char* get_buffer() const { return buffer_; }
  char* current_position_in_buffer() { return buffer_ + buffer_pos_; }
  size_t remaining_size_in_buffer() { return buffer_size_ - buffer_pos_; }

  char* buffer_;  // Decode instructions into this buffer.
  size_t buffer_size_;  // The size of the character buffer.
  size_t buffer_pos_;  // Current character position in buffer.

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ARM64Decoder);
};


// Support for assertions in the ARM64Decoder formatting functions.
#define STRING_STARTS_WITH(string, compare_string) \
  (strncmp(string, compare_string, strlen(compare_string)) == 0)


// Append the str to the output buffer.
void ARM64Decoder::Print(const char* str) {
  char cur = *str++;
  while (cur != '\0' && (buffer_pos_ < (buffer_size_ - 1))) {
    buffer_[buffer_pos_++] = cur;
    cur = *str++;
  }
  buffer_[buffer_pos_] = '\0';
}


// These register names are defined in a way to match the native disassembler
// formatting, except for register aliases ctx (r9) and pp (r10).
// See for example the command "objdump -d <binary file>".
static const char* reg_names[kNumberOfCpuRegisters] = {
  "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",
  "r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",
  "ip0", "ip1", "sp", "r19", "r20", "r21", "r22", "r23",
  "r24", "r25", "r26", "pp",  "ctx", "fp",  "lr",  "r31",
};


// Print the register name according to the active name converter.
void ARM64Decoder::PrintRegister(int reg, R31Type r31t) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfCpuRegisters);
  if (reg == 31) {
    const char* rstr = (r31t == R31IsZR) ? "zr" : "csp";
    Print(rstr);
  } else {
    Print(reg_names[reg]);
  }
}


void ARM64Decoder::PrintVRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfVRegisters);
  buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                             remaining_size_in_buffer(),
                             "v%d", reg);
}


// These shift names are defined in a way to match the native disassembler
// formatting. See for example the command "objdump -d <binary file>".
static const char* shift_names[kMaxShift] = {
  "lsl", "lsr", "asr", "ror"
};


static const char* extend_names[kMaxExtend] = {
  "uxtb", "uxth", "uxtw", "uxtx",
  "sxtb", "sxth", "sxtw", "sxtx",
};


// These condition names are defined in a way to match the native disassembler
// formatting. See for example the command "objdump -d <binary file>".
static const char* cond_names[kMaxCondition] = {
  "eq", "ne", "cs" , "cc" , "mi" , "pl" , "vs" , "vc" ,
  "hi", "ls", "ge", "lt", "gt", "le", "", "invalid",
};


// Print the condition guarding the instruction.
void ARM64Decoder::PrintCondition(Instr* instr) {
  if (instr->IsConditionalSelectOp()) {
    Print(cond_names[instr->SelectConditionField()]);
  } else {
    Print(cond_names[instr->ConditionField()]);
  }
}


// Print the register shift operands for the instruction. Generally used for
// data processing instructions.
void ARM64Decoder::PrintShiftExtendRm(Instr* instr) {
  int rm = instr->RmField();
  Shift shift = instr->ShiftTypeField();
  int shift_amount = instr->ShiftAmountField();
  Extend extend = instr->ExtendTypeField();
  int extend_shift_amount = instr->ExtShiftAmountField();

  PrintRegister(rm, R31IsZR);

  if (instr->IsShift() && (shift == LSL) && (shift_amount == 0)) {
    // Special case for using rm only.
    return;
  }
  if (instr->IsShift()) {
    // by immediate
    if ((shift == ROR) && (shift_amount == 0)) {
      Print(" RRX");
      return;
    } else if (((shift == LSR) || (shift == ASR)) && (shift_amount == 0)) {
      shift_amount = 32;
    }
    buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                               remaining_size_in_buffer(),
                               " %s #%d",
                               shift_names[shift],
                               shift_amount);
  } else {
    ASSERT(instr->IsExtend());
    // by register
    buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                               remaining_size_in_buffer(),
                               " %s",
                               extend_names[extend]);
    if (((instr->SFField() == 1) && (extend == UXTX)) ||
        ((instr->SFField() == 0) && (extend == UXTW))) {
      // Shift amount.
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 " %d",
                                 extend_shift_amount);
    }
  }
}


void ARM64Decoder::PrintMemOperand(Instr* instr) {
  const Register rn = instr->RnField();
  if (instr->Bit(24) == 1) {
    // rn + scaled unsigned 12-bit immediate offset.
    const uint32_t scale = instr->SzField();
    const uint32_t imm12 = instr->Imm12Field();
    const uint32_t off = imm12 << scale;
    Print("[");
    PrintRegister(rn, R31IsSP);
    if (off != 0) {
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 ", #%d",
                                 off);
    }
    Print("]");
  } else {
    switch (instr->Bits(10, 2)) {
      case 0: {
        // rn + signed 9-bit immediate, pre-index, no writeback.
        const int32_t imm9 = instr->SImm9Field();
        Print("[");
        PrintRegister(rn, R31IsSP);
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   ", #%d",
                                   imm9);
        Print("]");
        break;
      }
      case 1: {
        const int32_t imm9 = instr->SImm9Field();
        // rn + signed 9-bit immediate, post-index, writeback.
        Print("[");
        PrintRegister(rn, R31IsSP);
        Print("]");
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   ", #%d !",
                                   imm9);
        break;
      }
      case 2: {
        const Register rm = instr->RmField();
        const Extend ext = instr->ExtendTypeField();
        const int s = instr->Bit(12);
        Print("[");
        PrintRegister(rn, R31IsSP);
        Print(", ");
        PrintRegister(rm, R31IsZR);
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   " %s",
                                   extend_names[ext]);
        if (s == 1) {
          Print(" scaled");
        }
        Print("]");
        break;
      }
      case 3: {
        const int32_t imm9 = instr->SImm9Field();
        // rn + signed 9-bit immediate, pre-index, writeback.
        Print("[");
        PrintRegister(rn, R31IsSP);
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   ", #%d",
                                   imm9);
        Print("] !");
        break;
      }
      default: {
        Print("???");
      }
    }
  }
}


void ARM64Decoder::PrintPairMemOperand(Instr* instr) {
  const Register rn = instr->RnField();
  const int32_t simm7 = instr->SImm7Field();
  const int32_t offset = simm7 << (2 + instr->Bit(31));
  Print("[");
  PrintRegister(rn, R31IsSP);
  switch (instr->Bits(23, 3)) {
    case 1:
      // rn + (imm7 << (2 + B31)), post-index, writeback.
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 "], #%d !",
                                 offset);
      break;
    case 2:
      // rn + (imm7 << (2 + B31)), pre-index, no writeback.
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 ", #%d ]",
                                 offset);
      break;
    case 3:
      // rn + (imm7 << (2 + B31)), pre-index, writeback.
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 ", #%d ]!",
                                 offset);
      break;
    default:
      Print(", ???]");
      break;
  }
}


// Handle all register based formatting in these functions to reduce the
// complexity of FormatOption.
int ARM64Decoder::FormatRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'r');
  if (format[1] == 'n') {  // 'rn: Rn register
    int reg = instr->RnField();
    PrintRegister(reg, instr->RnMode());
    return 2;
  } else if (format[1] == 'd') {  // 'rd: Rd register
    int reg = instr->RdField();
    PrintRegister(reg, instr->RdMode());
    return 2;
  } else if (format[1] == 'm') {  // 'rm: Rm register
    int reg = instr->RmField();
    PrintRegister(reg, R31IsZR);
    return 2;
  } else if (format[1] == 't') {  // 'rt: Rt register
    int reg = instr->RtField();
    PrintRegister(reg, R31IsZR);
    return 2;
  } else if (format[1] == 'a') {  // 'ra: Ra register
    int reg = instr->RaField();
    PrintRegister(reg, R31IsZR);
    return 2;
  }
  UNREACHABLE();
  return -1;
}


int ARM64Decoder::FormatVRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'v');
  if (format[1] == 'd') {
    int reg = instr->VdField();
    PrintVRegister(reg);
    return 2;
  } else if (format[1] == 'n') {
    int reg = instr->VnField();
    PrintVRegister(reg);
    return 2;
  } else if (format[1] == 'm') {
    int reg = instr->VmField();
    PrintVRegister(reg);
    return 2;
  } else if (format[1] == 't') {
    int reg = instr->VtField();
    PrintVRegister(reg);
    return 2;
  }
  UNREACHABLE();
  return -1;
}


// FormatOption takes a formatting string and interprets it based on
// the current instructions. The format string points to the first
// character of the option string (the option escape has already been
// consumed by the caller.)  FormatOption returns the number of
// characters that were consumed from the formatting string.
int ARM64Decoder::FormatOption(Instr* instr, const char* format) {
  switch (format[0]) {
    case 'b': {
      if (format[3] == 'i') {
        ASSERT(STRING_STARTS_WITH(format, "bitimm"));
        const uint64_t imm = instr->ImmLogical();
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "0x%"Px64,
                                   imm);
        return 6;
      } else {
        ASSERT(STRING_STARTS_WITH(format, "bitpos"));
        int bitpos = instr->Bits(19, 4) | (instr->Bit(31) << 5);
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "#%d",
                                   bitpos);
        return 6;
      }
    }
    case 'c': {
      if (format[1] == 's') {
        ASSERT(STRING_STARTS_WITH(format, "csz"));
        const int32_t imm5 = instr->Bits(16, 5);
        char const* typ = "??";
        if (imm5 & 0x1) {
          typ = "b";
        } else if (imm5 & 0x2) {
          typ = "h";
        } else if (imm5 & 0x4) {
          typ = "s";
        } else if (imm5 & 0x8) {
          typ = "d";
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%s",
                                   typ);
        return 3;
      } else {
        ASSERT(STRING_STARTS_WITH(format, "cond"));
        PrintCondition(instr);
        return 4;
      }
    }
    case 'd': {
      if (format[4] == '2') {
        ASSERT(STRING_STARTS_WITH(format, "dest26"));
        int64_t off = instr->SImm26Field() << 2;
        uword destination = reinterpret_cast<uword>(instr) + off;
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%#" Px "",
                                   destination);
      } else {
        if (format[5] == '4') {
          ASSERT(STRING_STARTS_WITH(format, "dest14"));
          int64_t off = instr->SImm14Field() << 2;
          uword destination = reinterpret_cast<uword>(instr) + off;
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "%#" Px "",
                                     destination);
        } else {
          ASSERT(STRING_STARTS_WITH(format, "dest19"));
          int64_t off = instr->SImm19Field() << 2;
          uword destination = reinterpret_cast<uword>(instr) + off;
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "%#" Px "",
                                     destination);
        }
      }
      return 6;
    }
    case 'f': {
      ASSERT(STRING_STARTS_WITH(format, "fsz"));
        const int sz = instr->SzField();
        char const* sz_str;
        switch (sz) {
          case 0:
            if (instr->Bit(23) == 1) {
              sz_str = "q";
            } else {
              sz_str = "b";
            }
            break;
          case 1: sz_str = "h"; break;
          case 2: sz_str = "s"; break;
          case 3: sz_str = "d"; break;
          default: sz_str = "?"; break;
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%s",
                                   sz_str);
      return 3;
    }
    case 'h': {
      ASSERT(STRING_STARTS_WITH(format, "hw"));
      const int shift = instr->HWField() << 4;
      if (shift != 0) {
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "lsl %d",
                                   shift);
      }
      return 2;
    }
    case 'i': {  // 'imm12, 'imm16, 'immd
      if (format[1] == 'd') {
        // Element index for a SIMD copy instruction.
        ASSERT(STRING_STARTS_WITH(format, "idx"));
        const int32_t imm4 = instr->Bits(11, 4);
        const int32_t imm5 = instr->Bits(16, 5);
        int32_t shift = 0;
        int32_t imm = -1;
        if (format[3] == '4') {
          imm = imm4;
        } else if (format[3] == '5') {
          imm = imm5;
          shift = 1;
        }
        int32_t idx = -1;
        if (imm5 & 0x1) {
          idx = imm >> shift;
        } else if (imm5 & 0x2) {
          idx = imm >> (shift + 1);
        } else if (imm5 & 0x4) {
          idx = imm >> (shift + 2);
        } else if (imm5 & 0x8) {
          idx = imm >> (shift + 3);
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "[%d]",
                                   idx);
        return 4;
      } else if (format[3] == '1') {
        uint64_t imm;
        int ret = 5;
        if (format[4] == '2') {
          ASSERT(STRING_STARTS_WITH(format, "imm12"));
          imm = instr->Imm12Field();
          if (format[5] == 's') {
            // shifted immediate.
            if (instr->Imm12ShiftField() == 1) {
              imm = imm << 12;
            } else if ((instr->Imm12ShiftField() & 0x2) != 0) {
              Print("Unknown Shift");
            }
            ret = 6;
          }
        } else {
          ASSERT(STRING_STARTS_WITH(format, "imm16"));
          imm = instr->Imm16Field();
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "0x%"Px64,
                                   imm);
        return ret;
      } else {
        ASSERT(STRING_STARTS_WITH(format, "immd"));
        double dimm = bit_cast<double, int64_t>(
            Instr::VFPExpandImm(instr->Imm8Field()));
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%f",
                                   dimm);
        return 4;
      }
    }
    case 'm': {
      ASSERT(STRING_STARTS_WITH(format, "memop"));
      PrintMemOperand(instr);
      return 5;
    }
    case 'p': {
      if (format[1] == 'c') {
        if (format[2] == 'a') {
          ASSERT(STRING_STARTS_WITH(format, "pcadr"));
          const int64_t immhi = instr->SImm19Field();
          const int64_t immlo = instr->Bits(29, 2);
          const int64_t off = (immhi << 2) | immlo;
          const int64_t pc = reinterpret_cast<int64_t>(instr);
          const int64_t dest = pc + off;
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "0x%"Px64,
                                     dest);
        } else {
          ASSERT(STRING_STARTS_WITH(format, "pcldr"));
          const int64_t off = instr->SImm19Field() << 2;
          const int64_t pc = reinterpret_cast<int64_t>(instr);
          const int64_t dest = pc + off;
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "0x%"Px64,
                                     dest);
        }
        return 5;
      } else {
        ASSERT(STRING_STARTS_WITH(format, "pmemop"));
        PrintPairMemOperand(instr);
        return 6;
      }
    }
    case 'r': {
      return FormatRegister(instr, format);
    }
    case 'v': {
      if (format[1] == 's') {
        ASSERT(STRING_STARTS_WITH(format, "vsz"));
        char const* sz_str = NULL;
        if (instr->Bits(14, 2) == 3) {
          switch (instr->Bit(22)) {
            case 0: sz_str = "s"; break;
            case 1: sz_str = "d"; break;
            default: UNREACHABLE(); break;
          }
        } else {
          switch (instr->Bit(22)) {
            case 0: sz_str = "w"; break;
            case 1: sz_str = "x"; break;
            default: UNREACHABLE(); break;
          }
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%s",
                                   sz_str);
        return 3;
      } else {
        return FormatVRegister(instr, format);
      }
    }
    case 's': {  // 's: S flag.
      if (format[1] == 'h') {
        ASSERT(STRING_STARTS_WITH(format, "shift_op"));
        PrintShiftExtendRm(instr);
        return 8;
      } else if (format[1] == 'f') {
        ASSERT(STRING_STARTS_WITH(format, "sf"));
        if (instr->SFField() == 1) {
          // TODO(zra): If we don't use the w form much, we can omit printing
          // this x.
          Print("x");
        } else {
          Print("w");
        }
        return 2;
      } else if (format[1] == 'z') {
        ASSERT(STRING_STARTS_WITH(format, "sz"));
        const int sz = instr->SzField();
        char const* sz_str;
        switch (sz) {
          case 0: sz_str = "b"; break;
          case 1: sz_str = "h"; break;
          case 2: sz_str = "w"; break;
          case 3: sz_str = "x"; break;
          default: sz_str = "?"; break;
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%s",
                                   sz_str);
        return 2;
      } else if (format[1] == ' ') {
        if (instr->HasS()) {
          Print("s");
        }
        return 1;
      } else {
        UNREACHABLE();
      }
    }
    default: {
      UNREACHABLE();
      break;
    }
  }
  UNREACHABLE();
  return -1;
}


// Format takes a formatting string for a whole instruction and prints it into
// the output buffer. All escaped options are handed to FormatOption to be
// parsed further.
void ARM64Decoder::Format(Instr* instr, const char* format) {
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
void ARM64Decoder::Unknown(Instr* instr) {
  Format(instr, "unknown");
}


void ARM64Decoder::DecodeMoveWide(Instr* instr) {
  switch (instr->Bits(29, 2)) {
    case 0:
      Format(instr, "movn'sf 'rd, 'imm16 'hw");
      break;
    case 2:
      Format(instr, "movz'sf 'rd, 'imm16 'hw");
      break;
    case 3:
      Format(instr, "movk'sf 'rd, 'imm16 'hw");
      break;
    default:
      Unknown(instr);
      break;
  }
}


void ARM64Decoder::DecodeLoadStoreReg(Instr* instr) {
  if (instr->Bit(26) == 1) {
    // SIMD or FP src/dst.
    if (instr->Bit(22) == 1) {
      Format(instr, "fldr'fsz 'vt, 'memop");
    } else {
      Format(instr, "fstr'fsz 'vt, 'memop");
    }
  } else {
    // Integer src/dst.
    if (instr->Bits(22, 2) == 0) {
      Format(instr, "str'sz 'rt, 'memop");
    } else {
      Format(instr, "ldr'sz 'rt, 'memop");
    }
  }
}


void ARM64Decoder::DecodeLoadStoreRegPair(Instr* instr) {
  if (instr->Bit(22) == 1) {
    // Load.
    Format(instr, "ldp'sf 'rt, 'ra, 'pmemop");
  } else {
    // Store.
    Format(instr, "stp'sf 'rt, 'ra, 'pmemop");
  }
}


void ARM64Decoder::DecodeLoadRegLiteral(Instr* instr) {
  if ((instr->Bit(31) != 0) || (instr->Bit(29) != 0) ||
      (instr->Bits(24, 3) != 0)) {
    Unknown(instr);
  }
  if (instr->Bit(30)) {
    Format(instr, "ldrx 'rt, 'pcldr");
  } else {
    Format(instr, "ldrw 'rt, 'pcldr");
  }
}


void ARM64Decoder::DecodeAddSubImm(Instr* instr) {
  switch (instr->Bit(30)) {
    case 0: {
      if ((instr->RdField() == R31) && (instr->SField() == 1)) {
        Format(instr, "cmni'sf 'rn, 'imm12s");
      } else {
        if (((instr->RdField() == R31) || (instr->RnField() == R31)) &&
            (instr->Imm12Field() == 0) && (instr->Bit(29) == 0)) {
          Format(instr, "mov'sf 'rd, 'rn");
        } else {
          Format(instr, "addi'sf's 'rd, 'rn, 'imm12s");
        }
      }
      break;
    }
    case 1: {
      if ((instr->RdField() == R31) && (instr->SField() == 1)) {
        Format(instr, "cmpi'sf 'rn, 'imm12s");
      } else {
        Format(instr, "subi'sf's 'rd, 'rn, 'imm12s");
      }
      break;
    }
    default:
      Unknown(instr);
      break;
  }
}


void ARM64Decoder::DecodeLogicalImm(Instr* instr) {
  int op = instr->Bits(29, 2);
  switch (op) {
    case 0:
      Format(instr, "andi'sf 'rd, 'rn, 'bitimm");
      break;
    case 1: {
      if (instr->RnField() == R31) {
        Format(instr, "mov'sf 'rd, 'bitimm");
      } else {
        Format(instr, "orri'sf 'rd, 'rn, 'bitimm");
      }
      break;
    }
    case 2:
      Format(instr, "eori'sf 'rd, 'rn, 'bitimm");
      break;
    case 3:
      Format(instr, "andi'sfs 'rd, 'rn, 'bitimm");
      break;
    default:
      Unknown(instr);
      break;
  }
}


void ARM64Decoder::DecodePCRel(Instr* instr) {
  const int op = instr->Bit(31);
  if (op == 0) {
    Format(instr, "adr 'rd, 'pcadr");
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeDPImmediate(Instr* instr) {
  if (instr->IsMoveWideOp()) {
    DecodeMoveWide(instr);
  } else if (instr->IsAddSubImmOp()) {
    DecodeAddSubImm(instr);
  } else if (instr->IsLogicalImmOp()) {
    DecodeLogicalImm(instr);
  } else if (instr->IsPCRelOp()) {
    DecodePCRel(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeExceptionGen(Instr* instr) {
  if ((instr->Bits(0, 2) == 1) && (instr->Bits(2, 3) == 0) &&
      (instr->Bits(21, 3) == 0)) {
    Format(instr, "svc 'imm16");
  } else if ((instr->Bits(0, 2) == 0) && (instr->Bits(2, 3) == 0) &&
             (instr->Bits(21, 3) == 1)) {
    Format(instr, "brk 'imm16");
  } else if ((instr->Bits(0, 2) == 0) && (instr->Bits(2, 3) == 0) &&
             (instr->Bits(21, 3) == 2)) {
    Format(instr, "hlt 'imm16");
  }
}


void ARM64Decoder::DecodeSystem(Instr* instr) {
  if ((instr->Bits(0, 8) == 0x1f) && (instr->Bits(12, 4) == 2) &&
      (instr->Bits(16, 3) == 3) && (instr->Bits(19, 2) == 0) &&
      (instr->Bit(21) == 0)) {
    if (instr->Bits(8, 4) == 0) {
      Format(instr, "nop");
    } else {
      Unknown(instr);
    }
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeUnconditionalBranchReg(Instr* instr) {
  if ((instr->Bits(0, 5) == 0) && (instr->Bits(10, 5) == 0) &&
      (instr->Bits(16, 5) == 0x1f)) {
    switch (instr->Bits(21, 4)) {
      case 0:
        Format(instr, "br 'rn");
        break;
      case 1:
        Format(instr, "blr 'rn");
        break;
      case 2:
        Format(instr, "ret 'rn");
        break;
      default:
        Unknown(instr);
        break;
    }
  }
}


void ARM64Decoder::DecodeCompareAndBranch(Instr* instr) {
  const int op = instr->Bit(24);
  if (op == 0) {
    Format(instr, "cbz'sf 'rt, 'dest19");
  } else {
    Format(instr, "cbnz'sf 'rt, 'dest19");
  }
}


void ARM64Decoder::DecodeConditionalBranch(Instr* instr) {
  if ((instr->Bit(24) != 0) || (instr->Bit(4) != 0)) {
    Unknown(instr);
    return;
  }
  Format(instr, "b'cond 'dest19");
}


void ARM64Decoder::DecodeTestAndBranch(Instr* instr) {
  const int op = instr->Bit(24);
  if (op == 0) {
    Format(instr, "tbz'sf 'rt, 'bitpos, 'dest14");
  } else {
    Format(instr, "tbnz'sf 'rt, 'bitpos, 'dest14");
  }
}


void ARM64Decoder::DecodeUnconditionalBranch(Instr* instr) {
  const int op = instr->Bit(31);
  if (op == 0) {
    Format(instr, "b 'dest26");
  } else {
    Format(instr, "bl 'dest26");
  }
}

void ARM64Decoder::DecodeCompareBranch(Instr* instr) {
  if (instr->IsExceptionGenOp()) {
    DecodeExceptionGen(instr);
  } else if (instr->IsSystemOp()) {
    DecodeSystem(instr);
  } else if (instr->IsUnconditionalBranchRegOp()) {
    DecodeUnconditionalBranchReg(instr);
  } else if (instr->IsCompareAndBranchOp()) {
    DecodeCompareAndBranch(instr);
  } else if (instr->IsConditionalBranchOp()) {
    DecodeConditionalBranch(instr);
  } else if (instr->IsTestAndBranchOp()) {
    DecodeTestAndBranch(instr);
  } else if (instr->IsUnconditionalBranchOp()) {
    DecodeUnconditionalBranch(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeLoadStore(Instr* instr) {
  if (instr->IsLoadStoreRegOp()) {
    DecodeLoadStoreReg(instr);
  } else if (instr->IsLoadStoreRegPairOp()) {
    DecodeLoadStoreRegPair(instr);
  } else if (instr->IsLoadRegLiteralOp()) {
    DecodeLoadRegLiteral(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeAddSubShiftExt(Instr* instr) {
  switch (instr->Bit(30)) {
    case 0: {
      if ((instr->RdField() == R31) && (instr->SFField())) {
        Format(instr, "cmn'sf 'rn, 'shift_op");
      } else {
        Format(instr, "add'sf's 'rd, 'rn, 'shift_op");
      }
      break;
    }
    case 1: {
      if ((instr->RdField() == R31) && (instr->SFField())) {
        Format(instr, "cmp'sf 'rn, 'shift_op");
      } else {
        Format(instr, "sub'sf's 'rd, 'rn, 'shift_op");
      }
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}


void ARM64Decoder::DecodeAddSubWithCarry(Instr* instr) {
  switch (instr->Bit(30)) {
    case 0: {
      Format(instr, "adc'sf's 'rd, 'rn, 'rm");
      break;
    }
    case 1: {
      Format(instr, "sbc'sf's 'rd, 'rn, 'rm");
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}


void ARM64Decoder::DecodeLogicalShift(Instr* instr) {
  const int op = (instr->Bits(29, 2) << 1) | instr->Bit(21);
  switch (op) {
    case 0:
      Format(instr, "and'sf 'rd, 'rn, 'shift_op");
      break;
    case 1:
      Format(instr, "bic'sf 'rd, 'rn, 'shift_op");
      break;
    case 2: {
      if ((instr->RnField() == R31) && (instr->IsShift()) &&
          (instr->Imm16Field() == 0) && (instr->ShiftTypeField() == LSL)) {
        Format(instr, "mov'sf 'rd, 'rm");
      } else {
        Format(instr, "orr'sf 'rd, 'rn, 'shift_op");
      }
      break;
    }
    case 3:
      Format(instr, "orn'sf 'rd, 'rn, 'shift_op");
      break;
    case 4:
      Format(instr, "eor'sf 'rd, 'rn, 'shift_op");
      break;
    case 5:
      Format(instr, "eon'sf 'rd, 'rn, 'shift_op");
      break;
    case 6:
      Format(instr, "and'sfs 'rd, 'rn, 'shift_op");
      break;
    case 7:
      Format(instr, "bic'sfs 'rd, 'rn, 'shift_op");
      break;
    default:
      UNREACHABLE();
      break;
  }
}


void ARM64Decoder::DecodeMiscDP2Source(Instr* instr) {
  if (instr->Bit(29) != 0) {
    Unknown(instr);
  }

  const int op = instr->Bits(10, 5);
  switch (op) {
    case 2:
      Format(instr, "udiv'sf 'rd, 'rn, 'rm");
      break;
    case 3:
      Format(instr, "sdiv'sf 'rd, 'rn, 'rm");
      break;
    case 8:
      Format(instr, "lsl'sf 'rd, 'rn, 'rm");
      break;
    case 9:
      Format(instr, "lsr'sf 'rd, 'rn, 'rm");
      break;
    case 10:
      Format(instr, "asr'sf 'rd, 'rn, 'rm");
      break;
    default:
      Unknown(instr);
      break;
  }
}


void ARM64Decoder::DecodeMiscDP3Source(Instr* instr) {
  if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 0) &&
      (instr->Bit(15) == 0)) {
    if (instr->RaField() == R31) {
      Format(instr, "mul'sf, 'rd, 'rn, 'rm");
    } else {
      Format(instr, "madd'sf 'rd, 'rn, 'rm, 'ra");
    }
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 0) &&
             (instr->Bit(15) == 1)) {
    Format(instr, "msub'sf 'rd, 'rn, 'rm, 'ra");
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(21, 3) == 2) &&
             (instr->Bit(15) == 0)) {
    Format(instr, "smulh 'rd, 'rn, 'rm");
  } else if ((instr->Bits(29, 3) == 4) && (instr->Bits(21, 3) == 5) &&
             (instr->Bit(15) == 0)) {
    Format(instr, "umaddl 'rd, 'rn, 'rm, 'ra");
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeConditionalSelect(Instr* instr) {
  if ((instr->Bits(29, 2) == 0) && (instr->Bits(10, 2) == 0)) {
    Format(instr, "mov'sf'cond 'rd, 'rn, 'rm");
  } else if ((instr->Bits(29, 2) == 0) && (instr->Bits(10, 2) == 1)) {
    Format(instr, "csinc'sf'cond 'rd, 'rn, 'rm");
  } else if ((instr->Bits(29, 2) == 2) && (instr->Bits(10, 2) == 0)) {
    Format(instr, "csinv'sf'cond 'rd, 'rn, 'rm");
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeDPRegister(Instr* instr) {
  if (instr->IsAddSubShiftExtOp()) {
    DecodeAddSubShiftExt(instr);
  } else if (instr->IsAddSubWithCarryOp()) {
    DecodeAddSubWithCarry(instr);
  } else if (instr->IsLogicalShiftOp()) {
    DecodeLogicalShift(instr);
  } else if (instr->IsMiscDP2SourceOp()) {
    DecodeMiscDP2Source(instr);
  } else if (instr->IsMiscDP3SourceOp()) {
    DecodeMiscDP3Source(instr);
  } else if (instr->IsConditionalSelectOp()) {
    DecodeConditionalSelect(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeSIMDCopy(Instr* instr) {
  const int32_t Q = instr->Bit(30);
  const int32_t op = instr->Bit(29);
  const int32_t imm4 = instr->Bits(11, 4);

  if ((op == 0) && (imm4 == 7)) {
    if (Q == 0) {
      Format(instr, "vmovrs 'rd, 'vn'idx5");
    } else {
      Format(instr, "vmovrd 'rd, 'vn'idx5");
    }
  } else if ((Q == 1)  && (op == 0) && (imm4 == 0)) {
    Format(instr, "vdup'csz 'vd, 'vn'idx5");
  } else if ((Q == 1) && (op == 0) && (imm4 == 3)) {
    Format(instr, "vins'csz 'vd'idx5, 'rn");
  } else if ((Q == 1) && (op == 0) && (imm4 == 1)) {
    Format(instr, "vdup'csz 'vd, 'rn");
  } else if ((Q == 1) && (op == 1)) {
    Format(instr, "vins'csz 'vd'idx5, 'vn'idx4");
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeSIMDThreeSame(Instr* instr) {
  const int32_t Q = instr->Bit(30);
  const int32_t U = instr->Bit(29);
  const int32_t opcode = instr->Bits(11, 5);

  if (Q == 0) {
    Unknown(instr);
    return;
  }

  if ((U == 0) && (opcode == 0x3)) {
    if (instr->Bit(23) == 0) {
      Format(instr, "vand 'vd, 'vn, 'vm");
    } else {
      Format(instr, "vorr 'vd, 'vn, 'vm");
    }
  } else if ((U == 1) && (opcode == 0x3)) {
    Format(instr, "veor 'vd, 'vn, 'vm");
  } else if ((U == 0) && (opcode == 0x10)) {
    Format(instr, "vadd'vsz 'vd, 'vn, 'vm");
  } else if ((U == 1) && (opcode == 0x10)) {
    Format(instr, "vsub'vsz 'vd, 'vn, 'vm");
  } else if ((U == 0) && (opcode == 0x1a)) {
    if (instr->Bit(23) == 0) {
      Format(instr, "vadd'vsz 'vd, 'vn, 'vm");
    } else {
      Format(instr, "vsub'vsz 'vd, 'vn, 'vm");
    }
  } else if ((U == 1) && (opcode == 0x1b)) {
    Format(instr, "vmul'vsz 'vd, 'vn, 'vm");
  } else if ((U == 1) && (opcode == 0x1f)) {
    Format(instr, "vdiv'vsz 'vd, 'vn, 'vm");
  } else if ((U == 0) && (opcode == 0x1c)) {
    Format(instr, "vceq'vsz 'vd, 'vn, 'vm");
  } else if ((U == 1) && (opcode == 0x1c)) {
    if (instr->Bit(23) == 1) {
      Format(instr, "vcgt'vsz 'vd, 'vn, 'vm");
    } else {
      Format(instr, "vcge'vsz 'vd, 'vn, 'vm");
    }
  } else if ((U == 0) && (opcode == 0x1e)) {
    if (instr->Bit(23) == 1) {
      Format(instr, "vmin'vsz 'vd, 'vn, 'vm");
    } else {
      Format(instr, "vmax'vsz 'vd, 'vn, 'vm");
    }
  } else if ((U == 0) && (opcode == 0x1f)) {
    if (instr->Bit(23) == 1) {
      Format(instr, "vrsqrt'vsz 'vd, 'vn, 'vm");
    } else {
      Format(instr, "vrecps'vsz 'vd, 'vn, 'vm");
    }
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeSIMDTwoReg(Instr* instr) {
  const int32_t Q = instr->Bit(30);
  const int32_t U = instr->Bit(29);
  const int32_t op = instr->Bits(12, 5);
  const int32_t sz = instr->Bits(22, 2);

  if (Q == 0) {
    Unknown(instr);
    return;
  }

  if ((U == 1) && (op == 0x5)) {
    Format(instr, "vnot 'vd, 'vn");
  } else if ((U == 0) && (op == 0xf)) {
    if (sz == 2) {
      Format(instr, "vabss 'vd, 'vn");
    } else if (sz == 3) {
      Format(instr, "vabsd 'vd, 'vn");
    } else {
      Unknown(instr);
    }
  } else if ((U == 1) && (op == 0xf)) {
    if (sz == 2) {
      Format(instr, "vnegs 'vd, 'vn");
    } else if (sz == 3) {
      Format(instr, "vnegd 'vd, 'vn");
    } else {
      Unknown(instr);
    }
  } else if ((U == 1) && (op == 0x1f)) {
    if (sz == 2) {
      Format(instr, "vsqrts 'vd, 'vn");
    } else if (sz == 3) {
      Format(instr, "vsqrtd 'vd, 'vn");
    } else {
      Unknown(instr);
    }
  } else if ((U == 0) && (op == 0x1d)) {
    if (sz != 2) {
      Unknown(instr);
      return;
    }
    Format(instr, "vrecpes 'vd, 'vn");
  } else if ((U == 1) && (op == 0x1d)) {
    if (sz != 2) {
      Unknown(instr);
      return;
    }
    Format(instr, "vrsqrtes 'vd, 'vn");
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeDPSimd1(Instr* instr) {
  if (instr->IsSIMDCopyOp()) {
    DecodeSIMDCopy(instr);
  } else if (instr->IsSIMDThreeSameOp()) {
    DecodeSIMDThreeSame(instr);
  } else if (instr->IsSIMDTwoRegOp()) {
    DecodeSIMDTwoReg(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeFPImm(Instr* instr) {
  if ((instr->Bit(31) != 0) || (instr->Bit(29) != 0) || (instr->Bit(23) != 0) ||
      (instr->Bits(5, 5) != 0)) {
    Unknown(instr);
    return;
  }
  if (instr->Bit(22) == 1) {
    // Double.
    Format(instr, "fmovd 'vd, 'immd");
  } else {
    // Single.
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeFPIntCvt(Instr* instr) {
  if ((instr->Bit(29) != 0) || (instr->Bits(22, 2) != 1)) {
    Unknown(instr);
    return;
  }
  if (instr->Bits(16, 5) == 2) {
    Format(instr, "scvtfd'sf 'vd, 'rn");
  } else if (instr->Bits(16, 5) == 6) {
    Format(instr, "fmovrd'sf 'rd, 'vn");
  } else if (instr->Bits(16, 5) == 7) {
    Format(instr, "fmovdr'sf 'vd, 'rn");
  } else if (instr->Bits(16, 5) == 24) {
    Format(instr, "fcvtzds'sf 'rd, 'vn");
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeFPOneSource(Instr* instr) {
  const int opc = instr->Bits(15, 6);

  if ((opc != 5) && (instr->Bit(22) != 1)) {
    // Source is interpreted as single-precision only if we're doing a
    // conversion from single -> double.
    Unknown(instr);
    return;
  }

  switch (opc) {
    case 0:
      Format(instr, "fmovdd 'vd, 'vn");
      break;
    case 1:
      Format(instr, "fabsd 'vd, 'vn");
      break;
    case 2:
      Format(instr, "fnegd 'vd, 'vn");
      break;
    case 3:
      Format(instr, "fsqrtd 'vd, 'vn");
      break;
    case 4:
      Format(instr, "fcvtsd 'vd, 'vn");
      break;
    case 5:
      Format(instr, "fcvtds 'vd, 'vn");
      break;
    default:
      Unknown(instr);
      break;
  }
}


void ARM64Decoder::DecodeFPTwoSource(Instr* instr) {
  if (instr->Bits(22, 2) != 1) {
    Unknown(instr);
    return;
  }
  const int opc = instr->Bits(12, 4);

  switch (opc) {
    case 0:
      Format(instr, "fmuld 'vd, 'vn, 'vm");
      break;
    case 1:
      Format(instr, "fdivd 'vd, 'vn, 'vm");
      break;
    case 2:
      Format(instr, "faddd 'vd, 'vn, 'vm");
      break;
    case 3:
      Format(instr, "fsubd 'vd, 'vn, 'vm");
      break;
    default:
      Unknown(instr);
      break;
  }
}


void ARM64Decoder::DecodeFPCompare(Instr* instr) {
  if ((instr->Bit(22) == 1) && (instr->Bits(3, 2) == 0)) {
    Format(instr, "fcmpd 'vn, 'vm");
  } else if ((instr->Bit(22) == 1) && (instr->Bits(3, 2) == 1)) {
    if (instr->VmField() == V0) {
      Format(instr, "fcmpd 'vn, #0.0");
    } else {
      Unknown(instr);
    }
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeFP(Instr* instr) {
  if (instr->IsFPImmOp()) {
    DecodeFPImm(instr);
  } else if (instr->IsFPIntCvtOp()) {
    DecodeFPIntCvt(instr);
  } else if (instr->IsFPOneSourceOp()) {
    DecodeFPOneSource(instr);
  } else if (instr->IsFPTwoSourceOp()) {
    DecodeFPTwoSource(instr);
  } else if (instr->IsFPCompareOp()) {
    DecodeFPCompare(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeDPSimd2(Instr* instr) {
  if (instr->IsFPOp()) {
    DecodeFP(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::InstructionDecode(uword pc) {
  Instr* instr = Instr::At(pc);

  if (instr->IsDPImmediateOp()) {
    DecodeDPImmediate(instr);
  } else if (instr->IsCompareBranchOp()) {
    DecodeCompareBranch(instr);
  } else if (instr->IsLoadStoreOp()) {
    DecodeLoadStore(instr);
  } else if (instr->IsDPRegisterOp()) {
    DecodeDPRegister(instr);
  } else if (instr->IsDPSimd1Op()) {
    DecodeDPSimd1(instr);
  } else if (instr->IsDPSimd2Op()) {
    DecodeDPSimd2(instr);
  } else {
    Unknown(instr);
  }
}


void Disassembler::DecodeInstruction(char* hex_buffer, intptr_t hex_size,
                                     char* human_buffer, intptr_t human_size,
                                     int* out_instr_size, uword pc) {
  ARM64Decoder decoder(human_buffer, human_size);
  decoder.InstructionDecode(pc);
  int32_t instruction_bits = Instr::At(pc)->InstructionBits();
  OS::SNPrint(hex_buffer, hex_size, "%08x", instruction_bits);
  if (out_instr_size) {
    *out_instr_size = Instr::kInstrSize;
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
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
