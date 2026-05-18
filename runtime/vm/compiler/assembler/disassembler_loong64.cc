// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_LOONG64.
#if defined(TARGET_ARCH_LOONG64)

#include "vm/compiler/assembler/disassembler.h"

#include "platform/unaligned.h"
#include "platform/utils.h"
#include "vm/instructions.h"

namespace dart {

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

class Loong64Disassembler : public ValueObject {
 public:
  Loong64Disassembler(char* buffer, intptr_t buffer_size)
      : buffer_(buffer), buffer_size_(buffer_size), buffer_pos_(0) {
    buffer_[buffer_pos_] = '\0';
  }

  void Decode(uword pc);

 private:
  static constexpr uint32_t kAddiD = 0x02c00000;
  static constexpr uint32_t kAddu16iD = 0x10000000;
  static constexpr uint32_t kBranch = 0x50000000;
  static constexpr uint32_t kBranchLink = 0x54000000;
  static constexpr uint32_t kDbar = 0x38720000;
  static constexpr uint32_t kIbar = 0x38728000;
  static constexpr uint32_t kJirl = 0x4c000000;
  static constexpr uint32_t kLoadD = 0x28c00000;
  static constexpr uint32_t kLu12iW = 0x14000000;
  static constexpr uint32_t kLu32iD = 0x16000000;
  static constexpr uint32_t kLu52iD = 0x03000000;
  static constexpr uint32_t kNop = 0x03400000;
  static constexpr uint32_t kOri = 0x03800000;
  static constexpr uint32_t kPcAddU12I = 0x1c000000;
  static constexpr uint32_t kStoreD = 0x29c00000;

  static constexpr uint32_t kOp6Mask = 0xfc000000;
  static constexpr uint32_t kOp7Mask = 0xfe000000;
  static constexpr uint32_t kOp10Mask = 0xffc00000;
  static constexpr uint32_t kImm15Mask = 0x00007fff;

  static int32_t SignExtend(int bits, uint32_t value) {
    return static_cast<int32_t>(value << (32 - bits)) >> (32 - bits);
  }

  static Register Rd(uint32_t instr) {
    return static_cast<Register>(instr & 0x1f);
  }

  static Register Rj(uint32_t instr) {
    return static_cast<Register>((instr >> 5) & 0x1f);
  }

  static int32_t I12(uint32_t instr) {
    return SignExtend(12, (instr >> 10) & 0xfff);
  }

  static uint32_t Ui12(uint32_t instr) { return (instr >> 10) & 0xfff; }

  static int32_t I16Shift2(uint32_t instr) {
    return SignExtend(16, (instr >> 10) & 0xffff) << 2;
  }

  static int32_t I20(uint32_t instr) {
    return SignExtend(20, (instr >> 5) & 0xfffff);
  }

  static int32_t BranchOffset(uint32_t instr) {
    const uint32_t encoded =
        ((instr >> 10) & 0xffff) | ((instr & 0x3ff) << 16);
    return SignExtend(26, encoded) << 2;
  }

  static const char* RegName(Register reg) { return cpu_reg_names[reg]; }

  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  bool DecodeBranch(uint32_t instr);

  char* buffer_;
  intptr_t buffer_size_;
  intptr_t buffer_pos_;

  DISALLOW_COPY_AND_ASSIGN(Loong64Disassembler);
};

void Loong64Disassembler::Print(const char* format, ...) {
  if (buffer_pos_ >= (buffer_size_ - 1)) {
    return;
  }
  va_list args;
  va_start(args, format);
  const intptr_t len =
      Utils::VSNPrint(buffer_ + buffer_pos_, buffer_size_ - buffer_pos_,
                      format, args);
  va_end(args);
  buffer_pos_ += Utils::Minimum(len, buffer_size_ - buffer_pos_ - 1);
  buffer_[buffer_pos_] = '\0';
}

bool Loong64Disassembler::DecodeBranch(uint32_t instr) {
  const char* mnemonic = nullptr;
  switch (instr & kOp6Mask) {
    case 0x58000000:
      mnemonic = "beq";
      break;
    case 0x5c000000:
      mnemonic = "bne";
      break;
    case 0x60000000:
      mnemonic = "blt";
      break;
    case 0x64000000:
      mnemonic = "bge";
      break;
    case 0x68000000:
      mnemonic = "bltu";
      break;
    case 0x6c000000:
      mnemonic = "bgeu";
      break;
    default:
      return false;
  }

  Print("%s %s, %s, %d", mnemonic, RegName(Rj(instr)), RegName(Rd(instr)),
        I16Shift2(instr));
  return true;
}

void Loong64Disassembler::Decode(uword pc) {
  const uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(pc));

  if (instr == kNop) {
    Print("nop");
    return;
  }

  if ((instr & kOp10Mask) == kLoadD) {
    Print("ld.d %s, %s, %d", RegName(Rd(instr)), RegName(Rj(instr)),
          I12(instr));
    return;
  }

  if ((instr & kOp10Mask) == kStoreD) {
    Print("st.d %s, %s, %d", RegName(Rd(instr)), RegName(Rj(instr)),
          I12(instr));
    return;
  }

  if ((instr & kOp6Mask) == kJirl) {
    if ((Rd(instr) == ZR) && (Rj(instr) == RA) && (I16Shift2(instr) == 0)) {
      Print("ret");
    } else {
      Print("jirl %s, %s, %d", RegName(Rd(instr)), RegName(Rj(instr)),
            I16Shift2(instr));
    }
    return;
  }

  if ((instr & kOp6Mask) == kBranch) {
    Print("b %d", BranchOffset(instr));
    return;
  }

  if ((instr & kOp6Mask) == kBranchLink) {
    Print("bl %d", BranchOffset(instr));
    return;
  }

  if (DecodeBranch(instr)) {
    return;
  }

  if ((instr & kOp7Mask) == kPcAddU12I) {
    Print("pcaddu12i %s, %d", RegName(Rd(instr)), I20(instr));
    return;
  }

  if ((instr & kOp7Mask) == kLu12iW) {
    Print("lu12i.w %s, %d", RegName(Rd(instr)), I20(instr));
    return;
  }

  if ((instr & kOp7Mask) == kLu32iD) {
    Print("lu32i.d %s, %d", RegName(Rd(instr)), I20(instr));
    return;
  }

  if ((instr & kOp10Mask) == kAddiD) {
    Print("addi.d %s, %s, %d", RegName(Rd(instr)), RegName(Rj(instr)),
          I12(instr));
    return;
  }

  if ((instr & kOp10Mask) == kOri) {
    Print("ori %s, %s, 0x%x", RegName(Rd(instr)), RegName(Rj(instr)),
          Ui12(instr));
    return;
  }

  if ((instr & kOp10Mask) == kLu52iD) {
    Print("lu52i.d %s, %s, %d", RegName(Rd(instr)), RegName(Rj(instr)),
          I12(instr));
    return;
  }

  if ((instr & kOp6Mask) == kAddu16iD) {
    Print("addu16i.d %s, %s, %d", RegName(Rd(instr)), RegName(Rj(instr)),
          I16Shift2(instr) >> 2);
    return;
  }

  if ((instr & ~kImm15Mask) == kDbar) {
    Print("dbar 0x%x", instr & kImm15Mask);
    return;
  }

  if ((instr & ~kImm15Mask) == kIbar) {
    Print("ibar 0x%x", instr & kImm15Mask);
    return;
  }

  if ((instr & 0xffff8000) == 0x002a0000) {
    Print("break 0x%x", instr & kImm15Mask);
    return;
  }

  Print("unknown 0x%08x", instr);
}

void Disassembler::DecodeInstruction(char* hex_buffer,
                                     intptr_t hex_size,
                                     char* human_buffer,
                                     intptr_t human_size,
                                     int* out_instr_size,
                                     const Code& code,
                                     Object** object,
                                     uword pc) {
  const uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(pc));
  Utils::SNPrint(hex_buffer, hex_size, "%08x", instr);

  Loong64Disassembler decoder(human_buffer, human_size);
  decoder.Decode(pc);

  if (out_instr_size != nullptr) {
    *out_instr_size = 4;
  }

  *object = nullptr;
  if (!code.IsNull()) {
    *object = &Object::Handle();
    if (!DecodeLoadObjectFromPoolOrThread(pc, code, *object)) {
      *object = nullptr;
    }
  }
}

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
