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
  void PrintShiftExtendRm(Instr* instr);
  void PrintS(Instr* instr);

  // Handle formatting of instructions and their options.
  int FormatRegister(Instr* instr, const char* option);
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
  "r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23",
  "r24", "ip0", "ip1", "pp",  "ctx", "fp",  "lr",  "r31",
};


// Print the register name according to the active name converter.
void ARM64Decoder::PrintRegister(int reg, R31Type r31t) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfCpuRegisters);
  if ((reg == 31)) {
    const char* rstr = (r31t == R31IsZR) ? "zr" : "sp";
    Print(rstr);
  } else {
    Print(reg_names[reg]);
  }
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
    case 'i': {  // 'imm12, imm16
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
      } else if (format[1] == ' ') {
        if (instr->HasS()) {
          Print("s");
        }
        return 1;
      } else {
        UNREACHABLE();
      }
    }
    case 'r': {
      return FormatRegister(instr, format);
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


void ARM64Decoder::DecodeAddSubImm(Instr* instr) {
  switch (instr->Bit(30)) {
    case 0:
      Format(instr, "addi'sf's 'rd, 'rn, 'imm12s");
      break;
    case 1:
      Format(instr, "subi'sf's 'rd, 'rn, 'imm12s");
      break;
    default:
      Unknown(instr);
      break;
  }
}

void ARM64Decoder::DecodeDPImmediate(Instr* instr) {
  if (instr->IsMoveWideOp()) {
    DecodeMoveWide(instr);
  } else if (instr->IsAddSubImmOp()) {
    DecodeAddSubImm(instr);
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
  if ((instr->Bits(0, 8) == 0x5f) && (instr->Bits(12, 4) == 2) &&
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


void ARM64Decoder::DecodeCompareBranch(Instr* instr) {
  if (instr->IsExceptionGenOp()) {
    DecodeExceptionGen(instr);
  } else if (instr->IsSystemOp()) {
    DecodeSystem(instr);
  } else if (instr->IsUnconditionalBranchRegOp()) {
    DecodeUnconditionalBranchReg(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeLoadStore(Instr* instr) {
  Unknown(instr);
}


void ARM64Decoder::DecodeAddSubShiftExt(Instr* instr) {
  switch (instr->Bit(30)) {
    case 0:
      Format(instr, "add'sf's 'rd, 'rn, 'shift_op");
      break;
    case 1:
      Format(instr, "sub'sf's 'rd, 'rn, 'shift_op");
      break;
    default:
      UNREACHABLE();
      break;
  }
}


void ARM64Decoder::DecodeDPRegister(Instr* instr) {
  if (instr->IsAddSubShiftExtOp()) {
    DecodeAddSubShiftExt(instr);
  } else {
    Unknown(instr);
  }
}


void ARM64Decoder::DecodeDPSimd1(Instr* instr) {
  Unknown(instr);
}


void ARM64Decoder::DecodeDPSimd2(Instr* instr) {
  Unknown(instr);
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
  } else {
    ASSERT(instr->IsDPSimd2Op());
    DecodeDPSimd2(instr);
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
