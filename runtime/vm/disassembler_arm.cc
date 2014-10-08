// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "platform/assert.h"
#include "vm/cpu.h"

namespace dart {

class ARMDecoder : public ValueObject {
 public:
  ARMDecoder(char* buffer, size_t buffer_size)
      : buffer_(buffer),
        buffer_size_(buffer_size),
        buffer_pos_(0) {
    buffer_[buffer_pos_] = '\0';
  }

  ~ARMDecoder() {}

  // Writes one disassembled instruction into 'buffer' (0-terminated).
  // Returns true if the instruction was successfully decoded, false otherwise.
  void InstructionDecode(uword pc);

 private:
  // Bottleneck functions to print into the out_buffer.
  void Print(const char* str);

  // Printing of common values.
  void PrintRegister(int reg);
  void PrintSRegister(int reg);
  void PrintDRegister(int reg);
  void PrintDRegisterList(int start, int reg_count);
  void PrintQRegister(int reg);
  void PrintCondition(Instr* instr);
  void PrintShiftRm(Instr* instr);
  void PrintShiftImm(Instr* instr);
  void PrintPU(Instr* instr);

  // Handle formatting of instructions and their options.
  int FormatRegister(Instr* instr, const char* option);
  int FormatSRegister(Instr* instr, const char* option);
  int FormatDRegister(Instr* instr, const char* option);
  int FormatQRegister(Instr* instr, const char* option);
  int FormatOption(Instr* instr, const char* option);
  void Format(Instr* instr, const char* format);
  void Unknown(Instr* instr);

  // Each of these functions decodes one particular instruction type, a 3-bit
  // field in the instruction encoding.
  // Types 0 and 1 are combined as they are largely the same except for the way
  // they interpret the shifter operand.
  void DecodeType01(Instr* instr);
  void DecodeType2(Instr* instr);
  void DecodeType3(Instr* instr);
  void DecodeType4(Instr* instr);
  void DecodeType5(Instr* instr);
  void DecodeType6(Instr* instr);
  void DecodeType7(Instr* instr);
  void DecodeSIMDDataProcessing(Instr* instr);

  // Convenience functions.
  char* get_buffer() const { return buffer_; }
  char* current_position_in_buffer() { return buffer_ + buffer_pos_; }
  size_t remaining_size_in_buffer() { return buffer_size_ - buffer_pos_; }

  char* buffer_;  // Decode instructions into this buffer.
  size_t buffer_size_;  // The size of the character buffer.
  size_t buffer_pos_;  // Current character position in buffer.

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(ARMDecoder);
};


// Support for assertions in the ARMDecoder formatting functions.
#define STRING_STARTS_WITH(string, compare_string) \
  (strncmp(string, compare_string, strlen(compare_string)) == 0)


// Append the str to the output buffer.
void ARMDecoder::Print(const char* str) {
  char cur = *str++;
  while (cur != '\0' && (buffer_pos_ < (buffer_size_ - 1))) {
    buffer_[buffer_pos_++] = cur;
    cur = *str++;
  }
  buffer_[buffer_pos_] = '\0';
}


// These condition names are defined in a way to match the native disassembler
// formatting. See for example the command "objdump -d <binary file>".
static const char* cond_names[kMaxCondition] = {
  "eq", "ne", "cs" , "cc" , "mi" , "pl" , "vs" , "vc" ,
  "hi", "ls", "ge", "lt", "gt", "le", "", "invalid",
};


// Print the condition guarding the instruction.
void ARMDecoder::PrintCondition(Instr* instr) {
  Print(cond_names[instr->ConditionField()]);
}


// These register names are defined in a way to match the native disassembler
// formatting, except for register aliases ctx (r9) and pp (r10).
// See for example the command "objdump -d <binary file>".
static const char* reg_names[kNumberOfCpuRegisters] = {
  "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
  "r8", "ctx", "pp", "fp", "ip", "sp", "lr", "pc",
};


// Print the register name according to the active name converter.
void ARMDecoder::PrintRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfCpuRegisters);
  Print(reg_names[reg]);
}


void ARMDecoder::PrintSRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfSRegisters);
  buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                             remaining_size_in_buffer(),
                             "s%d", reg);
}


void ARMDecoder::PrintDRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfDRegisters);
  buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                             remaining_size_in_buffer(),
                             "d%d", reg);
}


void ARMDecoder::PrintQRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfQRegisters);
  buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                             remaining_size_in_buffer(),
                             "q%d", reg);
}


// These shift names are defined in a way to match the native disassembler
// formatting. See for example the command "objdump -d <binary file>".
static const char* shift_names[kMaxShift] = {
  "lsl", "lsr", "asr", "ror"
};


// Print the register shift operands for the instruction. Generally used for
// data processing instructions.
void ARMDecoder::PrintShiftRm(Instr* instr) {
  Shift shift = instr->ShiftField();
  int shift_amount = instr->ShiftAmountField();
  int rm = instr->RmField();

  PrintRegister(rm);

  if ((instr->RegShiftField() == 0) && (shift == LSL) && (shift_amount == 0)) {
    // Special case for using rm only.
    return;
  }
  if (instr->RegShiftField() == 0) {
    // by immediate
    if ((shift == ROR) && (shift_amount == 0)) {
      Print(", RRX");
      return;
    } else if (((shift == LSR) || (shift == ASR)) && (shift_amount == 0)) {
      shift_amount = 32;
    }
    buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                               remaining_size_in_buffer(),
                               ", %s #%d",
                               shift_names[shift],
                               shift_amount);
  } else {
    // by register
    int rs = instr->RsField();
    buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                               remaining_size_in_buffer(),
                              ", %s ",
                              shift_names[shift]);
    PrintRegister(rs);
  }
}


// Print the immediate operand for the instruction. Generally used for data
// processing instructions.
void ARMDecoder::PrintShiftImm(Instr* instr) {
  int rotate = instr->RotateField() * 2;
  int immed8 = instr->Immed8Field();
  int imm = (immed8 >> rotate) | (immed8 << (32 - rotate));
  buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                             remaining_size_in_buffer(),
                             "#%d",
                             imm);
}


// Print PU formatting to reduce complexity of FormatOption.
void ARMDecoder::PrintPU(Instr* instr) {
  switch (instr->PUField()) {
    case 0: {
      Print("da");
      break;
    }
    case 1: {
      Print("ia");
      break;
    }
    case 2: {
      Print("db");
      break;
    }
    case 3: {
      Print("ib");
      break;
    }
    default: {
      UNREACHABLE();
      break;
    }
  }
}


// Handle all register based formatting in these functions to reduce the
// complexity of FormatOption.
int ARMDecoder::FormatRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'r');
  if (format[1] == 'n') {  // 'rn: Rn register
    int reg = instr->RnField();
    PrintRegister(reg);
    return 2;
  } else if (format[1] == 'd') {  // 'rd: Rd register
    int reg = instr->RdField();
    PrintRegister(reg);
    if (format[2] == '2') {  // 'rd2: possibly Rd, Rd+1 register pair
      if (instr->HasSign() && !instr->HasL()) {
        if ((reg % 2) != 0) {
          Print(" *** unknown (odd register pair) ***");
        } else {
          Print(", ");
          PrintRegister(reg + 1);
        }
      }
      return 3;
    }
    return 2;
  } else if (format[1] == 's') {  // 'rs: Rs register
    int reg = instr->RsField();
    PrintRegister(reg);
    return 2;
  } else if (format[1] == 'm') {  // 'rm: Rm register
    int reg = instr->RmField();
    PrintRegister(reg);
    return 2;
  } else if (format[1] == 'l') {
    // 'rlist: register list for load and store multiple instructions
    ASSERT(STRING_STARTS_WITH(format, "rlist"));
    int rlist = instr->RlistField();
    int reg = 0;
    Print("{");
    // Print register list in ascending order, by scanning the bit mask.
    while (rlist != 0) {
      if ((rlist & 1) != 0) {
        PrintRegister(reg);
        if ((rlist >> 1) != 0) {
          Print(", ");
        }
      }
      reg++;
      rlist >>= 1;
    }
    Print("}");
    return 5;
  }
  UNREACHABLE();
  return -1;
}


int ARMDecoder::FormatSRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 's');
  if (format[1] == 'n') {  // 'sn: Sn register
    int reg = instr->SnField();
    PrintSRegister(reg);
    return 2;
  } else if (format[1] == 'd') {  // 'sd: Sd register
    int reg = instr->SdField();
    PrintSRegister(reg);
    return 2;
  } else if (format[1] == 'm') {
    int reg = instr->SmField();
    if (format[2] == '1') {  // 'sm1: S[m+1] register
      reg++;
      ASSERT(reg < kNumberOfSRegisters);
      PrintSRegister(reg);
      return 3;
    } else {  // 'sm: Sm register
      PrintSRegister(reg);
      return 2;
    }
  } else if (format[1] == 'l') {
    ASSERT(STRING_STARTS_WITH(format, "slist"));
    int reg_count = instr->Bits(0, 8);
    int start = instr->Bit(22) | (instr->Bits(12, 4) << 1);
    Print("{");
    for (int i = start; i < start + reg_count; i++) {
      PrintSRegister(i);
      if (i != start + reg_count - 1) {
        Print(", ");
      }
    }
    Print("}");
    return 5;
  }
  UNREACHABLE();
  return -1;
}


void ARMDecoder::PrintDRegisterList(int start, int reg_count) {
  Print("{");
  for (int i = start; i < start + reg_count; i++) {
    PrintDRegister(i);
    if (i != start + reg_count - 1) {
      Print(", ");
    }
  }
  Print("}");
}


int ARMDecoder::FormatDRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'd');
  if (format[1] == 'n') {  // 'dn: Dn register
    int reg = instr->DnField();
    PrintDRegister(reg);
    return 2;
  } else if (format[1] == 'd') {  // 'dd: Dd register
    int reg = instr->DdField();
    PrintDRegister(reg);
    return 2;
  } else if (format[1] == 'm') {  // 'dm: Dm register
    int reg = instr->DmField();
    PrintDRegister(reg);
    return 2;
  } else if (format[1] == 'l') {
    ASSERT(STRING_STARTS_WITH(format, "dlist"));
    int reg_count = instr->Bits(0, 8) >> 1;
    int start = (instr->Bit(22) << 4) | instr->Bits(12, 4);
    PrintDRegisterList(start, reg_count);
    return 5;
  } else if (format[1] == 't') {
    ASSERT(STRING_STARTS_WITH(format, "dtbllist"));
    int reg_count = instr->Bits(8, 2) + 1;
    int start = (instr->Bit(7) << 4) | instr->Bits(16, 4);
    PrintDRegisterList(start, reg_count);
    return 8;
  }
  UNREACHABLE();
  return -1;
}


int ARMDecoder::FormatQRegister(Instr* instr, const char* format) {
  ASSERT(format[0] == 'q');
  if (format[1] == 'n') {  // 'qn: Qn register
    int reg = instr->QnField();
    PrintQRegister(reg);
    return 2;
  } else if (format[1] == 'd') {  // 'qd: Qd register
    int reg = instr->QdField();
    PrintQRegister(reg);
    return 2;
  } else if (format[1] == 'm') {  // 'qm: Qm register
    int reg = instr->QmField();
    PrintQRegister(reg);
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
int ARMDecoder::FormatOption(Instr* instr, const char* format) {
  switch (format[0]) {
    case 'a': {  // 'a: accumulate multiplies
      if (instr->Bit(21) == 0) {
        Print("ul");
      } else {
        Print("la");
      }
      return 1;
    }
    case 'b': {  // 'b: byte loads or stores
      if (instr->HasB()) {
        Print("b");
      }
      return 1;
    }
    case 'c': {  // 'cond: conditional execution
      ASSERT(STRING_STARTS_WITH(format, "cond"));
      PrintCondition(instr);
      return 4;
    }
    case 'd': {
      if (format[1] == 'e') {  // 'dest: branch destination
        ASSERT(STRING_STARTS_WITH(format, "dest"));
        int off = (instr->SImmed24Field() << 2) + 8;
        uword destination = reinterpret_cast<uword>(instr) + off;
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%#" Px "",
                                   destination);
        return 4;
      } else {
        return FormatDRegister(instr, format);
      }
    }
    case 'q': {
      return FormatQRegister(instr, format);
    }
    case 'i': {  // 'imm12_4, imm4_12, immf, or immd
      uint16_t immed16;
      if (format[3] == 'f') {
        ASSERT(STRING_STARTS_WITH(format, "immf"));
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%f",
                                   instr->ImmFloatField());
        return 4;
      } else if (format[3] == 'd') {
        ASSERT(STRING_STARTS_WITH(format, "immd"));
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%g",
                                   instr->ImmDoubleField());
        return 4;
      } else if (format[3] == '1') {
        ASSERT(STRING_STARTS_WITH(format, "imm12_4"));
        immed16 = instr->BkptField();
      } else {
        ASSERT(format[3] == '4');
        if (format[5] == 'v') {
          ASSERT(STRING_STARTS_WITH(format, "imm4_vdup"));
          int32_t idx = -1;
          int32_t imm4 = instr->Bits(16, 4);
          if ((imm4 & 1) != 0) idx = imm4 >> 1;
          else if ((imm4 & 2) != 0) idx = imm4 >> 2;
          else if ((imm4 & 4) != 0) idx = imm4 >> 3;
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "%d",
                                     idx);
          return 9;
        } else {
          ASSERT(STRING_STARTS_WITH(format, "imm4_12"));
          immed16 = instr->MovwField();
        }
      }
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 "0x%x",
                                 immed16);
      return 7;
    }
    case 'l': {  // 'l: branch and link
      if (instr->HasLink()) {
        Print("l");
      }
      return 1;
    }
    case 'm': {  // 'memop: load/store instructions
      ASSERT(STRING_STARTS_WITH(format, "memop"));
      if (instr->HasL() ||
          // Extra load/store instructions.
          ((instr->TypeField() == 0) && instr->HasSign() && !instr->HasH())) {
        Print("ldr");
      } else {
        Print("str");
      }
      return 5;
    }
    case 'o': {
      if (format[3] == '1') {
        if (format[4] == '0') {
          // 'off10: 10-bit offset for VFP load and store instructions
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "%d",
                                     instr->Bits(0, 8) << 2);
        } else {
          // 'off12: 12-bit offset for load and store instructions.
          ASSERT(STRING_STARTS_WITH(format, "off12"));
          buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                     remaining_size_in_buffer(),
                                     "%d",
                                     instr->Offset12Field());
        }
        return 5;
      }
      // 'off8: 8-bit offset for extra load and store instructions.
      ASSERT(STRING_STARTS_WITH(format, "off8"));
      int offs8 = (instr->ImmedHField() << 4) | instr->ImmedLField();
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 "%d",
                                 offs8);
      return 4;
    }
    case 'p': {  // 'pu: P and U bits for load and store instructions.
      ASSERT(STRING_STARTS_WITH(format, "pu"));
      PrintPU(instr);
      return 2;
    }
    case 'r': {
      return FormatRegister(instr, format);
    }
    case 's': {
      if (format[1] == 'h') {  // 'shift_op or 'shift_rm
        if (format[6] == 'o') {  // 'shift_op
          ASSERT(STRING_STARTS_WITH(format, "shift_op"));
          if (instr->TypeField() == 0) {
            PrintShiftRm(instr);
          } else {
            ASSERT(instr->TypeField() == 1);
            PrintShiftImm(instr);
          }
          return 8;
        } else {  // 'shift_rm
          ASSERT(STRING_STARTS_WITH(format, "shift_rm"));
          PrintShiftRm(instr);
          return 8;
        }
      } else if (format[1] == 'v') {  // 'svc
        ASSERT(STRING_STARTS_WITH(format, "svc"));
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "0x%x",
                                   instr->SvcField());
        return 3;
      } else if (format[1] == 'z') {
        // 'sz: Size field of SIMD instructions.
        int sz = instr->Bits(20, 2);
        char const* sz_str;
        switch (sz) {
          case 0: sz_str = "b"; break;
          case 1: sz_str = "h"; break;
          case 2: sz_str = "w"; break;
          case 3: sz_str = "l"; break;
          default: sz_str = "?"; break;
        }
        buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                   remaining_size_in_buffer(),
                                   "%s",
                                   sz_str);
        return 2;
      } else if (format[1] == ' ') {
        // 's: S field of data processing instructions.
        if (instr->HasS()) {
          Print("s");
        }
        return 1;
      } else {
        return FormatSRegister(instr, format);
      }
    }
    case 't': {  // 'target: target of branch instructions.
      ASSERT(STRING_STARTS_WITH(format, "target"));
      int off = (instr->SImmed24Field() << 2) + 8;
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 "%+d",
                                 off);
      return 6;
    }
    case 'u': {  // 'u: signed or unsigned multiplies.
      if (instr->Bit(22) == 0) {
        Print("u");
      } else {
        Print("s");
      }
      return 1;
    }
    case 'w': {  // 'w: W field of load and store instructions.
      if (instr->HasW()) {
        Print("!");
      }
      return 1;
    }
    case 'x': {  // 'x: type of extra load/store instructions.
      if (!instr->HasSign()) {
        Print("h");
      } else if (instr->HasL()) {
        if (instr->HasH()) {
          Print("sh");
        } else {
          Print("sb");
        }
      } else {
        Print("d");
      }
      return 1;
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
void ARMDecoder::Format(Instr* instr, const char* format) {
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
void ARMDecoder::Unknown(Instr* instr) {
  Format(instr, "unknown");
}


void ARMDecoder::DecodeType01(Instr* instr) {
  if (!instr->IsDataProcessing()) {
    // miscellaneous, multiply, sync primitives, extra loads and stores.
    if (instr->IsMiscellaneous()) {
      switch (instr->Bits(4, 3)) {
        case 1: {
          if (instr->Bits(21, 2) == 0x3) {
            Format(instr, "clz'cond 'rd, 'rm");
          } else if (instr->Bits(21, 2) == 0x1) {
            Format(instr, "bx'cond 'rm");
          } else {
            Unknown(instr);
          }
          break;
        }
        case 3: {
          if (instr->Bits(21, 2) == 0x1) {
            Format(instr, "blx'cond 'rm");
          } else {
            // Could be inlined constant.
            Unknown(instr);
          }
          break;
        }
        case 7: {
          if ((instr->Bits(21, 2) == 0x1) && (instr->ConditionField() == AL)) {
            Format(instr, "bkpt #'imm12_4");
          } else {
             // Format(instr, "smc'cond");
            Unknown(instr);  // Not used.
          }
          break;
        }
        default: {
          Unknown(instr);  // Not used.
          break;
        }
      }
    } else if (instr->IsMultiplyOrSyncPrimitive()) {
      if (instr->Bit(24) == 0) {
        if ((TargetCPUFeatures::arm_version() != ARMv7) &&
            (instr->Bits(21, 3) != 0)) {
          // mla ... smlal only supported on armv7.
          Unknown(instr);
          return;
        }
        // multiply instructions
        switch (instr->Bits(21, 3)) {
          case 0: {
            // Assembler registers rd, rn, rm are encoded as rn, rm, rs.
            Format(instr, "mul'cond's 'rn, 'rm, 'rs");
            break;
          }
          case 1: {
            // Assembler registers rd, rn, rm, ra are encoded as rn, rm, rs, rd.
            Format(instr, "mla'cond's 'rn, 'rm, 'rs, 'rd");
            break;
          }
          case 2: {
            // Registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
            Format(instr, "umaal'cond's 'rd, 'rn, 'rm, 'rs");
            break;
          }
          case 3: {
            // Assembler registers rd, rn, rm, ra are encoded as rn, rm, rs, rd.
            Format(instr, "mls'cond's 'rn, 'rm, 'rs, 'rd");
            break;
          }
          case 4: {
            // Registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
            Format(instr, "umull'cond's 'rd, 'rn, 'rm, 'rs");
            break;
          }
          case 5: {
            // Registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
            Format(instr, "umlal'cond's 'rd, 'rn, 'rm, 'rs");
            break;
          }
          case 6: {
            // Registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
            Format(instr, "smull'cond's 'rd, 'rn, 'rm, 'rs");
            break;
          }
          case 7: {
            // Registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
            Format(instr, "smlal'cond's 'rd, 'rn, 'rm, 'rs");
            break;
          }
          default: {
            Unknown(instr);  // Not used.
            break;
          }
        }
      } else {
        // synchronization primitives
        switch (instr->Bits(20, 4)) {
          case 8: {
            Format(instr, "strex'cond 'rd, 'rm, ['rn]");
            break;
          }
          case 9: {
            Format(instr, "ldrex'cond 'rd, ['rn]");
            break;
          }
          default: {
            Unknown(instr);  // Not used.
            break;
          }
        }
      }
    } else if (instr->Bit(25) == 1) {
      // 16-bit immediate loads, msr (immediate), and hints
      switch (instr->Bits(20, 5)) {
        case 16: {
          if (TargetCPUFeatures::arm_version() == ARMv7) {
            Format(instr, "movw'cond 'rd, #'imm4_12");
          } else {
            Unknown(instr);
          }
          break;
        }
        case 18: {
          if ((instr->Bits(16, 4) == 0) && (instr->Bits(0, 8) == 0)) {
            Format(instr, "nop'cond");
          } else {
            Unknown(instr);  // Not used.
          }
          break;
        }
        case 20: {
          if (TargetCPUFeatures::arm_version() == ARMv7) {
            Format(instr, "movt'cond 'rd, #'imm4_12");
          } else {
            Unknown(instr);
          }
          break;
        }
        default: {
          Unknown(instr);  // Not used.
          break;
        }
      }
    } else {
      // extra load/store instructions
      switch (instr->PUField()) {
        case 0: {
          if (instr->Bit(22) == 0) {
            Format(instr, "'memop'cond'x 'rd2, ['rn], -'rm");
          } else {
            Format(instr, "'memop'cond'x 'rd2, ['rn], #-'off8");
          }
          break;
        }
        case 1: {
          if (instr->Bit(22) == 0) {
            Format(instr, "'memop'cond'x 'rd2, ['rn], +'rm");
          } else {
            Format(instr, "'memop'cond'x 'rd2, ['rn], #+'off8");
          }
          break;
        }
        case 2: {
          if (instr->Bit(22) == 0) {
            Format(instr, "'memop'cond'x 'rd2, ['rn, -'rm]'w");
          } else {
            Format(instr, "'memop'cond'x 'rd2, ['rn, #-'off8]'w");
          }
          break;
        }
        case 3: {
          if (instr->Bit(22) == 0) {
            Format(instr, "'memop'cond'x 'rd2, ['rn, +'rm]'w");
          } else {
            Format(instr, "'memop'cond'x 'rd2, ['rn, #+'off8]'w");
          }
          break;
        }
        default: {
          // The PU field is a 2-bit field.
          UNREACHABLE();
          break;
        }
      }
    }
  } else {
    switch (instr->OpcodeField()) {
      case AND: {
        Format(instr, "and'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case EOR: {
        Format(instr, "eor'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case SUB: {
        Format(instr, "sub'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case RSB: {
        Format(instr, "rsb'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case ADD: {
        Format(instr, "add'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case ADC: {
        Format(instr, "adc'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case SBC: {
        Format(instr, "sbc'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case RSC: {
        Format(instr, "rsc'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case TST: {
        if (instr->HasS()) {
          Format(instr, "tst'cond 'rn, 'shift_op");
        } else {
          Unknown(instr);  // Not used.
        }
        break;
      }
      case TEQ: {
        if (instr->HasS()) {
          Format(instr, "teq'cond 'rn, 'shift_op");
        } else {
          Unknown(instr);  // Not used.
        }
        break;
      }
      case CMP: {
        if (instr->HasS()) {
          Format(instr, "cmp'cond 'rn, 'shift_op");
        } else {
          Unknown(instr);  // Not used.
        }
        break;
      }
      case CMN: {
        if (instr->HasS()) {
          Format(instr, "cmn'cond 'rn, 'shift_op");
        } else {
          Unknown(instr);  // Not used.
        }
        break;
      }
      case ORR: {
        Format(instr, "orr'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case MOV: {
        Format(instr, "mov'cond's 'rd, 'shift_op");
        break;
      }
      case BIC: {
        Format(instr, "bic'cond's 'rd, 'rn, 'shift_op");
        break;
      }
      case MVN: {
        Format(instr, "mvn'cond's 'rd, 'shift_op");
        break;
      }
      default: {
        // The Opcode field is a 4-bit field.
        UNREACHABLE();
        break;
      }
    }
  }
}


void ARMDecoder::DecodeType2(Instr* instr) {
  switch (instr->PUField()) {
    case 0: {
      if (instr->HasW()) {
        Unknown(instr);  // Not used.
      } else {
        Format(instr, "'memop'cond'b 'rd, ['rn], #-'off12");
      }
      break;
    }
    case 1: {
      if (instr->HasW()) {
        Unknown(instr);  // Not used.
      } else {
        Format(instr, "'memop'cond'b 'rd, ['rn], #+'off12");
      }
      break;
    }
    case 2: {
      Format(instr, "'memop'cond'b 'rd, ['rn, #-'off12]'w");
      break;
    }
    case 3: {
      Format(instr, "'memop'cond'b 'rd, ['rn, #+'off12]'w");
      break;
    }
    default: {
      // The PU field is a 2-bit field.
      UNREACHABLE();
      break;
    }
  }
}


void ARMDecoder::DecodeType3(Instr* instr) {
  if (instr->IsDivision()) {
    if (!TargetCPUFeatures::integer_division_supported()) {
      Unknown(instr);
      return;
    }
    if (instr->Bit(21)) {
      Format(instr, "udiv'cond 'rn, 'rs, 'rm");
    } else {
      Format(instr, "sdiv'cond 'rn, 'rs, 'rm");
    }
    return;
  }
  switch (instr->PUField()) {
    case 0: {
      if (instr->HasW()) {
        Unknown(instr);
      } else {
        Format(instr, "'memop'cond'b 'rd, ['rn], -'shift_rm");
      }
      break;
    }
    case 1: {
      if (instr->HasW()) {
        Unknown(instr);
      } else {
        Format(instr, "'memop'cond'b 'rd, ['rn], +'shift_rm");
      }
      break;
    }
    case 2: {
      Format(instr, "'memop'cond'b 'rd, ['rn, -'shift_rm]'w");
      break;
    }
    case 3: {
      Format(instr, "'memop'cond'b 'rd, ['rn, +'shift_rm]'w");
      break;
    }
    default: {
      // The PU field is a 2-bit field.
      UNREACHABLE();
      break;
    }
  }
}


void ARMDecoder::DecodeType4(Instr* instr) {
  if (instr->Bit(22) == 1) {
    Unknown(instr);  // Privileged mode currently not supported.
  } else if (instr->HasL()) {
    Format(instr, "ldm'cond'pu 'rn'w, 'rlist");
  } else {
    Format(instr, "stm'cond'pu 'rn'w, 'rlist");
  }
}


void ARMDecoder::DecodeType5(Instr* instr) {
  Format(instr, "b'l'cond 'target ; 'dest");
}


void ARMDecoder::DecodeType6(Instr* instr) {
  if (instr->IsVFPDoubleTransfer()) {
    if (instr->Bit(8) == 0) {
      if (instr->Bit(20) == 1) {
        Format(instr, "vmovrrs'cond 'rd, 'rn, {'sm, 'sm1}");
      } else {
        Format(instr, "vmovsrr'cond {'sm, 'sm1}, 'rd, 'rn");
      }
    } else {
      if (instr->Bit(20) == 1) {
        Format(instr, "vmovrrd'cond 'rd, 'rn, 'dm");
      } else {
        Format(instr, "vmovdrr'cond 'dm, 'rd, 'rn");
      }
    }
  } else if (instr-> IsVFPLoadStore()) {
    if (instr->Bit(8) == 0) {
      if (instr->Bit(20) == 1) {  // vldrs
        if (instr->Bit(23) == 1) {
          Format(instr, "vldrs'cond 'sd, ['rn, #+'off10]");
        } else {
          Format(instr, "vldrs'cond 'sd, ['rn, #-'off10]");
        }
      } else {  // vstrs
        if (instr->Bit(23) == 1) {
          Format(instr, "vstrs'cond 'sd, ['rn, #+'off10]");
        } else {
          Format(instr, "vstrs'cond 'sd, ['rn, #-'off10]");
        }
      }
    } else {
      if (instr->Bit(20) == 1) {  // vldrd
        if (instr->Bit(23) == 1) {
          Format(instr, "vldrd'cond 'dd, ['rn, #+'off10]");
        } else {
          Format(instr, "vldrd'cond 'dd, ['rn, #-'off10]");
        }
      } else {  // vstrd
        if (instr->Bit(23) == 1) {
          Format(instr, "vstrd'cond 'dd, ['rn, #+'off10]");
        } else {
          Format(instr, "vstrd'cond 'dd, ['rn, #-'off10]");
        }
      }
    }
  } else if (instr->IsVFPMultipleLoadStore()) {
    if (instr->HasL()) {  // vldm
      if (instr->Bit(8)) {  // vldmd
        Format(instr, "vldmd'cond'pu 'rn'w, 'dlist");
      } else {  // vldms
        Format(instr, "vldms'cond'pu 'rn'w, 'slist");
      }
    } else {  // vstm
      if (instr->Bit(8)) {  // vstmd
        Format(instr, "vstmd'cond'pu 'rn'w, 'dlist");
      } else {  // vstms
        Format(instr, "vstms'cond'pu 'rn'w, 'slist");
      }
    }
  } else {
    Unknown(instr);
  }
}


void ARMDecoder::DecodeType7(Instr* instr) {
  if (instr->Bit(24) == 1) {
    Format(instr, "svc'cond #'svc");
    if (instr->SvcField() == kStopMessageSvcCode) {
      const char* message = *reinterpret_cast<const char**>(
          reinterpret_cast<intptr_t>(instr) - Instr::kInstrSize);
      buffer_pos_ += OS::SNPrint(current_position_in_buffer(),
                                 remaining_size_in_buffer(),
                                 " ; \"%s\"",
                                 message);
    }
  } else if (instr->IsVFPDataProcessingOrSingleTransfer()) {
    if (instr->Bit(4) == 0) {
      // VFP Data Processing
      switch (instr->Bits(20, 4) & 0xb) {
        case 0: {  // vmla, vmls floating-point
          if (instr->Bit(8) == 0) {
            if (instr->Bit(6) == 0) {
              Format(instr, "vmlas'cond 'sd, 'sn, 'sm");
            } else {
              Format(instr, "vmlss'cond 'sd, 'sn, 'sm");
            }
          } else {
            if (instr->Bit(6) == 0) {
              Format(instr, "vmlad'cond 'dd, 'dn, 'dm");
            } else {
              Format(instr, "vmlsd'cond 'dd, 'dn, 'dm");
            }
          }
          break;
        }
        case 1:  // vnmla, vnmls, vnmul
        default: {
          Unknown(instr);
          break;
        }
        case 2: {  // vmul
          if (instr->Bit(8) == 0) {
            Format(instr, "vmuls'cond 'sd, 'sn, 'sm");
          } else {
            Format(instr, "vmuld'cond 'dd, 'dn, 'dm");
          }
          break;
        }
        case 8: {  // vdiv
          if (instr->Bit(8) == 0) {
            Format(instr, "vdivs'cond 'sd, 'sn, 'sm");
          } else {
            Format(instr, "vdivd'cond 'dd, 'dn, 'dm");
          }
          break;
        }
        case 3: {  // vadd, vsub floating-point
          if (instr->Bit(8) == 0) {
            if (instr->Bit(6) == 0) {
              Format(instr, "vadds'cond 'sd, 'sn, 'sm");
            } else {
              Format(instr, "vsubs'cond 'sd, 'sn, 'sm");
            }
          } else {
            if (instr->Bit(6) == 0) {
              Format(instr, "vaddd'cond 'dd, 'dn, 'dm");
            } else {
              Format(instr, "vsubd'cond 'dd, 'dn, 'dm");
            }
          }
          break;
        }
        case 0xb: {  // Other VFP data-processing instructions
          if (instr->Bit(6) == 0) {  // vmov immediate
            if (instr->Bit(8) == 0) {
              Format(instr, "vmovs'cond 'sd, #'immf");
            } else {
              Format(instr, "vmovd'cond 'dd, #'immd");
            }
            break;
          }
          switch (instr->Bits(16, 4)) {
            case 0: {  // vmov register, vabs
              switch (instr->Bits(6, 2)) {
                case 1: {  // vmov register
                  if (instr->Bit(8) == 0) {
                    Format(instr, "vmovs'cond 'sd, 'sm");
                  } else {
                    Format(instr, "vmovd'cond 'dd, 'dm");
                  }
                  break;
                }
                case 3: {  // vabs
                  if (instr->Bit(8) == 0) {
                    Format(instr, "vabss'cond 'sd, 'sm");
                  } else {
                    Format(instr, "vabsd'cond 'dd, 'dm");
                  }
                  break;
                }
                default: {
                  Unknown(instr);
                  break;
                }
              }
              break;
            }
            case 1: {  // vneg, vsqrt
              switch (instr->Bits(6, 2)) {
                case 1: {  // vneg
                  if (instr->Bit(8) == 0) {
                    Format(instr, "vnegs'cond 'sd, 'sm");
                  } else {
                    Format(instr, "vnegd'cond 'dd, 'dm");
                  }
                  break;
                }
                case 3: {  // vsqrt
                  if (instr->Bit(8) == 0) {
                    Format(instr, "vsqrts'cond 'sd, 'sm");
                  } else {
                    Format(instr, "vsqrtd'cond 'dd, 'dm");
                  }
                  break;
                }
                default: {
                  Unknown(instr);
                  break;
                }
              }
              break;
            }
            case 4:  // vcmp, vcmpe
            case 5: {  // vcmp #0.0, vcmpe #0.0
              if (instr->Bit(7) == 1) {  // vcmpe
                Unknown(instr);
              } else {
                if (instr->Bit(8) == 0) {  // vcmps
                  if (instr->Bit(16) == 0) {
                    Format(instr, "vcmps'cond 'sd, 'sm");
                  } else {
                    Format(instr, "vcmps'cond 'sd, #0.0");
                  }
                } else {  // vcmpd
                  if (instr->Bit(16) == 0) {
                    Format(instr, "vcmpd'cond 'dd, 'dm");
                  } else {
                    Format(instr, "vcmpd'cond 'dd, #0.0");
                  }
                }
              }
              break;
            }
            case 7: {  // vcvt between double-precision and single-precision
              if (instr->Bit(8) == 0) {
                Format(instr, "vcvtds'cond 'dd, 'sm");
              } else {
                Format(instr, "vcvtsd'cond 'sd, 'dm");
              }
              break;
            }
            case 8: {  // vcvt, vcvtr between floating-point and integer
              if (instr->Bit(8) == 0) {
                if (instr->Bit(7) == 0) {
                  Format(instr, "vcvtsu'cond 'sd, 'sm");
                } else {
                  Format(instr, "vcvtsi'cond 'sd, 'sm");
                }
              } else {
                if (instr->Bit(7) == 0) {
                  Format(instr, "vcvtdu'cond 'dd, 'sm");
                } else {
                  Format(instr, "vcvtdi'cond 'dd, 'sm");
                }
              }
              break;
            }
            case 12:
            case 13: {  // vcvt, vcvtr between floating-point and integer
              if (instr->Bit(7) == 0) {
                // We only support round-to-zero mode
                Unknown(instr);
                break;
              }
              if (instr->Bit(8) == 0) {
                if (instr->Bit(16) == 0) {
                  Format(instr, "vcvtus'cond 'sd, 'sm");
                } else {
                  Format(instr, "vcvtis'cond 'sd, 'sm");
                }
              } else {
                if (instr->Bit(16) == 0) {
                  Format(instr, "vcvtud'cond 'sd, 'dm");
                } else {
                  Format(instr, "vcvtid'cond 'sd, 'dm");
                }
              }
              break;
            }
            case 2:  // vcvtb, vcvtt
            case 3:  // vcvtb, vcvtt
            case 9:  // undefined
            case 10:  // vcvt between floating-point and fixed-point
            case 11:  // vcvt between floating-point and fixed-point
            case 14:  // vcvt between floating-point and fixed-point
            case 15:  // vcvt between floating-point and fixed-point
            default: {
              Unknown(instr);
              break;
            }
          }
        }
        break;
      }
    } else {
      // 8, 16, or 32-bit Transfer between ARM Core and VFP
      if ((instr->Bits(21, 3) == 0) && (instr->Bit(8) == 0)) {
        if (instr->Bit(20) == 0) {
          Format(instr, "vmovs'cond 'sn, 'rd");
        } else {
          Format(instr, "vmovr'cond 'rd, 'sn");
        }
      } else if ((instr->Bits(22, 3) == 0) && (instr->Bit(20) == 0) &&
                 (instr->Bit(8) == 1) && (instr->Bits(5, 2) == 0)) {
        if (instr->Bit(21) == 0) {
          Format(instr, "vmovd'cond 'dn[0], 'rd");
        } else {
          Format(instr, "vmovd'cond 'dn[1], 'rd");
        }
      } else if ((instr->Bits(20, 4) == 0xf) && (instr->Bit(8) == 0) &&
                 (instr->Bits(12, 4) == 0xf)) {
        Format(instr, "vmstat'cond");
      } else {
        Unknown(instr);
      }
    }
  } else {
    Unknown(instr);
  }
}


void ARMDecoder::DecodeSIMDDataProcessing(Instr* instr) {
  ASSERT(instr->ConditionField() == kSpecialCondition);
  if (instr->Bit(6) == 1) {
    if ((instr->Bits(8, 4) == 8) && (instr->Bit(4) == 0) &&
        (instr->Bits(23, 2) == 0)) {
      Format(instr, "vaddq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 13) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 2) == 0) && (instr->Bit(21) == 0)) {
      Format(instr, "vaddqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 8) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 2) == 2)) {
      Format(instr, "vsubq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 13) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 2) == 0) && (instr->Bit(21) == 1)) {
      Format(instr, "vsubqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 9) && (instr->Bit(4) == 1) &&
               (instr->Bits(23, 2) == 0)) {
      Format(instr, "vmulq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 13) && (instr->Bit(4) == 1) &&
               (instr->Bits(23, 2) == 2) && (instr->Bit(21) == 0)) {
      Format(instr, "vmulqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 4) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 5) == 4)) {
      Format(instr, "vshlqi'sz 'qd, 'qm, 'qn");
    } else if ((instr->Bits(8, 4) == 4) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 5) == 6)) {
      Format(instr, "vshlqu'sz 'qd, 'qm, 'qn");
    } else if ((instr->Bits(8, 4) == 1) && (instr->Bit(4) == 1) &&
               (instr->Bits(20, 2) == 0) && (instr->Bits(23, 2) == 2)) {
      Format(instr, "veorq 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 1) && (instr->Bit(4) == 1) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vornq 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 1) && (instr->Bit(4) == 1) &&
               (instr->Bits(20, 2) == 2) && (instr->Bits(23, 2) == 0)) {
      if (instr->QmField() == instr->QnField()) {
        Format(instr, "vmovq 'qd, 'qm");
      } else {
        Format(instr, "vorrq 'qd, 'qm");
      }
    } else if ((instr->Bits(8, 4) == 1) && (instr->Bit(4) == 1) &&
               (instr->Bits(20, 2) == 0) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vandq 'qd, 'qn, 'qm");
    } else if ((instr->Bits(7, 5) == 11) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 5) == 7) &&
               (instr->Bits(16, 4) == 0)) {
      Format(instr, "vmvnq 'qd, 'qm");
    } else if ((instr->Bits(8, 4) == 15) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 2) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vminqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 15) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 0) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vmaxqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 7) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 3) &&
               (instr->Bit(7) == 0) && (instr->Bits(16, 4) == 9)) {
      Format(instr, "vabsqs 'qd, 'qm");
    } else if ((instr->Bits(8, 4) == 7) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 3) &&
               (instr->Bit(7) == 1) && (instr->Bits(16, 4) == 9)) {
      Format(instr, "vnegqs 'qd, 'qm");
    } else if ((instr->Bits(7, 5) == 10) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 3) &&
               (instr->Bits(16, 4) == 11)) {
      Format(instr, "vrecpeqs 'qd, 'qm");
    } else if ((instr->Bits(8, 4) == 15) && (instr->Bit(4) == 1) &&
               (instr->Bits(20, 2) == 0) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vrecpsqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 5) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 3) &&
               (instr->Bit(7) == 1) && (instr->Bits(16, 4) == 11)) {
      Format(instr, "vrsqrteqs 'qd, 'qm");
    } else if ((instr->Bits(8, 4) == 15) && (instr->Bit(4) == 1) &&
               (instr->Bits(20, 2) == 2) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vrsqrtsqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 12) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 3) &&
               (instr->Bit(7) == 0)) {
      int32_t imm4 = instr->Bits(16, 4);
      if (imm4 & 1) {
        Format(instr, "vdupb 'qd, 'dm['imm4_vdup]");
      } else if (imm4 & 2) {
        Format(instr, "vduph 'qd, 'dm['imm4_vdup]");
      } else if (imm4 & 4) {
        Format(instr, "vdupw 'qd, 'dm['imm4_vdup]");
      } else {
        Unknown(instr);
      }
    } else if ((instr->Bits(8, 4) == 1) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 3) && (instr->Bits(23, 2) == 3) &&
               (instr->Bit(7) == 1) && (instr->Bits(16, 4) == 10)) {
      Format(instr, "vzipqw 'qd, 'qm");
    } else if ((instr->Bits(8, 4) == 8) && (instr->Bit(4) == 1) &&
               (instr->Bits(23, 2) == 2)) {
      Format(instr, "vceqq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 14) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 0) && (instr->Bits(23, 2) == 0)) {
      Format(instr, "vceqqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 3) && (instr->Bit(4) == 1) &&
               (instr->Bits(23, 2) == 0)) {
      Format(instr, "vcgeq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 3) && (instr->Bit(4) == 1) &&
               (instr->Bits(23, 2) == 2)) {
      Format(instr, "vcugeq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 14) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 0) && (instr->Bits(23, 2) == 2)) {
      Format(instr, "vcgeqs 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 3) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 2) == 0)) {
      Format(instr, "vcgtq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 3) && (instr->Bit(4) == 0) &&
               (instr->Bits(23, 2) == 2)) {
      Format(instr, "vcugtq'sz 'qd, 'qn, 'qm");
    } else if ((instr->Bits(8, 4) == 14) && (instr->Bit(4) == 0) &&
               (instr->Bits(20, 2) == 2) && (instr->Bits(23, 2) == 2)) {
      Format(instr, "vcgtqs 'qd, 'qn, 'qm");
    } else {
      Unknown(instr);
    }
  } else {
    if ((instr->Bits(23, 2) == 3) && (instr->Bits(20, 2) == 3) &&
        (instr->Bits(10, 2) == 2) && (instr->Bit(4) == 0)) {
      Format(instr, "vtbl 'dd, 'dtbllist, 'dm");
    } else {
      Unknown(instr);
    }
  }
}


void ARMDecoder::InstructionDecode(uword pc) {
  Instr* instr = Instr::At(pc);

  if (instr->ConditionField() == kSpecialCondition) {
    if (instr->InstructionBits() == static_cast<int32_t>(0xf57ff01f)) {
      Format(instr, "clrex");
    } else {
      if (instr->IsSIMDDataProcessing()) {
        DecodeSIMDDataProcessing(instr);
      } else {
        Unknown(instr);
      }
    }
  } else {
    switch (instr->TypeField()) {
      case 0:
      case 1: {
        DecodeType01(instr);
        break;
      }
      case 2: {
        DecodeType2(instr);
        break;
      }
      case 3: {
        DecodeType3(instr);
        break;
      }
      case 4: {
        DecodeType4(instr);
        break;
      }
      case 5: {
        DecodeType5(instr);
        break;
      }
      case 6: {
        DecodeType6(instr);
        break;
      }
      case 7: {
        DecodeType7(instr);
        break;
      }
      default: {
        // The type field is 3-bits in the ARM encoding.
        UNREACHABLE();
        break;
      }
    }
  }
}


void Disassembler::DecodeInstruction(char* hex_buffer, intptr_t hex_size,
                                     char* human_buffer, intptr_t human_size,
                                     int* out_instr_size, uword pc) {
  ARMDecoder decoder(human_buffer, human_size);
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
