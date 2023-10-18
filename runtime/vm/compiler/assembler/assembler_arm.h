// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_ARM_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_ARM_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_arm.h directly; use assembler.h instead.
#endif

#include <functional>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/code_entry_kind.h"
#include "vm/compiler/assembler/assembler_base.h"
#include "vm/compiler/assembler/object_pool_builder.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/cpu.h"
#include "vm/hash_map.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class RegisterSet;
class RuntimeEntry;

// Load/store multiple addressing mode.
enum BlockAddressMode {
  // bit encoding P U W
  DA = (0 | 0 | 0) << 21,    // decrement after
  IA = (0 | 4 | 0) << 21,    // increment after
  DB = (8 | 0 | 0) << 21,    // decrement before
  IB = (8 | 4 | 0) << 21,    // increment before
  DA_W = (0 | 0 | 1) << 21,  // decrement after with writeback to base
  IA_W = (0 | 4 | 1) << 21,  // increment after with writeback to base
  DB_W = (8 | 0 | 1) << 21,  // decrement before with writeback to base
  IB_W = (8 | 4 | 1) << 21   // increment before with writeback to base
};

namespace compiler {

class Immediate : public ValueObject {
 public:
  explicit Immediate(int32_t value) : value_(value) {}

  int32_t value() const { return value_; }

 private:
  const int32_t value_;
};

// Instruction encoding bits.
enum {
  H = 1 << 5,   // halfword (or byte)
  L = 1 << 20,  // load (or store)
  S = 1 << 20,  // set condition code (or leave unchanged)
  W = 1 << 21,  // writeback base register (or leave unchanged)
  A = 1 << 21,  // accumulate in multiply instruction (or not)
  B = 1 << 22,  // unsigned byte (or word)
  D = 1 << 22,  // high/lo bit of start of s/d register range
  N = 1 << 22,  // long (or short)
  U = 1 << 23,  // positive (or negative) offset/index
  P = 1 << 24,  // offset/pre-indexed addressing (or post-indexed addressing)
  I = 1 << 25,  // immediate shifter operand (or not)

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
};

class ArmEncode : public AllStatic {
 public:
  static inline uint32_t Rd(Register rd) {
    ASSERT(rd < 16);
    return static_cast<uint32_t>(rd) << kRdShift;
  }

  static inline uint32_t Rm(Register rm) {
    ASSERT(rm < 16);
    return static_cast<uint32_t>(rm) << kRmShift;
  }

  static inline uint32_t Rn(Register rn) {
    ASSERT(rn < 16);
    return static_cast<uint32_t>(rn) << kRnShift;
  }

  static inline uint32_t Rs(Register rs) {
    ASSERT(rs < 16);
    return static_cast<uint32_t>(rs) << kRsShift;
  }
};

// Encodes Addressing Mode 1 - Data-processing operands.
class Operand : public ValueObject {
 public:
  // Data-processing operands - Uninitialized.
  Operand() : type_(-1), encoding_(-1) {}

  // Data-processing operands - Copy constructor.
  Operand(const Operand& other)
      : ValueObject(), type_(other.type_), encoding_(other.encoding_) {}

  // Data-processing operands - Assignment operator.
  Operand& operator=(const Operand& other) {
    type_ = other.type_;
    encoding_ = other.encoding_;
    return *this;
  }

  // Data-processing operands - Immediate.
  explicit Operand(uint32_t immediate) {
    ASSERT(immediate < (1 << kImmed8Bits));
    type_ = 1;
    encoding_ = immediate;
  }

  // Data-processing operands - Rotated immediate.
  Operand(uint32_t rotate, uint32_t immed8) {
    ASSERT((rotate < (1 << kRotateBits)) && (immed8 < (1 << kImmed8Bits)));
    type_ = 1;
    encoding_ = (rotate << kRotateShift) | (immed8 << kImmed8Shift);
  }

  // Data-processing operands - Register.
  explicit Operand(Register rm) {
    type_ = 0;
    encoding_ = static_cast<uint32_t>(rm);
  }

  // Data-processing operands - Logical shift/rotate by immediate.
  Operand(Register rm, Shift shift, uint32_t shift_imm) {
    ASSERT(shift_imm < (1 << kShiftImmBits));
    type_ = 0;
    encoding_ = shift_imm << kShiftImmShift |
                static_cast<uint32_t>(shift) << kShiftShift |
                static_cast<uint32_t>(rm);
  }

  // Data-processing operands - Logical shift/rotate by register.
  Operand(Register rm, Shift shift, Register rs) {
    type_ = 0;
    encoding_ = static_cast<uint32_t>(rs) << kShiftRegisterShift |
                static_cast<uint32_t>(shift) << kShiftShift | (1 << 4) |
                static_cast<uint32_t>(rm);
  }

  static bool CanHold(uint32_t immediate, Operand* o) {
    // Avoid the more expensive test for frequent small immediate values.
    if (immediate < (1 << kImmed8Bits)) {
      o->type_ = 1;
      o->encoding_ = (0 << kRotateShift) | (immediate << kImmed8Shift);
      return true;
    }
    // Note that immediate must be unsigned for the test to work correctly.
    for (int rot = 0; rot < 16; rot++) {
      uint32_t imm8 = Utils::RotateLeft(immediate, 2 * rot);
      if (imm8 < (1 << kImmed8Bits)) {
        o->type_ = 1;
        o->encoding_ = (rot << kRotateShift) | (imm8 << kImmed8Shift);
        return true;
      }
    }
    return false;
  }

 private:
  bool is_valid() const { return (type_ == 0) || (type_ == 1); }

  uint32_t type() const {
    ASSERT(is_valid());
    return type_;
  }

  uint32_t encoding() const {
    ASSERT(is_valid());
    return encoding_;
  }

  uint32_t type_;  // Encodes the type field (bits 27-25) in the instruction.
  uint32_t encoding_;

  friend class Assembler;
  friend class Address;
};

class Address : public ValueObject {
 public:
  enum OffsetKind {
    Immediate,
    IndexRegister,
    ScaledIndexRegister,
  };

  // Memory operand addressing mode
  enum Mode {
    kModeMask = (8 | 4 | 1) << 21,
    // bit encoding P U W
    Offset = (8 | 4 | 0) << 21,       // offset (w/o writeback to base)
    PreIndex = (8 | 4 | 1) << 21,     // pre-indexed addressing with writeback
    PostIndex = (0 | 4 | 0) << 21,    // post-indexed addressing with writeback
    NegOffset = (8 | 0 | 0) << 21,    // negative offset (w/o writeback to base)
    NegPreIndex = (8 | 0 | 1) << 21,  // negative pre-indexed with writeback
    NegPostIndex = (0 | 0 | 0) << 21  // negative post-indexed with writeback
  };

  Address(const Address& other)
      : ValueObject(),
        encoding_(other.encoding_),
        kind_(other.kind_),
        base_(other.base_),
        offset_(other.offset_) {}

  Address& operator=(const Address& other) {
    encoding_ = other.encoding_;
    kind_ = other.kind_;
    base_ = other.base_;
    offset_ = other.offset_;
    return *this;
  }

  bool Equals(const Address& other) const {
    return (encoding_ == other.encoding_) && (kind_ == other.kind_);
  }

  explicit Address(Register rn, int32_t offset = 0, Mode am = Offset) {
    kind_ = Immediate;
    base_ = rn;
    offset_ = offset;
    // If the offset can't be encoded in fewer bits, then it'll conflict with
    // the encoding of the mode and we won't be able to retrieve it later.
    ASSERT(Utils::MagnitudeIsUint(kOpcodeShift, offset));
    if (offset < 0) {
      encoding_ = (am ^ (1 << kUShift)) | -offset;  // Flip U to adjust sign.
    } else {
      encoding_ = am | offset;
    }
    encoding_ |= ArmEncode::Rn(rn);
  }

  // There is no register offset mode unless Mode is Offset, in which case the
  // shifted register case below should be used.
  Address(Register rn, Register r, Mode am);

  Address(Register rn,
          Register rm,
          Shift shift = LSL,
          uint32_t shift_imm = 0,
          Mode am = Offset) {
    Operand o(rm, shift, shift_imm);

    if ((shift == LSL) && (shift_imm == 0)) {
      kind_ = IndexRegister;
    } else {
      kind_ = ScaledIndexRegister;
    }
    encoding_ = o.encoding() | am | ArmEncode::Rn(rn);
  }

  // There is no shifted register mode with a register shift.
  Address(Register rn, Register rm, Shift shift, Register r, Mode am = Offset);

  static OperandSize OperandSizeFor(intptr_t cid);

  static bool CanHoldLoadOffset(OperandSize size,
                                int32_t offset,
                                int32_t* offset_mask);
  static bool CanHoldStoreOffset(OperandSize size,
                                 int32_t offset,
                                 int32_t* offset_mask);
  static bool CanHoldImmediateOffset(bool is_load,
                                     intptr_t cid,
                                     int64_t offset);

 private:
  Register rn() const {
    return Instr::At(reinterpret_cast<uword>(&encoding_))->RnField();
  }

  Register rm() const {
    return ((kind() == IndexRegister) || (kind() == ScaledIndexRegister))
               ? Instr::At(reinterpret_cast<uword>(&encoding_))->RmField()
               : kNoRegister;
  }

  Mode mode() const { return static_cast<Mode>(encoding_ & kModeMask); }

  bool has_writeback() const {
    return (mode() == PreIndex) || (mode() == PostIndex) ||
           (mode() == NegPreIndex) || (mode() == NegPostIndex);
  }

  static bool has_writeback(BlockAddressMode am) {
    switch (am) {
      case DA:
      case IA:
      case DB:
      case IB:
        return false;
      case DA_W:
      case IA_W:
      case DB_W:
      case IB_W:
        return true;
      default:
        UNREACHABLE();
        return false;
    }
  }

  uint32_t encoding() const {
    ASSERT_IMPLIES(kind_ == Immediate, Utils::MagnitudeIsUint(12, offset_));
    return encoding_;
  }

  // Encoding for addressing mode 3.
  uint32_t encoding3() const;

  // Encoding for vfp load/store addressing.
  uint32_t vencoding() const;

  OffsetKind kind() const { return kind_; }
  Register base() const { return base_; }
  int32_t offset() const { return offset_; }

  uint32_t encoding_;

  OffsetKind kind_;
  Register base_ = kNoRegister;
  int32_t offset_ = 0;

  friend class Assembler;
};

class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) {}

  // This addressing mode does not exist.
  FieldAddress(Register base, Register r);

  FieldAddress(const FieldAddress& other) : Address(other) {}

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};

class Assembler : public AssemblerBase {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder,
                     intptr_t far_branch_level = 0);
  ~Assembler() {}

  void PushRegister(Register r) { Push(r); }
  void PopRegister(Register r) { Pop(r); }

  // Push two registers to the stack; r0 to lower address location.
  void PushRegisterPair(Register r0, Register r1) {
    if ((r0 < r1) && (r0 != SP) && (r1 != SP)) {
      RegList reg_list = (1 << r0) | (1 << r1);
      PushList(reg_list);
    } else {
      PushRegister(r1);
      PushRegister(r0);
    }
  }

  // Pop two registers from the stack; r0 from lower address location.
  void PopRegisterPair(Register r0, Register r1) {
    if ((r0 < r1) && (r0 != SP) && (r1 != SP)) {
      RegList reg_list = (1 << r0) | (1 << r1);
      PopList(reg_list);
    } else {
      PopRegister(r0);
      PopRegister(r1);
    }
  }

  void PushValueAtOffset(Register base, int32_t offset) { UNIMPLEMENTED(); }

  void Bind(Label* label);
  // Unconditional jump to a given label. [distance] is ignored on ARM.
  void Jump(Label* label, JumpDistance distance = kFarJump) { b(label); }
  // Unconditional jump to a given address in register.
  void Jump(Register target) { bx(target); }
  // Unconditional jump to a given address in memory.
  void Jump(const Address& address) { Branch(address); }

  void LoadField(Register dst, const FieldAddress& address) override {
    LoadFromOffset(dst, address);
  }
  void LoadMemoryValue(Register dst, Register base, int32_t offset) {
    LoadFromOffset(dst, base, offset);
  }
  void LoadCompressed(Register dest, const Address& slot) {
    LoadFromOffset(dest, slot);
  }
  void LoadCompressedSmi(Register dest, const Address& slot) override;
  void StoreMemoryValue(Register src, Register base, int32_t offset) {
    StoreToOffset(src, base, offset);
  }
  void LoadAcquire(Register dst,
                   Register address,
                   int32_t offset = 0,
                   OperandSize size = kFourBytes) override {
    LoadFromOffset(dst, Address(address, offset), size);
    dmb();
  }
  void StoreRelease(Register src,
                    Register address,
                    int32_t offset = 0) override {
    StoreRelease(src, Address(address, offset));
  }
  void StoreRelease(Register src, Address dest) {
    dmb();
    StoreToOffset(src, dest);

    // We don't run TSAN bots on 32 bit.
  }

  void CompareWithCompressedFieldFromOffset(Register value,
                                            Register base,
                                            int32_t offset) {
    LoadCompressedFieldFromOffset(TMP, base, offset);
    cmp(value, Operand(TMP));
  }

  void CompareWithMemoryValue(Register value,
                              Address address,
                              OperandSize size = kFourBytes) override {
    ASSERT_EQUAL(size, kFourBytes);
    LoadFromOffset(TMP, address, size);
    cmp(value, Operand(TMP));
  }

  // Misc. functionality
  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

#if defined(TESTING) || defined(DEBUG)
  // Used in unit tests and to ensure predictable verification code size in
  // FlowGraphCompiler::EmitEdgeCounter.
  void set_use_far_branches(bool b) { use_far_branches_ = b; }
#endif  // TESTING || DEBUG

  // Debugging and bringup support.
  void Breakpoint() override { bkpt(0); }

  // Data-processing instructions.
  void and_(Register rd, Register rn, Operand o, Condition cond = AL);
  void ands(Register rd, Register rn, Operand o, Condition cond = AL);

  void eor(Register rd, Register rn, Operand o, Condition cond = AL);

  void sub(Register rd, Register rn, Operand o, Condition cond = AL);
  void subs(Register rd, Register rn, Operand o, Condition cond = AL);

  void rsb(Register rd, Register rn, Operand o, Condition cond = AL);
  void rsbs(Register rd, Register rn, Operand o, Condition cond = AL);

  void add(Register rd, Register rn, Operand o, Condition cond = AL);

  void adds(Register rd, Register rn, Operand o, Condition cond = AL);

  void adc(Register rd, Register rn, Operand o, Condition cond = AL);

  void adcs(Register rd, Register rn, Operand o, Condition cond = AL);

  void sbc(Register rd, Register rn, Operand o, Condition cond = AL);

  void sbcs(Register rd, Register rn, Operand o, Condition cond = AL);

  void rsc(Register rd, Register rn, Operand o, Condition cond = AL);

  void tst(Register rn, Operand o, Condition cond = AL);

  void teq(Register rn, Operand o, Condition cond = AL);

  void cmp(Register rn, Operand o, Condition cond = AL);

  void cmn(Register rn, Operand o, Condition cond = AL);

  void orr(Register rd, Register rn, Operand o, Condition cond = AL);
  void orrs(Register rd, Register rn, Operand o, Condition cond = AL);

  void mov(Register rd, Operand o, Condition cond = AL);
  void movs(Register rd, Operand o, Condition cond = AL);

  void bic(Register rd, Register rn, Operand o, Condition cond = AL);
  void bics(Register rd, Register rn, Operand o, Condition cond = AL);

  void mvn_(Register rd, Operand o, Condition cond = AL);
  void mvns(Register rd, Operand o, Condition cond = AL);

  // Miscellaneous data-processing instructions.
  void clz(Register rd, Register rm, Condition cond = AL);
  void rbit(Register rd, Register rm, Condition cond = AL);

  // Multiply instructions.
  void mul(Register rd, Register rn, Register rm, Condition cond = AL);
  void muls(Register rd, Register rn, Register rm, Condition cond = AL);
  void mla(Register rd,
           Register rn,
           Register rm,
           Register ra,
           Condition cond = AL);
  void mls(Register rd,
           Register rn,
           Register rm,
           Register ra,
           Condition cond = AL);
  void smull(Register rd_lo,
             Register rd_hi,
             Register rn,
             Register rm,
             Condition cond = AL);
  void umull(Register rd_lo,
             Register rd_hi,
             Register rn,
             Register rm,
             Condition cond = AL);
  void smlal(Register rd_lo,
             Register rd_hi,
             Register rn,
             Register rm,
             Condition cond = AL);
  void umlal(Register rd_lo,
             Register rd_hi,
             Register rn,
             Register rm,
             Condition cond = AL);

  // Emulation of this instruction uses IP and the condition codes. Therefore,
  // none of the registers can be IP, and the instruction can only be used
  // unconditionally.
  void umaal(Register rd_lo, Register rd_hi, Register rn, Register rm);

  // Division instructions.
  void sdiv(Register rd, Register rn, Register rm, Condition cond = AL);
  void udiv(Register rd, Register rn, Register rm, Condition cond = AL);

  // Load/store instructions.
  void ldr(Register rd, Address ad, Condition cond = AL);
  void str(Register rd, Address ad, Condition cond = AL);

  void ldrb(Register rd, Address ad, Condition cond = AL);
  void strb(Register rd, Address ad, Condition cond = AL);

  void ldrh(Register rd, Address ad, Condition cond = AL);
  void strh(Register rd, Address ad, Condition cond = AL);

  void ldrsb(Register rd, Address ad, Condition cond = AL);
  void ldrsh(Register rd, Address ad, Condition cond = AL);

  // ldrd and strd actually support the full range of addressing modes, but
  // we don't use them, so we only support the base + offset mode.
  // rd must be an even register and rd2 must be rd + 1.
  void ldrd(Register rd,
            Register rd2,
            Register rn,
            int32_t offset,
            Condition cond = AL);
  void strd(Register rd,
            Register rd2,
            Register rn,
            int32_t offset,
            Condition cond = AL);

  void ldm(BlockAddressMode am,
           Register base,
           RegList regs,
           Condition cond = AL);
  void stm(BlockAddressMode am,
           Register base,
           RegList regs,
           Condition cond = AL);

  void ldrex(Register rd, Register rn, Condition cond = AL);
  void strex(Register rd, Register rt, Register rn, Condition cond = AL);

  void dmb();

  // Media instructions.
  void sbfx(Register rd,
            Register rn,
            int32_t lsb,
            int32_t width,
            Condition cond = AL);
  void ubfx(Register rd,
            Register rn,
            int32_t lsb,
            int32_t width,
            Condition cond = AL);

  // Emit code to transition between generated and native modes.
  //
  // These require that CSP and SP are equal and aligned and require two scratch
  // registers (in addition to TMP).
  void TransitionGeneratedToNative(Register destination_address,
                                   Register exit_frame_fp,
                                   Register exit_through_ffi,
                                   Register scratch0,
                                   bool enter_safepoint);
  void TransitionNativeToGenerated(Register scratch0,
                                   Register scratch1,
                                   bool exit_safepoint,
                                   bool ignore_unwind_in_progress = false);
  void EnterFullSafepoint(Register scratch0, Register scratch1);
  void ExitFullSafepoint(Register scratch0,
                         Register scratch1,
                         bool ignore_unwind_in_progress);

  // Miscellaneous instructions.
  void clrex();
  void nop(Condition cond = AL);

  // Note that gdb sets breakpoints using the undefined instruction 0xe7f001f0.
  void bkpt(uint16_t imm16);

  static int32_t BkptEncoding(uint16_t imm16) {
    // bkpt requires that the cond field is AL.
    return (AL << kConditionShift) | B24 | B21 | ((imm16 >> 4) << 8) | B6 | B5 |
           B4 | (imm16 & 0xf);
  }

  // Floating point instructions (VFPv3-D16 and VFPv3-D32 profiles).
  void vmovsr(SRegister sn, Register rt, Condition cond = AL);
  void vmovrs(Register rt, SRegister sn, Condition cond = AL);
  void vmovsrr(SRegister sm, Register rt, Register rt2, Condition cond = AL);
  void vmovrrs(Register rt, Register rt2, SRegister sm, Condition cond = AL);
  void vmovdrr(DRegister dm, Register rt, Register rt2, Condition cond = AL);
  void vmovrrd(Register rt, Register rt2, DRegister dm, Condition cond = AL);
  void vmovdr(DRegister dd, int i, Register rt, Condition cond = AL);
  void vmovs(SRegister sd, SRegister sm, Condition cond = AL);
  void vmovd(DRegister dd, DRegister dm, Condition cond = AL);
  void vmovq(QRegister qd, QRegister qm);

  // Returns false if the immediate cannot be encoded.
  bool vmovs(SRegister sd, float s_imm, Condition cond = AL);
  bool vmovd(DRegister dd, double d_imm, Condition cond = AL);

  void vldrs(SRegister sd, Address ad, Condition cond = AL);
  void vstrs(SRegister sd, Address ad, Condition cond = AL);
  void vldrd(DRegister dd, Address ad, Condition cond = AL);
  void vstrd(DRegister dd, Address ad, Condition cond = AL);

  void vldms(BlockAddressMode am,
             Register base,
             SRegister first,
             SRegister last,
             Condition cond = AL);
  void vstms(BlockAddressMode am,
             Register base,
             SRegister first,
             SRegister last,
             Condition cond = AL);

  void vldmd(BlockAddressMode am,
             Register base,
             DRegister first,
             intptr_t count,
             Condition cond = AL);
  void vstmd(BlockAddressMode am,
             Register base,
             DRegister first,
             intptr_t count,
             Condition cond = AL);

  void vadds(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vaddd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vaddqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vaddqs(QRegister qd, QRegister qn, QRegister qm);
  void vsubs(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vsubd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vsubqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vsubqs(QRegister qd, QRegister qn, QRegister qm);
  void vmuls(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vmuld(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vmulqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vmulqs(QRegister qd, QRegister qn, QRegister qm);
  void vshlqi(OperandSize sz, QRegister qd, QRegister qm, QRegister qn);
  void vshlqu(OperandSize sz, QRegister qd, QRegister qm, QRegister qn);
  void vmlas(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vmlad(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vmlss(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vmlsd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vdivs(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vdivd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vminqs(QRegister qd, QRegister qn, QRegister qm);
  void vmaxqs(QRegister qd, QRegister qn, QRegister qm);
  void vrecpeqs(QRegister qd, QRegister qm);
  void vrecpsqs(QRegister qd, QRegister qn, QRegister qm);
  void vrsqrteqs(QRegister qd, QRegister qm);
  void vrsqrtsqs(QRegister qd, QRegister qn, QRegister qm);

  void veorq(QRegister qd, QRegister qn, QRegister qm);
  void vorrq(QRegister qd, QRegister qn, QRegister qm);
  void vornq(QRegister qd, QRegister qn, QRegister qm);
  void vandq(QRegister qd, QRegister qn, QRegister qm);
  void vmvnq(QRegister qd, QRegister qm);

  void vceqqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vceqqs(QRegister qd, QRegister qn, QRegister qm);
  void vcgeqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vcugeqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vcgeqs(QRegister qd, QRegister qn, QRegister qm);
  void vcgtqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vcugtqi(OperandSize sz, QRegister qd, QRegister qn, QRegister qm);
  void vcgtqs(QRegister qd, QRegister qn, QRegister qm);

  void vabss(SRegister sd, SRegister sm, Condition cond = AL);
  void vabsd(DRegister dd, DRegister dm, Condition cond = AL);
  void vabsqs(QRegister qd, QRegister qm);
  void vnegs(SRegister sd, SRegister sm, Condition cond = AL);
  void vnegd(DRegister dd, DRegister dm, Condition cond = AL);
  void vnegqs(QRegister qd, QRegister qm);
  void vsqrts(SRegister sd, SRegister sm, Condition cond = AL);
  void vsqrtd(DRegister dd, DRegister dm, Condition cond = AL);

  void vcvtsd(SRegister sd, DRegister dm, Condition cond = AL);
  void vcvtds(DRegister dd, SRegister sm, Condition cond = AL);
  void vcvtis(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtid(SRegister sd, DRegister dm, Condition cond = AL);
  void vcvtsi(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtdi(DRegister dd, SRegister sm, Condition cond = AL);
  void vcvtus(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtud(SRegister sd, DRegister dm, Condition cond = AL);
  void vcvtsu(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtdu(DRegister dd, SRegister sm, Condition cond = AL);

  void vcmps(SRegister sd, SRegister sm, Condition cond = AL);
  void vcmpd(DRegister dd, DRegister dm, Condition cond = AL);
  void vcmpsz(SRegister sd, Condition cond = AL);
  void vcmpdz(DRegister dd, Condition cond = AL);
  void vmrs(Register rd, Condition cond = AL);
  void vmstat(Condition cond = AL);

  // Duplicates the operand of size sz at index idx from dm to all elements of
  // qd. This is a special case of vtbl.
  void vdup(OperandSize sz, QRegister qd, DRegister dm, int idx);

  // Each byte of dm is an index into the table of bytes formed by concatenating
  // a list of 'length' registers starting with dn. The result is placed in dd.
  void vtbl(DRegister dd, DRegister dn, int length, DRegister dm);

  // The words of qd and qm are interleaved with the low words of the result
  // in qd and the high words in qm.
  void vzipqw(QRegister qd, QRegister qm);

  // Branch instructions.
  void b(Label* label, Condition cond = AL);
  void bl(Label* label, Condition cond = AL);
  void bx(Register rm, Condition cond = AL);
  void blx(Register rm, Condition cond = AL);

  void Branch(const Code& code,
              ObjectPoolBuilderEntry::Patchability patchable =
                  ObjectPoolBuilderEntry::kNotPatchable,
              Register pp = PP,
              Condition cond = AL);

  void Branch(const Address& address, Condition cond = AL);

  void BranchLink(const Code& code,
                  ObjectPoolBuilderEntry::Patchability patchable =
                      ObjectPoolBuilderEntry::kNotPatchable,
                  CodeEntryKind entry_kind = CodeEntryKind::kNormal,
                  ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
                      ObjectPoolBuilderEntry::kSnapshotable);

  // Branch and link to an entry address. Call sequence can be patched.
  void BranchLinkPatchable(
      const Code& code,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable);

  // Emit a call that shares its object pool entries with other calls
  // that have the same equivalence marker.
  void BranchLinkWithEquivalence(
      const Code& code,
      const Object& equivalence,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal);

  // Branch and link to [base + offset]. Call sequence is never patched.
  void BranchLinkOffset(Register base, int32_t offset);

  void Call(Address target, Condition cond = AL) {
    // CLOBBERS_LR uses __ to access the assembler.
#define __ this->
    CLOBBERS_LR({
      ldr(LR, target, cond);
      blx(LR, cond);
    });
#undef __
  }
  void Call(const Code& code) { BranchLink(code); }

  void CallCFunction(Address target) { Call(target); }

  void CallCFunction(Register target, Condition cond = AL) {
    blx(target, cond);
  }

  // Add signed immediate value to rd. May clobber IP.
  void AddImmediate(Register rd, int32_t value, Condition cond = AL) {
    AddImmediate(rd, rd, value, cond);
  }

  // Add signed immediate value. May clobber IP.
  void AddImmediate(Register rd,
                    Register rn,
                    int32_t value,
                    Condition cond = AL);
  void AddImmediateSetFlags(Register rd,
                            Register rn,
                            int32_t value,
                            Condition cond = AL);
  void AddRegisters(Register dest, Register src) {
    add(dest, dest, Operand(src));
  }
  // [dest] = [src] << [scale] + [value].
  void AddScaled(Register dest,
                 Register src,
                 ScaleFactor scale,
                 int32_t value) {
    if (scale == 0) {
      AddImmediate(dest, src, value);
    } else {
      Lsl(dest, src, Operand(scale));
      AddImmediate(dest, dest, value);
    }
  }
  void SubImmediate(Register rd,
                    Register rn,
                    int32_t value,
                    Condition cond = AL);
  void SubImmediateSetFlags(Register rd,
                            Register rn,
                            int32_t value,
                            Condition cond = AL);
  void SubRegisters(Register dest, Register src) {
    sub(dest, dest, Operand(src));
  }
  void MulImmediate(Register reg,
                    int32_t imm,
                    OperandSize width = kFourBytes) override {
    ASSERT(width == kFourBytes);
    if (Utils::IsPowerOfTwo(imm)) {
      LslImmediate(reg, Utils::ShiftForPowerOfTwo(imm));
    } else {
      LoadImmediate(TMP, imm);
      mul(reg, reg, TMP);
    }
  }
  void AndImmediate(Register rd, Register rs, int32_t imm, Condition cond = AL);
  void AndImmediate(Register rd, int32_t imm, Condition cond) {
    AndImmediate(rd, rd, imm, cond);
  }
  void AndImmediate(Register rd, int32_t imm) override {
    AndImmediate(rd, rd, imm, AL);
  }
  void AndImmediateSetFlags(Register rd,
                            Register rn,
                            int32_t value,
                            Condition cond = AL);
  void AndRegisters(Register dst,
                    Register src1,
                    Register src2 = kNoRegister) override {
    ASSERT(src1 != src2);  // Likely a mistake.
    if (src2 == kNoRegister) {
      src2 = dst;
    }
    and_(dst, src2, Operand(src1));
  }
  void OrImmediate(Register rd, Register rs, int32_t imm, Condition cond = AL);
  void OrImmediate(Register rd, int32_t imm, Condition cond = AL) {
    OrImmediate(rd, rd, imm, cond);
  }
  void LslImmediate(Register rd, Register rn, int32_t shift) {
    ASSERT((shift >= 0) && (shift < kBitsPerInt32));
    Lsl(rd, rn, Operand(shift));
  }
  void LslImmediate(Register rd, int32_t shift) {
    LslImmediate(rd, rd, shift);
  }
  void LslRegister(Register dst, Register shift) override {
    Lsl(dst, dst, shift);
  }
  void LsrImmediate(Register rd, Register rn, int32_t shift) {
    ASSERT((shift >= 0) && (shift < kBitsPerInt32));
    Lsr(rd, rn, Operand(shift));
  }
  void LsrImmediate(Register rd, int32_t shift) override {
    LsrImmediate(rd, rd, shift);
  }

  // Test rn and immediate. May clobber IP.
  void TestImmediate(Register rn, int32_t imm, Condition cond = AL);

  // Compare rn with signed immediate value. May clobber IP.
  void CompareImmediate(Register rn, int32_t value, Condition cond);
  void CompareImmediate(Register rn,
                        int32_t value,
                        OperandSize width = kFourBytes) override {
    ASSERT_EQUAL(width, kFourBytes);
    CompareImmediate(rn, value, AL);
  }

  // Signed integer division of left by right. Checks to see if integer
  // division is supported. If not, uses the FPU for division with
  // temporary registers tmpl and tmpr. tmpl and tmpr must be different
  // registers.
  void IntegerDivide(Register result,
                     Register left,
                     Register right,
                     DRegister tmpl,
                     DRegister tmpr);

  // Load and Store.
  // These three do not clobber IP.
  void LoadPatchableImmediate(Register rd, int32_t value, Condition cond = AL);
  void LoadDecodableImmediate(Register rd, int32_t value, Condition cond = AL);
  void LoadImmediate(Register rd, Immediate value, Condition cond = AL);
  void LoadImmediate(Register rd, int32_t value, Condition cond = AL);
  // These two may clobber IP.
  void LoadSImmediate(SRegister sd, float value, Condition cond = AL);
  void LoadDImmediate(DRegister dd,
                      double value,
                      Register scratch,
                      Condition cond = AL);
  void LoadQImmediate(QRegister dd, simd128_value_t value);

  void MarkExceptionHandler(Label* label);

  void Drop(intptr_t stack_elements);

  void RestoreCodePointer();
  void LoadPoolPointer(Register reg = PP);
  void SetupGlobalPoolAndDispatchTable();

  void LoadIsolate(Register rd);
  void LoadIsolateGroup(Register dst);

  // Load word from pool from the given index using encoding that
  // InstructionPattern::DecodeLoadWordFromPool can decode.
  void LoadWordFromPoolIndex(Register rd,
                             intptr_t index,
                             Register pp = PP,
                             Condition cond = AL);

  void LoadObject(Register rd, const Object& object, Condition cond = AL);
  void LoadUniqueObject(Register rd, const Object& object, Condition cond = AL);
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       ObjectPoolBuilderEntry::Patchability patchable,
                       Condition cond = AL);
  void PushObject(const Object& object);
  void PushImmediate(int32_t immediate) {
    LoadImmediate(TMP, immediate);
    Push(TMP);
  }
  void CompareObject(Register rn, const Object& object);

  // Store into a heap object and apply the generational and incremental write
  // barriers. All stores into heap objects must pass through this function or,
  // if the value can be proven either Smi or old-and-premarked, its NoBarrier
  // variants.
  // Preserves object and value registers.
  void StoreIntoObject(Register object,      // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,       // Value we are storing.
                       CanBeSmi can_value_be_smi = kValueCanBeSmi,
                       MemoryOrder memory_order = kRelaxedNonAtomic) override;
  void StoreIntoArray(Register object,
                      Register slot,
                      Register value,
                      CanBeSmi can_value_be_smi = kValueCanBeSmi);
  void StoreIntoObjectOffset(Register object,
                             int32_t offset,
                             Register value,
                             CanBeSmi can_value_be_smi = kValueCanBeSmi,
                             MemoryOrder memory_order = kRelaxedNonAtomic);

  void StoreIntoObjectNoBarrier(
      Register object,
      const Address& dest,
      Register value,
      MemoryOrder memory_order = kRelaxedNonAtomic) override;
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value,
                                MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreIntoObjectOffsetNoBarrier(
      Register object,
      int32_t offset,
      Register value,
      MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreIntoObjectOffsetNoBarrier(
      Register object,
      int32_t offset,
      const Object& value,
      MemoryOrder memory_order = kRelaxedNonAtomic);

  // Stores a non-tagged value into a heap object.
  void StoreInternalPointer(Register object,
                            const Address& dest,
                            Register value);

  // Store value_even, value_odd, value_even, ... into the words in the address
  // range [begin, end), assumed to be uninitialized fields in object (tagged).
  // The stores must not need a generational store barrier (e.g., smi/null),
  // and (value_even, value_odd) must be a valid register pair.
  // Destroys register 'begin'.
  void InitializeFieldsNoBarrier(Register object,
                                 Register begin,
                                 Register end,
                                 Register value_even,
                                 Register value_odd);
  // Like above, for the range [base+begin_offset, base+end_offset), unrolled.
  void InitializeFieldsNoBarrierUnrolled(Register object,
                                         Register base,
                                         intptr_t begin_offset,
                                         intptr_t end_offset,
                                         Register value_even,
                                         Register value_odd);

  // Stores a Smi value into a heap object field that always contains a Smi.
  void StoreIntoSmiField(const Address& dest, Register value);

  void ExtractClassIdFromTags(Register result,
                              Register tags,
                              Condition cond = AL);
  void ExtractInstanceSizeFromTags(Register result, Register tags);

  void RangeCheck(Register value,
                  Register temp,
                  intptr_t low,
                  intptr_t high,
                  RangeCheckCondition condition,
                  Label* target) override;

  void LoadClassId(Register result, Register object, Condition cond = AL);
  void LoadClassById(Register result, Register class_id);
  void CompareClassId(Register object, intptr_t class_id, Register scratch);
  void LoadClassIdMayBeSmi(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);
  void EnsureHasClassIdInDEBUG(intptr_t cid,
                               Register src,
                               Register scratch,
                               bool can_be_null = false) override;

  bool CanLoadFromObjectPool(const Object& object) const;

  Address PrepareLargeLoadOffset(const Address& addr,
                                 OperandSize sz,
                                 Condition cond);
  Address PrepareLargeStoreOffset(const Address& addr,
                                  OperandSize sz,
                                  Condition cond);

  void LoadFromOffset(Register reg,
                      const Address& address,
                      OperandSize type,
                      Condition cond);
  void LoadFromOffset(Register reg,
                      const Address& address,
                      OperandSize type = kFourBytes) override {
    LoadFromOffset(reg, address, type, AL);
  }
  void LoadFromOffset(Register reg,
                      Register base,
                      int32_t offset,
                      OperandSize type = kFourBytes,
                      Condition cond = AL) {
    LoadFromOffset(reg, Address(base, offset), type, cond);
  }
  void LoadFieldFromOffset(Register reg,
                           Register base,
                           int32_t offset,
                           OperandSize sz = kFourBytes) override {
    LoadFromOffset(reg, FieldAddress(base, offset), sz, AL);
  }
  void LoadFieldFromOffset(Register reg,
                           Register base,
                           int32_t offset,
                           OperandSize type,
                           Condition cond) {
    LoadFromOffset(reg, FieldAddress(base, offset), type, cond);
  }
  void LoadCompressedFieldFromOffset(Register reg,
                                     Register base,
                                     int32_t offset) override {
    LoadCompressedFieldFromOffset(reg, base, offset, kFourBytes, AL);
  }
  void LoadCompressedFieldFromOffset(Register reg,
                                     Register base,
                                     int32_t offset,
                                     OperandSize type,
                                     Condition cond = AL) {
    LoadFieldFromOffset(reg, base, offset, type, cond);
  }
  // For loading indexed payloads out of tagged objects like Arrays. If the
  // payload objects are word-sized, use TIMES_HALF_WORD_SIZE if the contents of
  // [index] is a Smi, otherwise TIMES_WORD_SIZE if unboxed.
  void LoadIndexedPayload(Register dst,
                          Register base,
                          int32_t payload_start,
                          Register index,
                          ScaleFactor scale,
                          OperandSize type = kFourBytes) {
    add(dst, base, Operand(index, LSL, scale));
    LoadFromOffset(dst, dst, payload_start - kHeapObjectTag, type);
  }
  void LoadIndexedCompressed(Register dst,
                             Register base,
                             int32_t offset,
                             Register index) {
    add(dst, base, Operand(index, LSL, TIMES_COMPRESSED_WORD_SIZE));
    LoadCompressedFieldFromOffset(dst, dst, offset);
  }
  void LoadFromStack(Register dst, intptr_t depth);
  void StoreToStack(Register src, intptr_t depth);
  void CompareToStack(Register src, intptr_t depth);

  void StoreToOffset(Register reg,
                     const Address& address,
                     OperandSize type,
                     Condition cond);
  void StoreToOffset(Register reg,
                     const Address& address,
                     OperandSize type = kFourBytes) override {
    StoreToOffset(reg, address, type, AL);
  }
  void StoreToOffset(Register reg,
                     Register base,
                     int32_t offset,
                     OperandSize type = kFourBytes,
                     Condition cond = AL) {
    StoreToOffset(reg, Address(base, offset), type, cond);
  }
  void StoreFieldToOffset(Register reg,
                          Register base,
                          int32_t offset,
                          OperandSize type = kFourBytes,
                          Condition cond = AL) {
    StoreToOffset(reg, FieldAddress(base, offset), type, cond);
  }
  void StoreZero(const Address& address, Register temp) {
    mov(temp, Operand(0));
    StoreToOffset(temp, address);
  }
  void LoadSFromOffset(SRegister reg,
                       Register base,
                       int32_t offset,
                       Condition cond = AL);
  void StoreSToOffset(SRegister reg,
                      Register base,
                      int32_t offset,
                      Condition cond = AL);
  void LoadDFromOffset(DRegister reg,
                       Register base,
                       int32_t offset,
                       Condition cond = AL);
  void StoreDToOffset(DRegister reg,
                      Register base,
                      int32_t offset,
                      Condition cond = AL);

  void LoadUnboxedDouble(FpuRegister dst, Register base, int32_t offset) {
    LoadDFromOffset(EvenDRegisterOf(dst), base, offset);
  }
  void StoreUnboxedDouble(FpuRegister src, Register base, int32_t offset) {
    StoreDToOffset(EvenDRegisterOf(src), base, offset);
  }
  void MoveUnboxedDouble(FpuRegister dst, FpuRegister src) {
    if (src != dst) {
      vmovd(EvenDRegisterOf(dst), EvenDRegisterOf(src));
    }
  }

  void LoadMultipleDFromOffset(DRegister first,
                               intptr_t count,
                               Register base,
                               int32_t offset);
  void StoreMultipleDToOffset(DRegister first,
                              intptr_t count,
                              Register base,
                              int32_t offset);

  void LoadUnboxedSimd128(FpuRegister dst, Register base, int32_t offset) {
    LoadMultipleDFromOffset(EvenDRegisterOf(dst), 2, base, offset);
  }
  void StoreUnboxedSimd128(FpuRegister src, Register base, int32_t offset) {
    StoreMultipleDToOffset(EvenDRegisterOf(src), 2, base, offset);
  }
  void MoveUnboxedSimd128(FpuRegister dst, FpuRegister src) {
    if (src != dst) {
      vmovq(dst, src);
    }
  }

  void Push(Register rd, Condition cond = AL);
  void Pop(Register rd, Condition cond = AL);

  void PushList(RegList regs, Condition cond = AL);
  void PopList(RegList regs, Condition cond = AL);

  void PushQuad(FpuRegister rd, Condition cond = AL);
  void PopQuad(FpuRegister rd, Condition cond = AL);

  void PushRegisters(const RegisterSet& regs);
  void PopRegisters(const RegisterSet& regs);

  void PushRegistersInOrder(std::initializer_list<Register> regs);

  // Push all registers which are callee-saved according to the ARM ABI.
  void PushNativeCalleeSavedRegisters();

  // Pop all registers which are callee-saved according to the ARM ABI.
  void PopNativeCalleeSavedRegisters();

  void CompareRegisters(Register rn, Register rm) { cmp(rn, Operand(rm)); }
  void CompareObjectRegisters(Register rn, Register rm) {
    CompareRegisters(rn, rm);
  }
  // Branches to the given label if the condition holds.
  // [distance] is ignored on ARM.
  void BranchIf(Condition condition,
                Label* label,
                JumpDistance distance = kFarJump) {
    b(label, condition);
  }
  void BranchIfZero(Register rn,
                    Label* label,
                    JumpDistance distance = kFarJump) {
    cmp(rn, Operand(0));
    b(label, ZERO);
  }
  void BranchIfBit(Register rn,
                   intptr_t bit_number,
                   Condition condition,
                   Label* label,
                   JumpDistance distance = kFarJump) {
    tst(rn, Operand(1 << bit_number));
    b(label, condition);
  }

  void MoveRegister(Register rd, Register rm, Condition cond) {
    ExtendValue(rd, rm, kFourBytes, cond);
  }
  void MoveRegister(Register rd, Register rm) override {
    MoveRegister(rd, rm, AL);
  }
  void MoveAndSmiTagRegister(Register rd, Register rm, Condition cond) {
    ExtendAndSmiTagValue(rd, rm, kFourBytes, cond);
  }
  void MoveAndSmiTagRegister(Register rd, Register rm) override {
    MoveAndSmiTagRegister(rd, rm, AL);
  }
  void ExtendValue(Register rd, Register rm, OperandSize sz, Condition cond);
  void ExtendValue(Register rd, Register rm, OperandSize sz) override {
    ExtendValue(rd, rm, sz, AL);
  }
  void ExtendAndSmiTagValue(Register rd,
                            Register rm,
                            OperandSize sz,
                            Condition cond) {
    ExtendValue(rd, rm, sz, cond);
    SmiTag(rd, cond);
  }
  void ExtendAndSmiTagValue(Register rd,
                            Register rm,
                            OperandSize sz = kFourBytes) override {
    ExtendAndSmiTagValue(rd, rm, sz, AL);
  }

  // Convenience shift instructions. Use mov instruction with shifter operand
  // for variants setting the status flags.
  void Lsl(Register rd,
           Register rm,
           const Operand& shift_imm,
           Condition cond = AL);
  void Lsl(Register rd, Register rm, Register rs, Condition cond = AL);
  void Lsr(Register rd,
           Register rm,
           const Operand& shift_imm,
           Condition cond = AL);
  void Lsr(Register rd, Register rm, Register rs, Condition cond = AL);
  void Asr(Register rd,
           Register rm,
           const Operand& shift_imm,
           Condition cond = AL);
  void Asr(Register rd, Register rm, Register rs, Condition cond = AL);
  void Asrs(Register rd,
            Register rm,
            const Operand& shift_imm,
            Condition cond = AL);
  void Ror(Register rd,
           Register rm,
           const Operand& shift_imm,
           Condition cond = AL);
  void Ror(Register rd, Register rm, Register rs, Condition cond = AL);
  void Rrx(Register rd, Register rm, Condition cond = AL);

  // Fill rd with the sign of rm.
  void SignFill(Register rd, Register rm, Condition cond = AL);

  void Vreciprocalqs(QRegister qd, QRegister qm);
  void VreciprocalSqrtqs(QRegister qd, QRegister qm);
  // If qm must be preserved, then provide a (non-QTMP) temporary.
  void Vsqrtqs(QRegister qd, QRegister qm, QRegister temp);
  void Vdivqs(QRegister qd, QRegister qn, QRegister qm);

  void SmiTag(Register reg, Condition cond) { SmiTag(reg, reg, cond); }
  void SmiTag(Register reg) override { SmiTag(reg, AL); }

  void SmiTag(Register dst, Register src, Condition cond = AL) {
    Lsl(dst, src, Operand(kSmiTagSize), cond);
  }

  void SmiUntag(Register reg, Condition cond = AL) { SmiUntag(reg, reg, cond); }

  void SmiUntag(Register dst, Register src, Condition cond = AL) {
    Asr(dst, src, Operand(kSmiTagSize), cond);
  }

  // Untag the value in the register assuming it is a smi.
  // Untagging shifts tag bit into the carry flag - if carry is clear
  // assumption was correct. In this case jump to the is_smi label.
  // Otherwise fall-through.
  void SmiUntag(Register dst, Register src, Label* is_smi) {
    ASSERT(kSmiTagSize == 1);
    Asrs(dst, src, Operand(kSmiTagSize));
    b(is_smi, CC);
  }

  // For ARM, the near argument is ignored.
  void BranchIfNotSmi(Register reg,
                      Label* label,
                      JumpDistance distance = kFarJump) {
    tst(reg, Operand(kSmiTagMask));
    b(label, NE);
  }

  // Truncates upper bits.
  void LoadInt32FromBoxOrSmi(Register result, Register value) override {
    if (result == value) {
      ASSERT(TMP != value);
      MoveRegister(TMP, value);
      value = TMP;
    }
    ASSERT(value != result);
    compiler::Label done;
    SmiUntag(result, value, &done);
    LoadFieldFromOffset(result, value, compiler::target::Mint::value_offset());
    Bind(&done);
  }

  // For ARM, the near argument is ignored.
  void BranchIfSmi(Register reg,
                   Label* label,
                   JumpDistance distance = kFarJump) override {
    tst(reg, Operand(kSmiTagMask));
    b(label, EQ);
  }

  void CheckCodePointer();

  void ArithmeticShiftRightImmediate(Register reg, intptr_t shift) override;
  void CompareWords(Register reg1,
                    Register reg2,
                    intptr_t offset,
                    Register count,
                    Register temp,
                    Label* equals) override;

  // Function frame setup and tear down.
  void EnterFrame(RegList regs, intptr_t frame_space);
  void LeaveFrame(RegList regs, bool allow_pop_pc = false);
  void Ret(Condition cond = AL);

  // Sets the return address to [value] as if there was a call.
  // On ARM sets LR.
  void SetReturnAddress(Register value);

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // In debug mode, this generates code to check that:
  //   FP + kExitLinkSlotFromEntryFp == SP
  // or triggers breakpoint otherwise.
  //
  // Requires a scratch register in addition to the assembler temporary.
  void EmitEntryFrameVerification(Register scratch);

  // For non-leaf runtime calls. For leaf runtime calls, use LeafRuntimeScope,
  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size, bool load_pool_pointer = true);

  void LeaveDartFrame();

  // Leaves the frame and returns.
  //
  // The difference to "LeaveDartFrame(); Ret();" is that we return using
  //
  //   ldmia sp!, {fp, pc}
  //
  // instead of
  //
  //   ldmia sp!, {fp, lr}
  //   blx lr
  //
  // This means that our return must go to ARM mode (and not thumb).
  void LeaveDartFrameAndReturn();

  // Set up a Dart frame for a function compiled for on-stack replacement.
  // The frame layout is a normal Dart frame, but the frame is partially set
  // up on entry (it is the frame of the unoptimized code).
  void EnterOsrFrame(intptr_t extra_size);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame();
  void LeaveStubFrame();

  // Set up a frame for calling a C function.
  // Automatically save the pinned registers in Dart which are not callee-
  // saved in the native calling convention.
  // Use together with CallCFunction.
  void EnterCFrame(intptr_t frame_space);
  void LeaveCFrame();

  void MonomorphicCheckedEntryJIT();
  void MonomorphicCheckedEntryAOT();
  void BranchOnMonomorphicCheckedEntryJIT(Label* label);

  void CombineHashes(Register dst, Register other) override;
  void FinalizeHashForSize(intptr_t bit_size,
                           Register dst,
                           Register scratch = TMP) override;

  // The register into which the allocation tracing state table is loaded with
  // LoadAllocationTracingStateAddress should be passed to MaybeTraceAllocation.
  //
  // These are separate assembler macros so we can avoid a dependent load too
  // nearby the load of the table address.
  void LoadAllocationTracingStateAddress(Register dest, intptr_t cid);

  Address ElementAddressForIntIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index,
                                    Register temp);

  void LoadElementAddressForIntIndex(Register address,
                                     bool is_load,
                                     bool is_external,
                                     intptr_t cid,
                                     intptr_t index_scale,
                                     Register array,
                                     intptr_t index);

  Address ElementAddressForRegIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    bool index_unboxed,
                                    Register array,
                                    Register index);

  void LoadElementAddressForRegIndex(Register address,
                                     bool is_load,
                                     bool is_external,
                                     intptr_t cid,
                                     intptr_t index_scale,
                                     bool index_unboxed,
                                     Register array,
                                     Register index);

  void LoadStaticFieldAddress(Register address,
                              Register field,
                              Register scratch);

  void LoadCompressedFieldAddressForRegOffset(Register address,
                                              Register instance,
                                              Register offset_in_words_as_smi) {
    return LoadFieldAddressForRegOffset(address, instance,
                                        offset_in_words_as_smi);
  }

  void LoadFieldAddressForRegOffset(Register address,
                                    Register instance,
                                    Register offset_in_words_as_smi);

  void LoadFieldAddressForOffset(Register address,
                                 Register instance,
                                 int32_t offset) override {
    AddImmediate(address, instance, offset - kHeapObjectTag);
  }

  void LoadHalfWordUnaligned(Register dst, Register addr, Register tmp);
  void LoadHalfWordUnsignedUnaligned(Register dst, Register addr, Register tmp);
  void StoreHalfWordUnaligned(Register src, Register addr, Register tmp);
  void LoadWordUnaligned(Register dst, Register addr, Register tmp);
  void StoreWordUnaligned(Register src, Register addr, Register tmp);

  // If allocation tracing is enabled, will jump to |trace| label,
  // which will allocate in the runtime where tracing occurs.
  void MaybeTraceAllocation(Register stats_addr_reg, Label* trace);

  // If allocation tracing for |cid| is enabled, will jump to |trace| label,
  // which will allocate in the runtime where tracing occurs.
  void MaybeTraceAllocation(intptr_t cid,
                            Label* trace,
                            Register temp_reg,
                            JumpDistance distance = JumpDistance::kFarJump);

  void TryAllocateObject(intptr_t cid,
                         intptr_t instance_size,
                         Label* failure,
                         JumpDistance distance,
                         Register instance_reg,
                         Register temp_reg) override;

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        Register instance,
                        Register end_address,
                        Register temp1,
                        Register temp2);

  void CheckAllocationCanary(Register top, Register tmp = TMP) {
#if defined(DEBUG)
    Label okay;
    ldr(tmp, Address(top, 0));
    cmp(tmp, Operand(kAllocationCanary));
    b(&okay, EQUAL);
    Stop("Allocation canary");
    Bind(&okay);
#endif
  }
  void WriteAllocationCanary(Register top) {
#if defined(DEBUG)
    ASSERT(top != TMP);
    LoadImmediate(TMP, kAllocationCanary);
    str(TMP, Address(top, 0));
#endif
  }

  // Copy [size] bytes from [src] address to [dst] address.
  // [size] should be a multiple of word size.
  // Clobbers [src], [dst], [size] and [temp] registers.
  void CopyMemoryWords(Register src,
                       Register dst,
                       Register size,
                       Register temp);

  // This emits an PC-relative call of the form "blr.<cond> <offset>".  The
  // offset is not yet known and needs therefore relocation to the right place
  // before the code can be used.
  //
  // The necessary information for the "linker" (i.e. the relocation
  // information) is stored in [UntaggedCode::static_calls_target_table_]: an
  // entry of the form
  //
  //   (Code::kPcRelativeCall & pc_offset, <target-code>, <target-function>)
  //
  // will be used during relocation to fix the offset.
  //
  // The provided [offset_into_target] will be added to calculate the final
  // destination.  It can be used e.g. for calling into the middle of a
  // function.
  void GenerateUnRelocatedPcRelativeCall(Condition cond = AL,
                                         intptr_t offset_into_target = 0);

  // This emits an PC-relative tail call of the form "b.<cond> <offset>".
  //
  // See also above for the pc-relative call.
  void GenerateUnRelocatedPcRelativeTailCall(Condition cond = AL,
                                             intptr_t offset_into_target = 0);

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return target::IsSmi(object); }

  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool b) { constant_pool_allowed_ = b; }

  compiler::LRState lr_state() const { return lr_state_; }
  void set_lr_state(compiler::LRState b) { lr_state_ = b; }

  // Whether we can branch to a target which is [distance] bytes away from the
  // beginning of the branch instruction.
  //
  // Use this function for testing whether [distance] can be encoded using the
  // 24-bit offsets in the branch instructions, which are multiples of 4.
  static bool CanEncodeBranchDistance(int32_t distance) {
    ASSERT(Utils::IsAligned(distance, 4));
    // The distance is off by 8 due to the way the ARM CPUs read PC.
    distance -= Instr::kPCReadOffset;
    distance >>= 2;
    return Utils::IsInt(24, distance);
  }

  static int32_t EncodeBranchOffset(int32_t offset, int32_t inst);
  static int32_t DecodeBranchOffset(int32_t inst);

 private:
  bool use_far_branches_;

  bool constant_pool_allowed_;

  compiler::LRState lr_state_ = compiler::LRState::OnEntry();

  // If you are thinking of using one or both of these instructions directly,
  // instead LoadImmediate should probably be used.
  void movw(Register rd, uint16_t imm16, Condition cond = AL);
  void movt(Register rd, uint16_t imm16, Condition cond = AL);

  void BindARMv7(Label* label);

  void BranchLink(const ExternalLabel* label);

  void LoadObjectHelper(Register rd,
                        const Object& object,
                        Condition cond,
                        bool is_unique,
                        Register pp);

  void EmitType01(Condition cond,
                  int type,
                  Opcode opcode,
                  int set_cc,
                  Register rn,
                  Register rd,
                  Operand o);

  void EmitType5(Condition cond, int32_t offset, bool link);

  void EmitMemOp(Condition cond, bool load, bool byte, Register rd, Address ad);

  void EmitMemOpAddressMode3(Condition cond,
                             int32_t mode,
                             Register rd,
                             Address ad);

  void EmitMultiMemOp(Condition cond,
                      BlockAddressMode am,
                      bool load,
                      Register base,
                      RegList regs);

  void EmitShiftImmediate(Condition cond,
                          Shift opcode,
                          Register rd,
                          Register rm,
                          Operand o);

  void EmitShiftRegister(Condition cond,
                         Shift opcode,
                         Register rd,
                         Register rm,
                         Operand o);

  void EmitMulOp(Condition cond,
                 int32_t opcode,
                 Register rd,
                 Register rn,
                 Register rm,
                 Register rs);

  void EmitDivOp(Condition cond,
                 int32_t opcode,
                 Register rd,
                 Register rn,
                 Register rm);

  void EmitMultiVSMemOp(Condition cond,
                        BlockAddressMode am,
                        bool load,
                        Register base,
                        SRegister start,
                        uint32_t count);

  void EmitMultiVDMemOp(Condition cond,
                        BlockAddressMode am,
                        bool load,
                        Register base,
                        DRegister start,
                        int32_t count);

  void EmitVFPsss(Condition cond,
                  int32_t opcode,
                  SRegister sd,
                  SRegister sn,
                  SRegister sm);

  void EmitVFPddd(Condition cond,
                  int32_t opcode,
                  DRegister dd,
                  DRegister dn,
                  DRegister dm);

  void EmitVFPsd(Condition cond, int32_t opcode, SRegister sd, DRegister dm);

  void EmitVFPds(Condition cond, int32_t opcode, DRegister dd, SRegister sm);

  void EmitSIMDqqq(int32_t opcode,
                   OperandSize sz,
                   QRegister qd,
                   QRegister qn,
                   QRegister qm);

  void EmitSIMDddd(int32_t opcode,
                   OperandSize sz,
                   DRegister dd,
                   DRegister dn,
                   DRegister dm);

  void EmitFarBranch(Condition cond, int32_t offset, bool link);
  void EmitBranch(Condition cond, Label* label, bool link);
  void BailoutIfInvalidBranchOffset(int32_t offset);
  int32_t EncodeTstOffset(int32_t offset, int32_t inst);
  int32_t DecodeTstOffset(int32_t inst);

  friend class dart::FlowGraphCompiler;
  std::function<void(Condition, Register)>
      generate_invoke_write_barrier_wrapper_;
  std::function<void(Condition)> generate_invoke_array_write_barrier_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_ARM_H_
