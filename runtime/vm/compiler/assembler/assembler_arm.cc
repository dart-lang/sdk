// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_ARM)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/cpu.h"
#include "vm/instructions.h"

// An extra check since we are assuming the existence of /proc/cpuinfo below.
#if !defined(USING_SIMULATOR) && !defined(__linux__) && !defined(ANDROID) &&   \
    !defined(HOST_OS_IOS) && !defined(HOST_OS_MACOS)
#error ARM cross-compile only supported on Linux, Android, iOS, and Mac
#endif

// For use by LR related macros (e.g. CLOBBERS_LR).
#define __ this->

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, inline_alloc);
DECLARE_FLAG(bool, precompiled_mode);
DECLARE_FLAG(bool, use_slow_path);

namespace compiler {

Assembler::Assembler(ObjectPoolBuilder* object_pool_builder,
                     bool use_far_branches)
    : AssemblerBase(object_pool_builder),
      use_far_branches_(use_far_branches),
      constant_pool_allowed_(false) {
  generate_invoke_write_barrier_wrapper_ = [&](Condition cond, Register reg) {
    Call(
        Address(THR, target::Thread::write_barrier_wrappers_thread_offset(reg)),
        cond);
  };
  generate_invoke_array_write_barrier_ = [&](Condition cond) {
    Call(Address(THR, target::Thread::array_write_barrier_entry_point_offset()),
         cond);
  };
}

uint32_t Address::encoding3() const {
  if (kind_ == Immediate) {
    uint32_t offset = encoding_ & kOffset12Mask;
    ASSERT(offset < 256);
    return (encoding_ & ~kOffset12Mask) | B22 | ((offset & 0xf0) << 4) |
           (offset & 0xf);
  }
  ASSERT(kind_ == IndexRegister);
  return encoding_;
}

uint32_t Address::vencoding() const {
  ASSERT(kind_ == Immediate);
  uint32_t offset = encoding_ & kOffset12Mask;
  ASSERT(offset < (1 << 10));           // In the range 0 to +1020.
  ASSERT(Utils::IsAligned(offset, 4));  // Multiple of 4.
  int mode = encoding_ & ((8 | 4 | 1) << 21);
  ASSERT((mode == Offset) || (mode == NegOffset));
  uint32_t vencoding = (encoding_ & (0xf << kRnShift)) | (offset >> 2);
  if (mode == Offset) {
    vencoding |= 1 << 23;
  }
  return vencoding;
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
                           Operand o) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding =
      static_cast<int32_t>(cond) << kConditionShift | type << kTypeShift |
      static_cast<int32_t>(opcode) << kOpcodeShift | set_cc << kSShift |
      ArmEncode::Rn(rn) | ArmEncode::Rd(rd) | o.encoding();
  Emit(encoding);
}

void Assembler::EmitType5(Condition cond, int32_t offset, bool link) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     5 << kTypeShift | (link ? 1 : 0) << kLinkShift;
  BailoutIfInvalidBranchOffset(offset);
  Emit(Assembler::EncodeBranchOffset(offset, encoding));
}

void Assembler::EmitMemOp(Condition cond,
                          bool load,
                          bool byte,
                          Register rd,
                          Address ad) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);
  // Unpredictable, illegal on some microarchitectures.
  ASSERT(!ad.has_writeback() || (ad.rn() != rd));

  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B26 |
                     (ad.kind() == Address::Immediate ? 0 : B25) |
                     (load ? L : 0) | (byte ? B : 0) | ArmEncode::Rd(rd) |
                     ad.encoding();
  Emit(encoding);
}

void Assembler::EmitMemOpAddressMode3(Condition cond,
                                      int32_t mode,
                                      Register rd,
                                      Address ad) {
  ASSERT(rd != kNoRegister);
  ASSERT(cond != kNoCondition);
  // Unpredictable, illegal on some microarchitectures.
  ASSERT(!ad.has_writeback() || (ad.rn() != rd));

  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | mode |
                     ArmEncode::Rd(rd) | ad.encoding3();
  Emit(encoding);
}

void Assembler::EmitMultiMemOp(Condition cond,
                               BlockAddressMode am,
                               bool load,
                               Register base,
                               RegList regs) {
  ASSERT(base != kNoRegister);
  ASSERT(cond != kNoCondition);
  // Unpredictable, illegal on some microarchitectures.
  ASSERT(!Address::has_writeback(am) || !(regs & (1 << base)));
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     am | (load ? L : 0) | ArmEncode::Rn(base) | regs;
  Emit(encoding);
}

void Assembler::EmitShiftImmediate(Condition cond,
                                   Shift opcode,
                                   Register rd,
                                   Register rm,
                                   Operand o) {
  ASSERT(cond != kNoCondition);
  ASSERT(o.type() == 1);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     static_cast<int32_t>(MOV) << kOpcodeShift |
                     ArmEncode::Rd(rd) | o.encoding() << kShiftImmShift |
                     static_cast<int32_t>(opcode) << kShiftShift |
                     static_cast<int32_t>(rm);
  Emit(encoding);
}

void Assembler::EmitShiftRegister(Condition cond,
                                  Shift opcode,
                                  Register rd,
                                  Register rm,
                                  Operand o) {
  ASSERT(cond != kNoCondition);
  ASSERT(o.type() == 0);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift |
                     static_cast<int32_t>(MOV) << kOpcodeShift |
                     ArmEncode::Rd(rd) | o.encoding() << kShiftRegisterShift |
                     static_cast<int32_t>(opcode) << kShiftShift | B4 |
                     static_cast<int32_t>(rm);
  Emit(encoding);
}

void Assembler::and_(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), AND, 0, rn, rd, o);
}

void Assembler::ands(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), AND, 1, rn, rd, o);
}

void Assembler::eor(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), EOR, 0, rn, rd, o);
}

void Assembler::sub(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), SUB, 0, rn, rd, o);
}

void Assembler::rsb(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), RSB, 0, rn, rd, o);
}

void Assembler::rsbs(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), RSB, 1, rn, rd, o);
}

void Assembler::add(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), ADD, 0, rn, rd, o);
}

void Assembler::adds(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), ADD, 1, rn, rd, o);
}

void Assembler::subs(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), SUB, 1, rn, rd, o);
}

void Assembler::adc(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), ADC, 0, rn, rd, o);
}

void Assembler::adcs(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), ADC, 1, rn, rd, o);
}

void Assembler::sbc(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), SBC, 0, rn, rd, o);
}

void Assembler::sbcs(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), SBC, 1, rn, rd, o);
}

void Assembler::rsc(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), RSC, 0, rn, rd, o);
}

void Assembler::tst(Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), TST, 1, rn, R0, o);
}

void Assembler::teq(Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), TEQ, 1, rn, R0, o);
}

void Assembler::cmp(Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), CMP, 1, rn, R0, o);
}

void Assembler::cmn(Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), CMN, 1, rn, R0, o);
}

void Assembler::orr(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), ORR, 0, rn, rd, o);
}

void Assembler::orrs(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), ORR, 1, rn, rd, o);
}

void Assembler::mov(Register rd, Operand o, Condition cond) {
  EmitType01(cond, o.type(), MOV, 0, R0, rd, o);
}

void Assembler::movs(Register rd, Operand o, Condition cond) {
  EmitType01(cond, o.type(), MOV, 1, R0, rd, o);
}

void Assembler::bic(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), BIC, 0, rn, rd, o);
}

void Assembler::bics(Register rd, Register rn, Operand o, Condition cond) {
  EmitType01(cond, o.type(), BIC, 1, rn, rd, o);
}

void Assembler::mvn(Register rd, Operand o, Condition cond) {
  EmitType01(cond, o.type(), MVN, 0, R0, rd, o);
}

void Assembler::mvns(Register rd, Operand o, Condition cond) {
  EmitType01(cond, o.type(), MVN, 1, R0, rd, o);
}

void Assembler::clz(Register rd, Register rm, Condition cond) {
  ASSERT(rd != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(rd != PC);
  ASSERT(rm != PC);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B24 |
                     B22 | B21 | (0xf << 16) | ArmEncode::Rd(rd) | (0xf << 8) |
                     B4 | static_cast<int32_t>(rm);
  Emit(encoding);
}

void Assembler::rbit(Register rd, Register rm, Condition cond) {
  ASSERT(rd != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(rd != PC);
  ASSERT(rm != PC);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B26 |
                     B25 | B23 | B22 | B21 | B20 | (0xf << 16) |
                     ArmEncode::Rd(rd) | (0xf << 8) | B5 | B4 |
                     static_cast<int32_t>(rm);
  Emit(encoding);
}

void Assembler::movw(Register rd, uint16_t imm16, Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift | B25 | B24 |
                     ((imm16 >> 12) << 16) | ArmEncode::Rd(rd) |
                     (imm16 & 0xfff);
  Emit(encoding);
}

void Assembler::movt(Register rd, uint16_t imm16, Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = static_cast<int32_t>(cond) << kConditionShift | B25 | B24 |
                     B22 | ((imm16 >> 12) << 16) | ArmEncode::Rd(rd) |
                     (imm16 & 0xfff);
  Emit(encoding);
}

void Assembler::EmitMulOp(Condition cond,
                          int32_t opcode,
                          Register rd,
                          Register rn,
                          Register rm,
                          Register rs) {
  ASSERT(rd != kNoRegister);
  ASSERT(rn != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(rs != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = opcode | (static_cast<int32_t>(cond) << kConditionShift) |
                     ArmEncode::Rn(rn) | ArmEncode::Rd(rd) | ArmEncode::Rs(rs) |
                     B7 | B4 | ArmEncode::Rm(rm);
  Emit(encoding);
}

void Assembler::mul(Register rd, Register rn, Register rm, Condition cond) {
  // Assembler registers rd, rn, rm are encoded as rn, rm, rs.
  EmitMulOp(cond, 0, R0, rd, rn, rm);
}

// Like mul, but sets condition flags.
void Assembler::muls(Register rd, Register rn, Register rm, Condition cond) {
  EmitMulOp(cond, B20, R0, rd, rn, rm);
}

void Assembler::mla(Register rd,
                    Register rn,
                    Register rm,
                    Register ra,
                    Condition cond) {
  // rd <- ra + rn * rm.
  // Assembler registers rd, rn, rm, ra are encoded as rn, rm, rs, rd.
  EmitMulOp(cond, B21, ra, rd, rn, rm);
}

void Assembler::mls(Register rd,
                    Register rn,
                    Register rm,
                    Register ra,
                    Condition cond) {
  // rd <- ra - rn * rm.
  // Assembler registers rd, rn, rm, ra are encoded as rn, rm, rs, rd.
  EmitMulOp(cond, B22 | B21, ra, rd, rn, rm);
}

void Assembler::smull(Register rd_lo,
                      Register rd_hi,
                      Register rn,
                      Register rm,
                      Condition cond) {
  // Assembler registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
  EmitMulOp(cond, B23 | B22, rd_lo, rd_hi, rn, rm);
}

void Assembler::umull(Register rd_lo,
                      Register rd_hi,
                      Register rn,
                      Register rm,
                      Condition cond) {
  // Assembler registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
  EmitMulOp(cond, B23, rd_lo, rd_hi, rn, rm);
}

void Assembler::umlal(Register rd_lo,
                      Register rd_hi,
                      Register rn,
                      Register rm,
                      Condition cond) {
  // Assembler registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
  EmitMulOp(cond, B23 | B21, rd_lo, rd_hi, rn, rm);
}

void Assembler::umaal(Register rd_lo,
                      Register rd_hi,
                      Register rn,
                      Register rm) {
  ASSERT(rd_lo != IP);
  ASSERT(rd_hi != IP);
  ASSERT(rn != IP);
  ASSERT(rm != IP);
  // Assembler registers rd_lo, rd_hi, rn, rm are encoded as rd, rn, rm, rs.
  EmitMulOp(AL, B22, rd_lo, rd_hi, rn, rm);
}

void Assembler::EmitDivOp(Condition cond,
                          int32_t opcode,
                          Register rd,
                          Register rn,
                          Register rm) {
  ASSERT(TargetCPUFeatures::integer_division_supported());
  ASSERT(rd != kNoRegister);
  ASSERT(rn != kNoRegister);
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = opcode | (static_cast<int32_t>(cond) << kConditionShift) |
                     (static_cast<int32_t>(rn) << kDivRnShift) |
                     (static_cast<int32_t>(rd) << kDivRdShift) | B26 | B25 |
                     B24 | B20 | B4 | (static_cast<int32_t>(rm) << kDivRmShift);
  Emit(encoding);
}

void Assembler::sdiv(Register rd, Register rn, Register rm, Condition cond) {
  EmitDivOp(cond, 0, rd, rn, rm);
}

void Assembler::udiv(Register rd, Register rn, Register rm, Condition cond) {
  EmitDivOp(cond, B21, rd, rn, rm);
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

void Assembler::ldrd(Register rd,
                     Register rd2,
                     Register rn,
                     int32_t offset,
                     Condition cond) {
  ASSERT((rd % 2) == 0);
  ASSERT(rd2 == rd + 1);
  EmitMemOpAddressMode3(cond, B7 | B6 | B4, rd, Address(rn, offset));
}

void Assembler::strd(Register rd,
                     Register rd2,
                     Register rn,
                     int32_t offset,
                     Condition cond) {
  ASSERT((rd % 2) == 0);
  ASSERT(rd2 == rd + 1);
  EmitMemOpAddressMode3(cond, B7 | B6 | B5 | B4, rd, Address(rn, offset));
}

void Assembler::ldm(BlockAddressMode am,
                    Register base,
                    RegList regs,
                    Condition cond) {
  ASSERT(regs != 0);
  EmitMultiMemOp(cond, am, true, base, regs);
}

void Assembler::stm(BlockAddressMode am,
                    Register base,
                    RegList regs,
                    Condition cond) {
  ASSERT(regs != 0);
  EmitMultiMemOp(cond, am, false, base, regs);
}

void Assembler::ldrex(Register rt, Register rn, Condition cond) {
  ASSERT(rn != kNoRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B24 |
                     B23 | L | (static_cast<int32_t>(rn) << kLdExRnShift) |
                     (static_cast<int32_t>(rt) << kLdExRtShift) | B11 | B10 |
                     B9 | B8 | B7 | B4 | B3 | B2 | B1 | B0;
  Emit(encoding);
}

void Assembler::strex(Register rd, Register rt, Register rn, Condition cond) {
  ASSERT(rn != kNoRegister);
  ASSERT(rd != kNoRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B24 |
                     B23 | (static_cast<int32_t>(rn) << kStrExRnShift) |
                     (static_cast<int32_t>(rd) << kStrExRdShift) | B11 | B10 |
                     B9 | B8 | B7 | B4 |
                     (static_cast<int32_t>(rt) << kStrExRtShift);
  Emit(encoding);
}

void Assembler::dmb() {
  // Emit a `dmb ish` instruction.
  Emit(kDataMemoryBarrier);
}

void Assembler::EnterSafepoint(Register addr, Register state) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced. This simplifies GenerateJitCallbackTrampolines.
  Label slow_path, done, retry;
  if (FLAG_use_slow_path) {
    b(&slow_path);
  }

  LoadImmediate(addr, target::Thread::safepoint_state_offset());
  add(addr, THR, Operand(addr));
  Bind(&retry);
  ldrex(state, addr);
  cmp(state, Operand(target::Thread::safepoint_state_unacquired()));
  b(&slow_path, NE);

  mov(state, Operand(target::Thread::safepoint_state_acquired()));
  strex(TMP, state, addr);
  cmp(TMP, Operand(0));  // 0 means strex was successful.
  b(&done, EQ);

  if (!FLAG_use_slow_path) {
    b(&retry);
  }

  Bind(&slow_path);
  ldr(TMP, Address(THR, target::Thread::enter_safepoint_stub_offset()));
  ldr(TMP, FieldAddress(TMP, target::Code::entry_point_offset()));
  blx(TMP);

  Bind(&done);
}

void Assembler::TransitionGeneratedToNative(Register destination_address,
                                            Register exit_frame_fp,
                                            Register exit_through_ffi,
                                            Register tmp1,
                                            bool enter_safepoint) {
  // Save exit frame information to enable stack walking.
  StoreToOffset(exit_frame_fp, THR,
                target::Thread::top_exit_frame_info_offset());

  StoreToOffset(exit_through_ffi, THR,
                target::Thread::exit_through_ffi_offset());
  Register tmp2 = exit_through_ffi;

  // Mark that the thread is executing native code.
  StoreToOffset(destination_address, THR, target::Thread::vm_tag_offset());
  LoadImmediate(tmp1, target::Thread::native_execution_state());
  StoreToOffset(tmp1, THR, target::Thread::execution_state_offset());

  if (enter_safepoint) {
    EnterSafepoint(tmp1, tmp2);
  }
}

void Assembler::ExitSafepoint(Register tmp1, Register tmp2) {
  Register addr = tmp1;
  Register state = tmp2;

  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterSafepoint.
  Label slow_path, done, retry;
  if (FLAG_use_slow_path) {
    b(&slow_path);
  }

  LoadImmediate(addr, target::Thread::safepoint_state_offset());
  add(addr, THR, Operand(addr));
  Bind(&retry);
  ldrex(state, addr);
  cmp(state, Operand(target::Thread::safepoint_state_acquired()));
  b(&slow_path, NE);

  mov(state, Operand(target::Thread::safepoint_state_unacquired()));
  strex(TMP, state, addr);
  cmp(TMP, Operand(0));  // 0 means strex was successful.
  b(&done, EQ);

  if (!FLAG_use_slow_path) {
    b(&retry);
  }

  Bind(&slow_path);
  ldr(TMP, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  ldr(TMP, FieldAddress(TMP, target::Code::entry_point_offset()));
  blx(TMP);

  Bind(&done);
}

void Assembler::TransitionNativeToGenerated(Register addr,
                                            Register state,
                                            bool exit_safepoint) {
  if (exit_safepoint) {
    ExitSafepoint(addr, state);
  } else {
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    LoadImmediate(state, 1 << target::Thread::safepoint_state_inside_bit());
    ldr(TMP, Address(THR, target::Thread::safepoint_state_offset()));
    ands(TMP, TMP, Operand(state));  // Is-at-safepoint is the LSB.
    Label ok;
    b(&ok, ZERO);
    Breakpoint();
    Bind(&ok);
#endif
  }

  // Mark that the thread is executing Dart code.
  LoadImmediate(state, target::Thread::vm_tag_dart_id());
  StoreToOffset(state, THR, target::Thread::vm_tag_offset());
  LoadImmediate(state, target::Thread::generated_execution_state());
  StoreToOffset(state, THR, target::Thread::execution_state_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  LoadImmediate(state, 0);
  StoreToOffset(state, THR, target::Thread::top_exit_frame_info_offset());
  StoreToOffset(state, THR, target::Thread::exit_through_ffi_offset());
}

void Assembler::clrex() {
  int32_t encoding = (kSpecialCondition << kConditionShift) | B26 | B24 | B22 |
                     B21 | B20 | (0xff << 12) | B4 | 0xf;
  Emit(encoding);
}

void Assembler::nop(Condition cond) {
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B25 |
                     B24 | B21 | (0xf << 12);
  Emit(encoding);
}

void Assembler::vmovsr(SRegister sn, Register rt, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(sn != kNoSRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B25 | ((static_cast<int32_t>(sn) >> 1) * B16) |
                     (static_cast<int32_t>(rt) * B12) | B11 | B9 |
                     ((static_cast<int32_t>(sn) & 1) * B7) | B4;
  Emit(encoding);
}

void Assembler::vmovrs(Register rt, SRegister sn, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(sn != kNoSRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B25 | B20 | ((static_cast<int32_t>(sn) >> 1) * B16) |
                     (static_cast<int32_t>(rt) * B12) | B11 | B9 |
                     ((static_cast<int32_t>(sn) & 1) * B7) | B4;
  Emit(encoding);
}

void Assembler::vmovsrr(SRegister sm,
                        Register rt,
                        Register rt2,
                        Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(sm != kNoSRegister);
  ASSERT(sm != S31);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B22 | (static_cast<int32_t>(rt2) * B16) |
                     (static_cast<int32_t>(rt) * B12) | B11 | B9 |
                     ((static_cast<int32_t>(sm) & 1) * B5) | B4 |
                     (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}

void Assembler::vmovrrs(Register rt,
                        Register rt2,
                        SRegister sm,
                        Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
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
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B22 | B20 | (static_cast<int32_t>(rt2) * B16) |
                     (static_cast<int32_t>(rt) * B12) | B11 | B9 |
                     ((static_cast<int32_t>(sm) & 1) * B5) | B4 |
                     (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}

void Assembler::vmovdr(DRegister dn, int i, Register rt, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT((i == 0) || (i == 1));
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(dn != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B25 | (i * B21) | (static_cast<int32_t>(rt) * B12) |
                     B11 | B9 | B8 | ((static_cast<int32_t>(dn) >> 4) * B7) |
                     ((static_cast<int32_t>(dn) & 0xf) * B16) | B4;
  Emit(encoding);
}

void Assembler::vmovdrr(DRegister dm,
                        Register rt,
                        Register rt2,
                        Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(dm != kNoDRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B22 | (static_cast<int32_t>(rt2) * B16) |
                     (static_cast<int32_t>(rt) * B12) | B11 | B9 | B8 |
                     ((static_cast<int32_t>(dm) >> 4) * B5) | B4 |
                     (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}

void Assembler::vmovrrd(Register rt,
                        Register rt2,
                        DRegister dm,
                        Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(dm != kNoDRegister);
  ASSERT(rt != kNoRegister);
  ASSERT(rt != SP);
  ASSERT(rt != PC);
  ASSERT(rt2 != kNoRegister);
  ASSERT(rt2 != SP);
  ASSERT(rt2 != PC);
  ASSERT(rt != rt2);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B22 | B20 | (static_cast<int32_t>(rt2) * B16) |
                     (static_cast<int32_t>(rt) * B12) | B11 | B9 | B8 |
                     ((static_cast<int32_t>(dm) >> 4) * B5) | B4 |
                     (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}

void Assembler::vldrs(SRegister sd, Address ad, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(sd != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B24 | B20 | ((static_cast<int32_t>(sd) & 1) * B22) |
                     ((static_cast<int32_t>(sd) >> 1) * B12) | B11 | B9 |
                     ad.vencoding();
  Emit(encoding);
}

void Assembler::vstrs(SRegister sd, Address ad, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(static_cast<Register>(ad.encoding_ & (0xf << kRnShift)) != PC);
  ASSERT(sd != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B24 | ((static_cast<int32_t>(sd) & 1) * B22) |
                     ((static_cast<int32_t>(sd) >> 1) * B12) | B11 | B9 |
                     ad.vencoding();
  Emit(encoding);
}

void Assembler::vldrd(DRegister dd, Address ad, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(dd != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B24 | B20 | ((static_cast<int32_t>(dd) >> 4) * B22) |
                     ((static_cast<int32_t>(dd) & 0xf) * B12) | B11 | B9 | B8 |
                     ad.vencoding();
  Emit(encoding);
}

void Assembler::vstrd(DRegister dd, Address ad, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(static_cast<Register>(ad.encoding_ & (0xf << kRnShift)) != PC);
  ASSERT(dd != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B24 | ((static_cast<int32_t>(dd) >> 4) * B22) |
                     ((static_cast<int32_t>(dd) & 0xf) * B12) | B11 | B9 | B8 |
                     ad.vencoding();
  Emit(encoding);
}

void Assembler::EmitMultiVSMemOp(Condition cond,
                                 BlockAddressMode am,
                                 bool load,
                                 Register base,
                                 SRegister start,
                                 uint32_t count) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(base != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(start != kNoSRegister);
  ASSERT(static_cast<int32_t>(start) + count <= kNumberOfSRegisters);

  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B11 | B9 | am | (load ? L : 0) |
                     ArmEncode::Rn(base) |
                     ((static_cast<int32_t>(start) & 0x1) ? D : 0) |
                     ((static_cast<int32_t>(start) >> 1) << 12) | count;
  Emit(encoding);
}

void Assembler::EmitMultiVDMemOp(Condition cond,
                                 BlockAddressMode am,
                                 bool load,
                                 Register base,
                                 DRegister start,
                                 int32_t count) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(base != kNoRegister);
  ASSERT(cond != kNoCondition);
  ASSERT(start != kNoDRegister);
  ASSERT(static_cast<int32_t>(start) + count <= kNumberOfDRegisters);
  const int notArmv5te = 0;

  int32_t encoding =
      (static_cast<int32_t>(cond) << kConditionShift) | B27 | B26 | B11 | B9 |
      B8 | am | (load ? L : 0) | ArmEncode::Rn(base) |
      ((static_cast<int32_t>(start) & 0x10) ? D : 0) |
      ((static_cast<int32_t>(start) & 0xf) << 12) | (count << 1) | notArmv5te;
  Emit(encoding);
}

void Assembler::vldms(BlockAddressMode am,
                      Register base,
                      SRegister first,
                      SRegister last,
                      Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(last > first);
  EmitMultiVSMemOp(cond, am, true, base, first, last - first + 1);
}

void Assembler::vstms(BlockAddressMode am,
                      Register base,
                      SRegister first,
                      SRegister last,
                      Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(last > first);
  EmitMultiVSMemOp(cond, am, false, base, first, last - first + 1);
}

void Assembler::vldmd(BlockAddressMode am,
                      Register base,
                      DRegister first,
                      intptr_t count,
                      Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(count <= 16);
  ASSERT(first + count <= kNumberOfDRegisters);
  EmitMultiVDMemOp(cond, am, true, base, first, count);
}

void Assembler::vstmd(BlockAddressMode am,
                      Register base,
                      DRegister first,
                      intptr_t count,
                      Condition cond) {
  ASSERT((am == IA) || (am == IA_W) || (am == DB_W));
  ASSERT(count <= 16);
  ASSERT(first + count <= kNumberOfDRegisters);
  EmitMultiVDMemOp(cond, am, false, base, first, count);
}

void Assembler::EmitVFPsss(Condition cond,
                           int32_t opcode,
                           SRegister sd,
                           SRegister sn,
                           SRegister sm) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(sd != kNoSRegister);
  ASSERT(sn != kNoSRegister);
  ASSERT(sm != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding =
      (static_cast<int32_t>(cond) << kConditionShift) | B27 | B26 | B25 | B11 |
      B9 | opcode | ((static_cast<int32_t>(sd) & 1) * B22) |
      ((static_cast<int32_t>(sn) >> 1) * B16) |
      ((static_cast<int32_t>(sd) >> 1) * B12) |
      ((static_cast<int32_t>(sn) & 1) * B7) |
      ((static_cast<int32_t>(sm) & 1) * B5) | (static_cast<int32_t>(sm) >> 1);
  Emit(encoding);
}

void Assembler::EmitVFPddd(Condition cond,
                           int32_t opcode,
                           DRegister dd,
                           DRegister dn,
                           DRegister dm) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(dd != kNoDRegister);
  ASSERT(dn != kNoDRegister);
  ASSERT(dm != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding =
      (static_cast<int32_t>(cond) << kConditionShift) | B27 | B26 | B25 | B11 |
      B9 | B8 | opcode | ((static_cast<int32_t>(dd) >> 4) * B22) |
      ((static_cast<int32_t>(dn) & 0xf) * B16) |
      ((static_cast<int32_t>(dd) & 0xf) * B12) |
      ((static_cast<int32_t>(dn) >> 4) * B7) |
      ((static_cast<int32_t>(dm) >> 4) * B5) | (static_cast<int32_t>(dm) & 0xf);
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
       (((imm32 >> 25) & ((1 << 6) - 1)) == ((1 << 5) - 1)))) {
    uint8_t imm8 = ((imm32 >> 31) << 7) | (((imm32 >> 29) & 1) << 6) |
                   ((imm32 >> 19) & ((1 << 6) - 1));
    EmitVFPsss(cond, B23 | B21 | B20 | ((imm8 >> 4) * B16) | (imm8 & 0xf), sd,
               S0, S0);
    return true;
  }
  return false;
}

bool Assembler::vmovd(DRegister dd, double d_imm, Condition cond) {
  uint64_t imm64 = bit_cast<uint64_t, double>(d_imm);
  if (((imm64 & ((1LL << 48) - 1)) == 0) &&
      ((((imm64 >> 54) & ((1 << 9) - 1)) == (1 << 8)) ||
       (((imm64 >> 54) & ((1 << 9) - 1)) == ((1 << 8) - 1)))) {
    uint8_t imm8 = ((imm64 >> 63) << 7) | (((imm64 >> 61) & 1) << 6) |
                   ((imm64 >> 48) & ((1 << 6) - 1));
    EmitVFPddd(cond, B23 | B21 | B20 | ((imm8 >> 4) * B16) | B8 | (imm8 & 0xf),
               dd, D0, D0);
    return true;
  }
  return false;
}

void Assembler::vadds(SRegister sd,
                      SRegister sn,
                      SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B21 | B20, sd, sn, sm);
}

void Assembler::vaddd(DRegister dd,
                      DRegister dn,
                      DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B21 | B20, dd, dn, dm);
}

void Assembler::vsubs(SRegister sd,
                      SRegister sn,
                      SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B21 | B20 | B6, sd, sn, sm);
}

void Assembler::vsubd(DRegister dd,
                      DRegister dn,
                      DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B21 | B20 | B6, dd, dn, dm);
}

void Assembler::vmuls(SRegister sd,
                      SRegister sn,
                      SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B21, sd, sn, sm);
}

void Assembler::vmuld(DRegister dd,
                      DRegister dn,
                      DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B21, dd, dn, dm);
}

void Assembler::vmlas(SRegister sd,
                      SRegister sn,
                      SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, 0, sd, sn, sm);
}

void Assembler::vmlad(DRegister dd,
                      DRegister dn,
                      DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, 0, dd, dn, dm);
}

void Assembler::vmlss(SRegister sd,
                      SRegister sn,
                      SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B6, sd, sn, sm);
}

void Assembler::vmlsd(DRegister dd,
                      DRegister dn,
                      DRegister dm,
                      Condition cond) {
  EmitVFPddd(cond, B6, dd, dn, dm);
}

void Assembler::vdivs(SRegister sd,
                      SRegister sn,
                      SRegister sm,
                      Condition cond) {
  EmitVFPsss(cond, B23, sd, sn, sm);
}

void Assembler::vdivd(DRegister dd,
                      DRegister dn,
                      DRegister dm,
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

void Assembler::EmitVFPsd(Condition cond,
                          int32_t opcode,
                          SRegister sd,
                          DRegister dm) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(sd != kNoSRegister);
  ASSERT(dm != kNoDRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding =
      (static_cast<int32_t>(cond) << kConditionShift) | B27 | B26 | B25 | B11 |
      B9 | opcode | ((static_cast<int32_t>(sd) & 1) * B22) |
      ((static_cast<int32_t>(sd) >> 1) * B12) |
      ((static_cast<int32_t>(dm) >> 4) * B5) | (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}

void Assembler::EmitVFPds(Condition cond,
                          int32_t opcode,
                          DRegister dd,
                          SRegister sm) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(dd != kNoDRegister);
  ASSERT(sm != kNoSRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding =
      (static_cast<int32_t>(cond) << kConditionShift) | B27 | B26 | B25 | B11 |
      B9 | opcode | ((static_cast<int32_t>(dd) >> 4) * B22) |
      ((static_cast<int32_t>(dd) & 0xf) * B12) |
      ((static_cast<int32_t>(sm) & 1) * B5) | (static_cast<int32_t>(sm) >> 1);
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

void Assembler::vmrs(Register rd, Condition cond) {
  ASSERT(TargetCPUFeatures::vfp_supported());
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B27 |
                     B26 | B25 | B23 | B22 | B21 | B20 | B16 |
                     (static_cast<int32_t>(rd) * B12) | B11 | B9 | B4;
  Emit(encoding);
}

void Assembler::vmstat(Condition cond) {
  vmrs(APSR, cond);
}

static inline int ShiftOfOperandSize(OperandSize size) {
  switch (size) {
    case kByte:
    case kUnsignedByte:
      return 0;
    case kTwoBytes:
    case kUnsignedTwoBytes:
      return 1;
    case kFourBytes:
    case kUnsignedFourBytes:
      return 2;
    case kWordPair:
      return 3;
    case kSWord:
    case kDWord:
      return 0;
    default:
      UNREACHABLE();
      break;
  }

  UNREACHABLE();
  return -1;
}

void Assembler::EmitSIMDqqq(int32_t opcode,
                            OperandSize size,
                            QRegister qd,
                            QRegister qn,
                            QRegister qm) {
  ASSERT(TargetCPUFeatures::neon_supported());
  int sz = ShiftOfOperandSize(size);
  int32_t encoding =
      (static_cast<int32_t>(kSpecialCondition) << kConditionShift) | B25 | B6 |
      opcode | ((sz & 0x3) * B20) |
      ((static_cast<int32_t>(qd * 2) >> 4) * B22) |
      ((static_cast<int32_t>(qn * 2) & 0xf) * B16) |
      ((static_cast<int32_t>(qd * 2) & 0xf) * B12) |
      ((static_cast<int32_t>(qn * 2) >> 4) * B7) |
      ((static_cast<int32_t>(qm * 2) >> 4) * B5) |
      (static_cast<int32_t>(qm * 2) & 0xf);
  Emit(encoding);
}

void Assembler::EmitSIMDddd(int32_t opcode,
                            OperandSize size,
                            DRegister dd,
                            DRegister dn,
                            DRegister dm) {
  ASSERT(TargetCPUFeatures::neon_supported());
  int sz = ShiftOfOperandSize(size);
  int32_t encoding =
      (static_cast<int32_t>(kSpecialCondition) << kConditionShift) | B25 |
      opcode | ((sz & 0x3) * B20) | ((static_cast<int32_t>(dd) >> 4) * B22) |
      ((static_cast<int32_t>(dn) & 0xf) * B16) |
      ((static_cast<int32_t>(dd) & 0xf) * B12) |
      ((static_cast<int32_t>(dn) >> 4) * B7) |
      ((static_cast<int32_t>(dm) >> 4) * B5) | (static_cast<int32_t>(dm) & 0xf);
  Emit(encoding);
}

void Assembler::vmovq(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B21 | B8 | B4, kByte, qd, qm, qm);
}

void Assembler::vaddqi(OperandSize sz,
                       QRegister qd,
                       QRegister qn,
                       QRegister qm) {
  EmitSIMDqqq(B11, sz, qd, qn, qm);
}

void Assembler::vaddqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B11 | B10 | B8, kSWord, qd, qn, qm);
}

void Assembler::vsubqi(OperandSize sz,
                       QRegister qd,
                       QRegister qn,
                       QRegister qm) {
  EmitSIMDqqq(B24 | B11, sz, qd, qn, qm);
}

void Assembler::vsubqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B21 | B11 | B10 | B8, kSWord, qd, qn, qm);
}

void Assembler::vmulqi(OperandSize sz,
                       QRegister qd,
                       QRegister qn,
                       QRegister qm) {
  EmitSIMDqqq(B11 | B8 | B4, sz, qd, qn, qm);
}

void Assembler::vmulqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B24 | B11 | B10 | B8 | B4, kSWord, qd, qn, qm);
}

void Assembler::vshlqi(OperandSize sz,
                       QRegister qd,
                       QRegister qm,
                       QRegister qn) {
  EmitSIMDqqq(B25 | B10, sz, qd, qn, qm);
}

void Assembler::vshlqu(OperandSize sz,
                       QRegister qd,
                       QRegister qm,
                       QRegister qn) {
  EmitSIMDqqq(B25 | B24 | B10, sz, qd, qn, qm);
}

void Assembler::veorq(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B24 | B8 | B4, kByte, qd, qn, qm);
}

void Assembler::vorrq(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B21 | B8 | B4, kByte, qd, qn, qm);
}

void Assembler::vornq(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B21 | B20 | B8 | B4, kByte, qd, qn, qm);
}

void Assembler::vandq(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B8 | B4, kByte, qd, qn, qm);
}

void Assembler::vmvnq(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B25 | B24 | B23 | B10 | B8 | B7, kWordPair, qd, Q0, qm);
}

void Assembler::vminqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B21 | B11 | B10 | B9 | B8, kSWord, qd, qn, qm);
}

void Assembler::vmaxqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B11 | B10 | B9 | B8, kSWord, qd, qn, qm);
}

void Assembler::vabsqs(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B24 | B23 | B21 | B20 | B19 | B16 | B10 | B9 | B8, kSWord, qd, Q0,
              qm);
}

void Assembler::vnegqs(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B24 | B23 | B21 | B20 | B19 | B16 | B10 | B9 | B8 | B7, kSWord,
              qd, Q0, qm);
}

void Assembler::vrecpeqs(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B24 | B23 | B21 | B20 | B19 | B17 | B16 | B10 | B8, kSWord, qd,
              Q0, qm);
}

void Assembler::vrecpsqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B11 | B10 | B9 | B8 | B4, kSWord, qd, qn, qm);
}

void Assembler::vrsqrteqs(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B24 | B23 | B21 | B20 | B19 | B17 | B16 | B10 | B8 | B7, kSWord,
              qd, Q0, qm);
}

void Assembler::vrsqrtsqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B21 | B11 | B10 | B9 | B8 | B4, kSWord, qd, qn, qm);
}

void Assembler::vdup(OperandSize sz, QRegister qd, DRegister dm, int idx) {
  ASSERT((sz != kDWord) && (sz != kSWord) && (sz != kWordPair));
  int code = 0;

  switch (sz) {
    case kByte:
    case kUnsignedByte: {
      ASSERT((idx >= 0) && (idx < 8));
      code = 1 | (idx << 1);
      break;
    }
    case kTwoBytes:
    case kUnsignedTwoBytes: {
      ASSERT((idx >= 0) && (idx < 4));
      code = 2 | (idx << 2);
      break;
    }
    case kFourBytes:
    case kUnsignedFourBytes: {
      ASSERT((idx >= 0) && (idx < 2));
      code = 4 | (idx << 3);
      break;
    }
    default: {
      break;
    }
  }

  EmitSIMDddd(B24 | B23 | B11 | B10 | B6, kWordPair,
              static_cast<DRegister>(qd * 2),
              static_cast<DRegister>(code & 0xf), dm);
}

void Assembler::vtbl(DRegister dd, DRegister dn, int len, DRegister dm) {
  ASSERT((len >= 1) && (len <= 4));
  EmitSIMDddd(B24 | B23 | B11 | ((len - 1) * B8), kWordPair, dd, dn, dm);
}

void Assembler::vzipqw(QRegister qd, QRegister qm) {
  EmitSIMDqqq(B24 | B23 | B21 | B20 | B19 | B17 | B8 | B7, kByte, qd, Q0, qm);
}

void Assembler::vceqqi(OperandSize sz,
                       QRegister qd,
                       QRegister qn,
                       QRegister qm) {
  EmitSIMDqqq(B24 | B11 | B4, sz, qd, qn, qm);
}

void Assembler::vceqqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B11 | B10 | B9, kSWord, qd, qn, qm);
}

void Assembler::vcgeqi(OperandSize sz,
                       QRegister qd,
                       QRegister qn,
                       QRegister qm) {
  EmitSIMDqqq(B9 | B8 | B4, sz, qd, qn, qm);
}

void Assembler::vcugeqi(OperandSize sz,
                        QRegister qd,
                        QRegister qn,
                        QRegister qm) {
  EmitSIMDqqq(B24 | B9 | B8 | B4, sz, qd, qn, qm);
}

void Assembler::vcgeqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B24 | B11 | B10 | B9, kSWord, qd, qn, qm);
}

void Assembler::vcgtqi(OperandSize sz,
                       QRegister qd,
                       QRegister qn,
                       QRegister qm) {
  EmitSIMDqqq(B9 | B8, sz, qd, qn, qm);
}

void Assembler::vcugtqi(OperandSize sz,
                        QRegister qd,
                        QRegister qn,
                        QRegister qm) {
  EmitSIMDqqq(B24 | B9 | B8, sz, qd, qn, qm);
}

void Assembler::vcgtqs(QRegister qd, QRegister qn, QRegister qm) {
  EmitSIMDqqq(B24 | B21 | B11 | B10 | B9, kSWord, qd, qn, qm);
}

void Assembler::bkpt(uint16_t imm16) {
  Emit(BkptEncoding(imm16));
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
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B24 |
                     B21 | (0xfff << 8) | B4 | ArmEncode::Rm(rm);
  Emit(encoding);
}

void Assembler::blx(Register rm, Condition cond) {
  ASSERT(rm != kNoRegister);
  ASSERT(cond != kNoCondition);
  int32_t encoding = (static_cast<int32_t>(cond) << kConditionShift) | B24 |
                     B21 | (0xfff << 8) | B5 | B4 | ArmEncode::Rm(rm);
  Emit(encoding);
}

void Assembler::MarkExceptionHandler(Label* label) {
  EmitType01(AL, 1, TST, 1, PC, R0, Operand(0));
  Label l;
  b(&l);
  EmitBranch(AL, label, false);
  Bind(&l);
}

void Assembler::Drop(intptr_t stack_elements) {
  ASSERT(stack_elements >= 0);
  if (stack_elements > 0) {
    AddImmediate(SP, stack_elements * target::kWordSize);
  }
}

intptr_t Assembler::FindImmediate(int32_t imm) {
  return object_pool_builder().FindImmediate(imm);
}

// Uses a code sequence that can easily be decoded.
void Assembler::LoadWordFromPoolIndex(Register rd,
                                      intptr_t index,
                                      Register pp,
                                      Condition cond) {
  ASSERT((pp != PP) || constant_pool_allowed());
  ASSERT(rd != pp);
  // PP is tagged on ARM.
  const int32_t offset =
      target::ObjectPool::element_offset(index) - kHeapObjectTag;
  int32_t offset_mask = 0;
  if (Address::CanHoldLoadOffset(kFourBytes, offset, &offset_mask)) {
    ldr(rd, Address(pp, offset), cond);
  } else {
    int32_t offset_hi = offset & ~offset_mask;  // signed
    uint32_t offset_lo = offset & offset_mask;  // unsigned
    // Inline a simplified version of AddImmediate(rd, pp, offset_hi).
    Operand o;
    if (Operand::CanHold(offset_hi, &o)) {
      add(rd, pp, o, cond);
    } else {
      LoadImmediate(rd, offset_hi, cond);
      add(rd, pp, Operand(rd), cond);
    }
    ldr(rd, Address(rd, offset_lo), cond);
  }
}

void Assembler::CheckCodePointer() {
#ifdef DEBUG
  if (!FLAG_check_code_pointer) {
    return;
  }
  Comment("CheckCodePointer");
  Label cid_ok, instructions_ok;
  Push(R0);
  Push(IP);
  CompareClassId(CODE_REG, kCodeCid, R0);
  b(&cid_ok, EQ);
  bkpt(0);
  Bind(&cid_ok);

  const intptr_t offset = CodeSize() + Instr::kPCReadOffset +
                          target::Instructions::HeaderSize() - kHeapObjectTag;
  mov(R0, Operand(PC));
  AddImmediate(R0, -offset);
  ldr(IP, FieldAddress(CODE_REG, target::Code::saved_instructions_offset()));
  cmp(R0, Operand(IP));
  b(&instructions_ok, EQ);
  bkpt(1);
  Bind(&instructions_ok);
  Pop(IP);
  Pop(R0);
#endif
}

void Assembler::RestoreCodePointer() {
  ldr(CODE_REG,
      Address(FP, target::frame_layout.code_from_fp * target::kWordSize));
  CheckCodePointer();
}

void Assembler::LoadPoolPointer(Register reg) {
  // Load new pool pointer.
  CheckCodePointer();
  ldr(reg, FieldAddress(CODE_REG, target::Code::object_pool_offset()));
  set_constant_pool_allowed(reg == PP);
}

void Assembler::SetupGlobalPoolAndDispatchTable() {
  ASSERT(FLAG_precompiled_mode && FLAG_use_bare_instructions);
  ldr(PP, Address(THR, target::Thread::global_object_pool_offset()));
  if (FLAG_use_table_dispatch) {
    ldr(DISPATCH_TABLE_REG,
        Address(THR, target::Thread::dispatch_table_array_offset()));
  }
}

void Assembler::LoadIsolate(Register rd) {
  ldr(rd, Address(THR, target::Thread::isolate_offset()));
}

bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(IsOriginalObject(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  ASSERT(IsNotTemporaryScopedHandle(object));
  ASSERT(IsInOldSpace(object));
  return true;
}

void Assembler::LoadObjectHelper(Register rd,
                                 const Object& object,
                                 Condition cond,
                                 bool is_unique,
                                 Register pp) {
  ASSERT(IsOriginalObject(object));
  // `is_unique == true` effectively means object has to be patchable.
  if (!is_unique) {
    intptr_t offset = 0;
    if (target::CanLoadFromThread(object, &offset)) {
      // Load common VM constants from the thread. This works also in places
      // where no constant pool is set up (e.g. intrinsic code).
      ldr(rd, Address(THR, offset), cond);
      return;
    }
    if (target::IsSmi(object)) {
      // Relocation doesn't apply to Smis.
      LoadImmediate(rd, target::ToRawSmi(object), cond);
      return;
    }
  }
  RELEASE_ASSERT(CanLoadFromObjectPool(object));
  // Make sure that class CallPattern is able to decode this load from the
  // object pool.
  const auto index = is_unique ? object_pool_builder().AddObject(object)
                               : object_pool_builder().FindObject(object);
  LoadWordFromPoolIndex(rd, index, pp, cond);
}

void Assembler::LoadObject(Register rd, const Object& object, Condition cond) {
  LoadObjectHelper(rd, object, cond, /* is_unique = */ false, PP);
}

void Assembler::LoadUniqueObject(Register rd,
                                 const Object& object,
                                 Condition cond) {
  LoadObjectHelper(rd, object, cond, /* is_unique = */ true, PP);
}

void Assembler::LoadNativeEntry(Register rd,
                                const ExternalLabel* label,
                                ObjectPoolBuilderEntry::Patchability patchable,
                                Condition cond) {
  const intptr_t index =
      object_pool_builder().FindNativeFunction(label, patchable);
  LoadWordFromPoolIndex(rd, index, PP, cond);
}

void Assembler::PushObject(const Object& object) {
  ASSERT(IsOriginalObject(object));
  LoadObject(IP, object);
  Push(IP);
}

void Assembler::CompareObject(Register rn, const Object& object) {
  ASSERT(IsOriginalObject(object));
  ASSERT(rn != IP);
  if (target::IsSmi(object)) {
    CompareImmediate(rn, target::ToRawSmi(object));
  } else {
    LoadObject(IP, object);
    cmp(rn, Operand(IP));
  }
}

// Preserves object and value registers.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* label,
                                      CanBeSmi value_can_be_smi,
                                      BarrierFilterMode how_to_jump) {
  COMPILE_ASSERT((target::ObjectAlignment::kNewObjectAlignmentOffset ==
                  target::kWordSize) &&
                 (target::ObjectAlignment::kOldObjectAlignmentOffset == 0));
  // For the value we are only interested in the new/old bit and the tag bit.
  // And the new bit with the tag bit. The resulting bit will be 0 for a Smi.
  if (value_can_be_smi == kValueCanBeSmi) {
    and_(
        IP, value,
        Operand(value, LSL, target::ObjectAlignment::kObjectAlignmentLog2 - 1));
    // And the result with the negated space bit of the object.
    bic(IP, IP, Operand(object));
  } else {
#if defined(DEBUG)
    Label okay;
    BranchIfNotSmi(value, &okay);
    Stop("Unexpected Smi!");
    Bind(&okay);
#endif
    bic(IP, value, Operand(object));
  }
  tst(IP, Operand(target::ObjectAlignment::kNewObjectAlignmentOffset));
  if (how_to_jump != kNoJump) {
    b(label, how_to_jump == kJumpToNoUpdate ? EQ : NE);
  }
}

Register UseRegister(Register reg, RegList* used) {
  ASSERT(reg != THR);
  ASSERT(reg != SP);
  ASSERT(reg != FP);
  ASSERT(reg != PC);
  ASSERT((*used & (1 << reg)) == 0);
  *used |= (1 << reg);
  return reg;
}

Register AllocateRegister(RegList* used) {
  const RegList free = ~*used;
  return (free == 0)
             ? kNoRegister
             : UseRegister(
                   static_cast<Register>(Utils::CountTrailingZerosWord(free)),
                   used);
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_be_smi) {
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);
  ASSERT(object != LINK_REGISTER);
  ASSERT(value != LINK_REGISTER);
  ASSERT(object != TMP);
  ASSERT(value != TMP);

  str(value, dest);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare ObjectLayout::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done);
  }
  const bool preserve_lr = lr_state().LRContainsReturnAddress();
  if (preserve_lr) {
    SPILLS_LR_TO_FRAME(Push(LR));
  }
  CLOBBERS_LR({
    ldrb(TMP, FieldAddress(object, target::Object::tags_offset()));
    ldrb(LR, FieldAddress(value, target::Object::tags_offset()));
    and_(TMP, LR,
         Operand(TMP, LSR, target::ObjectLayout::kBarrierOverlapShift));
    ldr(LR, Address(THR, target::Thread::write_barrier_mask_offset()));
    tst(TMP, Operand(LR));
  });
  if (value != kWriteBarrierValueReg) {
    // Unlikely. Only non-graph intrinsics.
    // TODO(rmacnak): Shuffle registers in intrinsics.
    Label restore_and_done;
    b(&restore_and_done, ZERO);
    Register objectForCall = object;
    if (object != kWriteBarrierValueReg) {
      Push(kWriteBarrierValueReg);
    } else {
      COMPILE_ASSERT(R2 != kWriteBarrierValueReg);
      COMPILE_ASSERT(R3 != kWriteBarrierValueReg);
      objectForCall = (value == R2) ? R3 : R2;
      PushList((1 << kWriteBarrierValueReg) | (1 << objectForCall));
      mov(objectForCall, Operand(object));
    }
    mov(kWriteBarrierValueReg, Operand(value));
    generate_invoke_write_barrier_wrapper_(AL, objectForCall);

    if (object != kWriteBarrierValueReg) {
      Pop(kWriteBarrierValueReg);
    } else {
      PopList((1 << kWriteBarrierValueReg) | (1 << objectForCall));
    }
    Bind(&restore_and_done);
  } else {
    generate_invoke_write_barrier_wrapper_(NE, object);
  }
  if (preserve_lr) {
    RESTORES_LR_FROM_FRAME(Pop(LR));
  }
  Bind(&done);
}

void Assembler::StoreIntoArray(Register object,
                               Register slot,
                               Register value,
                               CanBeSmi can_be_smi) {
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);
  ASSERT(object != LINK_REGISTER);
  ASSERT(value != LINK_REGISTER);
  ASSERT(slot != LINK_REGISTER);
  ASSERT(object != TMP);
  ASSERT(value != TMP);
  ASSERT(slot != TMP);

  str(value, Address(slot, 0));

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare ObjectLayout::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done);
  }
  const bool preserve_lr = lr_state().LRContainsReturnAddress();
  if (preserve_lr) {
    SPILLS_LR_TO_FRAME(Push(LR));
  }

  CLOBBERS_LR({
    ldrb(TMP, FieldAddress(object, target::Object::tags_offset()));
    ldrb(LR, FieldAddress(value, target::Object::tags_offset()));
    and_(TMP, LR,
         Operand(TMP, LSR, target::ObjectLayout::kBarrierOverlapShift));
    ldr(LR, Address(THR, target::Thread::write_barrier_mask_offset()));
    tst(TMP, Operand(LR));
  });

  if ((object != kWriteBarrierObjectReg) || (value != kWriteBarrierValueReg) ||
      (slot != kWriteBarrierSlotReg)) {
    // Spill and shuffle unimplemented. Currently StoreIntoArray is only used
    // from StoreIndexInstr, which gets these exact registers from the register
    // allocator.
    UNIMPLEMENTED();
  }
  generate_invoke_array_write_barrier_(NE);
  if (preserve_lr) {
    RESTORES_LR_FROM_FRAME(Pop(LR));
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectOffset(Register object,
                                      int32_t offset,
                                      Register value,
                                      CanBeSmi can_value_be_smi) {
  int32_t ignored = 0;
  if (Address::CanHoldStoreOffset(kFourBytes, offset - kHeapObjectTag,
                                  &ignored)) {
    StoreIntoObject(object, FieldAddress(object, offset), value,
                    can_value_be_smi);
  } else {
    AddImmediate(IP, object, offset - kHeapObjectTag);
    StoreIntoObject(object, Address(IP), value, can_value_be_smi);
  }
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  str(value, dest);
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value, &done, kValueCanBeSmi, kJumpToNoUpdate);

  ldrb(TMP, FieldAddress(object, target::Object::tags_offset()));
  tst(TMP, Operand(1 << target::ObjectLayout::kOldAndNotRememberedBit));
  b(&done, ZERO);

  Stop("Store buffer update is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  ASSERT(IsOriginalObject(value));
  ASSERT(IsNotTemporaryScopedHandle(value));
  // No store buffer update.
  LoadObject(IP, value);
  str(IP, dest);
}

void Assembler::StoreIntoObjectNoBarrierOffset(Register object,
                                               int32_t offset,
                                               Register value) {
  int32_t ignored = 0;
  if (Address::CanHoldStoreOffset(kFourBytes, offset - kHeapObjectTag,
                                  &ignored)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    Register base = object == R9 ? R8 : R9;
    Push(base);
    AddImmediate(base, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(base), value);
    Pop(base);
  }
}

void Assembler::StoreIntoObjectNoBarrierOffset(Register object,
                                               int32_t offset,
                                               const Object& value) {
  ASSERT(IsOriginalObject(value));
  int32_t ignored = 0;
  if (Address::CanHoldStoreOffset(kFourBytes, offset - kHeapObjectTag,
                                  &ignored)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    Register base = object == R9 ? R8 : R9;
    Push(base);
    AddImmediate(base, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(base), value);
    Pop(base);
  }
}

void Assembler::StoreInternalPointer(Register object,
                                     const Address& dest,
                                     Register value) {
  str(value, dest);
}

void Assembler::InitializeFieldsNoBarrier(Register object,
                                          Register begin,
                                          Register end,
                                          Register value_even,
                                          Register value_odd) {
  ASSERT(value_odd == value_even + 1);
  Label init_loop;
  Bind(&init_loop);
  AddImmediate(begin, 2 * target::kWordSize);
  cmp(begin, Operand(end));
  strd(value_even, value_odd, begin, -2 * target::kWordSize, LS);
  b(&init_loop, CC);
  str(value_even, Address(begin, -2 * target::kWordSize), HI);
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value_even, &done, kValueCanBeSmi,
                        kJumpToNoUpdate);
  StoreIntoObjectFilter(object, value_odd, &done, kValueCanBeSmi,
                        kJumpToNoUpdate);
  Stop("Store buffer update is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::InitializeFieldsNoBarrierUnrolled(Register object,
                                                  Register base,
                                                  intptr_t begin_offset,
                                                  intptr_t end_offset,
                                                  Register value_even,
                                                  Register value_odd) {
  ASSERT(value_odd == value_even + 1);
  intptr_t current_offset = begin_offset;
  while (current_offset + target::kWordSize < end_offset) {
    strd(value_even, value_odd, base, current_offset);
    current_offset += 2 * target::kWordSize;
  }
  while (current_offset < end_offset) {
    str(value_even, Address(base, current_offset));
    current_offset += target::kWordSize;
  }
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value_even, &done, kValueCanBeSmi,
                        kJumpToNoUpdate);
  StoreIntoObjectFilter(object, value_odd, &done, kValueCanBeSmi,
                        kJumpToNoUpdate);
  Stop("Store buffer update is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::StoreIntoSmiField(const Address& dest, Register value) {
#if defined(DEBUG)
  Label done;
  tst(value, Operand(kHeapObjectTag));
  b(&done, EQ);
  Stop("New value must be Smi.");
  Bind(&done);
#endif  // defined(DEBUG)
  str(value, dest);
}

void Assembler::ExtractClassIdFromTags(Register result, Register tags) {
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  Lsr(result, tags, Operand(target::ObjectLayout::kClassIdTagPos), AL);
}

void Assembler::ExtractInstanceSizeFromTags(Register result, Register tags) {
  ASSERT(target::ObjectLayout::kSizeTagPos == 8);
  ASSERT(target::ObjectLayout::kSizeTagSize == 8);
  Lsr(result, tags,
      Operand(target::ObjectLayout::kSizeTagPos -
              target::ObjectAlignment::kObjectAlignmentLog2),
      AL);
  AndImmediate(result, result,
               (Utils::NBitMask(target::ObjectLayout::kSizeTagSize)
                << target::ObjectAlignment::kObjectAlignmentLog2));
}

void Assembler::LoadClassId(Register result, Register object, Condition cond) {
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  const intptr_t class_id_offset =
      target::Object::tags_offset() +
      target::ObjectLayout::kClassIdTagPos / kBitsPerByte;
  ldrh(result, FieldAddress(object, class_id_offset), cond);
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);

  const intptr_t table_offset =
      target::Isolate::cached_class_table_table_offset();

  LoadIsolate(result);
  LoadFromOffset(result, result, table_offset);
  ldr(result, Address(result, class_id, LSL, target::kWordSizeLog2));
}

void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  LoadClassId(scratch, object);
  CompareImmediate(scratch, class_id);
}

void Assembler::LoadClassIdMayBeSmi(Register result, Register object) {
  tst(object, Operand(kSmiTagMask));
  LoadClassId(result, object, NE);
  LoadImmediate(result, kSmiCid, EQ);
}

void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  LoadClassIdMayBeSmi(result, object);
  SmiTag(result);
}

void Assembler::BailoutIfInvalidBranchOffset(int32_t offset) {
  if (!CanEncodeBranchDistance(offset)) {
    ASSERT(!use_far_branches());
    BailoutWithBranchOffsetError();
  }
}

int32_t Assembler::EncodeBranchOffset(int32_t offset, int32_t inst) {
  // The offset is off by 8 due to the way the ARM CPUs read PC.
  offset -= Instr::kPCReadOffset;

  // Properly preserve only the bits supported in the instruction.
  offset >>= 2;
  offset &= kBranchOffsetMask;
  return (inst & ~kBranchOffsetMask) | offset;
}

int Assembler::DecodeBranchOffset(int32_t inst) {
  // Sign-extend, left-shift by 2, then add 8.
  return ((((inst & kBranchOffsetMask) << 8) >> 6) + Instr::kPCReadOffset);
}

static int32_t DecodeARMv7LoadImmediate(int32_t movt, int32_t movw) {
  int32_t offset = 0;
  offset |= (movt & 0xf0000) << 12;
  offset |= (movt & 0xfff) << 16;
  offset |= (movw & 0xf0000) >> 4;
  offset |= movw & 0xfff;
  return offset;
}

class PatchFarBranch : public AssemblerFixup {
 public:
  PatchFarBranch() {}

  void Process(const MemoryRegion& region, intptr_t position) {
    ProcessARMv7(region, position);
  }

 private:
  void ProcessARMv7(const MemoryRegion& region, intptr_t position) {
    const int32_t movw = region.Load<int32_t>(position);
    const int32_t movt = region.Load<int32_t>(position + Instr::kInstrSize);
    const int32_t bx = region.Load<int32_t>(position + 2 * Instr::kInstrSize);

    if (((movt & 0xfff0f000) == 0xe340c000) &&  // movt IP, high
        ((movw & 0xfff0f000) == 0xe300c000)) {  // movw IP, low
      const int32_t offset = DecodeARMv7LoadImmediate(movt, movw);
      const int32_t dest = region.start() + offset;
      const uint16_t dest_high = Utils::High16Bits(dest);
      const uint16_t dest_low = Utils::Low16Bits(dest);
      const int32_t patched_movt =
          0xe340c000 | ((dest_high >> 12) << 16) | (dest_high & 0xfff);
      const int32_t patched_movw =
          0xe300c000 | ((dest_low >> 12) << 16) | (dest_low & 0xfff);

      region.Store<int32_t>(position, patched_movw);
      region.Store<int32_t>(position + Instr::kInstrSize, patched_movt);
      return;
    }

    // If the offset loading instructions aren't there, we must have replaced
    // the far branch with a near one, and so these instructions
    // should be NOPs.
    ASSERT((movt == Instr::kNopInstruction) && (bx == Instr::kNopInstruction));
  }

  virtual bool IsPointerOffset() const { return false; }
};

void Assembler::EmitFarBranch(Condition cond, int32_t offset, bool link) {
  buffer_.EmitFixup(new PatchFarBranch());
  LoadPatchableImmediate(IP, offset);
  if (link) {
    blx(IP, cond);
  } else {
    bx(IP, cond);
  }
}

void Assembler::EmitBranch(Condition cond, Label* label, bool link) {
  if (label->IsBound()) {
    const int32_t dest = label->Position() - buffer_.Size();
    if (use_far_branches() && !CanEncodeBranchDistance(dest)) {
      EmitFarBranch(cond, label->Position(), link);
    } else {
      EmitType5(cond, dest, link);
    }
    label->UpdateLRState(lr_state());
  } else {
    const intptr_t position = buffer_.Size();
    if (use_far_branches()) {
      const int32_t dest = label->position_;
      EmitFarBranch(cond, dest, link);
    } else {
      // Use the offset field of the branch instruction for linking the sites.
      EmitType5(cond, label->position_, link);
    }
    label->LinkTo(position, lr_state());
  }
}

void Assembler::BindARMv7(Label* label) {
  ASSERT(!label->IsBound());
  intptr_t bound_pc = buffer_.Size();
  while (label->IsLinked()) {
    const int32_t position = label->Position();
    int32_t dest = bound_pc - position;
    if (use_far_branches() && !CanEncodeBranchDistance(dest)) {
      // Far branches are enabled and we can't encode the branch offset.

      // Grab instructions that load the offset.
      const int32_t movw =
          buffer_.Load<int32_t>(position + 0 * Instr::kInstrSize);
      const int32_t movt =
          buffer_.Load<int32_t>(position + 1 * Instr::kInstrSize);

      // Change from relative to the branch to relative to the assembler
      // buffer.
      dest = buffer_.Size();
      const uint16_t dest_high = Utils::High16Bits(dest);
      const uint16_t dest_low = Utils::Low16Bits(dest);
      const int32_t patched_movt =
          0xe340c000 | ((dest_high >> 12) << 16) | (dest_high & 0xfff);
      const int32_t patched_movw =
          0xe300c000 | ((dest_low >> 12) << 16) | (dest_low & 0xfff);

      // Rewrite the instructions.
      buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize, patched_movw);
      buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize, patched_movt);
      label->position_ = DecodeARMv7LoadImmediate(movt, movw);
    } else if (use_far_branches() && CanEncodeBranchDistance(dest)) {
      // Far branches are enabled, but we can encode the branch offset.

      // Grab instructions that load the offset, and the branch.
      const int32_t movw =
          buffer_.Load<int32_t>(position + 0 * Instr::kInstrSize);
      const int32_t movt =
          buffer_.Load<int32_t>(position + 1 * Instr::kInstrSize);
      const int32_t branch =
          buffer_.Load<int32_t>(position + 2 * Instr::kInstrSize);

      // Grab the branch condition, and encode the link bit.
      const int32_t cond = branch & 0xf0000000;
      const int32_t link = (branch & 0x20) << 19;

      // Encode the branch and the offset.
      const int32_t new_branch = cond | link | 0x0a000000;
      const int32_t encoded = EncodeBranchOffset(dest, new_branch);

      // Write the encoded branch instruction followed by two nops.
      buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize, encoded);
      buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize,
                             Instr::kNopInstruction);
      buffer_.Store<int32_t>(position + 2 * Instr::kInstrSize,
                             Instr::kNopInstruction);

      label->position_ = DecodeARMv7LoadImmediate(movt, movw);
    } else {
      BailoutIfInvalidBranchOffset(dest);
      int32_t next = buffer_.Load<int32_t>(position);
      int32_t encoded = Assembler::EncodeBranchOffset(dest, next);
      buffer_.Store<int32_t>(position, encoded);
      label->position_ = Assembler::DecodeBranchOffset(next);
    }
  }
  label->BindTo(bound_pc, lr_state());
}

void Assembler::Bind(Label* label) {
  BindARMv7(label);
}

OperandSize Address::OperandSizeFor(intptr_t cid) {
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypeArgumentsCid:
      return kFourBytes;
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      return kByte;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      return kTwoBytes;
    case kTypedDataInt8ArrayCid:
      return kByte;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return kUnsignedByte;
    case kTypedDataInt16ArrayCid:
      return kTwoBytes;
    case kTypedDataUint16ArrayCid:
      return kUnsignedTwoBytes;
    case kTypedDataInt32ArrayCid:
      return kFourBytes;
    case kTypedDataUint32ArrayCid:
      return kUnsignedFourBytes;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return kDWord;
    case kTypedDataFloat32ArrayCid:
      return kSWord;
    case kTypedDataFloat64ArrayCid:
      return kDWord;
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
      return kRegList;
    case kTypedDataInt8ArrayViewCid:
      UNREACHABLE();
      return kByte;
    default:
      UNREACHABLE();
      return kByte;
  }
}

bool Address::CanHoldLoadOffset(OperandSize size,
                                int32_t offset,
                                int32_t* offset_mask) {
  switch (size) {
    case kByte:
    case kTwoBytes:
    case kUnsignedTwoBytes:
    case kWordPair: {
      *offset_mask = 0xff;
      return Utils::IsAbsoluteUint(8, offset);  // Addressing mode 3.
    }
    case kUnsignedByte:
    case kFourBytes:
    case kUnsignedFourBytes: {
      *offset_mask = 0xfff;
      return Utils::IsAbsoluteUint(12, offset);  // Addressing mode 2.
    }
    case kSWord:
    case kDWord: {
      *offset_mask = 0x3fc;  // Multiple of 4.
      // VFP addressing mode.
      return (Utils::IsAbsoluteUint(10, offset) && Utils::IsAligned(offset, 4));
    }
    case kRegList: {
      *offset_mask = 0x0;
      return offset == 0;
    }
    default: {
      UNREACHABLE();
      return false;
    }
  }
}

bool Address::CanHoldStoreOffset(OperandSize size,
                                 int32_t offset,
                                 int32_t* offset_mask) {
  switch (size) {
    case kTwoBytes:
    case kUnsignedTwoBytes:
    case kWordPair: {
      *offset_mask = 0xff;
      return Utils::IsAbsoluteUint(8, offset);  // Addressing mode 3.
    }
    case kByte:
    case kUnsignedByte:
    case kFourBytes:
    case kUnsignedFourBytes: {
      *offset_mask = 0xfff;
      return Utils::IsAbsoluteUint(12, offset);  // Addressing mode 2.
    }
    case kSWord:
    case kDWord: {
      *offset_mask = 0x3fc;  // Multiple of 4.
      // VFP addressing mode.
      return (Utils::IsAbsoluteUint(10, offset) && Utils::IsAligned(offset, 4));
    }
    case kRegList: {
      *offset_mask = 0x0;
      return offset == 0;
    }
    default: {
      UNREACHABLE();
      return false;
    }
  }
}

bool Address::CanHoldImmediateOffset(bool is_load,
                                     intptr_t cid,
                                     int64_t offset) {
  int32_t offset_mask = 0;
  if (is_load) {
    return CanHoldLoadOffset(OperandSizeFor(cid), offset, &offset_mask);
  } else {
    return CanHoldStoreOffset(OperandSizeFor(cid), offset, &offset_mask);
  }
}

void Assembler::Push(Register rd, Condition cond) {
  str(rd, Address(SP, -target::kWordSize, Address::PreIndex), cond);
}

void Assembler::Pop(Register rd, Condition cond) {
  ldr(rd, Address(SP, target::kWordSize, Address::PostIndex), cond);
}

void Assembler::PushList(RegList regs, Condition cond) {
  stm(DB_W, SP, regs, cond);
}

void Assembler::PopList(RegList regs, Condition cond) {
  ldm(IA_W, SP, regs, cond);
}

void Assembler::PushRegisters(const RegisterSet& regs) {
  const intptr_t fpu_regs_count = regs.FpuRegisterCount();
  if (fpu_regs_count > 0) {
    AddImmediate(SP, -(fpu_regs_count * kFpuRegisterSize));
    // Store fpu registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    mov(TMP, Operand(SP));
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; ++i) {
      QRegister fpu_reg = static_cast<QRegister>(i);
      if (regs.ContainsFpuRegister(fpu_reg)) {
        DRegister d = EvenDRegisterOf(fpu_reg);
        ASSERT(d + 1 == OddDRegisterOf(fpu_reg));
        vstmd(IA_W, IP, d, 2);
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (fpu_regs_count * kFpuRegisterSize));
  }

  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safe point's stack map.
  // NOTE: This matches the order of ARM's multi-register push.
  RegList reg_list = 0;
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      reg_list |= (1 << reg);
    }
  }
  if (reg_list != 0) {
    PushList(reg_list);
  }
}

void Assembler::PopRegisters(const RegisterSet& regs) {
  RegList reg_list = 0;
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      reg_list |= (1 << reg);
    }
  }
  if (reg_list != 0) {
    PopList(reg_list);
  }

  const intptr_t fpu_regs_count = regs.FpuRegisterCount();
  if (fpu_regs_count > 0) {
    // Fpu registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; ++i) {
      QRegister fpu_reg = static_cast<QRegister>(i);
      if (regs.ContainsFpuRegister(fpu_reg)) {
        DRegister d = EvenDRegisterOf(fpu_reg);
        ASSERT(d + 1 == OddDRegisterOf(fpu_reg));
        vldmd(IA_W, SP, d, 2);
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (fpu_regs_count * kFpuRegisterSize));
  }
}

void Assembler::PushNativeCalleeSavedRegisters() {
  // Save new context and C++ ABI callee-saved registers.
  PushList(kAbiPreservedCpuRegs);

  const DRegister firstd = EvenDRegisterOf(kAbiFirstPreservedFpuReg);
  if (TargetCPUFeatures::vfp_supported()) {
    ASSERT(2 * kAbiPreservedFpuRegCount < 16);
    // Save FPU registers. 2 D registers per Q register.
    vstmd(DB_W, SP, firstd, 2 * kAbiPreservedFpuRegCount);
  } else {
    sub(SP, SP, Operand(kAbiPreservedFpuRegCount * kFpuRegisterSize));
  }
}

void Assembler::PopNativeCalleeSavedRegisters() {
  const DRegister firstd = EvenDRegisterOf(kAbiFirstPreservedFpuReg);
  // Restore C++ ABI callee-saved registers.
  if (TargetCPUFeatures::vfp_supported()) {
    // Restore FPU registers. 2 D registers per Q register.
    vldmd(IA_W, SP, firstd, 2 * kAbiPreservedFpuRegCount);
  } else {
    AddImmediate(SP, kAbiPreservedFpuRegCount * kFpuRegisterSize);
  }
  // Restore CPU registers.
  PopList(kAbiPreservedCpuRegs);
}

void Assembler::MoveRegister(Register rd, Register rm, Condition cond) {
  if (rd != rm) {
    mov(rd, Operand(rm), cond);
  }
}

void Assembler::Lsl(Register rd,
                    Register rm,
                    const Operand& shift_imm,
                    Condition cond) {
  ASSERT(shift_imm.type() == 1);
  ASSERT(shift_imm.encoding() != 0);  // Do not use Lsl if no shift is wanted.
  mov(rd, Operand(rm, LSL, shift_imm.encoding()), cond);
}

void Assembler::Lsl(Register rd, Register rm, Register rs, Condition cond) {
  mov(rd, Operand(rm, LSL, rs), cond);
}

void Assembler::Lsr(Register rd,
                    Register rm,
                    const Operand& shift_imm,
                    Condition cond) {
  ASSERT(shift_imm.type() == 1);
  uint32_t shift = shift_imm.encoding();
  ASSERT(shift != 0);  // Do not use Lsr if no shift is wanted.
  if (shift == 32) {
    shift = 0;  // Comply to UAL syntax.
  }
  mov(rd, Operand(rm, LSR, shift), cond);
}

void Assembler::Lsr(Register rd, Register rm, Register rs, Condition cond) {
  mov(rd, Operand(rm, LSR, rs), cond);
}

void Assembler::Asr(Register rd,
                    Register rm,
                    const Operand& shift_imm,
                    Condition cond) {
  ASSERT(shift_imm.type() == 1);
  uint32_t shift = shift_imm.encoding();
  ASSERT(shift != 0);  // Do not use Asr if no shift is wanted.
  if (shift == 32) {
    shift = 0;  // Comply to UAL syntax.
  }
  mov(rd, Operand(rm, ASR, shift), cond);
}

void Assembler::Asrs(Register rd,
                     Register rm,
                     const Operand& shift_imm,
                     Condition cond) {
  ASSERT(shift_imm.type() == 1);
  uint32_t shift = shift_imm.encoding();
  ASSERT(shift != 0);  // Do not use Asr if no shift is wanted.
  if (shift == 32) {
    shift = 0;  // Comply to UAL syntax.
  }
  movs(rd, Operand(rm, ASR, shift), cond);
}

void Assembler::Asr(Register rd, Register rm, Register rs, Condition cond) {
  mov(rd, Operand(rm, ASR, rs), cond);
}

void Assembler::Ror(Register rd,
                    Register rm,
                    const Operand& shift_imm,
                    Condition cond) {
  ASSERT(shift_imm.type() == 1);
  ASSERT(shift_imm.encoding() != 0);  // Use Rrx instruction.
  mov(rd, Operand(rm, ROR, shift_imm.encoding()), cond);
}

void Assembler::Ror(Register rd, Register rm, Register rs, Condition cond) {
  mov(rd, Operand(rm, ROR, rs), cond);
}

void Assembler::Rrx(Register rd, Register rm, Condition cond) {
  mov(rd, Operand(rm, ROR, 0), cond);
}

void Assembler::SignFill(Register rd, Register rm, Condition cond) {
  Asr(rd, rm, Operand(31), cond);
}

void Assembler::Vreciprocalqs(QRegister qd, QRegister qm) {
  ASSERT(qm != QTMP);
  ASSERT(qd != QTMP);

  // Reciprocal estimate.
  vrecpeqs(qd, qm);
  // 2 Newton-Raphson steps.
  vrecpsqs(QTMP, qm, qd);
  vmulqs(qd, qd, QTMP);
  vrecpsqs(QTMP, qm, qd);
  vmulqs(qd, qd, QTMP);
}

void Assembler::VreciprocalSqrtqs(QRegister qd, QRegister qm) {
  ASSERT(qm != QTMP);
  ASSERT(qd != QTMP);

  // Reciprocal square root estimate.
  vrsqrteqs(qd, qm);
  // 2 Newton-Raphson steps. xn+1 = xn * (3 - Q1*xn^2) / 2.
  // First step.
  vmulqs(QTMP, qd, qd);       // QTMP <- xn^2
  vrsqrtsqs(QTMP, qm, QTMP);  // QTMP <- (3 - Q1*QTMP) / 2.
  vmulqs(qd, qd, QTMP);       // xn+1 <- xn * QTMP
  // Second step.
  vmulqs(QTMP, qd, qd);
  vrsqrtsqs(QTMP, qm, QTMP);
  vmulqs(qd, qd, QTMP);
}

void Assembler::Vsqrtqs(QRegister qd, QRegister qm, QRegister temp) {
  ASSERT(temp != QTMP);
  ASSERT(qm != QTMP);
  ASSERT(qd != QTMP);

  if (temp != kNoQRegister) {
    vmovq(temp, qm);
    qm = temp;
  }

  VreciprocalSqrtqs(qd, qm);
  vmovq(qm, qd);
  Vreciprocalqs(qd, qm);
}

void Assembler::Vdivqs(QRegister qd, QRegister qn, QRegister qm) {
  ASSERT(qd != QTMP);
  ASSERT(qn != QTMP);
  ASSERT(qm != QTMP);

  Vreciprocalqs(qd, qm);
  vmulqs(qd, qn, qd);
}

void Assembler::Branch(const Code& target,
                       ObjectPoolBuilderEntry::Patchability patchable,
                       Register pp,
                       Condition cond) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), patchable);
  LoadWordFromPoolIndex(CODE_REG, index, pp, cond);
  Branch(FieldAddress(CODE_REG, target::Code::entry_point_offset()), cond);
}

void Assembler::Branch(const Address& address, Condition cond) {
  ldr(PC, address, cond);
}

void Assembler::BranchLink(const Code& target,
                           ObjectPoolBuilderEntry::Patchability patchable,
                           CodeEntryKind entry_kind) {
  // Make sure that class CallPattern is able to patch the label referred
  // to by this code sequence.
  // For added code robustness, use 'blx lr' in a patchable sequence and
  // use 'blx ip' in a non-patchable sequence (see other BranchLink flavors).
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), patchable);
  LoadWordFromPoolIndex(CODE_REG, index, PP, AL);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::BranchLinkPatchable(const Code& target,
                                    CodeEntryKind entry_kind) {
  BranchLink(target, ObjectPoolBuilderEntry::kPatchable, entry_kind);
}

void Assembler::BranchLinkToRuntime() {
  ldr(IP, Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
  blx(IP);
}

void Assembler::BranchLinkWithEquivalence(const Code& target,
                                          const Object& equivalence,
                                          CodeEntryKind entry_kind) {
  // Make sure that class CallPattern is able to patch the label referred
  // to by this code sequence.
  // For added code robustness, use 'blx lr' in a patchable sequence and
  // use 'blx ip' in a non-patchable sequence (see other BranchLink flavors).
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), equivalence);
  LoadWordFromPoolIndex(CODE_REG, index, PP, AL);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::BranchLink(const ExternalLabel* label) {
  CLOBBERS_LR({
    LoadImmediate(LR, label->address());  // Target address is never patched.
    blx(LR);  // Use blx instruction so that the return branch prediction works.
  });
}

void Assembler::BranchLinkOffset(Register base, int32_t offset) {
  ASSERT(base != PC);
  ASSERT(base != IP);
  LoadFromOffset(IP, base, offset);
  blx(IP);  // Use blx instruction so that the return branch prediction works.
}

void Assembler::LoadPatchableImmediate(Register rd,
                                       int32_t value,
                                       Condition cond) {
  const uint16_t value_low = Utils::Low16Bits(value);
  const uint16_t value_high = Utils::High16Bits(value);
  movw(rd, value_low, cond);
  movt(rd, value_high, cond);
}

void Assembler::LoadDecodableImmediate(Register rd,
                                       int32_t value,
                                       Condition cond) {
  movw(rd, Utils::Low16Bits(value), cond);
  const uint16_t value_high = Utils::High16Bits(value);
  if (value_high != 0) {
    movt(rd, value_high, cond);
  }
}

void Assembler::LoadImmediate(Register rd, int32_t value, Condition cond) {
  Operand o;
  if (Operand::CanHold(value, &o)) {
    mov(rd, o, cond);
  } else if (Operand::CanHold(~value, &o)) {
    mvn(rd, o, cond);
  } else {
    LoadDecodableImmediate(rd, value, cond);
  }
}

void Assembler::LoadSImmediate(SRegister sd, float value, Condition cond) {
  if (!vmovs(sd, value, cond)) {
    const DRegister dd = static_cast<DRegister>(sd >> 1);
    const int index = sd & 1;
    LoadImmediate(IP, bit_cast<int32_t, float>(value), cond);
    vmovdr(dd, index, IP, cond);
  }
}

void Assembler::LoadDImmediate(DRegister dd,
                               double value,
                               Register scratch,
                               Condition cond) {
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

void Assembler::LoadFromOffset(Register reg,
                               Register base,
                               int32_t offset,
                               OperandSize size,
                               Condition cond) {
  ASSERT(size != kWordPair);
  int32_t offset_mask = 0;
  if (!Address::CanHoldLoadOffset(size, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  switch (size) {
    case kByte:
      ldrsb(reg, Address(base, offset), cond);
      break;
    case kUnsignedByte:
      ldrb(reg, Address(base, offset), cond);
      break;
    case kTwoBytes:
      ldrsh(reg, Address(base, offset), cond);
      break;
    case kUnsignedTwoBytes:
      ldrh(reg, Address(base, offset), cond);
      break;
    case kFourBytes:
      ldr(reg, Address(base, offset), cond);
      break;
    default:
      UNREACHABLE();
  }
}

void Assembler::LoadFromStack(Register dst, intptr_t depth) {
  ASSERT(depth >= 0);
  LoadFromOffset(dst, SPREG, depth * target::kWordSize);
}

void Assembler::StoreToStack(Register src, intptr_t depth) {
  ASSERT(depth >= 0);
  StoreToOffset(src, SPREG, depth * target::kWordSize);
}

void Assembler::CompareToStack(Register src, intptr_t depth) {
  LoadFromStack(TMP, depth);
  CompareRegisters(src, TMP);
}

void Assembler::StoreToOffset(Register reg,
                              Register base,
                              int32_t offset,
                              OperandSize size,
                              Condition cond) {
  ASSERT(size != kWordPair);
  int32_t offset_mask = 0;
  if (!Address::CanHoldStoreOffset(size, offset, &offset_mask)) {
    ASSERT(reg != IP);
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  switch (size) {
    case kByte:
      strb(reg, Address(base, offset), cond);
      break;
    case kTwoBytes:
      strh(reg, Address(base, offset), cond);
      break;
    case kFourBytes:
      str(reg, Address(base, offset), cond);
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
  if (!Address::CanHoldLoadOffset(kSWord, offset, &offset_mask)) {
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
  if (!Address::CanHoldStoreOffset(kSWord, offset, &offset_mask)) {
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
  if (!Address::CanHoldLoadOffset(kDWord, offset, &offset_mask)) {
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
  if (!Address::CanHoldStoreOffset(kDWord, offset, &offset_mask)) {
    ASSERT(base != IP);
    AddImmediate(IP, base, offset & ~offset_mask, cond);
    base = IP;
    offset = offset & offset_mask;
  }
  vstrd(reg, Address(base, offset), cond);
}

void Assembler::LoadMultipleDFromOffset(DRegister first,
                                        intptr_t count,
                                        Register base,
                                        int32_t offset) {
  ASSERT(base != IP);
  AddImmediate(IP, base, offset);
  vldmd(IA, IP, first, count);
}

void Assembler::StoreMultipleDToOffset(DRegister first,
                                       intptr_t count,
                                       Register base,
                                       int32_t offset) {
  ASSERT(base != IP);
  AddImmediate(IP, base, offset);
  vstmd(IA, IP, first, count);
}

void Assembler::CopyDoubleField(Register dst,
                                Register src,
                                Register tmp1,
                                Register tmp2,
                                DRegister dtmp) {
  if (TargetCPUFeatures::vfp_supported()) {
    LoadDFromOffset(dtmp, src, target::Double::value_offset() - kHeapObjectTag);
    StoreDToOffset(dtmp, dst, target::Double::value_offset() - kHeapObjectTag);
  } else {
    LoadFieldFromOffset(tmp1, src, target::Double::value_offset());
    LoadFieldFromOffset(tmp2, src,
                        target::Double::value_offset() + target::kWordSize);
    StoreFieldToOffset(tmp1, dst, target::Double::value_offset());
    StoreFieldToOffset(tmp2, dst,
                       target::Double::value_offset() + target::kWordSize);
  }
}

void Assembler::CopyFloat32x4Field(Register dst,
                                   Register src,
                                   Register tmp1,
                                   Register tmp2,
                                   DRegister dtmp) {
  if (TargetCPUFeatures::neon_supported()) {
    LoadMultipleDFromOffset(dtmp, 2, src,
                            target::Float32x4::value_offset() - kHeapObjectTag);
    StoreMultipleDToOffset(dtmp, 2, dst,
                           target::Float32x4::value_offset() - kHeapObjectTag);
  } else {
    LoadFieldFromOffset(
        tmp1, src, target::Float32x4::value_offset() + 0 * target::kWordSize);
    LoadFieldFromOffset(
        tmp2, src, target::Float32x4::value_offset() + 1 * target::kWordSize);
    StoreFieldToOffset(
        tmp1, dst, target::Float32x4::value_offset() + 0 * target::kWordSize);
    StoreFieldToOffset(
        tmp2, dst, target::Float32x4::value_offset() + 1 * target::kWordSize);

    LoadFieldFromOffset(
        tmp1, src, target::Float32x4::value_offset() + 2 * target::kWordSize);
    LoadFieldFromOffset(
        tmp2, src, target::Float32x4::value_offset() + 3 * target::kWordSize);
    StoreFieldToOffset(
        tmp1, dst, target::Float32x4::value_offset() + 2 * target::kWordSize);
    StoreFieldToOffset(
        tmp2, dst, target::Float32x4::value_offset() + 3 * target::kWordSize);
  }
}

void Assembler::CopyFloat64x2Field(Register dst,
                                   Register src,
                                   Register tmp1,
                                   Register tmp2,
                                   DRegister dtmp) {
  if (TargetCPUFeatures::neon_supported()) {
    LoadMultipleDFromOffset(dtmp, 2, src,
                            target::Float64x2::value_offset() - kHeapObjectTag);
    StoreMultipleDToOffset(dtmp, 2, dst,
                           target::Float64x2::value_offset() - kHeapObjectTag);
  } else {
    LoadFieldFromOffset(
        tmp1, src, target::Float64x2::value_offset() + 0 * target::kWordSize);
    LoadFieldFromOffset(
        tmp2, src, target::Float64x2::value_offset() + 1 * target::kWordSize);
    StoreFieldToOffset(
        tmp1, dst, target::Float64x2::value_offset() + 0 * target::kWordSize);
    StoreFieldToOffset(
        tmp2, dst, target::Float64x2::value_offset() + 1 * target::kWordSize);

    LoadFieldFromOffset(
        tmp1, src, target::Float64x2::value_offset() + 2 * target::kWordSize);
    LoadFieldFromOffset(
        tmp2, src, target::Float64x2::value_offset() + 3 * target::kWordSize);
    StoreFieldToOffset(
        tmp1, dst, target::Float64x2::value_offset() + 2 * target::kWordSize);
    StoreFieldToOffset(
        tmp2, dst, target::Float64x2::value_offset() + 3 * target::kWordSize);
  }
}

void Assembler::AddImmediate(Register rd,
                             Register rn,
                             int32_t value,
                             Condition cond) {
  if (value == 0) {
    if (rd != rn) {
      mov(rd, Operand(rn), cond);
    }
    return;
  }
  // We prefer to select the shorter code sequence rather than selecting add for
  // positive values and sub for negatives ones, which would slightly improve
  // the readability of generated code for some constants.
  Operand o;
  if (Operand::CanHold(value, &o)) {
    add(rd, rn, o, cond);
  } else if (Operand::CanHold(-value, &o)) {
    sub(rd, rn, o, cond);
  } else {
    ASSERT(rn != IP);
    if (Operand::CanHold(~value, &o)) {
      mvn(IP, o, cond);
      add(rd, rn, Operand(IP), cond);
    } else if (Operand::CanHold(~(-value), &o)) {
      mvn(IP, o, cond);
      sub(rd, rn, Operand(IP), cond);
    } else if (value > 0) {
      LoadDecodableImmediate(IP, value, cond);
      add(rd, rn, Operand(IP), cond);
    } else {
      LoadDecodableImmediate(IP, -value, cond);
      sub(rd, rn, Operand(IP), cond);
    }
  }
}

void Assembler::AddImmediateSetFlags(Register rd,
                                     Register rn,
                                     int32_t value,
                                     Condition cond) {
  Operand o;
  if (Operand::CanHold(value, &o)) {
    // Handles value == kMinInt32.
    adds(rd, rn, o, cond);
  } else if (Operand::CanHold(-value, &o)) {
    ASSERT(value != kMinInt32);  // Would cause erroneous overflow detection.
    subs(rd, rn, o, cond);
  } else {
    ASSERT(rn != IP);
    if (Operand::CanHold(~value, &o)) {
      mvn(IP, o, cond);
      adds(rd, rn, Operand(IP), cond);
    } else if (Operand::CanHold(~(-value), &o)) {
      ASSERT(value != kMinInt32);  // Would cause erroneous overflow detection.
      mvn(IP, o, cond);
      subs(rd, rn, Operand(IP), cond);
    } else {
      LoadDecodableImmediate(IP, value, cond);
      adds(rd, rn, Operand(IP), cond);
    }
  }
}

void Assembler::SubImmediate(Register rd,
                             Register rn,
                             int32_t value,
                             Condition cond) {
  AddImmediate(rd, rn, -value, cond);
}

void Assembler::SubImmediateSetFlags(Register rd,
                                     Register rn,
                                     int32_t value,
                                     Condition cond) {
  Operand o;
  if (Operand::CanHold(value, &o)) {
    // Handles value == kMinInt32.
    subs(rd, rn, o, cond);
  } else if (Operand::CanHold(-value, &o)) {
    ASSERT(value != kMinInt32);  // Would cause erroneous overflow detection.
    adds(rd, rn, o, cond);
  } else {
    ASSERT(rn != IP);
    if (Operand::CanHold(~value, &o)) {
      mvn(IP, o, cond);
      subs(rd, rn, Operand(IP), cond);
    } else if (Operand::CanHold(~(-value), &o)) {
      ASSERT(value != kMinInt32);  // Would cause erroneous overflow detection.
      mvn(IP, o, cond);
      adds(rd, rn, Operand(IP), cond);
    } else {
      LoadDecodableImmediate(IP, value, cond);
      subs(rd, rn, Operand(IP), cond);
    }
  }
}

void Assembler::AndImmediate(Register rd,
                             Register rs,
                             int32_t imm,
                             Condition cond) {
  Operand o;
  if (Operand::CanHold(imm, &o)) {
    and_(rd, rs, Operand(o), cond);
  } else {
    LoadImmediate(TMP, imm, cond);
    and_(rd, rs, Operand(TMP), cond);
  }
}

void Assembler::CompareImmediate(Register rn, int32_t value, Condition cond) {
  Operand o;
  if (Operand::CanHold(value, &o)) {
    cmp(rn, o, cond);
  } else {
    ASSERT(rn != IP);
    LoadImmediate(IP, value, cond);
    cmp(rn, Operand(IP), cond);
  }
}

void Assembler::TestImmediate(Register rn, int32_t imm, Condition cond) {
  Operand o;
  if (Operand::CanHold(imm, &o)) {
    tst(rn, o, cond);
  } else {
    LoadImmediate(IP, imm);
    tst(rn, Operand(IP), cond);
  }
}

void Assembler::IntegerDivide(Register result,
                              Register left,
                              Register right,
                              DRegister tmpl,
                              DRegister tmpr) {
  ASSERT(tmpl != tmpr);
  if (TargetCPUFeatures::integer_division_supported()) {
    sdiv(result, left, right);
  } else {
    ASSERT(TargetCPUFeatures::vfp_supported());
    SRegister stmpl = EvenSRegisterOf(tmpl);
    SRegister stmpr = EvenSRegisterOf(tmpr);
    vmovsr(stmpl, left);
    vcvtdi(tmpl, stmpl);  // left is in tmpl.
    vmovsr(stmpr, right);
    vcvtdi(tmpr, stmpr);  // right is in tmpr.
    vdivd(tmpr, tmpl, tmpr);
    vcvtid(stmpr, tmpr);
    vmovrs(result, stmpr);
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
    add(FP, SP, Operand(4 * NumRegsBelowFP(regs)));
  }
  if (frame_size != 0) {
    AddImmediate(SP, -frame_size);
  }
}

void Assembler::LeaveFrame(RegList regs, bool allow_pop_pc) {
  ASSERT(allow_pop_pc || (regs & (1 << PC)) == 0);  // Must not pop PC.
  if ((regs & (1 << FP)) != 0) {
    // Use FP to set SP.
    sub(SP, FP, Operand(4 * NumRegsBelowFP(regs)));
  }
  PopList(regs);
}

void Assembler::Ret(Condition cond /* = AL */) {
  READS_RETURN_ADDRESS_FROM_LR(bx(LR, cond));
}

void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  AddImmediate(SP, -frame_space);
  if (OS::ActivationFrameAlignment() > 1) {
    bic(SP, SP, Operand(OS::ActivationFrameAlignment() - 1));
  }
}

void Assembler::EmitEntryFrameVerification(Register scratch) {
#if defined(DEBUG)
  Label done;
  ASSERT(!constant_pool_allowed());
  LoadImmediate(scratch, target::frame_layout.exit_link_slot_from_entry_fp *
                             target::kWordSize);
  add(scratch, scratch, Operand(FPREG));
  cmp(scratch, Operand(SPREG));
  b(&done, EQ);

  Breakpoint();

  Bind(&done);
#endif
}

void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  Comment("EnterCallRuntimeFrame");
  // Preserve volatile CPU registers and PP.
  SPILLS_LR_TO_FRAME(
      EnterFrame(kDartVolatileCpuRegs | (1 << PP) | (1 << FP) | (1 << LR), 0));
  COMPILE_ASSERT((kDartVolatileCpuRegs & (1 << PP)) == 0);

  // Preserve all volatile FPU registers.
  if (TargetCPUFeatures::vfp_supported()) {
    DRegister firstv = EvenDRegisterOf(kDartFirstVolatileFpuReg);
    DRegister lastv = OddDRegisterOf(kDartLastVolatileFpuReg);
    if ((lastv - firstv + 1) >= 16) {
      DRegister mid = static_cast<DRegister>(firstv + 16);
      vstmd(DB_W, SP, mid, lastv - mid + 1);
      vstmd(DB_W, SP, firstv, 16);
    } else {
      vstmd(DB_W, SP, firstv, lastv - firstv + 1);
    }
  }

  ReserveAlignedFrameSpace(frame_space);
}

void Assembler::LeaveCallRuntimeFrame() {
  // SP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  const intptr_t kPushedFpuRegisterSize =
      TargetCPUFeatures::vfp_supported()
          ? kDartVolatileFpuRegCount * kFpuRegisterSize
          : 0;

  COMPILE_ASSERT(PP < FP);
  COMPILE_ASSERT((kDartVolatileCpuRegs & (1 << PP)) == 0);
  // kVolatileCpuRegCount +1 for PP, -1 because even though LR is volatile,
  // it is pushed ahead of FP.
  const intptr_t kPushedRegistersSize =
      kDartVolatileCpuRegCount * target::kWordSize + kPushedFpuRegisterSize;
  AddImmediate(SP, FP, -kPushedRegistersSize);

  // Restore all volatile FPU registers.
  if (TargetCPUFeatures::vfp_supported()) {
    DRegister firstv = EvenDRegisterOf(kDartFirstVolatileFpuReg);
    DRegister lastv = OddDRegisterOf(kDartLastVolatileFpuReg);
    if ((lastv - firstv + 1) >= 16) {
      DRegister mid = static_cast<DRegister>(firstv + 16);
      vldmd(IA_W, SP, firstv, 16);
      vldmd(IA_W, SP, mid, lastv - mid + 1);
    } else {
      vldmd(IA_W, SP, firstv, lastv - firstv + 1);
    }
  }

  // Restore volatile CPU registers.
  RESTORES_LR_FROM_FRAME(
      LeaveFrame(kDartVolatileCpuRegs | (1 << PP) | (1 << FP) | (1 << LR)));
}

void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}

void Assembler::EnterDartFrame(intptr_t frame_size, bool load_pool_pointer) {
  ASSERT(!constant_pool_allowed());

  // Registers are pushed in descending order: R5 | R6 | R7/R11 | R14.
  COMPILE_ASSERT(PP < CODE_REG);
  COMPILE_ASSERT(CODE_REG < FP);
  COMPILE_ASSERT(FP < LINK_REGISTER.code);

  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    SPILLS_LR_TO_FRAME(
        EnterFrame((1 << PP) | (1 << CODE_REG) | (1 << FP) | (1 << LR), 0));

    // Setup pool pointer for this dart function.
    if (load_pool_pointer) LoadPoolPointer();
  } else {
    SPILLS_LR_TO_FRAME(EnterFrame((1 << FP) | (1 << LR), 0));
  }
  set_constant_pool_allowed(true);

  // Reserve space for locals.
  AddImmediate(SP, -frame_size);
}

// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate. We must also set up the pool pointer for the function.
void Assembler::EnterOsrFrame(intptr_t extra_size) {
  ASSERT(!constant_pool_allowed());
  Comment("EnterOsrFrame");
  RestoreCodePointer();
  LoadPoolPointer();

  AddImmediate(SP, -extra_size);
}

void Assembler::LeaveDartFrame() {
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    ldr(PP, Address(FP, target::frame_layout.saved_caller_pp_from_fp *
                            target::kWordSize));
  }
  set_constant_pool_allowed(false);

  // This will implicitly drop saved PP, PC marker due to restoring SP from FP
  // first.
  RESTORES_LR_FROM_FRAME(LeaveFrame((1 << FP) | (1 << LR)));
}

void Assembler::LeaveDartFrameAndReturn() {
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    ldr(PP, Address(FP, target::frame_layout.saved_caller_pp_from_fp *
                            target::kWordSize));
  }
  set_constant_pool_allowed(false);

  // This will implicitly drop saved PP, PC marker due to restoring SP from FP
  // first.
  LeaveFrame((1 << FP) | (1 << PC), /*allow_pop_pc=*/true);
}

void Assembler::EnterStubFrame() {
  EnterDartFrame(0);
}

void Assembler::LeaveStubFrame() {
  LeaveDartFrame();
}

void Assembler::EnterCFrame(intptr_t frame_space) {
  EnterFrame(1 << FP, 0);
  ReserveAlignedFrameSpace(frame_space);
}

void Assembler::LeaveCFrame() {
  LeaveFrame(1 << FP);
}

// R0 receiver, R9 ICData entries array
// Preserve R4 (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryJIT() {
  has_monomorphic_entry_ = true;
#if defined(TESTING) || defined(DEBUG)
  bool saved_use_far_branches = use_far_branches();
  set_use_far_branches(false);
#endif
  intptr_t start = CodeSize();

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetJIT);

  const intptr_t cid_offset = target::Array::element_offset(0);
  const intptr_t count_offset = target::Array::element_offset(1);

  // Sadly this cannot use ldm because ldm takes no offset.
  ldr(R1, FieldAddress(R9, cid_offset));
  ldr(R2, FieldAddress(R9, count_offset));
  LoadClassIdMayBeSmi(IP, R0);
  add(R2, R2, Operand(target::ToRawSmi(1)));
  cmp(R1, Operand(IP, LSL, 1));
  Branch(Address(THR, target::Thread::switchable_call_miss_entry_offset()), NE);
  str(R2, FieldAddress(R9, count_offset));
  LoadImmediate(R4, 0);  // GC-safe for OptimizeInvokedFunction.

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetJIT);

#if defined(TESTING) || defined(DEBUG)
  set_use_far_branches(saved_use_far_branches);
#endif
}

// R0 receiver, R9 guarded cid as Smi.
// Preserve R4 (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryAOT() {
  has_monomorphic_entry_ = true;
#if defined(TESTING) || defined(DEBUG)
  bool saved_use_far_branches = use_far_branches();
  set_use_far_branches(false);
#endif
  intptr_t start = CodeSize();

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetAOT);

  LoadClassId(IP, R0);
  cmp(R9, Operand(IP, LSL, 1));
  Branch(Address(THR, target::Thread::switchable_call_miss_entry_offset()), NE);

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetAOT);

#if defined(TESTING) || defined(DEBUG)
  set_use_far_branches(saved_use_far_branches);
#endif
}

void Assembler::BranchOnMonomorphicCheckedEntryJIT(Label* label) {
  has_monomorphic_entry_ = true;
  while (CodeSize() < target::Instructions::kMonomorphicEntryOffsetJIT) {
    bkpt(0);
  }
  b(label);
  while (CodeSize() < target::Instructions::kPolymorphicEntryOffsetJIT) {
    bkpt(0);
  }
}

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(Register stats_addr_reg, Label* trace) {
  ASSERT(stats_addr_reg != kNoRegister);
  ASSERT(stats_addr_reg != TMP);
  ldrb(TMP, Address(stats_addr_reg, 0));
  cmp(TMP, Operand(0));
  b(trace, NE);
}

void Assembler::LoadAllocationStatsAddress(Register dest, intptr_t cid) {
  ASSERT(dest != kNoRegister);
  ASSERT(dest != TMP);
  ASSERT(cid > 0);

  const intptr_t shared_table_offset =
      target::Isolate::shared_class_table_offset();
  const intptr_t table_offset =
      target::SharedClassTable::class_heap_stats_table_offset();
  const intptr_t class_offset = target::ClassTable::ClassOffsetFor(cid);

  LoadIsolate(dest);
  ldr(dest, Address(dest, shared_table_offset));
  ldr(dest, Address(dest, table_offset));
  AddImmediate(dest, class_offset);
}
#endif  // !PRODUCT

void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            Register instance_reg,
                            Register temp_reg) {
  ASSERT(failure != NULL);
  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    const classid_t cid = target::Class::GetId(cls);
    ASSERT(instance_reg != temp_reg);
    ASSERT(temp_reg != IP);
    ASSERT(instance_size != 0);
    NOT_IN_PRODUCT(LoadAllocationStatsAddress(temp_reg, cid));
    ldr(instance_reg, Address(THR, target::Thread::top_offset()));
    // TODO(koda): Protect against unsigned overflow here.
    AddImmediateSetFlags(instance_reg, instance_reg, instance_size);

    // instance_reg: potential next object start.
    ldr(IP, Address(THR, target::Thread::end_offset()));
    cmp(IP, Operand(instance_reg));
    // fail if heap end unsigned less than or equal to instance_reg.
    b(failure, LS);

    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(temp_reg, failure));

    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    str(instance_reg, Address(THR, target::Thread::top_offset()));

    ASSERT(instance_size >= kHeapObjectTag);
    AddImmediate(instance_reg, -instance_size + kHeapObjectTag);

    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(IP, tags);
    str(IP, FieldAddress(instance_reg, target::Object::tags_offset()));
  } else {
    b(failure);
  }
}

void Assembler::TryAllocateArray(intptr_t cid,
                                 intptr_t instance_size,
                                 Label* failure,
                                 Register instance,
                                 Register end_address,
                                 Register temp1,
                                 Register temp2) {
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    NOT_IN_PRODUCT(LoadAllocationStatsAddress(temp1, cid));
    // Potential new object start.
    ldr(instance, Address(THR, target::Thread::top_offset()));
    AddImmediateSetFlags(end_address, instance, instance_size);
    b(failure, CS);  // Branch if unsigned overflow.

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start.
    // end_address: potential next object start.
    ldr(temp2, Address(THR, target::Thread::end_offset()));
    cmp(end_address, Operand(temp2));
    b(failure, CS);

    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(temp1, failure));

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    str(end_address, Address(THR, target::Thread::top_offset()));
    add(instance, instance, Operand(kHeapObjectTag));

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(temp2, tags);
    str(temp2,
        FieldAddress(instance, target::Object::tags_offset()));  // Store tags.
  } else {
    b(failure);
  }
}

void Assembler::GenerateUnRelocatedPcRelativeCall(Condition cond,
                                                  intptr_t offset_into_target) {
  // Emit "blr.cond <offset>".
  EmitType5(cond, 0x686868, /*link=*/true);

  PcRelativeCallPattern pattern(buffer_.contents() + buffer_.Size() -
                                PcRelativeCallPattern::kLengthInBytes);
  pattern.set_distance(offset_into_target);
}

void Assembler::GenerateUnRelocatedPcRelativeTailCall(
    Condition cond,
    intptr_t offset_into_target) {
  // Emit "b <offset>".
  EmitType5(cond, 0x686868, /*link=*/false);

  PcRelativeTailCallPattern pattern(buffer_.contents() + buffer_.Size() -
                                    PcRelativeTailCallPattern::kLengthInBytes);
  pattern.set_distance(offset_into_target);
}

Address Assembler::ElementAddressForIntIndex(bool is_load,
                                             bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             intptr_t index,
                                             Register temp) {
  const int64_t offset_base =
      (is_external ? 0
                   : (target::Instance::DataOffsetFor(cid) - kHeapObjectTag));
  const int64_t offset =
      offset_base + static_cast<int64_t>(index) * index_scale;
  ASSERT(Utils::IsInt(32, offset));

  if (Address::CanHoldImmediateOffset(is_load, cid, offset)) {
    return Address(array, static_cast<int32_t>(offset));
  } else {
    ASSERT(Address::CanHoldImmediateOffset(is_load, cid, offset - offset_base));
    AddImmediate(temp, array, static_cast<int32_t>(offset_base));
    return Address(temp, static_cast<int32_t>(offset - offset_base));
  }
}

void Assembler::LoadElementAddressForIntIndex(Register address,
                                              bool is_load,
                                              bool is_external,
                                              intptr_t cid,
                                              intptr_t index_scale,
                                              Register array,
                                              intptr_t index) {
  const int64_t offset_base =
      (is_external ? 0
                   : (target::Instance::DataOffsetFor(cid) - kHeapObjectTag));
  const int64_t offset =
      offset_base + static_cast<int64_t>(index) * index_scale;
  ASSERT(Utils::IsInt(32, offset));
  AddImmediate(address, array, offset);
}

Address Assembler::ElementAddressForRegIndex(bool is_load,
                                             bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             bool index_unboxed,
                                             Register array,
                                             Register index) {
  // If unboxed, index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
  int32_t offset =
      is_external ? 0 : (target::Instance::DataOffsetFor(cid) - kHeapObjectTag);
  const OperandSize size = Address::OperandSizeFor(cid);
  ASSERT(array != IP);
  ASSERT(index != IP);
  const Register base = is_load ? IP : index;
  if ((offset != 0) || (is_load && (size == kByte)) || (size == kTwoBytes) ||
      (size == kUnsignedTwoBytes) || (size == kSWord) || (size == kDWord) ||
      (size == kRegList)) {
    if (shift < 0) {
      ASSERT(shift == -1);
      add(base, array, Operand(index, ASR, 1));
    } else {
      add(base, array, Operand(index, LSL, shift));
    }
  } else {
    if (shift < 0) {
      ASSERT(shift == -1);
      return Address(array, index, ASR, 1);
    } else {
      return Address(array, index, LSL, shift);
    }
  }
  int32_t offset_mask = 0;
  if ((is_load && !Address::CanHoldLoadOffset(size, offset, &offset_mask)) ||
      (!is_load && !Address::CanHoldStoreOffset(size, offset, &offset_mask))) {
    AddImmediate(base, offset & ~offset_mask);
    offset = offset & offset_mask;
  }
  return Address(base, offset);
}

void Assembler::LoadElementAddressForRegIndex(Register address,
                                              bool is_load,
                                              bool is_external,
                                              intptr_t cid,
                                              intptr_t index_scale,
                                              bool index_unboxed,
                                              Register array,
                                              Register index) {
  // If unboxed, index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
  int32_t offset =
      is_external ? 0 : (target::Instance::DataOffsetFor(cid) - kHeapObjectTag);
  if (shift < 0) {
    ASSERT(shift == -1);
    add(address, array, Operand(index, ASR, 1));
  } else {
    add(address, array, Operand(index, LSL, shift));
  }
  if (offset != 0) {
    AddImmediate(address, offset);
  }
}

void Assembler::LoadFieldAddressForRegOffset(Register address,
                                             Register instance,
                                             Register offset_in_words_as_smi) {
  add(address, instance,
      Operand(offset_in_words_as_smi, LSL,
              target::kWordSizeLog2 - kSmiTagShift));
  AddImmediate(address, -kHeapObjectTag);
}

void Assembler::LoadHalfWordUnaligned(Register dst,
                                      Register addr,
                                      Register tmp) {
  ASSERT(dst != addr);
  ldrb(dst, Address(addr, 0));
  ldrsb(tmp, Address(addr, 1));
  orr(dst, dst, Operand(tmp, LSL, 8));
}

void Assembler::LoadHalfWordUnsignedUnaligned(Register dst,
                                              Register addr,
                                              Register tmp) {
  ASSERT(dst != addr);
  ldrb(dst, Address(addr, 0));
  ldrb(tmp, Address(addr, 1));
  orr(dst, dst, Operand(tmp, LSL, 8));
}

void Assembler::StoreHalfWordUnaligned(Register src,
                                       Register addr,
                                       Register tmp) {
  strb(src, Address(addr, 0));
  Lsr(tmp, src, Operand(8));
  strb(tmp, Address(addr, 1));
}

void Assembler::LoadWordUnaligned(Register dst, Register addr, Register tmp) {
  ASSERT(dst != addr);
  ldrb(dst, Address(addr, 0));
  ldrb(tmp, Address(addr, 1));
  orr(dst, dst, Operand(tmp, LSL, 8));
  ldrb(tmp, Address(addr, 2));
  orr(dst, dst, Operand(tmp, LSL, 16));
  ldrb(tmp, Address(addr, 3));
  orr(dst, dst, Operand(tmp, LSL, 24));
}

void Assembler::StoreWordUnaligned(Register src, Register addr, Register tmp) {
  strb(src, Address(addr, 0));
  Lsr(tmp, src, Operand(8));
  strb(tmp, Address(addr, 1));
  Lsr(tmp, src, Operand(16));
  strb(tmp, Address(addr, 2));
  Lsr(tmp, src, Operand(24));
  strb(tmp, Address(addr, 3));
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM)
