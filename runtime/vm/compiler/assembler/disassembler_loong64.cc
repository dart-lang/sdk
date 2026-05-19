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
  static constexpr uint32_t kFaddS = 0x01008000;
  static constexpr uint32_t kFaddD = 0x01010000;
  static constexpr uint32_t kFsubS = 0x01028000;
  static constexpr uint32_t kFsubD = 0x01030000;
  static constexpr uint32_t kFmulS = 0x01048000;
  static constexpr uint32_t kFmulD = 0x01050000;
  static constexpr uint32_t kFdivS = 0x01068000;
  static constexpr uint32_t kFdivD = 0x01070000;
  static constexpr uint32_t kFmaxS = 0x01088000;
  static constexpr uint32_t kFmaxD = 0x01090000;
  static constexpr uint32_t kFminS = 0x010a8000;
  static constexpr uint32_t kFminD = 0x010b0000;
  static constexpr uint32_t kFabsS = 0x01140400;
  static constexpr uint32_t kFabsD = 0x01140800;
  static constexpr uint32_t kFnegS = 0x01141400;
  static constexpr uint32_t kFnegD = 0x01141800;
  static constexpr uint32_t kFmovS = 0x01149400;
  static constexpr uint32_t kFmovD = 0x01149800;
  static constexpr uint32_t kFsqrtS = 0x01144400;
  static constexpr uint32_t kFsqrtD = 0x01144800;
  static constexpr uint32_t kMovfr2grS = 0x0114b400;
  static constexpr uint32_t kMovfr2grD = 0x0114b800;
  static constexpr uint32_t kFfintSL = 0x011d1800;
  static constexpr uint32_t kFfintDL = 0x011d2800;
  static constexpr uint32_t kFfintSW = 0x011d1000;
  static constexpr uint32_t kFfintDW = 0x011d2000;
  static constexpr uint32_t kFcvtSD = 0x01191800;
  static constexpr uint32_t kFcvtDS = 0x01192400;
  static constexpr uint32_t kFtintrmLS = 0x011a2400;
  static constexpr uint32_t kFtintrmLD = 0x011a2800;
  static constexpr uint32_t kFtintrpLS = 0x011a6400;
  static constexpr uint32_t kFtintrpLD = 0x011a6800;
  static constexpr uint32_t kFtintrzLS = 0x011aa400;
  static constexpr uint32_t kFtintrzLD = 0x011aa800;
  static constexpr uint32_t kFcmpCltS = 0x0c110000;
  static constexpr uint32_t kFcmpCeqS = 0x0c120000;
  static constexpr uint32_t kFcmpCleS = 0x0c130000;
  static constexpr uint32_t kFcmpCltD = 0x0c210000;
  static constexpr uint32_t kFcmpCeqD = 0x0c220000;
  static constexpr uint32_t kFcmpCleD = 0x0c230000;
  static constexpr uint32_t kMovcf2gr = 0x0114dc00;
  static constexpr uint32_t kMovgr2frW = 0x0114a400;
  static constexpr uint32_t kMovgr2frD = 0x0114a800;
  static constexpr uint32_t kNop = 0x03400000;
  static constexpr uint32_t kOri = 0x03800000;
  static constexpr uint32_t kPcAddU12I = 0x1c000000;
  static constexpr uint32_t kStoreD = 0x29c00000;

  static constexpr uint32_t kOp6Mask = 0xfc000000;
  static constexpr uint32_t kOp7Mask = 0xfe000000;
  static constexpr uint32_t kOp10Mask = 0xffc00000;
  static constexpr uint32_t kOp17Mask = 0xffff8000;
  static constexpr uint32_t kOp22Mask = 0xfffffc00;
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

  static FRegister Fd(uint32_t instr) {
    return static_cast<FRegister>(instr & 0x1f);
  }

  static FRegister Fj(uint32_t instr) {
    return static_cast<FRegister>((instr >> 5) & 0x1f);
  }

  static FRegister Fk(uint32_t instr) {
    return static_cast<FRegister>((instr >> 10) & 0x1f);
  }

  static uint32_t Fcc(uint32_t instr) { return instr & 0x7; }
  static uint32_t FccJ(uint32_t instr) { return (instr >> 5) & 0x7; }

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
  static const char* FpuRegName(FRegister reg) { return fpu_reg_names[reg]; }

  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  bool DecodeBranch(uint32_t instr);
  bool DecodeFpuBinary(uint32_t instr);
  bool DecodeFpuUnary(uint32_t instr);

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

bool Loong64Disassembler::DecodeFpuBinary(uint32_t instr) {
  const char* mnemonic = nullptr;
  switch (instr & kOp17Mask) {
    case kFaddS:
      mnemonic = "fadd.s";
      break;
    case kFaddD:
      mnemonic = "fadd.d";
      break;
    case kFsubS:
      mnemonic = "fsub.s";
      break;
    case kFsubD:
      mnemonic = "fsub.d";
      break;
    case kFmulS:
      mnemonic = "fmul.s";
      break;
    case kFmulD:
      mnemonic = "fmul.d";
      break;
    case kFdivS:
      mnemonic = "fdiv.s";
      break;
    case kFdivD:
      mnemonic = "fdiv.d";
      break;
    case kFmaxS:
      mnemonic = "fmax.s";
      break;
    case kFmaxD:
      mnemonic = "fmax.d";
      break;
    case kFminS:
      mnemonic = "fmin.s";
      break;
    case kFminD:
      mnemonic = "fmin.d";
      break;
    default:
      return false;
  }
  Print("%s %s, %s, %s", mnemonic, FpuRegName(Fd(instr)),
        FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
  return true;
}

bool Loong64Disassembler::DecodeFpuUnary(uint32_t instr) {
  const char* mnemonic = nullptr;
  switch (instr & kOp22Mask) {
    case kFabsS:
      mnemonic = "fabs.s";
      break;
    case kFabsD:
      mnemonic = "fabs.d";
      break;
    case kFnegS:
      mnemonic = "fneg.s";
      break;
    case kFnegD:
      mnemonic = "fneg.d";
      break;
    case kFmovS:
      mnemonic = "fmov.s";
      break;
    case kFmovD:
      mnemonic = "fmov.d";
      break;
    case kFsqrtS:
      mnemonic = "fsqrt.s";
      break;
    case kFsqrtD:
      mnemonic = "fsqrt.d";
      break;
    case kFcvtSD:
      mnemonic = "fcvt.s.d";
      break;
    case kFcvtDS:
      mnemonic = "fcvt.d.s";
      break;
    case kFtintrmLS:
      mnemonic = "ftintrm.l.s";
      break;
    case kFtintrmLD:
      mnemonic = "ftintrm.l.d";
      break;
    case kFtintrpLS:
      mnemonic = "ftintrp.l.s";
      break;
    case kFtintrpLD:
      mnemonic = "ftintrp.l.d";
      break;
    case kFtintrzLS:
      mnemonic = "ftintrz.l.s";
      break;
    case kFtintrzLD:
      mnemonic = "ftintrz.l.d";
      break;
    default:
      return false;
  }
  Print("%s %s, %s", mnemonic, FpuRegName(Fd(instr)), FpuRegName(Fj(instr)));
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

  if ((instr & kOp22Mask) == kMovgr2frW) {
    Print("movgr2fr.w %s, %s", FpuRegName(Fd(instr)), RegName(Rj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kMovgr2frD) {
    Print("movgr2fr.d %s, %s", FpuRegName(Fd(instr)), RegName(Rj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kMovfr2grS) {
    Print("movfr2gr.s %s, %s", RegName(Rd(instr)), FpuRegName(Fj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kMovfr2grD) {
    Print("movfr2gr.d %s, %s", RegName(Rd(instr)), FpuRegName(Fj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kFfintSW) {
    Print("ffint.s.w %s, %s", FpuRegName(Fd(instr)), FpuRegName(Fj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kFfintDW) {
    Print("ffint.d.w %s, %s", FpuRegName(Fd(instr)), FpuRegName(Fj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kFfintSL) {
    Print("ffint.s.l %s, %s", FpuRegName(Fd(instr)), FpuRegName(Fj(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kFfintDL) {
    Print("ffint.d.l %s, %s", FpuRegName(Fd(instr)), FpuRegName(Fj(instr)));
    return;
  }

  if (DecodeFpuBinary(instr)) {
    return;
  }

  if (DecodeFpuUnary(instr)) {
    return;
  }

  if ((instr & kOp17Mask) == kFcmpCltS) {
    Print("fcmp.clt.s $fcc%" Pu32 ", %s, %s", Fcc(instr),
          FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
    return;
  }

  if ((instr & kOp17Mask) == kFcmpCeqS) {
    Print("fcmp.ceq.s $fcc%" Pu32 ", %s, %s", Fcc(instr),
          FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
    return;
  }

  if ((instr & kOp17Mask) == kFcmpCleS) {
    Print("fcmp.cle.s $fcc%" Pu32 ", %s, %s", Fcc(instr),
          FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
    return;
  }

  if ((instr & kOp17Mask) == kFcmpCltD) {
    Print("fcmp.clt.d $fcc%" Pu32 ", %s, %s", Fcc(instr),
          FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
    return;
  }

  if ((instr & kOp17Mask) == kFcmpCeqD) {
    Print("fcmp.ceq.d $fcc%" Pu32 ", %s, %s", Fcc(instr),
          FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
    return;
  }

  if ((instr & kOp17Mask) == kFcmpCleD) {
    Print("fcmp.cle.d $fcc%" Pu32 ", %s, %s", Fcc(instr),
          FpuRegName(Fj(instr)), FpuRegName(Fk(instr)));
    return;
  }

  if ((instr & kOp22Mask) == kMovcf2gr) {
    Print("movcf2gr %s, $fcc%" Pu32, RegName(Rd(instr)), FccJ(instr));
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
