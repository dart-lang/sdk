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
  Address(Register base, int32_t offset = 0)
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
  int Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  int position_;

  void Reinitialize() {
    position_ = 0;
  }

  void BindTo(int position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(int position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class CPUFeatures : public AllStatic {
 public:
  static void InitOnce() { }
  static bool double_truncate_round_supported() {
    UNIMPLEMENTED();
    return false;
  }
};


class Assembler : public ValueObject {
 public:
  Assembler()
      : buffer_(),
        object_pool_(GrowableObjectArray::Handle()),
        prologue_offset_(-1),
        delay_slot_available_(false),
        in_delay_slot_(false),
        comments_() { }
  ~Assembler() { }

  void PopRegister(Register r) { Pop(r); }

  void Bind(Label* label);

  // Misc. functionality
  int CodeSize() const { return buffer_.Size(); }
  int prologue_offset() const { return -1; }
  const ZoneGrowableArray<int>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }
  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame(bool uses_pp = false);
  void LeaveStubFrame(bool uses_pp = false);

  // Instruction pattern from entrypoint is used in dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  // See EnterDartFrame. There are 6 instructions before we know the PC.
  static const intptr_t kOffsetOfSavedPCfromEntrypoint = 6 * Instr::kInstrSize;

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   bool near_jump,
                   Register instance_reg) {
    UNIMPLEMENTED();
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, int length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg) {
    UNIMPLEMENTED();
    return NULL;
  }

  static const char* FpuRegisterName(FpuRegister reg) {
    UNIMPLEMENTED();
    return NULL;
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
  void addd(FRegister fd, FRegister fs, FRegister ft) {
    ASSERT(EvenFPURegister(fd));
    ASSERT(EvenFPURegister(fs));
    ASSERT(EvenFPURegister(ft));
    EmitFpuRType(COP1, FMT_D, ft, fs, fd, COP1_ADD);
  }

  void addiu(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsInt(kImmBits, imm.value()));
    const uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(ADDIU, rs, rt, imm_value);
  }

  void adds(FRegister fd, FRegister fs, FRegister ft) {
    EmitFpuRType(COP1, FMT_S, ft, fs, fd, COP1_ADD);
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

  void clo(Register rd, Register rs) {
    EmitRType(SPECIAL2, rs, rd, rd, 0, CLO);
  }

  void clz(Register rd, Register rs) {
    EmitRType(SPECIAL2, rs, rd, rd, 0, CLZ);
  }

  void div(Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, R0, 0, DIV);
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

  void ldc1(FRegister ft, const Address& addr) {
    ASSERT(EvenFPURegister(ft));
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

  void movd(FRegister fd, FRegister fs) {
    ASSERT(EvenFPURegister(fd));
    ASSERT(EvenFPURegister(fs));
    EmitFpuRType(COP1, FMT_D, F0, fs, fd, COP1_MOV);
  }

  void movn(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, MOVN);
  }

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

  void sdc1(FRegister ft, const Address& addr) {
    ASSERT(EvenFPURegister(ft));
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

  void sltu(Register rd, Register rs, Register rt) {
    EmitRType(SPECIAL, rs, rt, rd, 0, SLTU);
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
  // rd and ro must not be TMP1 or TMP2.
  // ro must be different from all the other registers.
  void AdduDetectOverflow(Register rd, Register rs, Register rt, Register ro);

  // ro must be different from rd and rs.
  // rd and ro must not be TMP1 or TMP2
  void AddImmediateDetectOverflow(Register rd, Register rs, int32_t imm,
                                  Register ro) {
    LoadImmediate(rd, imm);
    AdduDetectOverflow(rd, rs, rd, ro);
  }

  // Subtraction of rt from rs (rs - rt) with the result placed in rd.
  // After, ro < 0 if there was signed overflow, ro >= 0 otherwise.
  // None of rd, rs, rt, or ro may be TMP1.
  // ro must be different from the other registers.
  void SubuDetectOverflow(Register rd, Register rs, Register rt, Register ro);

  // ro must be different from rd and rs.
  // None of rd, rs, rt, or ro may be TMP1.
  void SubImmediateDetectOverflow(Register rd, Register rs, int32_t imm,
                                  Register ro) {
    LoadImmediate(rd, imm);
    SubuDetectOverflow(rd, rs, rd, ro);
  }

  void Branch(const ExternalLabel* label) {
    LoadImmediate(TMP1, label->address());
    jr(TMP1);
  }

  void BranchPatchable(const ExternalLabel* label) {
    const uint16_t low = Utils::Low16Bits(label->address());
    const uint16_t high = Utils::High16Bits(label->address());
    lui(TMP1, Immediate(high));
    ori(TMP1, TMP1, Immediate(low));
    jr(TMP1);
    delay_slot_available_ = false;  // CodePatcher expects a nop.
  }

  void BranchLink(const ExternalLabel* label) {
    LoadImmediate(TMP1, label->address());
    jalr(TMP1);
  }

  void BranchLinkPatchable(const ExternalLabel* label) {
    const int32_t offset =
        Array::data_offset() + 4*AddExternalLabel(label) - kHeapObjectTag;
    LoadWordFromPoolOffset(TMP1, offset);
    jalr(TMP1);
    delay_slot_available_ = false;  // CodePatcher expects a nop.
  }

  void Drop(intptr_t stack_elements) {
    ASSERT(stack_elements >= 0);
    if (stack_elements > 0) {
      addiu(SP, SP, Immediate(stack_elements * kWordSize));
    }
  }

  void LoadImmediate(Register rd, int32_t value) {
    if (Utils::IsInt(kImmBits, value)) {
      addiu(rd, ZR, Immediate(value));
    } else {
      const uint16_t low = Utils::Low16Bits(value);
      const uint16_t high = Utils::High16Bits(value);
      lui(rd, Immediate(high));
      ori(rd, rd, Immediate(low));
    }
  }

  void LoadImmediate(FRegister rd, double value) {
    ASSERT(EvenFPURegister(rd));
    const int64_t ival = bit_cast<uint64_t, double>(value);
    const int32_t low = Utils::Low32Bits(ival);
    const int32_t high = Utils::High32Bits(ival);
    if (low != 0) {
      LoadImmediate(TMP1, low);
      mtc1(TMP1, rd);
    } else {
      mtc1(ZR, rd);
    }

    if (high != 0) {
      LoadImmediate(TMP1, high);
      mtc1(TMP1, static_cast<FRegister>(rd + 1));
    } else {
      mtc1(ZR, static_cast<FRegister>(rd + 1));
    }
  }

  void LoadImmediate(FRegister rd, float value) {
    const int32_t ival = bit_cast<int32_t, float>(value);
    if (ival == 0) {
      mtc1(ZR, rd);
    } else {
      LoadImmediate(TMP1, ival);
      mtc1(TMP1, rd);
    }
  }

  void AddImmediate(Register rd, Register rs, int32_t value) {
    if (Utils::IsInt(kImmBits, value)) {
      addiu(rd, rs, Immediate(value));
    } else {
      LoadImmediate(TMP1, value);
      addu(rd, rs, TMP1);
    }
  }

  void AddImmediate(Register rd, int32_t value) {
    AddImmediate(rd, rd, value);
  }

  void BranchEqual(Register rd, int32_t value, Label* l) {
    LoadImmediate(TMP1, value);
    beq(rd, TMP1, l);
  }

  void BranchEqual(Register rd, const Object& object, Label* l) {
    LoadObject(TMP1, object);
    beq(rd, TMP1, l);
  }

  void BranchNotEqual(Register rd, int32_t value, Label* l) {
    LoadImmediate(TMP1, value);
    bne(rd, TMP1, l);
  }

  void BranchNotEqual(Register rd, const Object& object, Label* l) {
    LoadObject(TMP1, object);
    bne(rd, TMP1, l);
  }

  void BranchGreater(Register rd, int32_t value, Label* l) {
    if (Utils::IsInt(kImmBits, -value)) {
      addiu(TMP1, rd, Immediate(-value));
      bgtz(TMP1, l);
    } else {
      LoadImmediate(TMP1, value);
      subu(TMP1, rd, TMP1);
      bgtz(TMP1, l);
    }
  }

  void BranchGreater(Register rd, Register rs, Label* l) {
    subu(TMP1, rd, rs);
    bgtz(TMP1, l);
  }

  void BranchGreaterEqual(Register rd, int32_t value, Label* l) {
    if (Utils::IsInt(kImmBits, -value)) {
      addiu(TMP1, rd, Immediate(-value));
      bgez(TMP1, l);
    } else {
      LoadImmediate(TMP1, value);
      subu(TMP1, rd, TMP1);
      bgez(TMP1, l);
    }
  }

  void BranchGreaterEqual(Register rd, Register rs, Label* l) {
    subu(TMP1, rd, rs);
    bgez(TMP1, l);
  }

  void BranchLess(Register rd, int32_t value, Label* l) {
    if (Utils::IsInt(kImmBits, -value)) {
      addiu(TMP1, rd, Immediate(-value));
      bltz(TMP1, l);
    } else {
      LoadImmediate(TMP1, value);
      subu(TMP1, rd, TMP1);
      bltz(TMP1, l);
    }
  }

  void BranchLess(Register rd, Register rs, Label* l) {
    subu(TMP1, rd, rs);
    bltz(TMP1, l);
  }

  void BranchLessEqual(Register rd, int32_t value, Label* l) {
    if (Utils::IsInt(kImmBits, -value)) {
      addiu(TMP1, rd, Immediate(-value));
      blez(TMP1, l);
    } else {
      LoadImmediate(TMP1, value);
      subu(TMP1, rd, TMP1);
      blez(TMP1, l);
    }
  }

  void BranchLessEqual(Register rd, Register rs, Label* l) {
    subu(TMP1, rd, rs);
    blez(TMP1, l);
  }

  void Push(Register rt) {
    addiu(SP, SP, Immediate(-kWordSize));
    sw(rt, Address(SP));
  }

  void Pop(Register rt) {
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

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // Create a frame for calling into runtime that preserves all volatile
  // registers.  Frame's SP is guaranteed to be correctly aligned and
  // frame_space bytes are reserved under it.
  void EnterCallRuntimeFrame(intptr_t frame_space);
  void LeaveCallRuntimeFrame();

  void LoadWordFromPoolOffset(Register rd, int32_t offset);
  void LoadObject(Register rd, const Object& object);
  void PushObject(const Object& object);

  // Sets register rd to zero if the object is equal to register rn,
  // sets it to non-zero otherwise.
  void CompareObject(Register rd, Register rn, const Object& object);

  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);
  void LoadClass(Register result, Register object);

  void StoreIntoObject(Register object,  // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,  // Value we are storing.
                       bool can_value_be_smi = true);

  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);

  void CallRuntime(const RuntimeEntry& entry);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size);
  void LeaveDartFrame();

 private:
  AssemblerBuffer buffer_;
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  int prologue_offset_;

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

  bool EvenFPURegister(FRegister reg) {
    return (static_cast<int>(reg) & 1) == 0;
  }

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

  void EmitBranch(Opcode b, Register rs, Register rt, Label* label) {
    if (label->IsBound()) {
      // Relative destination from an instruction after the branch.
      const int32_t dest =
          label->Position() - (buffer_.Size() + Instr::kInstrSize);
      const uint16_t dest_off = EncodeBranchOffset(dest, 0);
      EmitIType(b, rs, rt, dest_off);
    } else {
      const int position = buffer_.Size();
      const uint16_t dest_off = EncodeBranchOffset(label->position_, 0);
      EmitIType(b, rs, rt, dest_off);
      label->LinkTo(position);
    }
  }

  void EmitRegImmBranch(RtRegImm b, Register rs, Label* label) {
    if (label->IsBound()) {
      // Relative destination from an instruction after the branch.
      const int32_t dest =
          label->Position() - (buffer_.Size() + Instr::kInstrSize);
      const uint16_t dest_off = EncodeBranchOffset(dest, 0);
      EmitRegImmType(REGIMM, rs, b, dest_off);
    } else {
      const int position = buffer_.Size();
      const uint16_t dest_off = EncodeBranchOffset(label->position_, 0);
      EmitRegImmType(REGIMM, rs, b, dest_off);
      label->LinkTo(position);
    }
  }

  static int32_t EncodeBranchOffset(int32_t offset, int32_t instr);
  static int DecodeBranchOffset(int32_t instr);

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
