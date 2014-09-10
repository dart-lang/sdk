// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_MIPS_H_
#define VM_ASSEMBLER_MIPS_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_mips.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_mips.h"
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

class Immediate : public ValueObject {
 public:
  explicit Immediate(int32_t value) : value_(value) { }

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) { }
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
      : ValueObject(), base_(base), offset_(offset) { }

  Address(const Address& other)
      : ValueObject(), base_(other.base_), offset_(other.offset_) { }
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
      : Address(base, disp - kHeapObjectTag) { }

  FieldAddress(const FieldAddress& other) : Address(other) { }

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};


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


class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false)
      : buffer_(),
        object_pool_(GrowableObjectArray::Handle()),
        prologue_offset_(-1),
        use_far_branches_(use_far_branches),
        delay_slot_available_(false),
        in_delay_slot_(false),
        comments_(),
        allow_constant_pool_(true) { }
  ~Assembler() { }

  void PopRegister(Register r) { Pop(r); }

  void Bind(Label* label);

  // Misc. functionality
  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return prologue_offset_; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.
  intptr_t CountPointerOffsets() const {
    return buffer_.CountPointerOffsets();
  }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }
  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

  void set_use_far_branches(bool b) {
    ASSERT(buffer_.Size() == 0);
    use_far_branches_ = b;
  }

  void EnterFrame();
  void LeaveFrameAndReturn();

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame(bool load_pp = false);
  void LeaveStubFrame();
  // A separate macro for when a Ret immediately follows, so that we can use
  // the branch delay slot.
  void LeaveStubFrameAndReturn(Register ra = RA);

  // Instruction pattern from entrypoint is used in dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  // See EnterDartFrame. There are 6 instructions before we know the PC.
  static const intptr_t kEntryPointToPcMarkerOffset = 6 * Instr::kInstrSize;
  static intptr_t EntryPointToPcMarkerOffset() {
    return kEntryPointToPcMarkerOffset;
  }

  void UpdateAllocationStats(intptr_t cid,
                             Register temp_reg,
                             Heap::Space space = Heap::kNew);

  void UpdateAllocationStatsWithSize(intptr_t cid,
                                     Register size_reg,
                                     Register temp_reg,
                                     Heap::Space space = Heap::kNew);


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

  // TODO(zra): TraceSimMsg enables printing of helpful messages when
  // --trace_sim is given. Eventually these calls will be changed to Comment.
  void TraceSimMsg(const char* message);
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
  void b(Label* l) {
    beq(R0, R0, l);
  }

  void bal(Label *l) {
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

  void break_(int32_t code) {
    ASSERT(Utils::IsUint(20, code));
    Emit(SPECIAL << kOpcodeShift |
         code << kBreakCodeShift |
         BREAK << kFunctionShift);
  }

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

  // Converts a 64-bit signed int in fs to a double in fd.
  void cvtdl(DRegister dd, DRegister ds) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    FRegister fd = static_cast<FRegister>(dd * 2);
    EmitFpuRType(COP1, FMT_L, F0, fs, fd, COP1_CVT_D);
  }

  void cvtsd(FRegister fd, DRegister ds) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_CVT_S);
  }

  void cvtwd(FRegister fd, DRegister ds) {
    FRegister fs = static_cast<FRegister>(ds * 2);
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_CVT_W);
  }

  void div(Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, R0, 0, DIV);
  }

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

  void lb(Register rt, const Address& addr) {
    EmitLoadStore(LB, rt, addr);
  }

  void lbu(Register rt, const Address& addr) {
    EmitLoadStore(LBU, rt, addr);
  }

  void ldc1(DRegister dt, const Address& addr) {
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuLoadStore(LDC1, ft, addr);
  }

  void lh(Register rt, const Address& addr) {
    EmitLoadStore(LH, rt, addr);
  }

  void lhu(Register rt, const Address& addr) {
    EmitLoadStore(LHU, rt, addr);
  }

  void lui(Register rt, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(LUI, R0, rt, imm_value);
  }

  void lw(Register rt, const Address& addr) {
    EmitLoadStore(LW, rt, addr);
  }

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
    Emit(COP1 << kOpcodeShift |
         COP1_MF << kCop1SubShift |
         rt << kRtShift |
         fs << kFsShift);
  }

  void mfhi(Register rd) {
    EmitRType(SPECIAL, R0, R0, rd, 0, MFHI);
  }

  void mflo(Register rd) {
    EmitRType(SPECIAL, R0, R0, rd, 0, MFLO);
  }

  void mov(Register rd, Register rs) {
    or_(rd, rs, ZR);
  }

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
    Emit(COP1 << kOpcodeShift |
         COP1_MT << kCop1SubShift |
         rt << kRtShift |
         fs << kFsShift);
  }

  void mthi(Register rs) {
    EmitRType(SPECIAL, rs, R0, R0, 0, MTHI);
  }

  void mtlo(Register rs) {
    EmitRType(SPECIAL, rs, R0, R0, 0, MTLO);
  }

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

  void nop() {
    Emit(Instr::kNopInstruction);
  }

  void nor(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, NOR);
  }

  void or_(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, OR);
  }

  void ori(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(ORI, rs, rt, imm_value);
  }

  void sb(Register rt, const Address& addr) {
    EmitLoadStore(SB, rt, addr);
  }

  void sdc1(DRegister dt, const Address& addr) {
    FRegister ft = static_cast<FRegister>(dt * 2);
    EmitFpuLoadStore(SDC1, ft, addr);
  }

  void sh(Register rt, const Address& addr) {
    EmitLoadStore(SH, rt, addr);
  }

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
    int16_t imm_value = static_cast<int16_t>(imm.value());
    EmitIType(SLTI, rs, rt, imm_value);
  }

  void sltiu(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsUint(kImmBits, imm.value()));
    uint16_t imm_value = static_cast<uint16_t>(imm.value());
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

  void sw(Register rt, const Address& addr) {
    EmitLoadStore(SW, rt, addr);
  }

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
  void AdduDetectOverflow(Register rd, Register rs, Register rt, Register ro,
                          Register scratch = kNoRegister);

  // ro must be different from rd and rs.
  // rd and ro must not be TMP.
  // If rd and rs are the same, a scratch register different from the other
  // registers is needed.
  void AddImmediateDetectOverflow(Register rd, Register rs, int32_t imm,
                                  Register ro, Register scratch = kNoRegister) {
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
  void SubImmediateDetectOverflow(Register rd, Register rs, int32_t imm,
                                  Register ro) {
    ASSERT(!in_delay_slot_);
    LoadImmediate(rd, imm);
    SubuDetectOverflow(rd, rs, rd, ro);
  }

  void Branch(const ExternalLabel* label) {
    ASSERT(!in_delay_slot_);
    LoadImmediate(TMP, label->address());
    jr(TMP);
  }

  void BranchPatchable(const ExternalLabel* label) {
    ASSERT(!in_delay_slot_);
    const uint16_t low = Utils::Low16Bits(label->address());
    const uint16_t high = Utils::High16Bits(label->address());
    lui(T9, Immediate(high));
    ori(T9, T9, Immediate(low));
    jr(T9);
    delay_slot_available_ = false;  // CodePatcher expects a nop.
  }

  void BranchLink(const ExternalLabel* label) {
    ASSERT(!in_delay_slot_);
    LoadImmediate(T9, label->address());
    jalr(T9);
  }

  void BranchLinkPatchable(const ExternalLabel* label) {
    ASSERT(!in_delay_slot_);
    const int32_t offset =
        Array::data_offset() + 4*AddExternalLabel(label) - kHeapObjectTag;
    LoadWordFromPoolOffset(T9, offset);
    jalr(T9);
    delay_slot_available_ = false;  // CodePatcher expects a nop.
  }

  void Drop(intptr_t stack_elements) {
    ASSERT(stack_elements >= 0);
    if (stack_elements > 0) {
      addiu(SP, SP, Immediate(stack_elements * kWordSize));
    }
  }

  void LoadPoolPointer() {
    ASSERT(!in_delay_slot_);
    GetNextPC(TMP);  // TMP gets the address of the next instruction.
    const intptr_t object_pool_pc_dist =
        Instructions::HeaderSize() - Instructions::object_pool_offset() +
        CodeSize();
    lw(PP, Address(TMP, -object_pool_pc_dist));
  }

  void LoadImmediate(Register rd, int32_t value) {
    ASSERT(!in_delay_slot_);
    if (Utils::IsInt(kImmBits, value)) {
      addiu(rd, ZR, Immediate(value));
    } else {
      const uint16_t low = Utils::Low16Bits(value);
      const uint16_t high = Utils::High16Bits(value);
      lui(rd, Immediate(high));
      ori(rd, rd, Immediate(low));
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

  void BranchEqual(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      beq(rd, ZR, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, value);
      beq(rd, CMPRES2, l);
    }
  }

  void BranchEqual(Register rd, const Object& object, Label* l) {
    ASSERT(!in_delay_slot_);
    ASSERT(rd != CMPRES2);
    LoadObject(CMPRES2, object);
    beq(rd, CMPRES2, l);
  }

  void BranchNotEqual(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      bne(rd, ZR, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, value);
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

  void BranchSignedGreater(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      bgtz(rd, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, value);
      BranchSignedGreater(rd, CMPRES2, l);
    }
  }

  void BranchUnsignedGreater(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    sltu(CMPRES2, rs, rd);
    bne(CMPRES2, ZR, l);
  }

  void BranchUnsignedGreater(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      BranchNotEqual(rd, 0, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, value);
      BranchUnsignedGreater(rd, CMPRES2, l);
    }
  }

  void BranchSignedGreaterEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    slt(CMPRES2, rd, rs);  // CMPRES2 = rd < rs ? 1 : 0.
    beq(CMPRES2, ZR, l);  // If CMPRES2 = 0, then rd >= rs.
  }

  void BranchSignedGreaterEqual(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      bgez(rd, l);
    } else {
      if (Utils::IsInt(kImmBits, value)) {
        slti(CMPRES2, rd, Immediate(value));
        beq(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, value);
        BranchSignedGreaterEqual(rd, CMPRES2, l);
      }
    }
  }

  void BranchUnsignedGreaterEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    sltu(CMPRES2, rd, rs);  // CMPRES2 = rd < rs ? 1 : 0.
    beq(CMPRES2, ZR, l);
  }

  void BranchUnsignedGreaterEqual(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      b(l);
    } else {
      if (Utils::IsUint(kImmBits, value)) {
        sltiu(CMPRES2, rd, Immediate(value));
        beq(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, value);
        BranchUnsignedGreaterEqual(rd, CMPRES2, l);
      }
    }
  }

  void BranchSignedLess(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchSignedGreater(rs, rd, l);
  }

  void BranchSignedLess(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      bltz(rd, l);
    } else {
      if (Utils::IsInt(kImmBits, value)) {
        slti(CMPRES2, rd, Immediate(value));
        bne(CMPRES2, ZR, l);
      } else {
        ASSERT(rd != CMPRES2);
        LoadImmediate(CMPRES2, value);
        BranchSignedGreater(CMPRES2, rd, l);
      }
    }
  }

  void BranchUnsignedLess(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchUnsignedGreater(rs, rd, l);
  }

  void BranchUnsignedLess(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    ASSERT(value != 0);
    if (Utils::IsUint(kImmBits, value)) {
      sltiu(CMPRES2, rd, Immediate(value));
      bne(CMPRES2, ZR, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, value);
      BranchUnsignedGreater(CMPRES2, rd, l);
    }
  }

  void BranchSignedLessEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchSignedGreaterEqual(rs, rd, l);
  }

  void BranchSignedLessEqual(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    if (value == 0) {
      blez(rd, l);
    } else {
      ASSERT(rd != CMPRES2);
      LoadImmediate(CMPRES2, value);
      BranchSignedGreaterEqual(CMPRES2, rd, l);
    }
  }

  void BranchUnsignedLessEqual(Register rd, Register rs, Label* l) {
    ASSERT(!in_delay_slot_);
    BranchUnsignedGreaterEqual(rs, rd, l);
  }

  void BranchUnsignedLessEqual(Register rd, int32_t value, Label* l) {
    ASSERT(!in_delay_slot_);
    ASSERT(rd != CMPRES2);
    LoadImmediate(CMPRES2, value);
    BranchUnsignedGreaterEqual(CMPRES2, rd, l);
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

  void Ret() {
    jr(RA);
  }

  void SmiTag(Register reg) {
    sll(reg, reg, kSmiTagSize);
  }

  void SmiUntag(Register reg) {
    sra(reg, reg, kSmiTagSize);
  }

  void SmiUntag(Register dst, Register src) {
    sra(dst, src, kSmiTagSize);
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

  void LoadWordFromPoolOffset(Register rd, int32_t offset);
  void LoadObject(Register rd, const Object& object);
  void PushObject(const Object& object);

  // Compares rn with the object. Returns results in rd1 and rd2.
  // rd1 is 1 if rn < object. rd2 is 1 if object < rn. Since both cannot be
  // 1, rd1 == rd2 (== 0) iff rn == object.
  void CompareObject(Register rd1, Register rd2,
                     Register rn, const Object& object);

  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);
  void LoadClass(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

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

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size);
  void LeaveDartFrame();
  void LeaveDartFrameAndReturn();

  // Set up a Dart frame for a function compiled for on-stack replacement.
  // The frame layout is a normal Dart frame, but the frame is partially set
  // up on entry (it is the frame of the unoptimized code).
  void EnterOsrFrame(intptr_t extra_size);

  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const;
  Address ElementAddressForRegIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    Register index);

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
  AssemblerBuffer buffer_;
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  intptr_t prologue_offset_;

  bool use_far_branches_;
  bool delay_slot_available_;
  bool in_delay_slot_;

  int32_t AddObject(const Object& obj);
  int32_t AddExternalLabel(const ExternalLabel* label);

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

  void Emit(int32_t value) {
    // Emitting an instruction clears the delay slot state.
    in_delay_slot_ = false;
    delay_slot_available_ = false;
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<int32_t>(value);
  }

  // Encode CPU instructions according to the types specified in
  // Figures 4-1, 4-2 and 4-3 in VolI-A.
  void EmitIType(Opcode opcode,
                 Register rs,
                 Register rt,
                 uint16_t imm) {
    Emit(opcode << kOpcodeShift |
         rs << kRsShift |
         rt << kRtShift |
         imm);
  }

  void EmitLoadStore(Opcode opcode, Register rt,
                     const Address &addr) {
    Emit(opcode << kOpcodeShift |
         rt << kRtShift |
         addr.encoding());
  }

  void EmitFpuLoadStore(Opcode opcode, FRegister ft,
                        const Address &addr) {
    Emit(opcode << kOpcodeShift |
         ft << kFtShift |
         addr.encoding());
  }

  void EmitRegImmType(Opcode opcode,
                      Register rs,
                      RtRegImm code,
                      uint16_t imm) {
    Emit(opcode << kOpcodeShift |
         rs << kRsShift |
         code << kRtShift |
         imm);
  }

  void EmitJType(Opcode opcode, uint32_t destination) {
    UNIMPLEMENTED();
  }

  void EmitRType(Opcode opcode,
                 Register rs,
                 Register rt,
                 Register rd,
                 int sa,
                 SpecialFunction func) {
    ASSERT(Utils::IsUint(5, sa));
    Emit(opcode << kOpcodeShift |
         rs << kRsShift |
         rt << kRtShift |
         rd << kRdShift |
         sa << kSaShift |
         func << kFunctionShift);
  }

  void EmitFpuRType(Opcode opcode,
                    Format fmt,
                    FRegister ft,
                    FRegister fs,
                    FRegister fd,
                    Cop1Function func) {
    Emit(opcode << kOpcodeShift |
         fmt << kFmtShift |
         ft << kFtShift |
         fs << kFsShift |
         fd << kFdShift |
         func << kCop1FnShift);
  }

  int32_t EncodeBranchOffset(int32_t offset, int32_t instr);

  void EmitFarJump(int32_t offset, bool link);
  void EmitFarBranch(Opcode b, Register rs, Register rt, int32_t offset);
  void EmitFarRegImmBranch(RtRegImm b, Register rs, int32_t offset);
  void EmitFarFpuBranch(bool kind, int32_t offset);
  void EmitBranch(Opcode b, Register rs, Register rt, Label* label);
  void EmitRegImmBranch(RtRegImm b, Register rs, Label* label);
  void EmitFpuBranch(bool kind, Label *label);

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

#endif  // VM_ASSEMBLER_MIPS_H_
