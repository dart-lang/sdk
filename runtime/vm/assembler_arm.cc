// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/simulator.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, print_stop_message, true, "Print stop message.");


bool CPUFeatures::integer_division_supported_ = false;
#if defined(DEBUG)
bool CPUFeatures::initialized_ = false;
#endif


bool CPUFeatures::integer_division_supported() {
  DEBUG_ASSERT(initialized_);
  return integer_division_supported_;
}


#if defined(USING_SIMULATOR)
void CPUFeatures::set_integer_division_supported(bool supported) {
  integer_division_supported_ = supported;
}
#endif


#define __ assembler.

void CPUFeatures::InitOnce() {
#if defined(USING_SIMULATOR)
  integer_division_supported_ = true;
#else
  Assembler assembler;
  __ mrc(R0, 15, 0, 0, 2, 0);
  __ Lsr(R0, R0, 24);
  __ and_(R0, R0, ShifterOperand(0xf));
  __ Ret();

  const Code& code =
      Code::Handle(Code::FinalizeCode("DetectCPUFeatures", &assembler));
  Instructions& instructions = Instructions::Handle(code.instructions());
  typedef int32_t (*DetectCPUFeatures)();
  int32_t features =
      reinterpret_cast<DetectCPUFeatures>(instructions.EntryPoint())();
  integer_division_supported_ = features != 0;
#endif  // defined(USING_SIMULATOR)
#if defined(DEBUG)
  initialized_ = true;
#endif
}

#undef __


// Instruction encoding bits.
enum {
  H   = 1 << 5,   // halfword (or byte)
  L   = 1 << 20,  // load (or store)
  S   = 1 << 20,  // set condition code (or leave unchanged)
  W   = 1 << 21,  // writeback base register (or leave unchanged)
  A   = 1 << 21,  // accumulate in multiply instruction (or not)
  B   = 1 << 22,  // unsigned byte (or word)
  D   = 1 << 22,  // high/lo bit of start of s/d register range
  N   = 1 << 22,  // long (or short)
  U   = 1 << 23,  // positive (or negative) offset/index
  P   = 1 << 24,  // offset/pre-indexed addressing (or post-indexed addressing)
  I   = 1 << 25,  // immediate shifter operand (or not)

  B0 = 1,
  B1 = 1 << 1,
  B2 = 1 << 2,
  B3 = 1 << 3,
  B4 = 1 << 4,
  B5 = 1 << 5,
  B6 = 1 << 6,
  B7 = 1 << 7,
  B8 = 1 << 8,
  B9 = 1 << 9,
  B10 = 1 << 10,
  B11 = 1 << 11,
  B12 = 1 << 12,
  B16 = 1 << 16,
  B17 = 1 << 17,
  B18 = 1 << 18,
  B19 = 1 << 19,
  B20 = 1 << 20,
  B21 = 1 << 21,
  B22 = 1 << 22,
  B23 = 1 << 23,
  B24 = 1 << 24,
  B25 = 1 << 25,
  B26 = 1 << 26,
  B27 = 1 << 27,

  // ldrex/strex register field encodings.
  kLdExRnShift = 16,
  kLdExRtShift = 12,
  kStrExRnShift = 16,
  kStrExRdShift = 12,
  kStrExRtShift = 0,
};


uint32_t Address::encoding3() const {
  ASSERT(kind_ == Immediate);
  uint32_t offset = encoding_ & kOffset12Mask;
  ASSERT(offset < 256);
  return (encoding_ & ~kOffset12Mask) | ((offset & 0xf0) << 4) | (offset & 0xf);
}


uint32_t Address::vencoding() const {
  ASSERT(kind_ == Immediate);
  uint32_t offset = encoding_ & kOffset12Mask;
  ASSERT(offset < (1 << 10));  // In the range 0 to +1020.
  ASSERT(Utils::IsAligned(offset, 4));  // Multiple of 4.
  int mode = encoding_ & ((8|4|1) << 21);
  ASSERT((mode == Offset) || (mode == NegOffset));
  uint32_t vencoding = (encoding_ & (0xf << kRnShift)) | (offset >> 2);
  if (mode == Offset) {
    vencoding |= 1 << 23;
  }
  return vencoding;
}


void Assembler::InitializeMemoryWithBreakpoints(uword data, int length) {
  ASSERT(Utils::IsAligned(data, 4));
  ASSERT(Utils::IsAligned(length, 4));
  const uword end = data + length;
  while (data < end) {
    *reinterpret_cast<int32_t*>(data) = Instr::kBreakPointInstruction;
    data += 4;
  }
}


void Assembler::Emit(int32_t value) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<int32_t>(value);
}


void Assembler::EmitType01(Condition cond,
                           int type,
                           Opcode opcode,
                           int set_cc,
                           Register rn,
                           Register rd,
                           ShifterOperand so) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     type << kTypeShift |
                     static_cast<int32_t>(opcode) << kOpcodeShift |
                     set_cc << kSShift |
                     static_cast<int32_t>(rn) << kRnShift |
                     static_cast<int32_t>(rd) << kRdShift |
                     so.encoding();
  Emit(encoding);
}


void Assembler::EmitType5(Condition cond, int32_t offset, bool link) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     5 << kTypeShift |
                     (link ? 1 : 0) << kLinkShift;
  Emit(Assembler::EncodeBranchOffset(offset, encoding));
}


void Assembler::EmitMemOp(Condition cond,
                          bool load,
                          bool byte,
                          Register rd,
                          Address ad) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B26 | (ad.kind() == Address::Immediate ? 0 : B25) |
                     (load ? L : 0) |
                     (byte ? B : 0) |
                     (static_cast<int32_t>(rd) << kRdShift) |
                     ad.encoding();
  Emit(encoding);
}


void Assembler::EmitMemOpAddressMode3(Condition cond,
                                      int32_t mode,
                                      Register rd,
                                      Address ad) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B22  |
                     mode |
                     (static_cast<int32_t>(rd) << kRdShift) |
                     ad.encoding3();
  Emit(encoding);
}


void Assembler::EmitMultiMemOp(Condition cond,
                               BlockAddressMode am,
                               bool load,
                               Register base,
                               RegList regs) {
  ASSERT(base != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 |
                     am |
                     (load ? L : 0) |
                     (static_cast<int32_t>(base) << kRnShift) |
                     regs;
  Emit(encoding);
}


void Assembler::EmitShiftImmediate(Condition cond,
                                   Shift opcode,
                                   Register rd,
                                   Register rm,
                                   ShifterOperand so) {
  ASSERT(cond != kNoCondition);
  ASSERT(so.type() == 1);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     static_cast<int32_t>(MOV) << kOpcodeShift |
                     static_cast<int32_t>(rd) << kRdShift |
                     so.encoding() << kShiftImmShift |
                     static_cast<int32_t>(opcode) << kShiftShift |
                     static_cast<int32_t>(rm);
  Emit(encoding);
}


void Assembler::EmitShiftRegister(Condition cond,
                                  Shift opcode,
                                  Register rd,
                                  Register rm,
                                  ShifterOperand so) {
  ASSERT(cond != kNoCondition);
  ASSERT(so.type() == 0);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     static_cast<int32_t>(MOV) << kOpcodeShift |
                     static_cast<int32_t>(rd) << kRdShift |
                     so.encoding() << kShiftRegisterShift |
                     static_cast<int32_t>(opcode) << kShiftShift |
                     B4 |
                     static_cast<int32_t>(rm);
  Emit(encoding);
}


void Assembler::EmitBranch(Condition cond, Label* label, bool link) {
  if (label->IsBound()) {
    EmitType5(cond, label->Position() - buffer_.Size(), link);
  } else {
    int position = buffer_.Size();
    // Use the offset field of the branch instruction for linking the sites.
    EmitType5(cond, label->position_, link);
    label->LinkTo(position);
  }
}


void Assembler::and_(Register rd, Register rn, ShifterOperand so,
                     Condition cond) {
  EmitType01(cond, so.type(), AND, 0, rn, rd, so);
}


void Assembler::eor(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), EOR, 0, rn, rd, so);
}


void Assembler::sub(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), SUB, 0, rn, rd, so);
}

void Assembler::rsb(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), RSB, 0, rn, rd, so);
}

void Assembler::rsbs(Register rd, Register rn, ShifterOperand so,
                     Condition cond) {
  EmitType01(cond, so.type(), RSB, 1, rn, rd, so);
}


void Assembler::add(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), ADD, 0, rn, rd, so);
}


void Assembler::adds(Register rd, Register rn, ShifterOperand so,
                     Condition cond) {
  EmitType01(cond, so.type(), ADD, 1, rn, rd, so);
}


void Assembler::subs(Register rd, Register rn, ShifterOperand so,
                     Condition cond) {
  EmitType01(cond, so.type(), SUB, 1, rn, rd, so);
}


void Assembler::adc(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), ADC, 0, rn, rd, so);
}


void Assembler::sbc(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), SBC, 0, rn, rd, so);
}


void Assembler::rsc(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), RSC, 0, rn, rd, so);
}


void Assembler::tst(Register rn, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), TST, 1, rn, R0, so);
}


void Assembler::teq(Register rn, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), TEQ, 1, rn, R0, so);
}


void Assembler::cmp(Register rn, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), CMP, 1, rn, R0, so);
}


void Assembler::cmn(Register rn, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), CMN, 1, rn, R0, so);
}


void Assembler::orr(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), ORR, 0, rn, rd, so);
}


void Assembler::orrs(Register rd, Register rn, ShifterOperand so,
                     Condition cond) {
  EmitType01(cond, so.type(), ORR, 1, rn, rd, so);
}


void Assembler::mov(Register rd, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), MOV, 0, R0, rd, so);
}


void Assembler::movs(Register rd, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), MOV, 1, R0, rd, so);
}


void Assembler::bic(Register rd, Register rn, ShifterOperand so,
                    Condition cond) {
  EmitType01(cond, so.type(), BIC, 0, rn, rd, so);
}


void Assembler::mvn(Register rd, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), MVN, 0, R0, rd, so);
}


void Assembler::mvns(Register rd, ShifterOperand so, Condition cond) {
  EmitType01(cond, so.type(), MVN, 1, R0, rd, so);
}


void Assembler::clz(Register rd, Register rm, Condition cond) {
  ASSERT(rd != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(rd != PC);
  ASSERT(rm != PC);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B24 | B22 | B21 | (0xf << 16) |
                     (static_cast<int32_t>(rd) << kRdShift) |
                     (0xf << 8) | B4 | static_cast<int32_t>(rm);
  Emit(encoding);
}


void Assembler::movw(Register rd, uint16_t imm16, Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     B25 | B24 | ((imm16 >> 12) << 16) |
                     static_cast<int32_t>(rd) << kRdShift | (imm16 & 0xfff);
  Emit(encoding);
}


void Assembler::movt(Register rd, uint16_t imm16, Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     B25 | B24 | B22 | ((imm16 >> 12) << 16) |
                     static_cast<int32_t>(rd) << kRdShift | (imm16 & 0xfff);
  Emit(encoding);
}


void Assembler::EmitMulOp(Condition cond, int32_t opcode,
                          Register rd, Register rn,
                          Register rm, Register rs) {
  ASSERT(rd != kNoRegister);
  ASSERT(rn != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(rs != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = opcode |
      (static_cast<int32_t>(cond) << kConditionShift) |
      (static_cast<int32_t>(rn) << kRnShift) |
      (static_cast<int32_t>(rd) << kRdShift) |
      (static_cast<int32_t>(rs) << kRsShift) |
      B7 | B4 |
      (static_cast<int32_t>(rm) << kRmShift);
  Emit(encoding);
}


void Assembler::mul(Register rd, Register rn,
                    Register rm, Condition cond) {
  // Assembler registers rd, rn, rm are encoded as rn, rm, rs.
  EmitMulOp(cond, 0, R0, rd, rn, rm);
}


// Like mul, but sets condition flags.
void Assembler::muls(Register rd, Register rn,
                     Register rm, Condition cond) {
  EmitMulOp(cond, B20, R0, rd, rn, rm);
}


void Assembler::mla(Register rd, Register rn,
                    Register rm, Register ra, Condition cond) {
  // Assembler registers rd, rn, rm, ra are encoded as rn, rm, rs, rd.
  EmitMulOp(cond, B21, ra, rd, rn, rm);
}


void Assembler::mls(Register rd, Register rn,
                    Register rm, Register ra, Condition cond) {
  // Assembler registers rd, rn, rm, ra are encoded as rn, rm, rs, rd.
  EmitMulOp(cond, B22 | B21, ra, rd, rn, rm);
}


void Assembler::umull(Register rd_lo, Register rd_hi,
                      Register rn, Register rm, Condition cond) {
  // Assembler registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
  EmitMulOp(cond, B23, rd_lo, rd_hi, rn, rm);
}


void Assembler::EmitDivOp(Condition cond, int32_t opcode,
                          Register rd, Register rn, Register rm) {
  ASSERT(CPUFeatures::integer_division_supported());
  ASSERT(rd != kNoRegister);
  ASSERT(rn != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = opcode |
    (static_cast<int32_t>(cond) << kConditionShift) |
    (static_cast<int32_t>(rn) << kRnShift) |
    (static_cast<int32_t>(rd) << kRdShift) |
    B26 | B25 | B24 | B20 | B4 |
    (static_cast<int32_t>(rm) << kRmShift);
  Emit(encoding);
}


void Assembler::sdiv(Register rd, Register rn, Register rm, Condition cond) {
  EmitDivOp(cond, 0, rd, rn, rm);
}


void Assembler::udiv(Register rd, Register rn, Register rm, Condition cond) {
  EmitDivOp(cond, B21 , rd, rn, rm);
}


void Assembler::ldr(Register rd, Address ad, Condition cond) {
  EmitMemOp(cond, true, false, rd, ad);
}


void Assembler::str(Register rd, Address ad, Condition cond) {
  EmitMemOp(cond, false, false, rd, ad);
}


void Assembler::ldrb(Register rd, Address ad, Condition cond) {
  EmitMemOp(cond, true, true, rd, ad);
}


void Assembler::strb(Register rd, Address ad, Condition cond) {
  EmitMemOp(cond, false, true, rd, ad);
}


void Assembler::ldrh(Register rd, Address ad, Condition cond) {
  EmitMemOpAddressMode3(cond, L | B7 | H | B4, rd, ad);
}


void Assembler::strh(Register rd, Address ad, Condition cond) {
  EmitMemOpAddressMode3(cond, B7 | H | B4, rd, ad);
}


void Assembler::ldrsb(Register rd, Address ad, Condition cond) {
  EmitMemOpAddressMode3(cond, L | B7 | B6 | B4, rd, ad);
}


void Assembler::ldrsh(Register rd, Address ad, Condition cond) {
  EmitMemOpAddressMode3(cond, L | B7 | B6 | H | B4, rd, ad);
}


void Assembler::ldrd(Register rd, Address ad, Condition cond) {
  ASSERT((rd % 2) == 0);
  EmitMemOpAddressMode3(cond, B7 | B6 | B4, rd, ad);
}


void Assembler::strd(Register rd, Address ad, Condition cond) {
  ASSERT((rd % 2) == 0);
  EmitMemOpAddressMode3(cond, B7 | B6 | B5 | B4, rd, ad);
}


void Assembler::ldm(BlockAddressMode am, Register base, RegList regs,
                    Condition cond) {
  EmitMultiMemOp(cond, am, true, base, regs);
}


void Assembler::stm(BlockAddressMode am, Register base, RegList regs,
                    Condition cond) {
  EmitMultiMemOp(cond, am, false, base, regs);
}


void Assembler::ldrex(Register rt, Register rn, Condition cond) {
  ASSERT(rn != kNoRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B24 |
                     B23 |
                     L   |
                     (static_cast<int32_t>(rn) << kLdExRnShift) |
                     (static_cast<int32_t>(rt) << kLdExRtShift) |
                     B11 | B10 | B9 | B8 | B7 | B4 | B3 | B2 | B1 | B0;
  Emit(encoding);
}


void Assembler::strex(Register rd, Register rt, Register rn, Condition cond) {
  ASSERT(rn != kNoRegister);
  ASSERT(rd != kNoRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B24 |
                     B23 |
                     (static_cast<int32_t>(rn) << kStrExRnShift) |
                     (static_cast<int32_t>(rd) << kStrExRdShift) |
                     B11 | B10 | B9 | B8 | B7 | B4 |
                     (static_cast<int32_t>(rt) << kStrExRtShift);
  Emit(encoding);
}


void Assembler::clrex() {
  int32_t encoding = (kSpecialCondition << kConditionShift) |
                     B26 | B24 | B22 | B21 | B20 | (0xff << 12) | B4 | 0xf;
  Emit(encoding);
}


void Assembler::nop(Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B25 | B24 | B21 | (0xf << 12);
  Emit(encoding);
}


void Assembler::vmovsr(SRegister sn, Register rt, Condition cond) {
  ASSERT(sn != kNoSRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 |
                     ((static_cast<int32_t>(sn) >> 1)*B16) |
                     (static_cast<int32_t>(rt)*B12) | B11 | B9 |
                     ((static_cast<int32_t>(sn) & 1)*B7) | B4;
  Emit(encoding);
}


void Assembler::vmovrs(Register rt, SRegister sn, Condition cond) {
  ASSERT(sn != kNoSRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B20 |
                     ((static_cast<int32_t>(sn) >> 1)*B16) |
                     (static_cast<int32_t>(rt)*B12) | B11 | B9 |
                     ((static_cast<int32_t>(sn) & 1)*B7) | B4;
  Emit(encoding);
}


void Assembler::vmovsrr(SRegister sm, Register rt, Register rt2,
                        Condition cond) {
  ASSERT(sm != kNoSRegister);
  ASSERT(sm != S31);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B22 |
                     (static_cast<int32_t>(rt2)*B16) |
                     (static_cast<int32_t>(rt)*B12) | B11 | B9 |
                     ((static_cast<int32_t>(sm) & 1)*B5) | B4 |
                     (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}


void Assembler::vmovrrs(Register rt, Register rt2, SRegister sm,
                        Condition cond) {
  ASSERT(sm != kNoSRegister);
  ASSERT(sm != S31);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(rt != rt2);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B22 | B20 |
                     (static_cast<int32_t>(rt2)*B16) |
                     (static_cast<int32_t>(rt)*B12) | B11 | B9 |
                     ((static_cast<int32_t>(sm) & 1)*B5) | B4 |
                     (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}


void Assembler::vmovdrr(DRegister dm, Register rt, Register rt2,
                        Condition cond) {
  ASSERT(dm != kNoDRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B22 |
                     (static_cast<int32_t>(rt2)*B16) |
                     (static_cast<int32_t>(rt)*B12) | B11 | B9 | B8 |
                     ((static_cast<int32_t>(dm) >> 4)*B5) | B4 |
                     (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}


void Assembler::vmovrrd(Register rt, Register rt2, DRegister dm,
                        Condition cond) {
  ASSERT(dm != kNoDRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(rt != rt2);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B22 | B20 |
                     (static_cast<int32_t>(rt2)*B16) |
                     (static_cast<int32_t>(rt)*B12) | B11 | B9 | B8 |
                     ((static_cast<int32_t>(dm) >> 4)*B5) | B4 |
                     (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}


void Assembler::vldrs(SRegister sd, Address ad, Condition cond) {
  ASSERT(sd != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B24 | B20 |
                     ((static_cast<int32_t>(sd) & 1)*B22) |
                     ((static_cast<int32_t>(sd) >> 1)*B12) |
                     B11 | B9 | ad.vencoding();
  Emit(encoding);
}


void Assembler::vstrs(SRegister sd, Address ad, Condition cond) {
  ASSERT(static_cast<Register>(ad.encoding_ & (0xf << kRnShift)) != PC);
  ASSERT(sd != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B24 |
                     ((static_cast<int32_t>(sd) & 1)*B22) |
                     ((static_cast<int32_t>(sd) >> 1)*B12) |
                     B11 | B9 | ad.vencoding();
  Emit(encoding);
}


void Assembler::vldrd(DRegister dd, Address ad, Condition cond) {
  ASSERT(dd != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B24 | B20 |
                     ((static_cast<int32_t>(dd) >> 4)*B22) |
                     ((static_cast<int32_t>(dd) & 0xf)*B12) |
                     B11 | B9 | B8 | ad.vencoding();
  Emit(encoding);
}


void Assembler::vstrd(DRegister dd, Address ad, Condition cond) {
  ASSERT(static_cast<Register>(ad.encoding_ & (0xf << kRnShift)) != PC);
  ASSERT(dd != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B24 |
                     ((static_cast<int32_t>(dd) >> 4)*B22) |
                     ((static_cast<int32_t>(dd) & 0xf)*B12) |
                     B11 | B9 | B8 | ad.vencoding();
  Emit(encoding);
}

void Assembler::EmitMultiVSMemOp(Condition cond,
                                BlockAddressMode am,
                                bool load,
                                Register base,
                                SRegister start,
                                uint32_t count) {
  ASSERT(base != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(start != kNoSRegister);
  ASSERT(static_cast<int32_t>(start) + count <= kNumberOfSRegisters);

  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B11 | B9 |
                     am |
                     (load ? L : 0) |
                     (static_cast<int32_t>(base) << kRnShift) |
                     ((static_cast<int32_t>(start) & 0x1) ? D : 0) |
                     ((static_cast<int32_t>(start) >> 1) << 12) |
                     count;
  Emit(encoding);
}


void Assembler::EmitMultiVDMemOp(Condition cond,
                                BlockAddressMode am,
                                bool load,
                                Register base,
                                DRegister start,
                                int32_t count) {
  ASSERT(base != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(start != kNoDRegister);
  ASSERT(static_cast<int32_t>(start) + count <= kNumberOfDRegisters);

  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B11 | B9 | B8 |
                     am |
                     (load ? L : 0) |
                     (static_cast<int32_t>(base) << kRnShift) |
                     ((static_cast<int32_t>(start) & 0x10) ? D : 0) |
                     ((static_cast<int32_t>(start) & 0xf) << 12) |
                     (count << 1);
  Emit(encoding);
}


void Assembler::vldms(BlockAddressMode am, Register base,
                      SRegister first, SRegister last, Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(last > first);
  EmitMultiVSMemOp(cond, am, true, base, first, last - first + 1);
}


void Assembler::vstms(BlockAddressMode am, Register base,
                      SRegister first, SRegister last, Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(last > first);
  EmitMultiVSMemOp(cond, am, false, base, first, last - first + 1);
}


void Assembler::vldmd(BlockAddressMode am, Register base,
                      DRegister first, DRegister last, Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(last > first);
  EmitMultiVDMemOp(cond, am, true, base, first, last - first + 1);
}


void Assembler::vstmd(BlockAddressMode am, Register base,
                      DRegister first, DRegister last, Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(last > first);
  EmitMultiVDMemOp(cond, am, false, base, first, last - first + 1);
}


void Assembler::EmitVFPsss(Condition cond, int32_t opcode,
                           SRegister sd, SRegister sn, SRegister sm) {
  ASSERT(sd != kNoSRegister);
  ASSERT(sn != kNoSRegister);
  ASSERT(sm != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B11 | B9 | opcode |
                     ((static_cast<int32_t>(sd) & 1)*B22) |
                     ((static_cast<int32_t>(sn) >> 1)*B16) |
                     ((static_cast<int32_t>(sd) >> 1)*B12) |
                     ((static_cast<int32_t>(sn) & 1)*B7) |
                     ((static_cast<int32_t>(sm) & 1)*B5) |
                     (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}


void Assembler::EmitVFPddd(Condition cond, int32_t opcode,
                           DRegister dd, DRegister dn, DRegister dm) {
  ASSERT(dd != kNoDRegister);
  ASSERT(dn != kNoDRegister);
  ASSERT(dm != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B11 | B9 | B8 | opcode |
                     ((static_cast<int32_t>(dd) >> 4)*B22) |
                     ((static_cast<int32_t>(dn) & 0xf)*B16) |
                     ((static_cast<int32_t>(dd) & 0xf)*B12) |
                     ((static_cast<int32_t>(dn) >> 4)*B7) |
                     ((static_cast<int32_t>(dm) >> 4)*B5) |
                     (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}


void Assembler::vmovs(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B6, sd, S0, sm);
}


void Assembler::vmovd(DRegister dd, DRegister dm, Condition cond) {
  EmitVFPddd(cond, B23 | B21 | B20 | B6, dd, D0, dm);
}


bool Assembler::vmovs(SRegister sd, float s_imm, Condition cond) {
  uint32_t imm32 = bit_cast<uint32_t, float>(s_imm);
  if (((imm32 & ((1 << 19) - 1)) == 0) &&
      ((((imm32 >> 25) & ((1 << 6) - 1)) == (1 << 5)) ||
       (((imm32 >> 25) & ((1 << 6) - 1)) == ((1 << 5) -1)))) {
    uint8_t imm8 = ((imm32 >> 31) << 7) | (((imm32 >> 29) & 1) << 6) |
        ((imm32 >> 19) & ((1 << 6) -1));
    EmitVFPsss(cond, B23 | B21 | B20 | ((imm8 >> 4)*B16) | (imm8 & 0xf),
               sd, S0, S0);
    return true;
  }
  return false;
}


bool Assembler::vmovd(DRegister dd, double d_imm, Condition cond) {
  uint64_t imm64 = bit_cast<uint64_t, double>(d_imm);
  if (((imm64 & ((1LL << 48) - 1)) == 0) &&
      ((((imm64 >> 54) & ((1 << 9) - 1)) == (1 << 8)) ||
       (((imm64 >> 54) & ((1 << 9) - 1)) == ((1 << 8) -1)))) {
    uint8_t imm8 = ((imm64 >> 63) << 7) | (((imm64 >> 61) & 1) << 6) |
        ((imm64 >> 48) & ((1 << 6) -1));
    EmitVFPddd(cond, B23 | B21 | B20 | ((imm8 >> 4)*B16) | B8 | (imm8 & 0xf),
               dd, D0, D0);
    return true;
  }
  return false;
}


void Assembler::vadds(SRegister sd, SRegister sn, SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B21 | B20, sd, sn, sm);
}


void Assembler::vaddd(DRegister dd, DRegister dn, DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B21 | B20, dd, dn, dm);
}


void Assembler::vsubs(SRegister sd, SRegister sn, SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B21 | B20 | B6, sd, sn, sm);
}


void Assembler::vsubd(DRegister dd, DRegister dn, DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B21 | B20 | B6, dd, dn, dm);
}


void Assembler::vmuls(SRegister sd, SRegister sn, SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B21, sd, sn, sm);
}


void Assembler::vmuld(DRegister dd, DRegister dn, DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B21, dd, dn, dm);
}


void Assembler::vmlas(SRegister sd, SRegister sn, SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, 0, sd, sn, sm);
}


void Assembler::vmlad(DRegister dd, DRegister dn, DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, 0, dd, dn, dm);
}


void Assembler::vmlss(SRegister sd, SRegister sn, SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B6, sd, sn, sm);
}


void Assembler::vmlsd(DRegister dd, DRegister dn, DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B6, dd, dn, dm);
}


void Assembler::vdivs(SRegister sd, SRegister sn, SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B23, sd, sn, sm);
}


void Assembler::vdivd(DRegister dd, DRegister dn, DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B23, dd, dn, dm);
}


void Assembler::vabss(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B7 | B6, sd, S0, sm);
}


void Assembler::vabsd(DRegister dd, DRegister dm, Condition cond) {
  EmitVFPddd(cond, B23 | B21 | B20 | B7 | B6, dd, D0, dm);
}


void Assembler::vnegs(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B16 | B6, sd, S0, sm);
}


void Assembler::vnegd(DRegister dd, DRegister dm, Condition cond) {
  EmitVFPddd(cond, B23 | B21 | B20 | B16 | B6, dd, D0, dm);
}


void Assembler::vsqrts(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B16 | B7 | B6, sd, S0, sm);
}

void Assembler::vsqrtd(DRegister dd, DRegister dm, Condition cond) {
  EmitVFPddd(cond, B23 | B21 | B20 | B16 | B7 | B6, dd, D0, dm);
}


void Assembler::EmitVFPsd(Condition cond, int32_t opcode,
                          SRegister sd, DRegister dm) {
  ASSERT(sd != kNoSRegister);
  ASSERT(dm != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B11 | B9 | opcode |
                     ((static_cast<int32_t>(sd) & 1)*B22) |
                     ((static_cast<int32_t>(sd) >> 1)*B12) |
                     ((static_cast<int32_t>(dm) >> 4)*B5) |
                     (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}


void Assembler::EmitVFPds(Condition cond, int32_t opcode,
                          DRegister dd, SRegister sm) {
  ASSERT(dd != kNoDRegister);
  ASSERT(sm != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B11 | B9 | opcode |
                     ((static_cast<int32_t>(dd) >> 4)*B22) |
                     ((static_cast<int32_t>(dd) & 0xf)*B12) |
                     ((static_cast<int32_t>(sm) & 1)*B5) |
                     (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}


void Assembler::vcvtsd(SRegister sd, DRegister dm, Condition cond) {
  EmitVFPsd(cond, B23 | B21 | B20 | B18 | B17 | B16 | B8 | B7 | B6, sd, dm);
}


void Assembler::vcvtds(DRegister dd, SRegister sm, Condition cond) {
  EmitVFPds(cond, B23 | B21 | B20 | B18 | B17 | B16 | B7 | B6, dd, sm);
}


void Assembler::vcvtis(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B19 | B18 | B16 | B7 | B6, sd, S0, sm);
}


void Assembler::vcvtid(SRegister sd, DRegister dm, Condition cond) {
  EmitVFPsd(cond, B23 | B21 | B20 | B19 | B18 | B16 | B8 | B7 | B6, sd, dm);
}


void Assembler::vcvtsi(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B19 | B7 | B6, sd, S0, sm);
}


void Assembler::vcvtdi(DRegister dd, SRegister sm, Condition cond) {
  EmitVFPds(cond, B23 | B21 | B20 | B19 | B8 | B7 | B6, dd, sm);
}


void Assembler::vcvtus(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B19 | B18 | B7 | B6, sd, S0, sm);
}


void Assembler::vcvtud(SRegister sd, DRegister dm, Condition cond) {
  EmitVFPsd(cond, B23 | B21 | B20 | B19 | B18 | B8 | B7 | B6, sd, dm);
}


void Assembler::vcvtsu(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B19 | B6, sd, S0, sm);
}


void Assembler::vcvtdu(DRegister dd, SRegister sm, Condition cond) {
  EmitVFPds(cond, B23 | B21 | B20 | B19 | B8 | B6, dd, sm);
}


void Assembler::vcmps(SRegister sd, SRegister sm, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B18 | B6, sd, S0, sm);
}


void Assembler::vcmpd(DRegister dd, DRegister dm, Condition cond) {
  EmitVFPddd(cond, B23 | B21 | B20 | B18 | B6, dd, D0, dm);
}


void Assembler::vcmpsz(SRegister sd, Condition cond) {
  EmitVFPsss(cond, B23 | B21 | B20 | B18 | B16 | B6, sd, S0, S0);
}


void Assembler::vcmpdz(DRegister dd, Condition cond) {
  EmitVFPddd(cond, B23 | B21 | B20 | B18 | B16 | B6, dd, D0, D0);
}


void Assembler::vmstat(Condition cond) {  // VMRS APSR_nzcv, FPSCR
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B23 | B22 | B21 | B20 | B16 |
                     (static_cast<int32_t>(PC)*B12) |
                     B11 | B9 | B4;
  Emit(encoding);
}


void Assembler::svc(uint32_t imm24, Condition cond) {
  ASSERT(cond != kNoCondition);
  ASSERT(imm24 < (1 << 24));
  int32_t encoding = (cond << kConditionShift) | B27 | B26 | B25 | B24 | imm24;
  Emit(encoding);
}


void Assembler::bkpt(uint16_t imm16, Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = (cond << kConditionShift) | B24 | B21 |
                     ((imm16 >> 4) << 8) | B6 | B5 | B4 | (imm16 & 0xf);
  Emit(encoding);
}


void Assembler::b(Label* label, Condition cond) {
  EmitBranch(cond, label, false);
}


void Assembler::bl(Label* label, Condition cond) {
  EmitBranch(cond, label, true);
}


void Assembler::bx(Register rm, Condition cond) {
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B24 | B21 | (0xfff << 8) | B4 |
                     (static_cast<int32_t>(rm) << kRmShift);
  Emit(encoding);
}


void Assembler::blx(Register rm, Condition cond) {
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B24 | B21 | (0xfff << 8) | B5 | B4 |
                     (static_cast<int32_t>(rm) << kRmShift);
  Emit(encoding);
}


void Assembler::mrc(Register rd, int32_t coproc, int32_t opc1,
                    int32_t crn, int32_t crm, int32_t opc2, Condition cond) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);

  // This is all the simulator and disassembler know about.
  ASSERT(coproc == 15);
  ASSERT(opc1 == 0);
  ASSERT(crn == 0);
  ASSERT(crm == 2);
  ASSERT(opc2 == 0);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) |
                     B27 | B26 | B25 | B20 | B4 |
                     ((opc1 & 0x7) << kOpc1Shift) |
                     ((crn & 0xf) << kCRnShift) |
                     ((coproc & 0xf) << kCoprocShift) |
                     ((opc2 & 0x7) << kOpc2Shift) |
                     ((crm & 0xf) << kCRmShift) |
                     (static_cast<int32_t>(rd) << kRdShift);
  Emit(encoding);
}


void Assembler::MarkExceptionHandler(Label* label) {
  EmitType01(AL, 1, TST, 1, PC, R0, ShifterOperand(0));
  Label l;
  b(&l);
  EmitBranch(AL, label, false);
  Bind(&l);
}


void Assembler::Drop(intptr_t stack_elements) {
  ASSERT(stack_elements >= 0);
  if (stack_elements > 0) {
    AddImmediate(SP, SP, stack_elements * kWordSize);
  }
}


// Uses a code sequence that can easily be decoded.
void Assembler::LoadWordFromPoolOffset(Register rd, int32_t offset) {
  ASSERT(rd != PP);
  int32_t offset_mask = 0;
  if (Address::CanHoldLoadOffset(kLoadWord, offset, &offset_mask)) {
    ldr(rd, Address(PP, offset));
  } else {
    int32_t offset_hi = offset & ~offset_mask;  // signed
    uint32_t offset_lo = offset & offset_mask;  // unsigned
    // Inline a simplified version of AddImmediate(rd, PP, offset_hi).
    ShifterOperand shifter_op;
    if (ShifterOperand::CanHold(offset_hi, &shifter_op)) {
      add(rd, PP, shifter_op);
    } else {
      movw(rd, Utils::Low16Bits(offset_hi));
      const uint16_t value_high = Utils::High16Bits(offset_hi);
      if (value_high != 0) {
        movt(rd, value_high);
      }
      add(rd, PP, ShifterOperand(LR));
    }
    ldr(rd, Address(rd, offset_lo));
  }
}


void Assembler::LoadObject(Register rd, const Object& object) {
  // Smi's and VM heap objects are never relocated; do not use object pool.
  if (object.IsSmi()) {
    LoadImmediate(rd, reinterpret_cast<int32_t>(object.raw()));
  } else if (object.InVMHeap()) {
    // Make sure that class CallPattern is able to decode this load immediate.
    const int32_t object_raw = reinterpret_cast<int32_t>(object.raw());
    movw(rd, Utils::Low16Bits(object_raw));
    const uint16_t value_high = Utils::High16Bits(object_raw);
    if (value_high != 0) {
      movt(rd, value_high);
    }
  } else {
    // Make sure that class CallPattern is able to decode this load from the
    // object pool.
    const int32_t offset =
        Array::data_offset() + 4*AddObject(object) - kHeapObjectTag;
    LoadWordFromPoolOffset(rd, offset);
  }
}


void Assembler::PushObject(const Object& object) {
  LoadObject(IP, object);
  Push(IP);
}


void Assembler::CompareObject(Register rn, const Object& object) {
  ASSERT(rn != IP);
  LoadObject(IP, object);
  cmp(rn, ShifterOperand(IP));
}


// Preserves object and value registers.
void Assembler::StoreIntoObjectFilterNoSmi(Register object,
                                           Register value,
                                           Label* no_update) {
  COMPILE_ASSERT((kNewObjectAlignmentOffset == kWordSize) &&
                 (kOldObjectAlignmentOffset == 0), young_alignment);

  // Write-barrier triggers if the value is in the new space (has bit set) and
  // the object is in the old space (has bit cleared).
  // To check that, we compute value & ~object and skip the write barrier
  // if the bit is not set. We can't destroy the object.
  bic(IP, value, ShifterOperand(object));
  tst(IP, ShifterOperand(kNewObjectAlignmentOffset));
  b(no_update, EQ);
}


// Preserves object and value registers.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* no_update) {
  // For the value we are only interested in the new/old bit and the tag bit.
  // And the new bit with the tag bit. The resulting bit will be 0 for a Smi.
  and_(IP, value, ShifterOperand(value, LSL, kObjectAlignmentLog2 - 1));
  // And the result with the negated space bit of the object.
  bic(IP, IP, ShifterOperand(object));
  tst(IP, ShifterOperand(kNewObjectAlignmentOffset));
  b(no_update, EQ);
}


void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                bool can_value_be_smi) {
  ASSERT(object != value);
  str(value, dest);
  Label done;
  if (can_value_be_smi) {
    StoreIntoObjectFilter(object, value, &done);
  } else {
    StoreIntoObjectFilterNoSmi(object, value, &done);
  }
  // A store buffer update is required.
  if (value != R0) Push(R0);  // Preserve R0.
  if (object != R0) {
    mov(R0, ShifterOperand(object));
  }
  BranchLink(&StubCode::UpdateStoreBufferLabel());
  if (value != R0) Pop(R0);  // Restore R0.
  Bind(&done);
}


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  str(value, dest);
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value, &done);
  Stop("Store buffer update is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  ASSERT(value.IsSmi() || value.InVMHeap() ||
         (value.IsOld() && value.IsNotTemporaryScopedHandle()));
  // No store buffer update.
  LoadObject(IP, value);
  str(IP, dest);
}


void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(RawObject::kClassIdTagBit == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset = Object::tags_offset() +
      RawObject::kClassIdTagBit / kBitsPerByte;
  ldrh(result, FieldAddress(object, class_id_offset));
}


void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);
  ldr(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  LoadFromOffset(kLoadWord, result, result, table_offset_in_isolate);
  ldr(result, Address(result, class_id, LSL, 2));
}


void Assembler::LoadClass(Register result, Register object, Register scratch) {
  ASSERT(scratch != result);
  LoadClassId(scratch, object);

  ldr(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  LoadFromOffset(kLoadWord, result, result, table_offset_in_isolate);
  ldr(result, Address(result, scratch, LSL, 2));
}


void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  LoadClassId(scratch, object);
  CompareImmediate(scratch, class_id);
}


void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  int bound_pc = buffer_.Size();
  while (label->IsLinked()) {
    int32_t position = label->Position();
    int32_t next = buffer_.Load<int32_t>(position);
    int32_t encoded = Assembler::EncodeBranchOffset(bound_pc - position, next);
    buffer_.Store<int32_t>(position, encoded);
    label->position_ = Assembler::DecodeBranchOffset(next);
  }
  label->BindTo(bound_pc);
}


bool Address::CanHoldLoadOffset(LoadOperandType type,
                                int32_t offset,
                                int32_t* offset_mask) {
  switch (type) {
    case kLoadSignedByte:
    case kLoadSignedHalfword:
    case kLoadUnsignedHalfword:
    case kLoadWordPair: {
      *offset_mask = 0xff;
      return Utils::IsAbsoluteUint(8, offset);  // Addressing mode 3.
    }
    case kLoadUnsignedByte:
    case kLoadWord: {
      *offset_mask = 0xfff;
      return Utils::IsAbsoluteUint(12, offset);  // Addressing mode 2.
    }
    case kLoadSWord:
    case kLoadDWord: {
      *offset_mask = 0x3ff;
      return Utils::IsAbsoluteUint(10, offset);  // VFP addressing mode.
    }
    default: {
      UNREACHABLE();
      return false;
    }
  }
}


bool Address::CanHoldStoreOffset(StoreOperandType type,
                                 int32_t offset,
                                 int32_t* offset_mask) {
  switch (type) {
    case kStoreHalfword:
    case kStoreWordPair: {
      *offset_mask = 0xff;
      return Utils::IsAbsoluteUint(8, offset);  // Addressing mode 3.
    }
    case kStoreByte:
    case kStoreWord: {
      *offset_mask = 0xfff;
      return Utils::IsAbsoluteUint(12, offset);  // Addressing mode 2.
    }
    case kStoreSWord:
    case kStoreDWord: {
      *offset_mask = 0x3ff;
      return Utils::IsAbsoluteUint(10, offset);  // VFP addressing mode.
    }
    default: {
      UNREACHABLE();
      return false;
    }
  }
}


void Assembler::Push(Register rd, Condition cond) {
  str(rd, Address(SP, -kWordSize, Address::PreIndex), cond);
}


void Assembler::Pop(Register rd, Condition cond) {
  ldr(rd, Address(SP, kWordSize, Address::PostIndex), cond);
}


void Assembler::PushList(RegList regs, Condition cond) {
  stm(DB_W, SP, regs, cond);
}


void Assembler::PopList(RegList regs, Condition cond) {
  ldm(IA_W, SP, regs, cond);
}


void Assembler::Mov(Register rd, Register rm, Condition cond) {
  if (rd != rm) {
    mov(rd, ShifterOperand(rm), cond);
  }
}


void Assembler::Lsl(Register rd, Register rm, uint32_t shift_imm,
                    Condition cond) {
  ASSERT(shift_imm != 0);  // Do not use Lsl if no shift is wanted.
  mov(rd, ShifterOperand(rm, LSL, shift_imm), cond);
}


void Assembler::Lsr(Register rd, Register rm, uint32_t shift_imm,
                    Condition cond) {
  ASSERT(shift_imm != 0);  // Do not use Lsr if no shift is wanted.
  if (shift_imm == 32) shift_imm = 0;  // Comply to UAL syntax.
  mov(rd, ShifterOperand(rm, LSR, shift_imm), cond);
}


void Assembler::Asr(Register rd, Register rm, uint32_t shift_imm,
                    Condition cond) {
  ASSERT(shift_imm != 0);  // Do not use Asr if no shift is wanted.
  if (shift_imm == 32) shift_imm = 0;  // Comply to UAL syntax.
  mov(rd, ShifterOperand(rm, ASR, shift_imm), cond);
}


void Assembler::Ror(Register rd, Register rm, uint32_t shift_imm,
                    Condition cond) {
  ASSERT(shift_imm != 0);  // Use Rrx instruction.
  mov(rd, ShifterOperand(rm, ROR, shift_imm), cond);
}


void Assembler::Rrx(Register rd, Register rm, Condition cond) {
  mov(rd, ShifterOperand(rm, ROR, 0), cond);
}


void Assembler::Branch(const ExternalLabel* label, Condition cond) {
  LoadImmediate(IP, label->address(), cond);  // Address is never patched.
  bx(IP, cond);
}


void Assembler::BranchPatchable(const ExternalLabel* label) {
  // Use a fixed size code sequence, since a function prologue may be patched
  // with this branch sequence.
  // Contrarily to BranchLinkPatchable, BranchPatchable requires an instruction
  // cache flush upon patching.
  movw(IP, Utils::Low16Bits(label->address()));
  movt(IP, Utils::High16Bits(label->address()));
  bx(IP);
}


void Assembler::BranchLink(const ExternalLabel* label) {
  LoadImmediate(IP, label->address());  // Target address is never patched.
  blx(IP);  // Use blx instruction so that the return branch prediction works.
}


void Assembler::BranchLinkPatchable(const ExternalLabel* label) {
  // Make sure that class CallPattern is able to patch the label referred
  // to by this code sequence.
  // For added code robustness, use 'blx lr' in a patchable sequence and
  // use 'blx ip' in a non-patchable sequence (see other BranchLink flavors).
  const int32_t offset =
      Array::data_offset() + 4*AddExternalLabel(label) - kHeapObjectTag;
  LoadWordFromPoolOffset(LR, offset);
  blx(LR);  // Use blx instruction so that the return branch prediction works.
}


void Assembler::BranchLinkStore(const ExternalLabel* label, Address ad) {
  // TODO(regis): Revisit this code sequence.
  LoadImmediate(IP, label->address());  // Target address is never patched.
  str(PC, ad);
  blx(IP);  // Use blx instruction so that the return branch prediction works.
}


void Assembler::BranchLinkOffset(Register base, int32_t offset) {
  ASSERT(base != PC);
  ASSERT(base != IP);
  LoadFromOffset(kLoadWord, IP, base, offset);
  blx(IP);  // Use blx instruction so that the return branch prediction works.
}


void Assembler::LoadImmediate(Register rd, int32_t value, Condition cond) {
  ShifterOperand shifter_op;
  if (ShifterOperand::CanHold(value, &shifter_op)) {
    mov(rd, shifter_op, cond);
  } else if (ShifterOperand::CanHold(~value, &shifter_op)) {
    mvn(rd, shifter_op, cond);
  } else {
    movw(rd, Utils::Low16Bits(value), cond);
    const uint16_t value_high = Utils::High16Bits(value);
    if (value_high != 0) {
      movt(rd, value_high, cond);
    }
  }
}


void Assembler::LoadSImmediate(SRegister sd, float value, Condition cond) {
  if (!vmovs(sd, value, cond)) {
    LoadImmediate(IP, bit_cast<int32_t, float>(value), cond);
    vmovsr(sd, IP, cond);
  }
}


void Assembler::LoadDImmediate(DRegister dd,
                               double value,
                               Register scratch,
                               Condition cond) {
  // TODO(regis): Revisit this code sequence.
  ASSERT(scratch != PC);
  ASSERT(scratch != IP);
  if (!vmovd(dd, value, cond)) {
    // A scratch register and IP are needed to load an arbitrary double.
    ASSERT(scratch != kNoRegister);
    int64_t imm64 = bit_cast<int64_t, double>(value);
    LoadImmediate(IP, Utils::Low32Bits(imm64), cond);
    LoadImmediate(scratch, Utils::High32Bits(imm64), cond);
    vmovdrr(dd, IP, scratch, cond);
  }
}


void Assembler::LoadFromOffset(LoadOperandType type,
                               Register reg,
                               Register base,
                               int32_t offset,
                               Condition cond) {
  int32_t offset_mask = 0;
  if (!Address::CanHoldLoadOffset(type, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  switch (type) {
    case kLoadSignedByte:
      ldrsb(reg, Address(base, offset), cond);
      break;
    case kLoadUnsignedByte:
      ldrb(reg, Address(base, offset), cond);
      break;
    case kLoadSignedHalfword:
      ldrsh(reg, Address(base, offset), cond);
      break;
    case kLoadUnsignedHalfword:
      ldrh(reg, Address(base, offset), cond);
      break;
    case kLoadWord:
      ldr(reg, Address(base, offset), cond);
      break;
    case kLoadWordPair:
      ldrd(reg, Address(base, offset), cond);
      break;
    default:
      UNREACHABLE();
  }
}


void Assembler::StoreToOffset(StoreOperandType type,
                              Register reg,
                              Register base,
                              int32_t offset,
                              Condition cond) {
  int32_t offset_mask = 0;
  if (!Address::CanHoldStoreOffset(type, offset, &offset_mask)) {
    ASSERT(reg != IP);
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  switch (type) {
    case kStoreByte:
      strb(reg, Address(base, offset), cond);
      break;
    case kStoreHalfword:
      strh(reg, Address(base, offset), cond);
      break;
    case kStoreWord:
      str(reg, Address(base, offset), cond);
      break;
    case kStoreWordPair:
      strd(reg, Address(base, offset), cond);
      break;
    default:
      UNREACHABLE();
  }
}


void Assembler::LoadSFromOffset(SRegister reg,
                                Register base,
                                int32_t offset,
                                Condition cond) {
  int32_t offset_mask = 0;
  if (!Address::CanHoldLoadOffset(kLoadSWord, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  vldrs(reg, Address(base, offset), cond);
}


void Assembler::StoreSToOffset(SRegister reg,
                               Register base,
                               int32_t offset,
                               Condition cond) {
  int32_t offset_mask = 0;
  if (!Address::CanHoldStoreOffset(kStoreSWord, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  vstrs(reg, Address(base, offset), cond);
}


void Assembler::LoadDFromOffset(DRegister reg,
                                Register base,
                                int32_t offset,
                                Condition cond) {
  int32_t offset_mask = 0;
  if (!Address::CanHoldLoadOffset(kLoadDWord, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  vldrd(reg, Address(base, offset), cond);
}


void Assembler::StoreDToOffset(DRegister reg,
                               Register base,
                               int32_t offset,
                               Condition cond) {
  int32_t offset_mask = 0;
  if (!Address::CanHoldStoreOffset(kStoreDWord, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  vstrd(reg, Address(base, offset), cond);
}


void Assembler::AddImmediate(Register rd, int32_t value, Condition cond) {
  AddImmediate(rd, rd, value, cond);
}


void Assembler::AddImmediate(Register rd, Register rn, int32_t value,
                            Condition cond) {
  if (value == 0) {
    if (rd != rn) {
      mov(rd, ShifterOperand(rn), cond);
    }
    return;
  }
  // We prefer to select the shorter code sequence rather than selecting add for
  // positive values and sub for negatives ones, which would slightly improve
  // the readability of generated code for some constants.
  ShifterOperand shifter_op;
  if (ShifterOperand::CanHold(value, &shifter_op)) {
    add(rd, rn, shifter_op, cond);
  } else if (ShifterOperand::CanHold(-value, &shifter_op)) {
    sub(rd, rn, shifter_op, cond);
  } else {
    ASSERT(rn != IP);
    if (ShifterOperand::CanHold(~value, &shifter_op)) {
      mvn(IP, shifter_op, cond);
      add(rd, rn, ShifterOperand(IP), cond);
    } else if (ShifterOperand::CanHold(~(-value), &shifter_op)) {
      mvn(IP, shifter_op, cond);
      sub(rd, rn, ShifterOperand(IP), cond);
    } else {
      movw(IP, Utils::Low16Bits(value), cond);
      const uint16_t value_high = Utils::High16Bits(value);
      if (value_high != 0) {
        movt(IP, value_high, cond);
      }
      add(rd, rn, ShifterOperand(IP), cond);
    }
  }
}


void Assembler::AddImmediateSetFlags(Register rd, Register rn, int32_t value,
                                    Condition cond) {
  ShifterOperand shifter_op;
  if (ShifterOperand::CanHold(value, &shifter_op)) {
    adds(rd, rn, shifter_op, cond);
  } else if (ShifterOperand::CanHold(-value, &shifter_op)) {
    subs(rd, rn, shifter_op, cond);
  } else {
    ASSERT(rn != IP);
    if (ShifterOperand::CanHold(~value, &shifter_op)) {
      mvn(IP, shifter_op, cond);
      adds(rd, rn, ShifterOperand(IP), cond);
    } else if (ShifterOperand::CanHold(~(-value), &shifter_op)) {
      mvn(IP, shifter_op, cond);
      subs(rd, rn, ShifterOperand(IP), cond);
    } else {
      movw(IP, Utils::Low16Bits(value), cond);
      const uint16_t value_high = Utils::High16Bits(value);
      if (value_high != 0) {
        movt(IP, value_high, cond);
      }
      adds(rd, rn, ShifterOperand(IP), cond);
    }
  }
}


void Assembler::AddImmediateWithCarry(Register rd, Register rn, int32_t value,
                                     Condition cond) {
  ShifterOperand shifter_op;
  if (ShifterOperand::CanHold(value, &shifter_op)) {
    adc(rd, rn, shifter_op, cond);
  } else if (ShifterOperand::CanHold(-value - 1, &shifter_op)) {
    sbc(rd, rn, shifter_op, cond);
  } else {
    ASSERT(rn != IP);
    if (ShifterOperand::CanHold(~value, &shifter_op)) {
      mvn(IP, shifter_op, cond);
      adc(rd, rn, ShifterOperand(IP), cond);
    } else if (ShifterOperand::CanHold(~(-value - 1), &shifter_op)) {
      mvn(IP, shifter_op, cond);
      sbc(rd, rn, ShifterOperand(IP), cond);
    } else {
      movw(IP, Utils::Low16Bits(value), cond);
      const uint16_t value_high = Utils::High16Bits(value);
      if (value_high != 0) {
        movt(IP, value_high, cond);
      }
      adc(rd, rn, ShifterOperand(IP), cond);
    }
  }
}


void Assembler::CompareImmediate(Register rn, int32_t value, Condition cond) {
  ShifterOperand shifter_op;
  if (ShifterOperand::CanHold(value, &shifter_op)) {
    cmp(rn, shifter_op, cond);
  } else {
    ASSERT(rn != IP);
    LoadImmediate(IP, value, cond);
    cmp(rn, ShifterOperand(IP), cond);
  }
}


static int NumRegsBelowFP(RegList regs) {
  int count = 0;
  for (int i = 0; i < FP; i++) {
    if ((regs & (1 << i)) != 0) {
      count++;
    }
  }
  return count;
}


void Assembler::EnterFrame(RegList regs, intptr_t frame_size) {
  if (prologue_offset_ == -1) {
    prologue_offset_ = CodeSize();
  }
  PushList(regs);
  if ((regs & (1 << FP)) != 0) {
    // Set FP to the saved previous FP.
    add(FP, SP, ShifterOperand(4 * NumRegsBelowFP(regs)));
  }
  AddImmediate(SP, -frame_size);
}


void Assembler::LeaveFrame(RegList regs) {
  ASSERT((regs & (1 << PC)) == 0);  // Must not pop PC.
  if ((regs & (1 << FP)) != 0) {
    // Use FP to set SP.
    sub(SP, FP, ShifterOperand(4 * NumRegsBelowFP(regs)));
  }
  PopList(regs);
}


void Assembler::Ret() {
  bx(LR);
}


void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  AddImmediate(SP, -frame_space);
  if (OS::ActivationFrameAlignment() > 0) {
    bic(SP, SP, ShifterOperand(OS::ActivationFrameAlignment() - 1));
  }
}


void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  // Preserve volatile CPU registers.
  EnterFrame(kDartVolatileCpuRegs | (1 << FP) | (1 << LR), 0);

  // Preserve all volatile FPU registers.
  vstmd(DB_W, SP, kDartFirstVolatileFpuReg, kDartLastVolatileFpuReg);

  ReserveAlignedFrameSpace(frame_space);
}


void Assembler::LeaveCallRuntimeFrame() {
  // SP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  const intptr_t kPushedRegistersSize =
      kDartVolatileCpuRegCount * kWordSize +
      kDartVolatileFpuRegCount * 2 * kWordSize;
  AddImmediate(SP, FP, -kPushedRegistersSize);

  // Restore all volatile FPU registers.
  vldmd(IA_W, SP, kDartFirstVolatileFpuReg, kDartLastVolatileFpuReg);

  // Restore volatile CPU registers.
  LeaveFrame(kDartVolatileCpuRegs | (1 << FP) | (1 << LR));
}


void Assembler::CallRuntime(const RuntimeEntry& entry) {
  entry.Call(this);
}


void Assembler::EnterDartFrame(intptr_t frame_size) {
  const intptr_t offset = CodeSize();
  // Save PC in frame for fast identification of corresponding code.
  // Note that callee-saved registers can be added to the register list.
  EnterFrame((1 << PP) | (1 << FP) | (1 << LR) | (1 << PC), 0);

  if (offset != 0) {
    // Adjust saved PC for any intrinsic code that could have been generated
    // before a frame is created. Use PP as temp register.
    ldr(PP, Address(FP, 2 * kWordSize));
    AddImmediate(PP, PP, -offset);
    str(PP, Address(FP, 2 * kWordSize));
  }

  // Setup pool pointer for this dart function.
  const intptr_t object_pool_pc_dist =
     Instructions::HeaderSize() - Instructions::object_pool_offset() +
     CodeSize() + Instr::kPCReadOffset;
  ldr(PP, Address(PC, -object_pool_pc_dist));

  // Reserve space for locals.
  AddImmediate(SP, -frame_size);
}


void Assembler::LeaveDartFrame() {
  LeaveFrame((1 << PP) | (1 << FP) | (1 << LR));
  // Adjust SP for PC pushed in EnterDartFrame.
  AddImmediate(SP, kWordSize);
}


void Assembler::EnterStubFrame(bool uses_pp) {
  // Push 0 as saved PC for stub frames.
  mov(IP, ShifterOperand(LR));
  mov(LR, ShifterOperand(0));
  RegList regs = (1 << FP) | (1 << IP) | (1 << LR);
  if (uses_pp) {
    regs |= (1 << PP);
  }
  EnterFrame(regs, 0);
  if (uses_pp) {
    // Setup pool pointer for this stub.
    const intptr_t object_pool_pc_dist =
       Instructions::HeaderSize() - Instructions::object_pool_offset() +
       CodeSize() + Instr::kPCReadOffset;
    ldr(PP, Address(PC, -object_pool_pc_dist));
  }
}


void Assembler::LeaveStubFrame(bool uses_pp) {
  RegList regs = (1 << FP) | (1 << LR);
  if (uses_pp) {
    regs |= (1 << PP);
  }
  LeaveFrame(regs);
  // Adjust SP for null PC pushed in EnterStubFrame.
  AddImmediate(SP, kWordSize);
}


void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            bool near_jump,
                            Register instance_reg) {
  UNIMPLEMENTED();
}


void Assembler::Stop(const char* message) {
  if (FLAG_print_stop_message) {
    PushList((1 << R0) | (1 << IP) | (1 << LR));  // Preserve R0, IP, LR.
    LoadImmediate(R0, reinterpret_cast<int32_t>(message));
    // PrintStopMessage() preserves all registers.
    BranchLink(&StubCode::PrintStopMessageLabel());  // Passing message in R0.
    PopList((1 << R0) | (1 << IP) | (1 << LR));  // Restore R0, IP, LR.
  }
  // Emit the message address before the svc instruction, so that we can
  // 'unstop' and continue execution in the simulator or jump to the next
  // instruction in gdb.
  Label stop;
  b(&stop);
  Emit(reinterpret_cast<int32_t>(message));
  Bind(&stop);
  svc(kStopMessageSvcCode);
}


int32_t Assembler::EncodeBranchOffset(int32_t offset, int32_t inst) {
  // The offset is off by 8 due to the way the ARM CPUs read PC.
  offset -= 8;
  ASSERT(Utils::IsAligned(offset, 4));
  ASSERT(Utils::IsInt(Utils::CountOneBits(kBranchOffsetMask), offset));

  // Properly preserve only the bits supported in the instruction.
  offset >>= 2;
  offset &= kBranchOffsetMask;
  return (inst & ~kBranchOffsetMask) | offset;
}


int Assembler::DecodeBranchOffset(int32_t inst) {
  // Sign-extend, left-shift by 2, then add 8.
  return ((((inst & kBranchOffsetMask) << 8) >> 6) + 8);
}


int32_t Assembler::AddObject(const Object& obj) {
  ASSERT(obj.IsNotTemporaryScopedHandle());
  ASSERT(obj.IsOld());
  if (object_pool_.IsNull()) {
    // The object pool cannot be used in the vm isolate.
    ASSERT(Isolate::Current() != Dart::vm_isolate());
    object_pool_ = GrowableObjectArray::New(Heap::kOld);
  }
  for (int i = 0; i < object_pool_.Length(); i++) {
    if (object_pool_.At(i) == obj.raw()) {
      return i;
    }
  }
  object_pool_.Add(obj, Heap::kOld);
  return object_pool_.Length() - 1;
}


int32_t Assembler::AddExternalLabel(const ExternalLabel* label) {
  if (object_pool_.IsNull()) {
    // The object pool cannot be used in the vm isolate.
    ASSERT(Isolate::Current() != Dart::vm_isolate());
    object_pool_ = GrowableObjectArray::New(Heap::kOld);
  }
  const word address = label->address();
  ASSERT(Utils::IsAligned(address, 4));
  // The address is stored in the object array as a RawSmi.
  const Smi& smi = Smi::Handle(Smi::New(address >> kSmiTagShift));
  // Do not reuse an existing entry, since each reference may be patched
  // independently.
  object_pool_.Add(smi, Heap::kOld);
  return object_pool_.Length() - 1;
}


static const char* cpu_reg_names[kNumberOfCpuRegisters] = {
  "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
  "r8", "ctx", "pp", "fp", "ip", "sp", "lr", "pc",
};


const char* Assembler::RegisterName(Register reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
  return cpu_reg_names[reg];
}


static const char* fpu_reg_names[kNumberOfFpuRegisters] = {
  "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7",
  "d8", "d9", "d10", "d11", "d12", "d13", "d14", "d15",
#ifdef VFPv3_D32
  "d16", "d17", "d18", "d19", "d20", "d21", "d22", "d23",
  "d24", "d25", "d26", "d27", "d28", "d29", "d30", "d31",
#endif
};


const char* Assembler::FpuRegisterName(FpuRegister reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfFpuRegisters));
  return fpu_reg_names[reg];
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM

