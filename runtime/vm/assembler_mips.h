// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ASSEMBLER_MIPS_H_
#define RUNTIME_VM_ASSEMBLER_MIPS_H_

#ifndef RUNTIME_VM_ASSEMBLER_H_
#error Do not include assembler_mips.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_mips.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/simulator.h"

// References to documentation in this file refer to:
// "MIPS® Architecture For Programmers Volume I-A:
//   Introduction to the MIPS32® Architecture" in short "VolI-A"
// and
// "MIPS® Architecture For Programmers Volume II-A:
//   The MIPS32® Instruction Set" in short "VolII-A"
namespace dart {

// Forward declarations.
class RuntimeEntry;
class StubEntry;

class Immediate : public ValueObject {
 public:
  explicit Immediate(int32_t value) : value_(value) {}

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) {}
  Immediate& operator=(const Immediate& other) {
    value_ = other.value_;
    return *this;
  }

 private:
  int32_t value_;

  int32_t value() const { return value_; }

  friend class Assembler;
};


class Address : public ValueObject {
 public:
  explicit Address(Register base, int32_t offset = 0)
      : ValueObject(), base_(base), offset_(offset) {}

  // This addressing mode does not exist.
  Address(Register base, Register offset);

  Address(const Address& other)
      : ValueObject(), base_(other.base_), offset_(other.offset_) {}
  Address& operator=(const Address& other) {
    base_ = other.base_;
    offset_ = other.offset_;
    return *this;
  }

  uint32_t encoding() const {
    ASSERT(Utils::IsInt(kImmBits, offset_));
    uint16_t imm_value = static_cast<uint16_t>(offset_);
    return (base_ << kRsShift) | imm_value;
  }

  static bool CanHoldOffset(int32_t offset) {
    return Utils::IsInt(kImmBits, offset);
  }

  Register base() const { return base_; }
  int32_t offset() const { return offset_; }

 private:
  Register base_;
  int32_t offset_;
};


class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) {}

  FieldAddress(const FieldAddress& other) : Address(other) {}

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};


class Label : public ValueObject {
 public:
  Label() : position_(0) {}

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

  void Reinitialize() { position_ = 0; }

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


// There is no dedicated status register on MIPS, but Condition values are used
// and passed around by the intermediate language, so we need a Condition type.
// We delay code generation of a comparison that would result in a traditional
// condition code in the status register by keeping both register operands and
// the relational operator between them as the Condition.
class Condition : public ValueObject {
 public:
  enum Bits {
    kLeftPos = 0,
    kLeftSize = 6,
    kRightPos = kLeftPos + kLeftSize,
    kRightSize = 6,
    kRelOpPos = kRightPos + kRightSize,
    kRelOpSize = 4,
    kImmPos = kRelOpPos + kRelOpSize,
    kImmSize = 16,
  };

  class LeftBits : public BitField<uword, Register, kLeftPos, kLeftSize> {};
  class RightBits : public BitField<uword, Register, kRightPos, kRightSize> {};
  class RelOpBits
      : public BitField<uword, RelationOperator, kRelOpPos, kRelOpSize> {};
  class ImmBits : public BitField<uword, uint16_t, kImmPos, kImmSize> {};

  Register left() const { return LeftBits::decode(bits_); }
  Register right() const { return RightBits::decode(bits_); }
  RelationOperator rel_op() const { return RelOpBits::decode(bits_); }
  int16_t imm() const { return static_cast<int16_t>(ImmBits::decode(bits_)); }

  static bool IsValidImm(int32_t value) {
    // We want both value and value + 1 to fit in an int16_t.
    return (-0x08000 <= value) && (value < 0x7fff);
  }

  void set_rel_op(RelationOperator value) {
    ASSERT(IsValidRelOp(value));
    bits_ = RelOpBits::update(value, bits_);
  }

  // Uninitialized condition.
  Condition() : ValueObject(), bits_(0) {}

  // Copy constructor.
  Condition(const Condition& other) : ValueObject(), bits_(other.bits_) {}

  // Copy assignment operator.
  Condition& operator=(const Condition& other) {
    bits_ = other.bits_;
    return *this;
  }

  Condition(Register left,
            Register right,
            RelationOperator rel_op,
            int16_t imm = 0) {
    // At most one constant, ZR or immediate.
    ASSERT(!(((left == ZR) || (left == IMM)) &&
             ((right == ZR) || (right == IMM))));
    // Non-zero immediate value is only allowed for IMM.
    ASSERT((imm != 0) == ((left == IMM) || (right == IMM)));
    set_left(left);
    set_right(right);
    set_rel_op(rel_op);
    set_imm(imm);
  }

 private:
  static bool IsValidRelOp(RelationOperator value) {
    return (AL <= value) && (value <= ULE);
  }

  static bool IsValidRegister(Register value) {
    return (ZR <= value) && (value <= IMM) && (value != AT);
  }

  void set_left(Register value) {
    ASSERT(IsValidRegister(value));
    bits_ = LeftBits::update(value, bits_);
  }

  void set_right(Register value) {
    ASSERT(IsValidRegister(value));
    bits_ = RightBits::update(value, bits_);
  }

  void set_imm(int16_t value) {
    ASSERT(IsValidImm(value));
    bits_ = ImmBits::update(static_cast<uint16_t>(value), bits_);
  }

  uword bits_;
};


class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false)
      : buffer_(),
        prologue_offset_(-1),
        has_single_entry_point_(true),
        use_far_branches_(use_far_branches),
        delay_slot_available_(false),
        in_delay_slot_(false),
        comments_(),
        constant_pool_allowed_(true) {}
  ~Assembler() {}

  void PopRegister(Register r) { Pop(r); }

  void Bind(Label* label);
  void Jump(Label* label) { b(label); }

  // Misc. functionality
  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return prologue_offset_; }
  bool has_single_entry_point() const { return has_single_entry_point_; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.
  intptr_t CountPointerOffsets() const { return buffer_.CountPointerOffsets(); }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }

  ObjectPoolWrapper& object_pool_wrapper() { return object_pool_wrapper_; }

  RawObjectPool* MakeObjectPool() {
    return object_pool_wrapper_.MakeObjectPool();
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

  void set_use_far_branches(bool b) { use_far_branches_ = b; }

  void EnterFrame();
  void LeaveFrameAndReturn();

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame(intptr_t frame_size = 0);
  void LeaveStubFrame();
  // A separate macro for when a Ret immediately follows, so that we can use
  // the branch delay slot.
  void LeaveStubFrameAndReturn(Register ra = RA);

  void MonomorphicCheckedEntry();

  void UpdateAllocationStats(intptr_t cid,
                             Register temp_reg,
                             Heap::Space space);

  void UpdateAllocationStatsWithSize(intptr_t cid,
                                     Register size_reg,
                                     Register temp_reg,
                                     Heap::Space space);


  void MaybeTraceAllocation(intptr_t cid, Register temp_reg, Label* trace);

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

  void SetPrologueOffset() {
    if (prologue_offset_ == -1) {
      prologue_offset_ = CodeSize();
    }
  }

  // A utility to be able to assemble an instruction into the delay slot.
  Assembler* delay_slot() {
    ASSERT(delay_slot_available_);
    ASSERT(buffer_.Load<int32_t>(buffer_.GetPosition() - sizeof(int32_t)) ==
           Instr::kNopInstruction);
    buffer_.Remit<int32_t>();
    delay_slot_available_ = false;
    in_delay_slot_ = true;
    return this;
  }

  // CPU instructions in alphabetical order.
  void addd(DRegister dd, DRegister ds, DRegister dt) {
    // DRegisters start at the even FRegisters.
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, fd, COP1_ADD);
  }

  void addiu(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsInt(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(ADDIU, rs, rt, imm_value);
  }

  void addu(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, ADDU);
  }

  void and_(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, AND);
  }

  void andi(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(ANDI, rs, rt, imm_value);
  }

  // Unconditional branch.
  void b(Label* l) { beq(R0, R0, l); }

  void bal(Label* l) {
    ASSERT(!in_delay_slot_);
    EmitRegImmBranch(BGEZAL, R0, l);
    EmitBranchDelayNop();
  }

  // Branch on floating point false.
  void bc1f(Label* l) {
    EmitFpuBranch(false, l);
    EmitBranchDelayNop();
  }

  // Branch on floating point true.
  void bc1t(Label* l) {
    EmitFpuBranch(true, l);
    EmitBranchDelayNop();
  }

  // Branch if equal.
  void beq(Register rs, Register rt, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitBranch(BEQ, rs, rt, l);
    EmitBranchDelayNop();
  }

  // Branch if equal, likely taken.
  // Delay slot executed only when branch taken.
  void beql(Register rs, Register rt, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitBranch(BEQL, rs, rt, l);
    EmitBranchDelayNop();
  }

  // Branch if rs >= 0.
  void bgez(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitRegImmBranch(BGEZ, rs, l);
    EmitBranchDelayNop();
  }

  // Branch if rs >= 0, likely taken.
  // Delay slot executed only when branch taken.
  void bgezl(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitRegImmBranch(BGEZL, rs, l);
    EmitBranchDelayNop();
  }

  // Branch if rs > 0.
  void bgtz(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitBranch(BGTZ, rs, R0, l);
    EmitBranchDelayNop();
  }

  // Branch if rs > 0, likely taken.
  // Delay slot executed only when branch taken.
  void bgtzl(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitBranch(BGTZL, rs, R0, l);
    EmitBranchDelayNop();
  }

  // Branch if rs <= 0.
  void blez(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitBranch(BLEZ, rs, R0, l);
    EmitBranchDelayNop();
  }

  // Branch if rs <= 0, likely taken.
  // Delay slot executed only when branch taken.
  void blezl(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitBranch(BLEZL, rs, R0, l);
    EmitBranchDelayNop();
  }

  // Branch if rs < 0.
  void bltz(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitRegImmBranch(BLTZ, rs, l);
    EmitBranchDelayNop();
  }

  // Branch if rs < 0, likely taken.
  // Delay slot executed only when branch taken.
  void bltzl(Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    EmitRegImmBranch(BLTZL, rs, l);
    EmitBranchDelayNop();
  }

  // Branch if not equal.
  void bne(Register rs, Register rt, Label* l) {
    ASSERT(!in_delay_slot_);  // Jump within a delay slot is not supported.
    EmitBranch(BNE, rs, rt, l);
    EmitBranchDelayNop();
  }

  // Branch if not equal, likely taken.
  // Delay slot executed only when branch taken.
  void bnel(Register rs, Register rt, Label* l) {
    ASSERT(!in_delay_slot_);  // Jump within a delay slot is not supported.
    EmitBranch(BNEL, rs, rt, l);
    EmitBranchDelayNop();
  }

  static int32_t BreakEncoding(int32_t code) {
    ASSERT(Utils::IsUint(20, code));
    return SPECIAL << kOpcodeShift | code << kBreakCodeShift |
           BREAK << kFunctionShift;
  }


  void break_(int32_t code) { Emit(BreakEncoding(code)); }

  static uword GetBreakInstructionFiller() { return BreakEncoding(0); }

  // FPU compare, always false.
  void cfd(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_F);
  }

  // FPU compare, true if unordered, i.e. one is NaN.
  void cund(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_UN);
  }

  // FPU compare, true if equal.
  void ceqd(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_EQ);
  }

  // FPU compare, true if unordered or equal.
  void cueqd(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_UEQ);
  }

  // FPU compare, true if less than.
  void coltd(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_OLT);
  }

  // FPU compare, true if unordered or less than.
  void cultd(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_ULT);
  }

  // FPU compare, true if less or equal.
  void coled(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_OLE);
  }

  // FPU compare, true if unordered or less or equal.
  void culed(DRegister ds, DRegister dt) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, F0, COP1_C_ULE);
  }

  void clo(Register rd, Register rs) {
    EmitRType(SPECIAL2, rs, rd, rd, 0, CLO);
  }

  void clz(Register rd, Register rs) {
    EmitRType(SPECIAL2, rs, rd, rd, 0, CLZ);
  }

  // Convert a double in ds to a 32-bit signed int in fd rounding towards 0.
  void truncwd(FRegister fd, DRegister ds) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_TRUNC_W);
  }

  // Convert a 32-bit float in fs to a 64-bit double in dd.
  void cvtds(DRegister dd, FRegister fs) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    EmitFpuRType(COP1, FMT_S, F0, fs, fd, COP1_CVT_D);
  }

  // Converts a 32-bit signed int in fs to a double in fd.
  void cvtdw(DRegister dd, FRegister fs) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    EmitFpuRType(COP1, FMT_W, F0, fs, fd, COP1_CVT_D);
  }

  // Convert a 64-bit double in ds to a 32-bit float in fd.
  void cvtsd(FRegister fd, DRegister ds) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_CVT_S);
  }

  void div(Register rs, Register rt) { EmitRType(SPECIAL, rs, rt, R0, 0, DIV); }

  void divd(DRegister dd, DRegister ds, DRegister dt) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, fd, COP1_DIV);
  }

  void divu(Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, R0, 0, DIVU);
  }

  void jalr(Register rs, Register rd = RA) {
    ASSERT(rs != rd);
    ASSERT(!in_delay_slot_);  // Jump within a delay slot is not supported.
    EmitRType(SPECIAL, rs, R0, rd, 0, JALR);
    EmitBranchDelayNop();
  }

  void jr(Register rs) {
    ASSERT(!in_delay_slot_);  // Jump within a delay slot is not supported.
    EmitRType(SPECIAL, rs, R0, R0, 0, JR);
    EmitBranchDelayNop();
  }

  void lb(Register rt, const Address& addr) { EmitLoadStore(LB, rt, addr); }

  void lbu(Register rt, const Address& addr) { EmitLoadStore(LBU, rt, addr); }

  void ldc1(DRegister dt, const Address& addr) {
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuLoadStore(LDC1, ft, addr);
  }

  void lh(Register rt, const Address& addr) { EmitLoadStore(LH, rt, addr); }

  void lhu(Register rt, const Address& addr) { EmitLoadStore(LHU, rt, addr); }

  void ll(Register rt, const Address& addr) { EmitLoadStore(LL, rt, addr); }

  void lui(Register rt, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(LUI, R0, rt, imm_value);
  }

  void lw(Register rt, const Address& addr) { EmitLoadStore(LW, rt, addr); }

  void lwc1(FRegister ft, const Address& addr) {
    EmitFpuLoadStore(LWC1, ft, addr);
  }

  void madd(Register rs, Register rt) {
    EmitRType(SPECIAL2, rs, rt, R0, 0, MADD);
  }

  void maddu(Register rs, Register rt) {
    EmitRType(SPECIAL2, rs, rt, R0, 0, MADDU);
  }

  void mfc1(Register rt, FRegister fs) {
    Emit(COP1 << kOpcodeShift | COP1_MF << kCop1SubShift | rt << kRtShift |
         fs << kFsShift);
  }

  void mfhi(Register rd) { EmitRType(SPECIAL, R0, R0, rd, 0, MFHI); }

  void mflo(Register rd) { EmitRType(SPECIAL, R0, R0, rd, 0, MFLO); }

  void mov(Register rd, Register rs) { or_(rd, rs, ZR); }

  void movd(DRegister dd, DRegister ds) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_MOV);
  }

  // Move if floating point false.
  void movf(Register rd, Register rs) {
    EmitRType(SPECIAL, rs, R0, rd, 0, MOVCI);
  }

  void movn(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, MOVN);
  }

  // Move if floating point true.
  void movt(Register rd, Register rs) {
    EmitRType(SPECIAL, rs, R1, rd, 0, MOVCI);
  }

  // rd <- (rt == 0) ? rs : rd;
  void movz(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, MOVZ);
  }

  void movs(FRegister fd, FRegister fs) {
    EmitFpuRType(COP1, FMT_S, F0, fs, fd, COP1_MOV);
  }

  void mtc1(Register rt, FRegister fs) {
    Emit(COP1 << kOpcodeShift | COP1_MT << kCop1SubShift | rt << kRtShift |
         fs << kFsShift);
  }

  void mthi(Register rs) { EmitRType(SPECIAL, rs, R0, R0, 0, MTHI); }

  void mtlo(Register rs) { EmitRType(SPECIAL, rs, R0, R0, 0, MTLO); }

  void muld(DRegister dd, DRegister ds, DRegister dt) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, fd, COP1_MUL);
  }

  void mult(Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, R0, 0, MULT);
  }

  void multu(Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, R0, 0, MULTU);
  }

  void negd(DRegister dd, DRegister ds) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_NEG);
  }

  void nop() { Emit(Instr::kNopInstruction); }

  void nor(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, NOR);
  }

  void or_(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, OR);
  }

  void ori(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(ORI, rs, rt, imm_value);
  }

  void sb(Register rt, const Address& addr) { EmitLoadStore(SB, rt, addr); }

  // rt = 1 on success, 0 on failure.
  void sc(Register rt, const Address& addr) { EmitLoadStore(SC, rt, addr); }

  void sdc1(DRegister dt, const Address& addr) {
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuLoadStore(SDC1, ft, addr);
  }

  void sh(Register rt, const Address& addr) { EmitLoadStore(SH, rt, addr); }

  void sll(Register rd, Register rt, int sa) {
    EmitRType(SPECIAL, R0, rt, rd, sa, SLL);
  }

  void sllv(Register rd, Register rt, Register rs) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SLLV);
  }

  void slt(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SLT);
  }

  void slti(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsInt(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(SLTI, rs, rt, imm_value);
  }

  // Although imm argument is int32_t, it is interpreted as an uint32_t.
  // For example, -1 stands for 0xffffffffUL: it is encoded as 0xffff in the
  // instruction imm field and is then sign extended back to 0xffffffffUL.
  void sltiu(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsInt(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(SLTIU, rs, rt, imm_value);
  }

  void sltu(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SLTU);
  }

  void sqrtd(DRegister dd, DRegister ds) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_SQRT);
  }

  void sra(Register rd, Register rt, int sa) {
    EmitRType(SPECIAL, R0, rt, rd, sa, SRA);
  }

  void srav(Register rd, Register rt, Register rs) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SRAV);
  }

  void srl(Register rd, Register rt, int sa) {
    EmitRType(SPECIAL, R0, rt, rd, sa, SRL);
  }

  void srlv(Register rd, Register rt, Register rs) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SRLV);
  }

  void subd(DRegister dd, DRegister ds, DRegister dt) {
    FRegister fd = static_cast<FRegister>(dd * 2);
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuRType(COP1, FMT_D, ft, fs, fd, COP1_SUB);
  }

  void subu(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SUBU);
  }

  void sw(Register rt, const Address& addr) { EmitLoadStore(SW, rt, addr); }

  void swc1(FRegister ft, const Address& addr) {
    EmitFpuLoadStore(SWC1, ft, addr);
  }

  void xori(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(XORI, rs, rt, imm_value);
  }

  void xor_(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, XOR);
  }

  // Macros in alphabetical order.

  // Addition of rs and rt with the result placed in rd.
  // After, ro < 0 if there was signed overflow, ro >= 0 otherwise.
  // rd and ro must not be TMP.
  // ro must be different from all the other registers.
  // If rd, rs, and rt are the same register, then a scratch register different
  // from the other registers is needed.
  void AdduDetectOverflow(Register rd,
                          Register rs,
                          Register rt,
                          Register ro,
                          Register scratch = kNoRegister);

  // ro must be different from rd and rs.
  // rd and ro must not be TMP.
  // If rd and rs are the same, a scratch register different from the other
  // registers is needed.
  void AddImmediateDetectOverflow(Register rd,
                                  Register rs,
                                  int32_t imm,
                                  Register ro,
                                  Register scratch = kNoRegister) {
    ASSERT(!in_delay_slot_);
    LoadImmediate(rd, imm);
    AdduDetectOverflow(rd, rs, rd, ro, scratch);
  }

  // Subtraction of rt from rs (rs - rt) with the result placed in rd.
  // After, ro < 0 if there was signed overflow, ro >= 0 otherwise.
  // None of rd, rs, rt, or ro may be TMP.
  // ro must be different from the other registers.
  void SubuDetectOverflow(Register rd, Register rs, Register rt, Register ro);

  // ro must be different from rd and rs.
  // None of rd, rs, rt, or ro may be TMP.
  void SubImmediateDetectOverflow(Register rd,
                                  Register rs,
                                  int32_t imm,
                                  Register ro) {
    ASSERT(!in_delay_slot_);
    LoadImmediate(rd, imm);
    SubuDetectOverflow(rd, rs, rd, ro);
  }

  void Branch(const StubEntry& stub_entry, Register pp = PP);

  void BranchLink(const StubEntry& stub_entry,
                  Patchability patchable = kNotPatchable);

  void BranchLinkPatchable(const StubEntry& stub_entry);
  void BranchLinkToRuntime();

  // Emit a call that shares its object pool entries with other calls
  // that have the same equivalence marker.
  void BranchLinkWithEquivalence(const StubEntry& stub_entry,
                                 const Object& equivalence);

  void Drop(intptr_t stack_elements) {
    ASSERT(stack_elements >= 0);
    if (stack_elements > 0) {
      addiu(SP, SP, Immediate(stack_elements * kWordSize));
    }
  }

  void LoadPoolPointer(Register reg = PP) {
    ASSERT(!in_delay_slot_);
    CheckCodePointer();
    lw(reg, FieldAddress(CODE_REG, Code::object_pool_offset()));
    set_constant_pool_allowed(reg == PP);
  }

  void CheckCodePointer();

  void RestoreCodePointer();

  void LoadImmediate(Register rd, int32_t value) {
    ASSERT(!in_delay_slot_);
    if (Utils::IsInt(kImmBits, value)) {
      addiu(rd, ZR, Immediate(value));
    } else {
      const uint16_t low = Utils::Low16Bits(value);
      const uint16_t high = Utils::High16Bits(value);
      lui(rd, Immediate(high));
      if (low != 0) {
        ori(rd, rd, Immediate(low));
      }
    }
  }

  void LoadImmediate(DRegister rd, double value) {
    ASSERT(!in_delay_slot_);
    FRegister frd = static_cast<FRegister>(rd * 2);
    const int64_t ival = bit_cast<uint64_t, double>(value);
    const int32_t low = Utils::Low32Bits(ival);
    const int32_t high = Utils::High32Bits(ival);
    if (low != 0) {
      LoadImmediate(TMP, low);
      mtc1(TMP, frd);
    } else {
      mtc1(ZR, frd);
    }

    if (high != 0) {
      LoadImmediate(TMP, high);
      mtc1(TMP, static_cast<FRegister>(frd + 1));
    } else {
      mtc1(ZR, static_cast<FRegister>(frd + 1));
    }
  }

  void LoadImmediate(FRegister rd, float value) {
    ASSERT(!in_delay_slot_);
    const int32_t ival = bit_cast<int32_t, float>(value);
    if (ival == 0) {
      mtc1(ZR, rd);
    } else {
      LoadImmediate(TMP, ival);
      mtc1(TMP, rd);
    }
  }

  void AddImmediate(Register rd, Register rs, int32_t value) {
    ASSERT(!in_delay_slot_);
    if ((value == 0) && (rd == rs)) return;
    // If value is 0, we still want to move rs to rd if they aren't the same.
    if (Utils::IsInt(kImmBits, value)) {
      addiu(rd, rs, Immediate(value));
    } else {
      LoadImmediate(TMP, value);
      addu(rd, rs, TMP);
    }
  }

  void AddImmediate(Register rd, int32_t value) {
    ASSERT(!in_delay_slot_);
    AddImmediate(rd, rd, value);
  }

  void AndImmediate(Register rd, Register rs, int32_t imm) {
    ASSERT(!in_delay_slot_);
    if (imm == 0) {
      mov(rd, ZR);
      return;
    }

    if (Utils::IsUint(kImmBits, imm)) {
      andi(rd, rs, Immediate(imm));
    } else {
      LoadImmediate(TMP, imm);
      and_(rd, rs, TMP);
    }
  }

  void OrImmediate(Register rd, Register rs, int32_t imm) {
    ASSERT(!in_delay_slot_);
    if (imm == 0) {
      mov(rd, rs);
      return;
    }

    if (Utils::IsUint(kImmBits, imm)) {
      ori(rd, rs, Immediate(imm));
    } else {
      LoadImmediate(TMP, imm);
      or_(rd, rs, TMP);
    }
  }

  void XorImmediate(Register rd, Register rs, int32_t imm) {
    ASSERT(!in_delay_slot_);
    if (imm == 0) {
      mov(rd, rs);
      return;
    }

    if (Utils::IsUint(kImmBits, imm)) {
      xori(rd, rs, Immediate(imm));
    } else {
      LoadImmediate(TMP, imm);
      xor_(rd, rs, TMP);
    }
  }

  Register LoadConditionOperand(Register rd,
                                const Object& operand,
                                int16_t* imm) {
    if (operand.IsSmi()) {
      const int32_t val = reinterpret_cast<int32_t>(operand.raw());
      if (val == 0) {
        return ZR;
      } else if (Condition::IsValidImm(val)) {
        ASSERT(*imm == 0);
        *imm = val;
        return IMM;
      }
    }
    LoadObject(rd, operand);
    return rd;
  }

  // Branch to label if condition is true.
  void BranchOnCondition(Condition cond, Label* l) {
    ASSERT(!in_delay_slot_);
    Register left = cond.left();
    Register right = cond.right();
    RelationOperator rel_op = cond.rel_op();
    switch (rel_op) {
      case NV:
        return;
      case AL:
        b(l);
        return;
      case EQ:  // fall through.
      case NE: {
        if (left == IMM) {
          addiu(AT, ZR, Immediate(cond.imm()));
          left = AT;
        } else if (right == IMM) {
          addiu(AT, ZR, Immediate(cond.imm()));
          right = AT;
        }
        if (rel_op == EQ) {
          beq(left, right, l);
        } else {
          bne(left, right, l);
        }
        break;
      }
      case GT: {
        if (left == ZR) {
          bltz(right, l);
        } else if (right == ZR) {
          bgtz(left, l);
        } else if (left == IMM) {
          slti(AT, right, Immediate(cond.imm()));
          bne(AT, ZR, l);
        } else if (right == IMM) {
          slti(AT, left, Immediate(cond.imm() + 1));
          beq(AT, ZR, l);
        } else {
          slt(AT, right, left);
          bne(AT, ZR, l);
        }
        break;
      }
      case GE: {
        if (left == ZR) {
          blez(right, l);
        } else if (right == ZR) {
          bgez(left, l);
        } else if (left == IMM) {
          slti(AT, right, Immediate(cond.imm() + 1));
          bne(AT, ZR, l);
        } else if (right == IMM) {
          slti(AT, left, Immediate(cond.imm()));
          beq(AT, ZR, l);
        } else {
          slt(AT, left, right);
          beq(AT, ZR, l);
        }
        break;
      }
      case LT: {
        if (left == ZR) {
          bgtz(right, l);
        } else if (right == ZR) {
          bltz(left, l);
        } else if (left == IMM) {
          slti(AT, right, Immediate(cond.imm() + 1));
          beq(AT, ZR, l);
        } else if (right == IMM) {
          slti(AT, left, Immediate(cond.imm()));
          bne(AT, ZR, l);
        } else {
          slt(AT, left, right);
          bne(AT, ZR, l);
        }
        break;
      }
      case LE: {
        if (left == ZR) {
          bgez(right, l);
        } else if (right == ZR) {
          blez(left, l);
        } else if (left == IMM) {
          slti(AT, right, Immediate(cond.imm()));
          beq(AT, ZR, l);
        } else if (right == IMM) {
          slti(AT, left, Immediate(cond.imm() + 1));
          bne(AT, ZR, l);
        } else {
          slt(AT, right, left);
          beq(AT, ZR, l);
        }
        break;
      }
      case UGT: {
        ASSERT((left != IMM) && (right != IMM));  // No unsigned constants used.
        if (left == ZR) {
          // NV: Never branch. Fall through.
        } else if (right == ZR) {
          bne(left, ZR, l);
        } else {
          sltu(AT, right, left);
          bne(AT, ZR, l);
        }
        break;
      }
      case UGE: {
        ASSERT((left != IMM) && (right != IMM));  // No unsigned constants used.
        if (left == ZR) {
          beq(right, ZR, l);
        } else if (right == ZR) {
          // AL: Always branch to l.
          beq(ZR, ZR, l);
        } else {
          sltu(AT, left, right);
          beq(AT, ZR, l);
        }
        break;
      }
      case ULT: {
        ASSERT((left != IMM) && (right != IMM));  // No unsigned constants used.
        if (left == ZR) {
          bne(right, ZR, l);
        } else if (right == ZR) {
          // NV: Never branch. Fall through.
        } else {
          sltu(AT, left, right);
          bne(AT, ZR, l);
        }
        break;
      }
      case ULE: {
        ASSERT((left != IMM) && (right != IMM));  // No unsigned constants used.
        if (left == ZR) {
          // AL: Always branch to l.
          beq(ZR, ZR, l);
        } else if (right == ZR) {
          beq(left, ZR, l);
        } else {
          sltu(AT, right, left);
          beq(AT, ZR, l);
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  }

  void BranchEqual(Register rd, Register rn, Label* l) { beq(rd, rn, l); }

  void BranchEqual(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      beq(rd, ZR, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, imm.value());
      beq(rd, CMPRES2, l);
    }
  }

  void BranchEqual(Register rd, const Object& object, Label* l) {
    ASSERT(!in_delay_slot_);
    ASSERT(rd != CMPRES2);
    LoadObject(CMPRES2, object);
    beq(rd, CMPRES2, l);
  }

  void BranchNotEqual(Register rd, Register rn, Label* l) { bne(rd, rn, l); }

  void BranchNotEqual(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      bne(rd, ZR, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, imm.value());
      bne(rd, CMPRES2, l);
    }
  }

  void BranchNotEqual(Register rd, const Object& object, Label* l) {
    ASSERT(!in_delay_slot_);
    ASSERT(rd != CMPRES2);
    LoadObject(CMPRES2, object);
    bne(rd, CMPRES2, l);
  }

  void BranchSignedGreater(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    slt(CMPRES2, rs, rd);  // CMPRES2 = rd > rs ? 1 : 0.
    bne(CMPRES2, ZR, l);
  }

  void BranchSignedGreater(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      bgtz(rd, l);
    } else {
      if (Utils::IsInt(kImmBits, imm.value() + 1)) {
        slti(CMPRES2, rd, Immediate(imm.value() + 1));
        beq(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchSignedGreater(rd, CMPRES2, l);
      }
    }
  }

  void BranchUnsignedGreater(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    sltu(CMPRES2, rs, rd);
    bne(CMPRES2, ZR, l);
  }

  void BranchUnsignedGreater(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      BranchNotEqual(rd, Immediate(0), l);
    } else {
      if ((imm.value() != -1) && Utils::IsInt(kImmBits, imm.value() + 1)) {
        sltiu(CMPRES2, rd, Immediate(imm.value() + 1));
        beq(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchUnsignedGreater(rd, CMPRES2, l);
      }
    }
  }

  void BranchSignedGreaterEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    slt(CMPRES2, rd, rs);  // CMPRES2 = rd < rs ? 1 : 0.
    beq(CMPRES2, ZR, l);   // If CMPRES2 = 0, then rd >= rs.
  }

  void BranchSignedGreaterEqual(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      bgez(rd, l);
    } else {
      if (Utils::IsInt(kImmBits, imm.value())) {
        slti(CMPRES2, rd, imm);
        beq(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchSignedGreaterEqual(rd, CMPRES2, l);
      }
    }
  }

  void BranchUnsignedGreaterEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    sltu(CMPRES2, rd, rs);  // CMPRES2 = rd < rs ? 1 : 0.
    beq(CMPRES2, ZR, l);
  }

  void BranchUnsignedGreaterEqual(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      b(l);
    } else {
      if (Utils::IsInt(kImmBits, imm.value())) {
        sltiu(CMPRES2, rd, imm);
        beq(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchUnsignedGreaterEqual(rd, CMPRES2, l);
      }
    }
  }

  void BranchSignedLess(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchSignedGreater(rs, rd, l);
  }

  void BranchSignedLess(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      bltz(rd, l);
    } else {
      if (Utils::IsInt(kImmBits, imm.value())) {
        slti(CMPRES2, rd, imm);
        bne(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchSignedGreater(CMPRES2, rd, l);
      }
    }
  }

  void BranchUnsignedLess(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchUnsignedGreater(rs, rd, l);
  }

  void BranchUnsignedLess(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      // Never branch. Fall through.
    } else {
      if (Utils::IsInt(kImmBits, imm.value())) {
        sltiu(CMPRES2, rd, imm);
        bne(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchUnsignedGreater(CMPRES2, rd, l);
      }
    }
  }

  void BranchSignedLessEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchSignedGreaterEqual(rs, rd, l);
  }

  void BranchSignedLessEqual(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      blez(rd, l);
    } else {
      if (Utils::IsInt(kImmBits, imm.value() + 1)) {
        slti(CMPRES2, rd, Immediate(imm.value() + 1));
        bne(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchSignedGreaterEqual(CMPRES2, rd, l);
      }
    }
  }

  void BranchUnsignedLessEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchUnsignedGreaterEqual(rs, rd, l);
  }

  void BranchUnsignedLessEqual(Register rd, const Immediate& imm, Label* l) {
    ASSERT(!in_delay_slot_);
    if (imm.value() == 0) {
      beq(rd, ZR, l);
    } else {
      if ((imm.value() != -1) && Utils::IsInt(kImmBits, imm.value() + 1)) {
        sltiu(CMPRES2, rd, Immediate(imm.value() + 1));
        bne(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, imm.value());
        BranchUnsignedGreaterEqual(CMPRES2, rd, l);
      }
    }
  }

  void Push(Register rt) {
    ASSERT(!in_delay_slot_);
    addiu(SP, SP, Immediate(-kWordSize));
    sw(rt, Address(SP));
  }

  void Pop(Register rt) {
    ASSERT(!in_delay_slot_);
    lw(rt, Address(SP));
    addiu(SP, SP, Immediate(kWordSize));
  }

  void Ret() { jr(RA); }

  void SmiTag(Register reg) { sll(reg, reg, kSmiTagSize); }

  void SmiTag(Register dst, Register src) { sll(dst, src, kSmiTagSize); }

  void SmiUntag(Register reg) { sra(reg, reg, kSmiTagSize); }

  void SmiUntag(Register dst, Register src) { sra(dst, src, kSmiTagSize); }

  void BranchIfNotSmi(Register reg, Label* label) {
    andi(CMPRES1, reg, Immediate(kSmiTagMask));
    bne(CMPRES1, ZR, label);
  }

  void BranchIfSmi(Register reg, Label* label) {
    andi(CMPRES1, reg, Immediate(kSmiTagMask));
    beq(CMPRES1, ZR, label);
  }

  void LoadFromOffset(Register reg, Register base, int32_t offset) {
    ASSERT(!in_delay_slot_);
    if (Utils::IsInt(kImmBits, offset)) {
      lw(reg, Address(base, offset));
    } else {
      LoadImmediate(TMP, offset);
      addu(TMP, base, TMP);
      lw(reg, Address(TMP, 0));
    }
  }

  void LoadFieldFromOffset(Register reg, Register base, int32_t offset) {
    LoadFromOffset(reg, base, offset - kHeapObjectTag);
  }

  void StoreToOffset(Register reg, Register base, int32_t offset) {
    ASSERT(!in_delay_slot_);
    if (Utils::IsInt(kImmBits, offset)) {
      sw(reg, Address(base, offset));
    } else {
      LoadImmediate(TMP, offset);
      addu(TMP, base, TMP);
      sw(reg, Address(TMP, 0));
    }
  }

  void StoreFieldToOffset(Register reg, Register base, int32_t offset) {
    StoreToOffset(reg, base, offset - kHeapObjectTag);
  }


  void StoreDToOffset(DRegister reg, Register base, int32_t offset) {
    ASSERT(!in_delay_slot_);
    FRegister lo = static_cast<FRegister>(reg * 2);
    FRegister hi = static_cast<FRegister>(reg * 2 + 1);
    swc1(lo, Address(base, offset));
    swc1(hi, Address(base, offset + kWordSize));
  }

  void LoadDFromOffset(DRegister reg, Register base, int32_t offset) {
    ASSERT(!in_delay_slot_);
    FRegister lo = static_cast<FRegister>(reg * 2);
    FRegister hi = static_cast<FRegister>(reg * 2 + 1);
    lwc1(lo, Address(base, offset));
    lwc1(hi, Address(base, offset + kWordSize));
  }

  // dest gets the address of the following instruction. If temp is given,
  // RA is preserved using it as a temporary.
  void GetNextPC(Register dest, Register temp = kNoRegister);

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // Create a frame for calling into runtime that preserves all volatile
  // registers.  Frame's SP is guaranteed to be correctly aligned and
  // frame_space bytes are reserved under it.
  void EnterCallRuntimeFrame(intptr_t frame_space);
  void LeaveCallRuntimeFrame();

  void LoadObject(Register rd, const Object& object);
  void LoadUniqueObject(Register rd, const Object& object);
  void LoadFunctionFromCalleePool(Register dst,
                                  const Function& function,
                                  Register new_pp);
  void LoadNativeEntry(Register rd,
                       const ExternalLabel* label,
                       Patchability patchable);
  void PushObject(const Object& object);

  void LoadIsolate(Register result);

  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);
  void LoadClass(Register result, Register object);
  void LoadClassIdMayBeSmi(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

  void StoreIntoObject(Register object,      // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,       // Value we are storing.
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

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size);
  void LeaveDartFrame(RestorePP restore_pp = kRestoreCallerPP);
  void LeaveDartFrameAndReturn(Register ra = RA);

  // Set up a Dart frame for a function compiled for on-stack replacement.
  // The frame layout is a normal Dart frame, but the frame is partially set
  // up on entry (it is the frame of the unoptimized code).
  void EnterOsrFrame(intptr_t extra_size);

  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const;
  void LoadElementAddressForIntIndex(Register address,
                                     bool is_external,
                                     intptr_t cid,
                                     intptr_t index_scale,
                                     Register array,
                                     intptr_t index);
  Address ElementAddressForRegIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    Register index);
  void LoadElementAddressForRegIndex(Register address,
                                     bool is_load,
                                     bool is_external,
                                     intptr_t cid,
                                     intptr_t index_scale,
                                     Register array,
                                     Register index);

  void LoadHalfWordUnaligned(Register dst, Register addr, Register tmp);
  void LoadHalfWordUnsignedUnaligned(Register dst, Register addr, Register tmp);
  void StoreHalfWordUnaligned(Register src, Register addr, Register tmp);
  void LoadWordUnaligned(Register dst, Register addr, Register tmp);
  void StoreWordUnaligned(Register src, Register addr, Register tmp);

  static Address VMTagAddress() {
    return Address(THR, Thread::vm_tag_offset());
  }

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return object.IsSmi(); }

  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool b) { constant_pool_allowed_ = b; }

 private:
  AssemblerBuffer buffer_;
  ObjectPoolWrapper object_pool_wrapper_;

  intptr_t prologue_offset_;
  bool has_single_entry_point_;
  bool use_far_branches_;
  bool delay_slot_available_;
  bool in_delay_slot_;

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) {}

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  GrowableArray<CodeComment*> comments_;

  bool constant_pool_allowed_;

  void BranchLink(const ExternalLabel* label);
  void BranchLink(const Code& code, Patchability patchable);

  bool CanLoadFromObjectPool(const Object& object) const;

  void LoadWordFromPoolOffset(Register rd, int32_t offset, Register pp = PP);
  void LoadObjectHelper(Register rd, const Object& object, bool is_unique);

  void Emit(int32_t value) {
    // Emitting an instruction clears the delay slot state.
    in_delay_slot_ = false;
    delay_slot_available_ = false;
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<int32_t>(value);
  }

  // Encode CPU instructions according to the types specified in
  // Figures 4-1, 4-2 and 4-3 in VolI-A.
  void EmitIType(Opcode opcode, Register rs, Register rt, uint16_t imm) {
    Emit(opcode << kOpcodeShift | rs << kRsShift | rt << kRtShift | imm);
  }

  void EmitLoadStore(Opcode opcode, Register rt, const Address& addr) {
    Emit(opcode << kOpcodeShift | rt << kRtShift | addr.encoding());
  }

  void EmitFpuLoadStore(Opcode opcode, FRegister ft, const Address& addr) {
    Emit(opcode << kOpcodeShift | ft << kFtShift | addr.encoding());
  }

  void EmitRegImmType(Opcode opcode, Register rs, RtRegImm code, uint16_t imm) {
    Emit(opcode << kOpcodeShift | rs << kRsShift | code << kRtShift | imm);
  }

  void EmitJType(Opcode opcode, uint32_t destination) { UNIMPLEMENTED(); }

  void EmitRType(Opcode opcode,
                 Register rs,
                 Register rt,
                 Register rd,
                 int sa,
                 SpecialFunction func) {
    ASSERT(Utils::IsUint(5, sa));
    Emit(opcode << kOpcodeShift | rs << kRsShift | rt << kRtShift |
         rd << kRdShift | sa << kSaShift | func << kFunctionShift);
  }

  void EmitFpuRType(Opcode opcode,
                    Format fmt,
                    FRegister ft,
                    FRegister fs,
                    FRegister fd,
                    Cop1Function func) {
    Emit(opcode << kOpcodeShift | fmt << kFmtShift | ft << kFtShift |
         fs << kFsShift | fd << kFdShift | func << kCop1FnShift);
  }

  int32_t EncodeBranchOffset(int32_t offset, int32_t instr);

  void EmitFarJump(int32_t offset, bool link);
  void EmitFarBranch(Opcode b, Register rs, Register rt, int32_t offset);
  void EmitFarRegImmBranch(RtRegImm b, Register rs, int32_t offset);
  void EmitFarFpuBranch(bool kind, int32_t offset);
  void EmitBranch(Opcode b, Register rs, Register rt, Label* label);
  void EmitRegImmBranch(RtRegImm b, Register rs, Label* label);
  void EmitFpuBranch(bool kind, Label* label);

  void EmitBranchDelayNop() {
    Emit(Instr::kNopInstruction);  // Branch delay NOP.
    delay_slot_available_ = true;
  }

  void StoreIntoObjectFilter(Register object, Register value, Label* no_update);

  // Shorter filtering sequence that assumes that value is not a smi.
  void StoreIntoObjectFilterNoSmi(Register object,
                                  Register value,
                                  Label* no_update);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // RUNTIME_VM_ASSEMBLER_MIPS_H_
