// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_ARM_H_
#define VM_ASSEMBLER_ARM_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_arm.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_arm.h"
#include "vm/cpu.h"
#include "vm/object.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;

class Label : public ValueObject {
 public:
  Label() : position_(0) { }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  intptr_t Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  intptr_t position_;

  void Reinitialize() {
    position_ = 0;
  }

  void BindTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


// Encodes Addressing Mode 1 - Data-processing operands.
class Operand : public ValueObject {
 public:
  // Data-processing operands - Uninitialized.
  Operand() : type_(-1), encoding_(-1) { }

  // Data-processing operands - Copy constructor.
  Operand(const Operand& other)
      : ValueObject(), type_(other.type_), encoding_(other.encoding_) { }

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
      uint32_t imm8 = (immediate << 2*rot) | (immediate >> (32 - 2*rot));
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


enum OperandSize {
  kByte,
  kUnsignedByte,
  kHalfword,
  kUnsignedHalfword,
  kWord,
  kUnsignedWord,
  kWordPair,
  kSWord,
  kDWord,
  kRegList,
};


// Load/store multiple addressing mode.
enum BlockAddressMode {
  // bit encoding P U W
  DA           = (0|0|0) << 21,  // decrement after
  IA           = (0|4|0) << 21,  // increment after
  DB           = (8|0|0) << 21,  // decrement before
  IB           = (8|4|0) << 21,  // increment before
  DA_W         = (0|0|1) << 21,  // decrement after with writeback to base
  IA_W         = (0|4|1) << 21,  // increment after with writeback to base
  DB_W         = (8|0|1) << 21,  // decrement before with writeback to base
  IB_W         = (8|4|1) << 21   // increment before with writeback to base
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
    // bit encoding P U W
    Offset       = (8|4|0) << 21,  // offset (w/o writeback to base)
    PreIndex     = (8|4|1) << 21,  // pre-indexed addressing with writeback
    PostIndex    = (0|4|0) << 21,  // post-indexed addressing with writeback
    NegOffset    = (8|0|0) << 21,  // negative offset (w/o writeback to base)
    NegPreIndex  = (8|0|1) << 21,  // negative pre-indexed with writeback
    NegPostIndex = (0|0|0) << 21   // negative post-indexed with writeback
  };

  Address(const Address& other)
      : ValueObject(), encoding_(other.encoding_), kind_(other.kind_) {
  }

  Address& operator=(const Address& other) {
    encoding_ = other.encoding_;
    kind_ = other.kind_;
    return *this;
  }

  bool Equals(const Address& other) const {
    return (encoding_ == other.encoding_) && (kind_ == other.kind_);
  }

  explicit Address(Register rn, int32_t offset = 0, Mode am = Offset) {
    ASSERT(Utils::IsAbsoluteUint(12, offset));
    kind_ = Immediate;
    if (offset < 0) {
      encoding_ = (am ^ (1 << kUShift)) | -offset;  // Flip U to adjust sign.
    } else {
      encoding_ = am | offset;
    }
    encoding_ |= static_cast<uint32_t>(rn) << kRnShift;
  }

  Address(Register rn, Register rm,
          Shift shift = LSL, uint32_t shift_imm = 0, Mode am = Offset) {
    Operand o(rm, shift, shift_imm);

    if ((shift == LSL) && (shift_imm == 0)) {
      kind_ = IndexRegister;
    } else {
      kind_ = ScaledIndexRegister;
    }
    encoding_ = o.encoding() | am | (static_cast<uint32_t>(rn) << kRnShift);
  }

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
  uint32_t encoding() const { return encoding_; }

  // Encoding for addressing mode 3.
  uint32_t encoding3() const;

  // Encoding for vfp load/store addressing.
  uint32_t vencoding() const;

  OffsetKind kind() const { return kind_; }

  uint32_t encoding_;

  OffsetKind kind_;

  friend class Assembler;
};


class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) { }

  FieldAddress(const FieldAddress& other) : Address(other) { }

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};


class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false)
      : buffer_(),
        object_pool_(GrowableObjectArray::Handle()),
        prologue_offset_(-1),
        use_far_branches_(use_far_branches),
        comments_(),
        allow_constant_pool_(true) { }

  ~Assembler() { }

  void PopRegister(Register r) { Pop(r); }

  void Bind(Label* label);
  void Jump(Label* label) { b(label); }

  // Misc. functionality
  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return prologue_offset_; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.  On ARM there are no pointers in code.
  intptr_t CountPointerOffsets() const { return 0; }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    ASSERT(buffer_.pointer_offsets().length() == 0);  // No pointers in code.
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }

  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

  void set_use_far_branches(bool b) {
    ASSERT(buffer_.Size() == 0);
    use_far_branches_ = b;
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, intptr_t length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  static bool EmittingComments();

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg);

  // Data-processing instructions.
  void and_(Register rd, Register rn, Operand o, Condition cond = AL);

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

  void mvn(Register rd, Operand o, Condition cond = AL);
  void mvns(Register rd, Operand o, Condition cond = AL);

  // Miscellaneous data-processing instructions.
  void clz(Register rd, Register rm, Condition cond = AL);
  void movw(Register rd, uint16_t imm16, Condition cond = AL);
  void movt(Register rd, uint16_t imm16, Condition cond = AL);

  // Multiply instructions.
  void mul(Register rd, Register rn, Register rm, Condition cond = AL);
  void muls(Register rd, Register rn, Register rm, Condition cond = AL);
  void mla(Register rd, Register rn, Register rm, Register ra,
           Condition cond = AL);
  void mls(Register rd, Register rn, Register rm, Register ra,
           Condition cond = AL);
  void smull(Register rd_lo, Register rd_hi, Register rn, Register rm,
             Condition cond = AL);
  void umull(Register rd_lo, Register rd_hi, Register rn, Register rm,
             Condition cond = AL);
  void smlal(Register rd_lo, Register rd_hi, Register rn, Register rm,
             Condition cond = AL);
  void umlal(Register rd_lo, Register rd_hi, Register rn, Register rm,
             Condition cond = AL);

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

  void ldrd(Register rd, Address ad, Condition cond = AL);
  void strd(Register rd, Address ad, Condition cond = AL);

  void ldm(BlockAddressMode am, Register base,
           RegList regs, Condition cond = AL);
  void stm(BlockAddressMode am, Register base,
           RegList regs, Condition cond = AL);

  void ldrex(Register rd, Register rn, Condition cond = AL);
  void strex(Register rd, Register rt, Register rn, Condition cond = AL);

  // Miscellaneous instructions.
  void clrex();
  void nop(Condition cond = AL);

  // Note that gdb sets breakpoints using the undefined instruction 0xe7f001f0.
  void bkpt(uint16_t imm16);
  void svc(uint32_t imm24, Condition cond = AL);

  // Floating point instructions (VFPv3-D16 and VFPv3-D32 profiles).
  void vmovsr(SRegister sn, Register rt, Condition cond = AL);
  void vmovrs(Register rt, SRegister sn, Condition cond = AL);
  void vmovsrr(SRegister sm, Register rt, Register rt2, Condition cond = AL);
  void vmovrrs(Register rt, Register rt2, SRegister sm, Condition cond = AL);
  void vmovdrr(DRegister dm, Register rt, Register rt2, Condition cond = AL);
  void vmovrrd(Register rt, Register rt2, DRegister dm, Condition cond = AL);
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

  void vldms(BlockAddressMode am, Register base,
             SRegister first, SRegister last, Condition cond = AL);
  void vstms(BlockAddressMode am, Register base,
             SRegister first, SRegister last, Condition cond = AL);

  void vldmd(BlockAddressMode am, Register base,
             DRegister first, intptr_t count, Condition cond = AL);
  void vstmd(BlockAddressMode am, Register base,
             DRegister first, intptr_t count, Condition cond = AL);

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
  void vmstat(Condition cond = AL);  // VMRS APSR_nzcv, FPSCR

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

  // Macros.
  // Branch to an entry address. Call sequence is never patched.
  void Branch(const ExternalLabel* label, Condition cond = AL);

  // Branch to an entry address. Call sequence can be patched or even replaced.
  void BranchPatchable(const ExternalLabel* label);

  // Branch and link to an entry address. Call sequence is never patched.
  void BranchLink(const ExternalLabel* label);

  // Branch and link to an entry address. Call sequence can be patched.
  void BranchLinkPatchable(const ExternalLabel* label);

  // Branch and link to [base + offset]. Call sequence is never patched.
  void BranchLinkOffset(Register base, int32_t offset);

  // Add signed immediate value to rd. May clobber IP.
  void AddImmediate(Register rd, int32_t value, Condition cond = AL);
  void AddImmediate(Register rd, Register rn, int32_t value,
                    Condition cond = AL);
  void AddImmediateSetFlags(Register rd, Register rn, int32_t value,
                            Condition cond = AL);
  void SubImmediateSetFlags(Register rd, Register rn, int32_t value,
                            Condition cond = AL);
  void AndImmediate(Register rd, Register rs, int32_t imm, Condition cond = AL);

  // Test rn and immediate. May clobber IP.
  void TestImmediate(Register rn, int32_t imm, Condition cond = AL);

  // Compare rn with signed immediate value. May clobber IP.
  void CompareImmediate(Register rn, int32_t value, Condition cond = AL);


  // Signed integer division of left by right. Checks to see if integer
  // division is supported. If not, uses the FPU for division with
  // temporary registers tmpl and tmpr. tmpl and tmpr must be different
  // registers.
  void IntegerDivide(Register result, Register left, Register right,
                     DRegister tmpl, DRegister tmpr);

  // If we aren't on ARMv7, there is no smull.
  void CheckMultSignedOverflow(Register left,
                               Register right,
                               Register tmp,
                               DRegister dtmp0, DRegister dtmp1,
                               Label* overflow);

  // Load and Store. May clobber IP.
  void LoadPatchableImmediate(Register rd, int32_t value, Condition cond = AL);
  void LoadDecodableImmediate(Register rd, int32_t value, Condition cond = AL);
  void LoadImmediate(Register rd, int32_t value, Condition cond = AL);
  void LoadSImmediate(SRegister sd, float value, Condition cond = AL);
  void LoadDImmediate(DRegister dd, double value,
                      Register scratch, Condition cond = AL);

  void MarkExceptionHandler(Label* label);

  void Drop(intptr_t stack_elements);

  void LoadPoolPointer();

  void LoadObject(Register rd, const Object& object, Condition cond = AL);
  void PushObject(const Object& object);
  void CompareObject(Register rn, const Object& object);

  void StoreIntoObject(Register object,  // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,  // Value we are storing.
                       bool can_value_be_smi = true);
  void StoreIntoObjectOffset(Register object,
                             int32_t offset,
                             Register value,
                             bool can_value_be_smi = true);

  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectNoBarrierOffset(Register object,
                                      int32_t offset,
                                      Register value);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);
  void StoreIntoObjectNoBarrierOffset(Register object,
                                      int32_t offset,
                                      const Object& value);

  void LoadClassId(Register result, Register object, Condition cond = AL);
  void LoadClassById(Register result, Register class_id);
  void LoadClass(Register result, Register object, Register scratch);
  void CompareClassId(Register object, intptr_t class_id, Register scratch);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

  void LoadWordFromPoolOffset(Register rd, int32_t offset, Condition cond = AL);
  void LoadFromOffset(OperandSize type,
                      Register reg,
                      Register base,
                      int32_t offset,
                      Condition cond = AL);
  void StoreToOffset(OperandSize type,
                     Register reg,
                     Register base,
                     int32_t offset,
                     Condition cond = AL);
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

  void LoadMultipleDFromOffset(DRegister first,
                               intptr_t count,
                               Register base,
                               int32_t offset);
  void StoreMultipleDToOffset(DRegister first,
                              intptr_t count,
                              Register base,
                              int32_t offset);

  void CopyDoubleField(Register dst, Register src,
                       Register tmp1, Register tmp2, DRegister dtmp);
  void CopyFloat32x4Field(Register dst, Register src,
                          Register tmp1, Register tmp2, DRegister dtmp);
  void CopyFloat64x2Field(Register dst, Register src,
                          Register tmp1, Register tmp2, DRegister dtmp);

  void Push(Register rd, Condition cond = AL);
  void Pop(Register rd, Condition cond = AL);

  void PushList(RegList regs, Condition cond = AL);
  void PopList(RegList regs, Condition cond = AL);

  void MoveRegister(Register rd, Register rm, Condition cond = AL);

  // Convenience shift instructions. Use mov instruction with shifter operand
  // for variants setting the status flags.
  void Lsl(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Lsl(Register rd, Register rm, Register rs, Condition cond = AL);
  void Lsr(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Lsr(Register rd, Register rm, Register rs, Condition cond = AL);
  void Asr(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Asr(Register rd, Register rm, Register rs, Condition cond = AL);
  void Asrs(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Ror(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Ror(Register rd, Register rm, Register rs, Condition cond = AL);
  void Rrx(Register rd, Register rm, Condition cond = AL);

  // Fill rd with the sign of rm.
  void SignFill(Register rd, Register rm, Condition cond = AL);

  void Vreciprocalqs(QRegister qd, QRegister qm);
  void VreciprocalSqrtqs(QRegister qd, QRegister qm);
  // If qm must be preserved, then provide a (non-QTMP) temporary.
  void Vsqrtqs(QRegister qd, QRegister qm, QRegister temp);
  void Vdivqs(QRegister qd, QRegister qn, QRegister qm);

  void SmiTag(Register reg, Condition cond = AL) {
    Lsl(reg, reg, kSmiTagSize, cond);
  }

  void SmiTag(Register dst, Register src, Condition cond = AL) {
    Lsl(dst, src, kSmiTagSize, cond);
  }

  void SmiUntag(Register reg, Condition cond = AL) {
    Asr(reg, reg, kSmiTagSize, cond);
  }

  void SmiUntag(Register dst, Register src, Condition cond = AL) {
    Asr(dst, src, kSmiTagSize, cond);
  }

  // Untag the value in the register assuming it is a smi.
  // Untagging shifts tag bit into the carry flag - if carry is clear
  // assumption was correct. In this case jump to the is_smi label.
  // Otherwise fall-through.
  void SmiUntag(Register dst, Register src, Label* is_smi) {
    ASSERT(kSmiTagSize == 1);
    Asrs(dst, src, kSmiTagSize);
    b(is_smi, CC);
  }

  // Function frame setup and tear down.
  void EnterFrame(RegList regs, intptr_t frame_space);
  void LeaveFrame(RegList regs);
  void Ret();
  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // Create a frame for calling into runtime that preserves all volatile
  // registers.  Frame's SP is guaranteed to be correctly aligned and
  // frame_space bytes are reserved under it.
  void EnterCallRuntimeFrame(intptr_t frame_space);
  void LeaveCallRuntimeFrame();

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size);
  void LeaveDartFrame();

  // Set up a Dart frame for a function compiled for on-stack replacement.
  // The frame layout is a normal Dart frame, but the frame is partially set
  // up on entry (it is the frame of the unoptimized code).
  void EnterOsrFrame(intptr_t extra_size);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame(bool load_pp = false);
  void LeaveStubFrame();

  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static intptr_t EntryPointToPcMarkerOffset() {
    return TargetCPUFeatures::store_pc_read_offset();
  }

  void UpdateAllocationStats(intptr_t cid,
                             Register temp_reg,
                             Heap::Space space = Heap::kNew);

  void UpdateAllocationStatsWithSize(intptr_t cid,
                                     Register size_reg,
                                     Register temp_reg,
                                     Heap::Space space = Heap::kNew);

  Address ElementAddressForIntIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index,
                                    Register temp);

  Address ElementAddressForRegIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    Register index);

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   Register instance_reg,
                   Register temp_reg);

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        Register instance,
                        Register end_address,
                        Register temp1,
                        Register temp2);

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return object.IsSmi(); }

  bool allow_constant_pool() const {
    return allow_constant_pool_;
  }
  void set_allow_constant_pool(bool b) {
    allow_constant_pool_ = b;
  }

 private:
  AssemblerBuffer buffer_;  // Contains position independent code.
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  int32_t prologue_offset_;

  bool use_far_branches_;

  int32_t AddObject(const Object& obj);
  int32_t AddExternalLabel(const ExternalLabel* label);

  void BindARMv6(Label* label);
  void BindARMv7(Label* label);

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) { }

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  GrowableArray<CodeComment*> comments_;

  bool allow_constant_pool_;

  void EmitType01(Condition cond,
                  int type,
                  Opcode opcode,
                  int set_cc,
                  Register rn,
                  Register rd,
                  Operand o);

  void EmitType5(Condition cond, int32_t offset, bool link);

  void EmitMemOp(Condition cond,
                 bool load,
                 bool byte,
                 Register rd,
                 Address ad);

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

  void EmitVFPsd(Condition cond,
                 int32_t opcode,
                 SRegister sd,
                 DRegister dm);

  void EmitVFPds(Condition cond,
                 int32_t opcode,
                 DRegister dd,
                 SRegister sm);

  void EmitSIMDqqq(int32_t opcode, OperandSize sz,
                   QRegister qd, QRegister qn, QRegister qm);

  void EmitSIMDddd(int32_t opcode, OperandSize sz,
                   DRegister dd, DRegister dn, DRegister dm);

  void EmitFarBranch(Condition cond, int32_t offset, bool link);
  void EmitBranch(Condition cond, Label* label, bool link);
  int32_t EncodeBranchOffset(int32_t offset, int32_t inst);
  static int32_t DecodeBranchOffset(int32_t inst);
  int32_t EncodeTstOffset(int32_t offset, int32_t inst);
  int32_t DecodeTstOffset(int32_t inst);

  void StoreIntoObjectFilter(Register object, Register value, Label* no_update);

  // Shorter filtering sequence that assumes that value is not a smi.
  void StoreIntoObjectFilterNoSmi(Register object,
                                  Register value,
                                  Label* no_update);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_ARM_H_
