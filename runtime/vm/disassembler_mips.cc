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
  void InstructionDecode(Instr* instr);

 private:
  // Bottleneck functions to print into the out_buffer.
  void Print(const char* str);

  // Printing of common values.
  void PrintRegister(Register reg);

  int FormatRegister(Instr* instr, const char* format);
  int FormatOption(Instr* instr, const char* format);
  void Format(Instr* instr, const char* format);

  void DecodeSpecial(Instr* instr);
  void DecodeSpecial2(Instr* instr);
  void DecodeSpecial3(Instr* instr);

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


void MIPSDecoder::PrintRegister(Register reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kNumberOfCpuRegisters);
  Print(reg_names[reg]);
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


// FormatOption takes a formatting string and interprets it based on
// the current instructions. The format string points to the first
// character of the option string (the option escape has already been
// consumed by the caller.)  FormatOption returns the number of
// characters that were consumed from the formatting string.
int MIPSDecoder::FormatOption(Instr* instr, const char* format) {
  switch (format[0]) {
    case 'h': {
      ASSERT(STRING_STARTS_WITH(format, "hint"));
      if (instr->SaField() != 0) {
        UNIMPLEMENTED();
      }
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
    case DIV: {
      Format(instr, "div 'rs, 'rt");
      break;
    }
    case DIVU: {
      Format(instr, "divu 'rs, 'rt");
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
    case JR: {
      ASSERT(instr->RtField() == R0);
      ASSERT(instr->RdField() == R0);
      Format(instr, "jr'hint 'rs");
      break;
    }
    default: {
      OS::PrintErr("DecodeSpecial: 0x%x\n", instr->InstructionBits());
      UNREACHABLE();
      break;
    }
  }
}


void MIPSDecoder::DecodeSpecial2(Instr* instr) {
  ASSERT(instr->OpcodeField() == SPECIAL2);
  switch (instr->FunctionField()) {
    case CLO: {
      Format(instr, "clo 'rd, 'rs");
      break;
    }
    case CLZ: {
      Format(instr, "clz 'rd, 'rs");
      break;
    }
    default: {
      OS::PrintErr("DecodeSpecial2: 0x%x\n", instr->InstructionBits());
      UNREACHABLE();
      break;
    }
  }
}


void MIPSDecoder::DecodeSpecial3(Instr* instr) {
  ASSERT(instr->OpcodeField() == SPECIAL3);
  switch (instr->FunctionField()) {
    default: {
      OS::PrintErr("DecodeSpecial3: 0x%x\n", instr->InstructionBits());
      UNREACHABLE();
      break;
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
    case SPECIAL3: {
      DecodeSpecial3(instr);
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
    case LB: {
      Format(instr, "lb 'rt, 'imms('rs)");
      break;
    }
    case LBU: {
      Format(instr, "lbu 'rt, 'imms('rs)");
      break;
    }
    case LH: {
      Format(instr, "lh 'rt, 'imms('rs)");
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
    case ORI: {
      Format(instr, "ori 'rt, 'rs, 'immu");
      break;
    }
    case SB: {
      Format(instr, "sb 'rt, 'imms('rs)");
      break;
    }
    case SH: {
      Format(instr, "sh 'rt, 'imms('rs)");
      break;
    }
    case SW: {
      Format(instr, "sw 'rt, 'imms('rs)");
      break;
    }
    default: {
      OS::PrintErr("Undecoded instruction: 0x%x\n", instr->InstructionBits());
      UNREACHABLE();
      break;
    }
  }
}


int Disassembler::DecodeInstruction(char* hex_buffer, intptr_t hex_size,
                                    char* human_buffer, intptr_t human_size,
                                    uword pc) {
  MIPSDecoder decoder(human_buffer, human_size);
  Instr* instr = Instr::At(pc);
  decoder.InstructionDecode(instr);
  OS::SNPrint(hex_buffer, hex_size, "%08x", instr->InstructionBits());
  return Instr::kInstrSize;
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
    int instruction_length = DecodeInstruction(hex_buffer,
                                               sizeof(hex_buffer),
                                               human_buffer,
                                               sizeof(human_buffer),
                                               pc);
    formatter->ConsumeInstruction(hex_buffer,
                                  sizeof(hex_buffer),
                                  human_buffer,
                                  sizeof(human_buffer),
                                  pc);
    pc += instruction_length;
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
