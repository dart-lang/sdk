// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_loong64.h directly; use assembler.h instead.
#endif

#include <functional>
#include <initializer_list>

#include "platform/utils.h"
#include "vm/compiler/assembler/assembler_base.h"
#include "vm/constants.h"

namespace dart {

DECLARE_FLAG(bool, precompiled_mode);

// Forward declarations.
class FlowGraphCompiler;
class RuntimeEntry;
class RegisterSet;

namespace compiler {

class Address {
 public:
  Address(Register base, intptr_t offset) : base_(base), offset_(offset) {}
  explicit Address(Register base) : base_(base), offset_(0) {}

  Address(Register base, Register index) = delete;

  Register base() const { return base_; }
  intptr_t offset() const { return offset_; }

 private:
  Register base_;
  intptr_t offset_;
};

class FieldAddress : public Address {
 public:
  FieldAddress(Register base, intptr_t offset)
      : Address(base, offset - kHeapObjectTag) {}

  FieldAddress(Register base, Register index) = delete;
};

class Assembler : public AssemblerBase {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder,
                     intptr_t far_branch_level = 0)
      : AssemblerBase(object_pool_builder) {
    USE(far_branch_level);
  }
  ~Assembler() override = default;

  void Emit32(uint32_t instruction) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<uint32_t>(instruction);
  }

  uint32_t Read32(intptr_t position) { return buffer_.Load<uint32_t>(position); }

  void Write32(intptr_t position, uint32_t instruction) {
    buffer_.Store<uint32_t>(position, instruction);
  }

  void nop() { Emit32(kNop); }
  void Breakpoint() override { Emit32(0x002a0000); }
  void StoreStoreFence() override { dbar(0); }
  void SmiTag(Register r) override { SmiTag(r, r); }
  void Bind(Label* label) override {
    ASSERT(!label->IsBound());
    const intptr_t bound_pc = CodeSize();
    while (label->IsLinked()) {
      const intptr_t position = label->Position();
      const uint32_t instr = Read32(position);
      const intptr_t dest = bound_pc - position;
      label->position_ = DecodeAndPatchBranch(position, instr, dest);
    }
    label->BindTo(bound_pc);
  }
  void ExtendValue(Register dst, Register src, OperandSize sz) override {
    if ((dst == src) && (sz == kWordBytes)) {
      return;
    }
    switch (sz) {
      case kEightBytes:
        if (dst != src) {
          addi_d(dst, src, 0);
        }
        break;
      case kFourBytes:
        slli_d(dst, src, 32);
        srai_d(dst, dst, 32);
        break;
      case kUnsignedFourBytes:
        slli_d(dst, src, 32);
        srli_d(dst, dst, 32);
        break;
      case kTwoBytes:
        slli_d(dst, src, 48);
        srai_d(dst, dst, 48);
        break;
      case kUnsignedTwoBytes:
        slli_d(dst, src, 48);
        srli_d(dst, dst, 48);
        break;
      case kByte:
        slli_d(dst, src, 56);
        srai_d(dst, dst, 56);
        break;
      case kUnsignedByte:
        andi(dst, src, 0xff);
        break;
      default:
        UNREACHABLE();
    }
  }
  void TryAllocateObject(intptr_t cid,
                         intptr_t instance_size,
                         Label* failure,
                         JumpDistance distance,
                         Register instance_reg,
                         Register temp) override {
    ASSERT(failure != nullptr);
    ASSERT(instance_size != 0);
    ASSERT(instance_reg != temp);
    ASSERT(temp != kNoRegister);
    ASSERT(Utils::IsAligned(instance_size,
                            target::ObjectAlignment::kObjectAlignment));
    if (FLAG_inline_alloc &&
        target::Heap::IsAllocatableInNewSpace(instance_size)) {
      NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp));

      Load(instance_reg, Address(THR, target::Thread::top_offset()));
      Load(temp, Address(THR, target::Thread::end_offset()));
      AddImmediate(instance_reg, instance_reg, instance_size);
      bgeu(instance_reg, temp, failure, distance);
      CheckAllocationCanary(instance_reg, temp);

      Store(instance_reg, Address(THR, target::Thread::top_offset()));
      AddImmediate(instance_reg, instance_reg,
                   -instance_size + kHeapObjectTag);

      const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
      LoadImmediate(temp, tags);
      InitializeHeader(temp, instance_reg);
    } else {
      j(failure, distance);
    }
  }
  void BranchIfSmi(Register reg,
                   Label* label,
                   JumpDistance distance = kFarJump) override {
    ASSERT(reg != TMP2);
    AndImmediate(TMP2, reg, kSmiTagMask);
    beq(TMP2, ZR, label, distance);
  }
  void LslImmediate(Register reg,
                    int32_t shift,
                    OperandSize sz = kWordBytes) override {
    LslImmediate(reg, reg, shift, sz);
  }
  void LslImmediate(Register dst,
                    Register src,
                    int32_t shift,
                    OperandSize sz = kWordBytes) override {
    USE(sz);
    slli_d(dst, src, shift);
  }
  void ArithmeticShiftRightImmediate(Register reg,
                                     int32_t shift,
                                     OperandSize sz = kWordBytes) override {
    ArithmeticShiftRightImmediate(reg, reg, shift, sz);
  }
  void ArithmeticShiftRightImmediate(Register dst,
                                     Register src,
                                     int32_t shift,
                                     OperandSize sz = kWordBytes) override {
    USE(sz);
    srai_d(dst, src, shift);
  }
  void CompareWords(Register reg1,
                    Register reg2,
                    intptr_t offset,
                    Register count,
                    Register temp,
                    Label* equals) override {
  }
  void LoadFieldAddressForOffset(Register reg,
                                 Register base,
                                 int32_t offset) override {
    AddImmediate(reg, base, offset - kHeapObjectTag);
  }
  void LoadFieldAddressForRegOffset(Register address,
                                    Register instance,
                                    Register offset_in_words_as_smi) override {
    AddScaled(address, instance, offset_in_words_as_smi,
              static_cast<ScaleFactor>(target::kWordSizeLog2 - kSmiTagShift),
              -kHeapObjectTag);
  }
  void LoadAcquire(Register dst,
                   const Address& address,
                   OperandSize size = kWordBytes) override {
    Load(dst, address, size);
    dbar(0);
  }
  void StoreRelease(Register src,
                    const Address& address,
                    OperandSize size = kWordBytes) override {
    dbar(0);
    Store(src, address, size);
  }
  void Load(Register dst,
            const Address& address,
            OperandSize sz = kWordBytes) override {
    const Address addr = PrepareAddress(address.base(), address.offset());
    switch (sz) {
      case kEightBytes:
        ld_d(dst, addr);
        break;
      case kFourBytes:
        ld_w(dst, addr);
        break;
      case kUnsignedFourBytes:
        ld_wu(dst, addr);
        break;
      case kTwoBytes:
        ld_h(dst, addr);
        break;
      case kUnsignedTwoBytes:
        ld_hu(dst, addr);
        break;
      case kByte:
        ld_b(dst, addr);
        break;
      case kUnsignedByte:
        ld_bu(dst, addr);
        break;
      default:
        UNREACHABLE();
    }
  }
  void Store(Register src,
             const Address& address,
             OperandSize sz = kWordBytes) override {
    const Address addr = PrepareAddress(address.base(), address.offset());
    switch (sz) {
      case kEightBytes:
        st_d(src, addr);
        break;
      case kFourBytes:
      case kUnsignedFourBytes:
        st_w(src, addr);
        break;
      case kTwoBytes:
      case kUnsignedTwoBytes:
        st_h(src, addr);
        break;
      case kByte:
      case kUnsignedByte:
        st_b(src, addr);
        break;
      default:
        UNREACHABLE();
    }
  }
  void StoreObjectIntoObjectNoBarrier(
      Register object,
      const Address& address,
      const Object& value,
      MemoryOrder memory_order = kRelaxedNonAtomic,
      OperandSize size = kWordBytes) override {
    USE(object);
    if (memory_order == kRelease) {
      dbar(0);
    }
    LoadObject(TMP2, value);
    Store(TMP2, address, size);
  }
  void LoadIndexedPayload(Register dst,
                          Register base,
                          int32_t offset,
                          Register index,
                          ScaleFactor scale,
                          OperandSize sz = kWordBytes) override {
    AddScaled(TMP, base, index, scale, offset - kHeapObjectTag);
    Load(dst, Address(TMP), sz);
  }
  void LoadInt32FromBoxOrSmi(Register result, Register value) override {
    if (result == value) {
      ASSERT(TMP != value);
      MoveRegister(TMP, value);
      value = TMP;
    }
    ASSERT(value != result);
    compiler::Label done;
    SmiUntag(result, value);
    BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    LoadFieldFromOffset(result, value, target::Mint::value_offset(),
                        compiler::kFourBytes);
    Bind(&done);
  }
  void LoadInt64FromBoxOrSmi(Register result, Register value) override {
    if (result == value) {
      ASSERT(TMP != value);
      MoveRegister(TMP, value);
      value = TMP;
    }
    ASSERT(value != result);
    compiler::Label done;
    SmiUntag(result, value);
    BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    LoadFieldFromOffset(result, value, target::Mint::value_offset());
    Bind(&done);
  }
  void AddScaled(Register dst,
                 Register base,
                 Register index,
                 ScaleFactor scale,
                 int32_t disp) override {
    if (scale == 0) {
      MoveRegister(dst, index);
    } else {
      slli_d(dst, index, scale);
    }
    if (base != kNoRegister) {
      add_d(dst, dst, base);
    }
    if (disp != 0) {
      AddImmediate(dst, dst, disp);
    }
  }
  void LoadImmediate(Register dst, target::word imm) override {
    if (Utils::IsInt(12, imm)) {
      addi_d(dst, ZR, imm);
      return;
    }

    const uint64_t value = static_cast<uint64_t>(imm);
    const int32_t lo12 = value & 0xfff;
    const int32_t hi20 = (value >> 12) & 0xfffff;
    const int32_t hi32 = (value >> 32) & 0xfffff;
    const int32_t hi52 = (value >> 52) & 0xfff;
    const int32_t hi52_signed = (hi52 & 0x800) != 0 ? hi52 - 0x1000 : hi52;

    lu12i_w(dst, hi20);
    if (lo12 != 0) {
      ori(dst, dst, lo12);
    }
    if (!Utils::IsInt(32, imm)) {
      lu32i_d(dst, hi32);
      lu52i_d(dst, dst, hi52_signed);
    }
  }
  void CompareImmediate(Register reg,
                        target::word imm,
                        OperandSize width = kWordBytes) override {
    USE(width);
    compare_left_ = reg;
    if (imm == 0) {
      compare_right_ = ZR;
    } else {
      LoadImmediate(TMP2, imm);
      compare_right_ = TMP2;
    }
  }
  void CompareWithMemoryValue(Register value,
                              Address address,
                              OperandSize size = kWordBytes) override {
    Load(TMP2, address, size);
    CompareRegisters(value, TMP2);
  }
  void AndImmediate(Register reg,
                    target::word imm,
                    OperandSize sz = kWordBytes) override {
    AndImmediate(reg, reg, imm, sz);
  }
  void AndImmediate(Register dst,
                    Register src,
                    target::word imm,
                    OperandSize sz = kWordBytes) override {
    USE(sz);
    if (Utils::IsUint(12, imm)) {
      andi(dst, src, imm);
    } else {
      LoadImmediate(TMP2, imm);
      and_(dst, src, TMP2);
    }
  }
  void LsrImmediate(Register dst, int32_t shift) override {
    srli_d(dst, dst, shift);
  }
  void MulImmediate(Register dst,
                    target::word imm,
                    OperandSize sz = kWordBytes) override {
    USE(sz);
    if (Utils::IsPowerOfTwo(imm)) {
      slli_d(dst, dst, Utils::ShiftForPowerOfTwo(imm));
    } else {
      LoadImmediate(TMP2, imm);
      mul_d(dst, dst, TMP2);
    }
  }
  void AndRegisters(Register dst,
                    Register src1,
                    Register src2 = kNoRegister) override {
    and_(dst, src1, src2 == kNoRegister ? dst : src2);
  }
  void LslRegister(Register dst, Register shift) override { sll_d(dst, dst, shift); }
  void ExtractBitField(Register dst,
                       Register src,
                       intptr_t low_bit,
                       intptr_t width) override {
    srli_d(dst, src, low_bit);
    if (width < XLEN) {
      AndImmediate(dst, dst, (static_cast<uint64_t>(1) << width) - 1);
    }
  }
  void CombineHashes(Register dst, Register other) override {
    AddImmediate(dst, dst, 0x1fffffff);
    add_d(dst, dst, other);
    AndImmediate(dst, dst, 0x1fffffff);
  }
  void FinalizeHashForSize(intptr_t bit_size,
                           Register hash,
                           Register scratch = TMP) override {
    USE(bit_size);
    USE(hash);
    USE(scratch);
  }
  void EnsureHasClassIdInDEBUG(intptr_t cid,
                               Register src,
                               Register scratch,
                               bool can_be_null = false) override {
  }
  void RangeCheck(Register value,
                  Register temp,
                  intptr_t low,
                  intptr_t high,
                  RangeCheckCondition condition,
                  Label* target) override {
    const Condition branch_condition = condition == kIfInRange ? LS : HI;
    Register to_check = temp != kNoRegister ? temp : value;
    AddImmediate(to_check, value, -low);
    CompareImmediate(to_check, high - low);
    BranchIf(branch_condition, target);
  }
  void StoreBarrier(Register object,
                    Register value,
                    CanBeSmi can_be_smi,
                    Register scratch) override {
    ASSERT(object != value);
    ASSERT(object != scratch);
    ASSERT(value != scratch);
    ASSERT(object != RA);
    ASSERT(value != RA);
    ASSERT(scratch != RA);
    ASSERT(object != TMP2);
    ASSERT(value != TMP2);
    ASSERT(scratch != TMP2);
    ASSERT(scratch != kNoRegister);

    Label done;
    if (can_be_smi == kValueCanBeSmi) {
      BranchIfSmi(value, &done, kNearJump);
    } else {
#if defined(DEBUG)
      Label passed_check;
      BranchIfNotSmi(value, &passed_check, kNearJump);
      Breakpoint();
      Bind(&passed_check);
#endif
    }

    Load(scratch, FieldAddress(object, target::Object::tags_offset()),
         kUnsignedByte);
    Load(TMP2, FieldAddress(value, target::Object::tags_offset()),
         kUnsignedByte);
    srli_d(scratch, scratch, target::UntaggedObject::kBarrierOverlapShift);
    and_(scratch, scratch, TMP2);
    bge(WRITE_BARRIER_STATE, scratch, &done, kNearJump);

    Register object_for_call = object;
    if (value != kWriteBarrierValueReg) {
      if (object != kWriteBarrierValueReg) {
        PushRegister(kWriteBarrierValueReg);
      } else {
        COMPILE_ASSERT(S4 != kWriteBarrierValueReg);
        COMPILE_ASSERT(S5 != kWriteBarrierValueReg);
        object_for_call = (value == S4) ? S5 : S4;
        PushRegisterPair(kWriteBarrierValueReg, object_for_call);
        MoveRegister(object_for_call, object);
      }
      MoveRegister(kWriteBarrierValueReg, value);
    }

    Load(TMP, Address(THR, target::Thread::write_barrier_wrappers_thread_offset(
                               object_for_call)));
    jirl(TMP, TMP, 0);

    if (value != kWriteBarrierValueReg) {
      if (object != kWriteBarrierValueReg) {
        PopRegister(kWriteBarrierValueReg);
      } else {
        PopRegisterPair(kWriteBarrierValueReg, object_for_call);
      }
    }
    Bind(&done);
  }
  void ArrayStoreBarrier(Register object,
                         Register slot,
                         Register value,
                         CanBeSmi can_be_smi,
                         Register scratch) override {
    const bool spill_lr = true;
    ASSERT(object != slot);
    ASSERT(object != value);
    ASSERT(object != scratch);
    ASSERT(slot != value);
    ASSERT(slot != scratch);
    ASSERT(value != scratch);
    ASSERT(object != RA);
    ASSERT(slot != RA);
    ASSERT(value != RA);
    ASSERT(scratch != RA);
    ASSERT(object != TMP2);
    ASSERT(slot != TMP2);
    ASSERT(value != TMP2);
    ASSERT(scratch != TMP2);
    ASSERT(scratch != kNoRegister);

    Label done;
    if (can_be_smi == kValueCanBeSmi) {
      BranchIfSmi(value, &done, kNearJump);
    } else {
#if defined(DEBUG)
      Label passed_check;
      BranchIfNotSmi(value, &passed_check, kNearJump);
      Breakpoint();
      Bind(&passed_check);
#endif
    }

    Load(scratch, FieldAddress(object, target::Object::tags_offset()),
         kUnsignedByte);
    Load(TMP2, FieldAddress(value, target::Object::tags_offset()),
         kUnsignedByte);
    srli_d(scratch, scratch, target::UntaggedObject::kBarrierOverlapShift);
    and_(scratch, scratch, TMP2);
    bge(WRITE_BARRIER_STATE, scratch, &done, kNearJump);

    if (spill_lr) {
      PushRegister(RA);
    }
    if ((object != kWriteBarrierObjectReg) ||
        (value != kWriteBarrierValueReg) || (slot != kWriteBarrierSlotReg)) {
      PushRegister(object);
      PushRegister(slot);
      PushRegister(value);
      PopRegister(kWriteBarrierValueReg);
      PopRegister(kWriteBarrierSlotReg);
      PopRegister(kWriteBarrierObjectReg);
    }
    Call(Address(THR, target::Thread::array_write_barrier_entry_point_offset()));
    if (spill_lr) {
      PopRegister(RA);
    }
    Bind(&done);
  }
  void VerifyStoreNeedsNoWriteBarrier(Register object,
                                      Register value) override {
    if (value == ZR) return;
    Label done;
    BranchIfSmi(value, &done, kNearJump);
    Load(TMP2, FieldAddress(value, target::Object::tags_offset()),
         kUnsignedByte);
    andi(TMP2, TMP2, 1 << target::UntaggedObject::kNewOrEvacuationCandidateBit);
    beqz(TMP2, &done, kNearJump);
    Load(TMP2, FieldAddress(object, target::Object::tags_offset()),
         kUnsignedByte);
    andi(TMP2, TMP2, 1 << target::UntaggedObject::kOldAndNotRememberedBit);
    beqz(TMP2, &done, kNearJump);
    Stop("Write barrier is required");
    Bind(&done);
  }

  void PushRegister(Register reg) {
    AddImmediate(SP, SP, -target::kWordSize);
    Store(reg, Address(SP));
  }
  void PopRegister(Register reg) {
    Load(reg, Address(SP));
    AddImmediate(SP, SP, target::kWordSize);
  }
  void PushRegisterPair(Register r0, Register r1) {
    AddImmediate(SP, SP, -2 * target::kWordSize);
    Store(r0, Address(SP, 0));
    Store(r1, Address(SP, target::kWordSize));
  }
  void PopRegisterPair(Register r0, Register r1) {
    Load(r0, Address(SP, 0));
    Load(r1, Address(SP, target::kWordSize));
    AddImmediate(SP, SP, 2 * target::kWordSize);
  }
  void PushRegisters(const RegisterSet& registers);
  void PopRegisters(const RegisterSet& registers);
  void PushRegistersAligned(const RegisterSet& registers, intptr_t space);
  void PopRegistersAligned(const RegisterSet& registers, intptr_t space);
  void PushRegistersInOrder(std::initializer_list<Register> regs) {
    for (Register reg : regs) {
      PushRegister(reg);
    }
  }
  void PushValueAtOffset(Register base, int32_t offset) {
    Load(TMP, Address(base, offset));
    PushRegister(TMP);
  }
  void PushNativeCalleeSavedRegisters() {
    const intptr_t size = kAbiPreservedCpuRegCount * target::kWordSize +
                          kAbiPreservedFpuRegCount * sizeof(double);
    AddImmediate(SP, SP, -size);
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
      const RegList bit = static_cast<RegList>(1) << i;
      const FpuRegister reg = static_cast<FpuRegister>(i);
      if ((kAbiPreservedFpuRegs & bit) != 0) {
        StoreD(reg, Address(SP, offset));
        offset += sizeof(double);
      }
    }
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
      const RegList bit = static_cast<RegList>(1) << i;
      const Register reg = static_cast<Register>(i);
      if ((kAbiPreservedCpuRegs & bit) != 0) {
        Store(reg, Address(SP, offset));
        offset += target::kWordSize;
      }
    }
    ASSERT(offset == size);
  }
  void PopNativeCalleeSavedRegisters() {
    const intptr_t size = kAbiPreservedCpuRegCount * target::kWordSize +
                          kAbiPreservedFpuRegCount * sizeof(double);
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
      const RegList bit = static_cast<RegList>(1) << i;
      const FpuRegister reg = static_cast<FpuRegister>(i);
      if ((kAbiPreservedFpuRegs & bit) != 0) {
        LoadD(reg, Address(SP, offset));
        offset += sizeof(double);
      }
    }
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
      const RegList bit = static_cast<RegList>(1) << i;
      const Register reg = static_cast<Register>(i);
      if ((kAbiPreservedCpuRegs & bit) != 0) {
        Load(reg, Address(SP, offset));
        offset += target::kWordSize;
      }
    }
    ASSERT(offset == size);
    AddImmediate(SP, SP, size);
  }

  void Drop(intptr_t stack_elements) {
    if (stack_elements > 0) {
      AddImmediate(SP, SP, stack_elements * target::kWordSize);
    }
  }
  void Jump(Label* label, JumpDistance distance = kFarJump) { b(label, distance); }
  void Jump(Register target) { jr(target); }
  void Jump(const Address& address) {
    Load(TMP, address);
    Jump(TMP);
  }

  void LoadMemoryValue(Register dst, Register base, int32_t offset) {
    Load(dst, Address(base, offset));
  }
  void StoreMemoryValue(Register src, Register base, int32_t offset) {
    Store(src, Address(base, offset));
  }

  void TsanLoadAcquire(Register dst, const Address& address, OperandSize size) {
  }
  void TsanStoreRelease(Register src, const Address& address, OperandSize size) {
  }
  void TsanFuncEntry(bool preserve_registers = true) {  }
  void TsanFuncExit(bool preserve_registers = true) {  }

  void SetPrologueOffset() {
    if (prologue_offset_ == -1) {
      prologue_offset_ = CodeSize();
    }
  }
  void ReserveAlignedFrameSpace(intptr_t frame_space) {
    ASSERT(Utils::IsAligned(frame_space, target::kWordSize));
    if (frame_space != 0) {
      AddImmediate(SP, SP, -frame_space);
    }
    const intptr_t kAbiStackAlignment = 16;
    AndImmediate(SP, SP, ~(kAbiStackAlignment - 1));
    ASSERT(Utils::IsAligned(CodeSize(), 4));
  }
  void EmitEntryFrameVerification() {  }

  static constexpr intptr_t kEntryPointToPcMarkerOffset = 0;
  static intptr_t EntryPointToPcMarkerOffset() {
    return kEntryPointToPcMarkerOffset;
  }

  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return target::IsSmi(object); }

  void CompareRegisters(Register rn, Register rm) {
    compare_left_ = rn;
    compare_right_ = rm;
  }
  void CompareObjectRegisters(Register rn, Register rm) { CompareRegisters(rn, rm); }
  void TestRegisters(Register rn, Register rm) {
    and_(TMP, rn, rm);
    CompareRegisters(TMP, ZR);
  }
  void BranchIf(Condition condition,
                Label* label,
                JumpDistance distance = kFarJump) {
    ASSERT(compare_left_ != kNoRegister);
    BranchOnCondition(condition, compare_left_, compare_right_, label, distance);
  }
  void BranchIfZero(Register rn,
                    Label* label,
                    JumpDistance distance = kFarJump) {
    beq(rn, ZR, label, distance);
  }
  void BranchIfNotZero(Register rn,
                       Label* label,
                       JumpDistance distance = kFarJump) {
    bne(rn, ZR, label, distance);
  }
  void BranchIfBit(Register rn,
                   intptr_t bit_number,
                   Condition condition,
                   Label* label,
                   JumpDistance distance = kFarJump) {
    ASSERT((condition == ZERO) || (condition == NOT_ZERO));
    if (Utils::IsUint(12, static_cast<uint64_t>(1) << bit_number)) {
      andi(TMP, rn, static_cast<uint64_t>(1) << bit_number);
    } else {
      LoadImmediate(TMP2, static_cast<uint64_t>(1) << bit_number);
      and_(TMP, rn, TMP2);
    }
    if (condition == ZERO) {
      beq(TMP, ZR, label, distance);
    } else {
      bne(TMP, ZR, label, distance);
    }
  }
  void SetIf(Condition condition, Register rd) {
    Label is_false, done;
    BranchIf(InvertCondition(condition), &is_false);
    LoadImmediate(rd, 1);
    b(&done);
    Bind(&is_false);
    LoadImmediate(rd, 0);
    Bind(&done);
  }
  void ZeroIf(Condition condition, Register rd, Register rs) {
    Label keep, done;
    BranchIf(InvertCondition(condition), &keep);
    LoadImmediate(rd, 0);
    b(&done);
    Bind(&keep);
    MoveRegister(rd, rs);
    Bind(&done);
  }

  void SmiUntag(Register reg) { SmiUntag(reg, reg); }
  void SmiUntag(Register dst, Register src) { srai_d(dst, src, kSmiTagShift); }
  void SmiTag(Register dst, Register src) { slli_d(dst, src, kSmiTagShift); }
  void BranchIfNotSmi(Register reg,
                      Label* label,
                      JumpDistance distance = kFarJump) {
    ASSERT(reg != TMP2);
    AndImmediate(TMP2, reg, kSmiTagMask);
    bne(TMP2, ZR, label, distance);
  }

  void JumpAndLink(
      const Code& code,
      ObjectPoolBuilderEntry::Patchability patchable =
          ObjectPoolBuilderEntry::kNotPatchable,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
    const intptr_t index =
        object_pool_builder().FindObject(ToObject(code), patchable,
                                         snapshot_behavior);
    JumpAndLink(index, entry_kind);
  }
  void JumpAndLinkPatchable(
      const Code& code,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
    JumpAndLink(code, ObjectPoolBuilderEntry::kPatchable, entry_kind,
                snapshot_behavior);
  }
  void JumpAndLinkWithEquivalence(const Code& code,
                                  const Object& equivalence,
                                  CodeEntryKind entry_kind =
                                      CodeEntryKind::kNormal) {
    const intptr_t index =
        object_pool_builder().FindObject(ToObject(code), equivalence);
    JumpAndLink(index, entry_kind);
  }

  void JumpAndLink(intptr_t target_code_pool_index,
                   CodeEntryKind entry_kind = CodeEntryKind::kNormal) {
    const Register code_reg = FLAG_precompiled_mode ? TMP : CODE_REG;
    LoadWordFromPoolIndex(code_reg, target_code_pool_index);
    Call(FieldAddress(code_reg, target::Code::entry_point_offset(entry_kind)));
  }

  void Call(Address target) {
    Load(RA, target);
    Call(RA);
  }
  void Call(Register target) { jirl(RA, target, 0); }
  void Call(const Code& code) { JumpAndLink(code); }
  void CallCFunction(Address target) { Call(target); }
  void CallCFunction(Register target) { Call(target); }

  void AddRegisters(Register dst, Register src) { add_d(dst, dst, src); }
  void AddShifted(Register dst, Register base, Register index, intx_t shift) {
    if (shift == 0) {
      add_d(dst, base, index);
    } else if (shift < 0) {
      if (base != dst) {
        srai_d(dst, index, -shift);
        add_d(dst, dst, base);
      } else {
        srai_d(TMP2, index, -shift);
        add_d(dst, TMP2, base);
      }
    } else {
      if (base != dst) {
        slli_d(dst, index, shift);
        add_d(dst, dst, base);
      } else {
        slli_d(TMP2, index, shift);
        add_d(dst, TMP2, base);
      }
    }
  }
  void SubRegisters(Register dst, Register src) { sub_d(dst, dst, src); }
  void OrImmediate(Register rd,
                   Register rn,
                   intx_t imm,
                   OperandSize sz = kWordBytes) {
    USE(sz);
    if (imm == 0) {
      MoveRegister(rd, rn);
    } else if (Utils::IsUint(12, imm)) {
      ori(rd, rn, imm);
    } else {
      LoadImmediate(TMP2, imm);
      or_(rd, rn, TMP2);
    }
  }
  void OrImmediate(Register rd, intx_t imm) { OrImmediate(rd, rd, imm); }
  void XorImmediate(Register rd,
                    Register rn,
                    intx_t imm,
                    OperandSize sz = kWordBytes) {
    USE(sz);
    if (imm == 0) {
      MoveRegister(rd, rn);
    } else if (Utils::IsUint(12, imm)) {
      xori(rd, rn, imm);
    } else {
      LoadImmediate(TMP2, imm);
      xor_(rd, rn, TMP2);
    }
  }
  void TestImmediate(Register rn, intx_t imm, OperandSize sz = kWordBytes) {
    AndImmediate(TMP, rn, imm, sz);
    CompareRegisters(TMP, ZR);
  }

  void LoadS(FRegister dst, const Address& address) { fl_s(dst, PrepareAddress(address.base(), address.offset())); }
  void LoadD(FRegister dst, const Address& address) { fl_d(dst, PrepareAddress(address.base(), address.offset())); }
  void LoadQ(FRegister dst, const Address& address) { vld(dst, PrepareAddress(address.base(), address.offset())); }
  void LoadSFromOffset(FRegister dst, Register base, int32_t offset) {
    LoadS(dst, Address(base, offset));
  }
  void LoadDFromOffset(FRegister dst, Register base, int32_t offset) {
    LoadD(dst, Address(base, offset));
  }
  void LoadQFromOffset(FRegister dst, Register base, int32_t offset) {
    LoadQ(dst, Address(base, offset));
  }
  void LoadSFieldFromOffset(FRegister dst, Register base, int32_t offset) {
    LoadS(dst, FieldAddress(base, offset));
  }
  void LoadDFieldFromOffset(FRegister dst, Register base, int32_t offset) {
    LoadD(dst, FieldAddress(base, offset));
  }
  void LoadQFieldFromOffset(FRegister dst, Register base, int32_t offset) {
    LoadQ(dst, FieldAddress(base, offset));
  }
  void LoadFromStack(Register dst, intptr_t depth) {
    Load(dst, Address(SP, depth * target::kWordSize));
  }
  void StoreToStack(Register src, intptr_t depth) {
    Store(src, Address(SP, depth * target::kWordSize));
  }
  void CompareToStack(Register src, intptr_t depth) {  }

  void StoreZero(const Address& address, Register temp = kNoRegister) {
    USE(temp);
    Store(ZR, address);
  }
  void StoreS(FRegister src, const Address& address) { fs_s(src, PrepareAddress(address.base(), address.offset())); }
  void StoreD(FRegister src, const Address& address) { fs_d(src, PrepareAddress(address.base(), address.offset())); }
  void StoreQ(FRegister src, const Address& address) { vst(src, PrepareAddress(address.base(), address.offset())); }
  void StoreSToOffset(FRegister src, Register base, int32_t offset) {
    StoreS(src, Address(base, offset));
  }
  void StoreSFieldToOffset(FRegister src, Register base, int32_t offset) {
    StoreS(src, FieldAddress(base, offset));
  }
  void StoreDToOffset(FRegister src, Register base, int32_t offset) {
    StoreD(src, Address(base, offset));
  }
  void StoreDFieldToOffset(FRegister src, Register base, int32_t offset) {
    StoreD(src, FieldAddress(base, offset));
  }
  void StoreQToOffset(FRegister src, Register base, int32_t offset) {
    StoreQ(src, Address(base, offset));
  }
  void StoreQFieldToOffset(FRegister src, Register base, int32_t offset) {
    StoreQ(src, FieldAddress(base, offset));
  }

  void LoadUnboxedDouble(FpuRegister dst, Register base, int32_t offset) {
    LoadDFromOffset(dst, base, offset);
  }
  void StoreUnboxedDouble(FpuRegister src, Register base, int32_t offset) {
    StoreDToOffset(src, base, offset);
  }
  void MoveUnboxedDouble(FpuRegister dst, FpuRegister src) {
    if (dst != src) {
      fmov_d(dst, src);
    }
  }
  void LoadUnboxedSimd128(FpuRegister dst, Register base, int32_t offset) {
    LoadQFromOffset(dst, base, offset);
  }
  void StoreUnboxedSimd128(FpuRegister src, Register base, int32_t offset) {
    StoreQToOffset(src, base, offset);
  }
  void MoveUnboxedSimd128(FpuRegister dst, FpuRegister src) {
    if (dst != src) {
      vor_v(dst, src, src);
    }
  }

  void InitializeHeader(Register tags, Register object) {
    Store(tags, FieldAddress(object, target::Object::tags_offset()));
#if defined(TARGET_HAS_FAST_WRITE_WRITE_FENCE)
    StoreStoreFence();
#endif
  }
  void InitializeHeaderUntagged(Register tags, Register object) {
    Store(tags, Address(object, target::Object::tags_offset()));
#if defined(TARGET_HAS_FAST_WRITE_WRITE_FENCE)
    StoreStoreFence();
#endif
  }
  void StoreInternalPointer(Register object,
                            const Address& dest,
                            Register value) {
    USE(object);
    Store(value, dest);
  }

  void LoadPoolPointer(Register pp = PP) {
    Load(pp, FieldAddress(CODE_REG, target::Code::object_pool_offset()));
    AddImmediate(pp, pp, -kHeapObjectTag);
    set_constant_pool_allowed(pp == PP);
  }
  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool value) { constant_pool_allowed_ = value; }
  bool CanLoadFromObjectPool(const Object& object) const {
    USE(object);
    return constant_pool_allowed();
  }
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       ObjectPoolBuilderEntry::Patchability patchable) {
    const intptr_t index =
        object_pool_builder().FindNativeFunction(label, patchable);
    LoadWordFromPoolIndex(dst, index);
  }
  void LoadIsolate(Register dst) {
    Load(dst, Address(THR, target::Thread::isolate_offset()));
  }
  void LoadIsolateGroup(Register dst) {
    Load(dst, Address(THR, target::Thread::isolate_group_offset()));
  }
  void LoadUniqueObject(
      Register dst,
      const Object& object,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
    LoadObject(dst, object, snapshot_behavior,
               ObjectPoolBuilderEntry::kPatchable);
  }

  void LoadSImmediate(FRegister reg, float imms) {
    const uint32_t imm = bit_cast<uint32_t, float>(imms);
    ASSERT(constant_pool_allowed());
    const intptr_t index = object_pool_builder().FindImmediate(imm);
    LoadSFromOffset(reg, PP, target::ObjectPool::element_offset(index));
  }
  void LoadDImmediate(FRegister reg, double immd) {
    const uint64_t imm = bit_cast<uint64_t, double>(immd);
    ASSERT(constant_pool_allowed());
    const intptr_t index = object_pool_builder().FindImmediate(imm);
    LoadDFromOffset(reg, PP, target::ObjectPool::element_offset(index));
  }
  void LoadQImmediate(FRegister reg, simd128_value_t immq) {
    ASSERT(constant_pool_allowed());
    const intptr_t index = object_pool_builder().FindImmediate128(immq);
    LoadQFromOffset(reg, PP, target::ObjectPool::element_offset(index));
  }
  void LoadWordFromPoolIndex(Register dst, intptr_t index, Register pp = PP) {
    ASSERT(dst != pp);
    const intptr_t offset = target::ObjectPool::element_offset(index);
    Load(dst, Address(pp, offset));
  }
  void StoreWordToPoolIndex(Register src, intptr_t index, Register pp = PP) {
    const intptr_t offset = target::ObjectPool::element_offset(index);
    Store(src, Address(pp, offset));
  }

  void PushObject(const Object& object) {
    LoadObject(TMP, object);
    PushRegister(TMP);
  }
  void PushImmediate(int64_t immediate) {
    LoadImmediate(TMP, immediate);
    PushRegister(TMP);
  }
  void CompareObject(Register reg, const Object& object) {
    LoadObject(TMP2, object);
    CompareRegisters(reg, TMP2);
  }

  void ExtractClassIdFromTags(Register result, Register tags) {
    ASSERT(target::UntaggedObject::kClassIdTagPos == 12);
    ASSERT(target::UntaggedObject::kClassIdTagSize == 20);
    srli_d(result, tags, target::UntaggedObject::kClassIdTagPos);
  }
  void ExtractInstanceSizeFromTags(Register result, Register tags) {
    ASSERT(target::UntaggedObject::kSizeTagPos == 8);
    ASSERT(target::UntaggedObject::kSizeTagSize == 4);
    srli_d(result, tags, target::UntaggedObject::kSizeTagPos);
    andi(result, result, (1 << target::UntaggedObject::kSizeTagSize) - 1);
    slli_d(result, result, target::ObjectAlignment::kObjectAlignmentLog2);
  }
  void LoadClassId(Register result, Register object) {
    Load(result, FieldAddress(object, target::Object::tags_offset()),
         kUnsignedFourBytes);
    ExtractClassIdFromTags(result, result);
  }
  void LoadClassById(Register result, Register class_id) {
    ASSERT(result != class_id);
    const intptr_t table_offset =
        target::IsolateGroup::cached_class_table_table_offset();
    LoadIsolateGroup(result);
    LoadFromOffset(result, result, table_offset);
    AddShifted(result, result, class_id, target::kWordSizeLog2);
    lx(result, Address(result, 0));
  }
  void CompareClassId(Register object,
                      intptr_t class_id,
                      Register scratch = kNoRegister) {
    if (scratch == kNoRegister) {
      scratch = TMP;
    }
    LoadClassId(scratch, object);
    CompareImmediate(scratch, class_id);
  }
  void LoadClassIdMayBeSmi(Register result, Register object) {
    ASSERT(result != object);
    ASSERT(result != TMP2);
    ASSERT(object != TMP2);
    LoadImmediate(result, kSmiCid);
    Label done;
    BranchIfSmi(object, &done, kNearJump);
    LoadClassId(result, object);
    Bind(&done);
  }
  void LoadTaggedClassIdMayBeSmi(Register result, Register object) {
    LoadClassIdMayBeSmi(result, object);
    SmiTag(result);
  }

  void AddImmediate(Register rd, target::word imm) { AddImmediate(rd, rd, imm); }
  void AddImmediate(Register rd, Register rn, target::word imm) {
    if ((imm == 0) && (rd == rn)) {
      return;
    }
    if (Utils::IsInt(12, imm)) {
      addi_d(rd, rn, imm);
    } else {
      LoadImmediate(TMP2, imm);
      add_d(rd, rn, TMP2);
    }
  }
  void LoadObject(
      Register dst,
      const Object& object,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable,
      ObjectPoolBuilderEntry::Patchability patchable =
          ObjectPoolBuilderEntry::kNotPatchable) {
    if (patchable == ObjectPoolBuilderEntry::kNotPatchable) {
      if (IsSameObject(compiler::NullObject(), object)) {
        MoveRegister(dst, NULL_REG);
        return;
      }
      if (IsSameObject(CastHandle<Object>(compiler::TrueObject()), object)) {
        AddImmediate(dst, NULL_REG, kTrueOffsetFromNull);
        return;
      }
      if (IsSameObject(CastHandle<Object>(compiler::FalseObject()), object)) {
        AddImmediate(dst, NULL_REG, kFalseOffsetFromNull);
        return;
      }
      word offset = 0;
      if (target::CanLoadFromThread(object, &offset)) {
        Load(dst, Address(THR, offset));
        return;
      }
      if (target::IsSmi(object)) {
        LoadImmediate(dst, target::ToRawSmi(object));
        return;
      }
    }
    RELEASE_ASSERT(CanLoadFromObjectPool(object));
    const intptr_t index =
        object_pool_builder().FindObject(object, patchable, snapshot_behavior);
    LoadWordFromPoolIndex(dst, index);
  }
  void Ret() { ret(); }

  void EnterFrame(intptr_t frame_size) {
    AddImmediate(SP, SP, -(frame_size + 2 * target::kWordSize));
    Store(RA, Address(SP, frame_size + target::kWordSize));
    Store(FP, Address(SP, frame_size));
    AddImmediate(FP, SP, frame_size + 2 * target::kWordSize);
  }
  void LeaveFrame() {
    AddImmediate(SP, FP, -2 * target::kWordSize);
    Load(RA, Address(SP, target::kWordSize));
    Load(FP, Address(SP));
    AddImmediate(SP, SP, 2 * target::kWordSize);
  }
  void SetReturnAddress(Register value) { MoveRegister(RA, value); }

  void TransitionGeneratedToNative(Register destination_address,
                                   Register new_exit_frame,
                                   Register new_exit_through_ffi,
                                   bool enter_safepoint) {
    Store(new_exit_frame,
          Address(THR, target::Thread::top_exit_frame_info_offset()));
    Store(new_exit_through_ffi,
          Address(THR, target::Thread::exit_through_ffi_offset()));
    Register tmp = new_exit_through_ffi;

#if defined(DEBUG)
    ASSERT(S8 != TMP2);
    MoveRegister(S8, TMP2);
    VerifyInGenerated(tmp);
    MoveRegister(TMP2, S8);
#endif

    Store(destination_address,
          Address(THR, target::Thread::vm_tag_offset()));
    LoadImmediate(tmp, target::Thread::native_execution_state());
    Store(tmp, Address(THR, target::Thread::execution_state_offset()));

    if (enter_safepoint) {
      EnterFullSafepoint(tmp);
    }
  }
  void TransitionNativeToGenerated(Register scratch,
                                   bool exit_safepoint,
                                   bool set_tag = true) {
    if (exit_safepoint) {
      ExitFullSafepoint(scratch);
    } else {
#if defined(DEBUG)
      ASSERT(target::Thread::native_safepoint_state_acquired() != 0);
      LoadImmediate(scratch, target::Thread::native_safepoint_state_acquired());
      Load(RA, Address(THR, target::Thread::safepoint_state_offset()));
      and_(RA, RA, scratch);
      Label ok;
      beq(RA, ZR, &ok, Assembler::kNearJump);
      Breakpoint();
      Bind(&ok);
#endif
    }

    VerifyNotInGenerated(scratch);
    if (set_tag) {
      LoadImmediate(scratch, target::Thread::vm_tag_dart_id());
      Store(scratch, Address(THR, target::Thread::vm_tag_offset()));
    }
    LoadImmediate(scratch, target::Thread::generated_execution_state());
    Store(scratch, Address(THR, target::Thread::execution_state_offset()));

    Store(ZR, Address(THR, target::Thread::top_exit_frame_info_offset()));
    Store(ZR, Address(THR, target::Thread::exit_through_ffi_offset()));
  }
  void VerifyInGenerated(Register scratch) {
#if defined(DEBUG)
    Load(scratch, Address(THR, target::Thread::execution_state_offset()));
    Label ok;
    CompareImmediate(scratch, target::Thread::generated_execution_state());
    BranchIf(EQ, &ok, Assembler::kNearJump);
    Breakpoint();
    Bind(&ok);
#endif
  }
  void VerifyNotInGenerated(Register scratch) {
#if defined(DEBUG)
    Load(scratch, Address(THR, target::Thread::execution_state_offset()));
    Label ok;
    CompareImmediate(scratch, target::Thread::generated_execution_state());
    BranchIf(NE, &ok, Assembler::kNearJump);
    Breakpoint();
    Bind(&ok);
#endif
  }
  void EnterFullSafepoint(Register state) {
    Register addr = RA;
    ASSERT(addr != state);

    Label slow_path, done, retry;
    if (FLAG_use_slow_path || FLAG_target_thread_sanitizer) {
      j(&slow_path, Assembler::kNearJump);
    }

    AddImmediate(addr, THR, target::Thread::safepoint_state_offset());
    Bind(&retry);
    ll_d(state, Address(addr, 0));
    AddImmediate(state, state,
                 -target::Thread::native_safepoint_state_unacquired());
    bne(state, ZR, &slow_path, Assembler::kNearJump);

    LoadImmediate(state, target::Thread::native_safepoint_state_acquired());
    sc_d(state, Address(addr, 0));
    bne(state, ZR, &done, Assembler::kNearJump);

    if (!FLAG_use_slow_path && !FLAG_target_thread_sanitizer) {
      j(&retry, Assembler::kNearJump);
    }

    Bind(&slow_path);
    Load(addr, Address(THR, target::Thread::enter_safepoint_stub_offset()));
    Load(addr, FieldAddress(addr, target::Code::entry_point_offset()));
    Call(addr);

    Bind(&done);
  }
  void ExitFullSafepoint(Register state) {
    Register addr = RA;
    ASSERT(addr != state);

    Label slow_path, done, retry;
    if (FLAG_use_slow_path || FLAG_target_thread_sanitizer) {
      j(&slow_path, Assembler::kNearJump);
    }

    AddImmediate(addr, THR, target::Thread::safepoint_state_offset());
    Bind(&retry);
    ll_d(state, Address(addr, 0));
    AddImmediate(state, state,
                 -target::Thread::native_safepoint_state_acquired());
    bne(state, ZR, &slow_path, Assembler::kNearJump);

    LoadImmediate(state, target::Thread::native_safepoint_state_unacquired());
    sc_d(state, Address(addr, 0));
    bne(state, ZR, &done, Assembler::kNearJump);

    if (!FLAG_use_slow_path && !FLAG_target_thread_sanitizer) {
      j(&retry, Assembler::kNearJump);
    }

    Bind(&slow_path);
    Load(addr, Address(THR, target::Thread::exit_safepoint_stub_offset()));
    Load(addr, FieldAddress(addr, target::Code::entry_point_offset()));
    Call(addr);

    Bind(&done);
  }

  void CheckFpSpDist(intptr_t fp_sp_dist) { USE(fp_sp_dist); }
  void CheckCodePointer() {  }
  void RestoreCodePointer() {
    Load(CODE_REG,
         Address(FP, target::frame_layout.code_from_fp * target::kWordSize));
  }
  void RestorePoolPointer() {
    if (FLAG_precompiled_mode) {
      Load(PP, Address(THR, target::Thread::global_object_pool_offset()));
    } else {
      Load(PP, Address(FP, target::frame_layout.code_from_fp * target::kWordSize));
      Load(PP, FieldAddress(PP, target::Code::object_pool_offset()));
    }
    AddImmediate(PP, PP, -kHeapObjectTag);
  }
  void RestorePinnedRegisters() {
    Load(WRITE_BARRIER_STATE,
         Address(THR, target::Thread::write_barrier_mask_offset()));
    xori(WRITE_BARRIER_STATE, WRITE_BARRIER_STATE,
         (target::UntaggedObject::kGenerationalBarrierMask << 1) - 1);
    Load(NULL_REG, Address(THR, target::Thread::object_null_offset()));
  }
  void SetupGlobalPoolAndDispatchTable() {
    ASSERT(FLAG_precompiled_mode);
    Load(PP, Address(THR, target::Thread::global_object_pool_offset()));
    AddImmediate(PP, PP, -kHeapObjectTag);
    Load(DISPATCH_TABLE_REG,
         Address(THR, target::Thread::dispatch_table_array_offset()));
  }

  void EnterDartFrame(intptr_t frame_size, Register new_pp = kNoRegister) {
    ASSERT(!constant_pool_allowed());
    if (FLAG_precompiled_mode) {
      AddImmediate(SP, SP, -(frame_size + 2 * target::kWordSize));
      Store(RA, Address(SP, frame_size + target::kWordSize));
      Store(FP, Address(SP, frame_size));
      AddImmediate(FP, SP, frame_size + 2 * target::kWordSize);
    } else {
      AddImmediate(SP, SP, -(frame_size + 4 * target::kWordSize));
      Store(RA, Address(SP, frame_size + 3 * target::kWordSize));
      Store(FP, Address(SP, frame_size + 2 * target::kWordSize));
      Store(CODE_REG, Address(SP, frame_size + target::kWordSize));
      AddImmediate(PP, PP, kHeapObjectTag);
      Store(PP, Address(SP, frame_size));
      AddImmediate(FP, SP, frame_size + 4 * target::kWordSize);
      if (new_pp == kNoRegister) {
        LoadPoolPointer();
      } else {
        MoveRegister(PP, new_pp);
      }
    }
    set_constant_pool_allowed(true);
  }
  void EnterOsrFrame(intptr_t extra_size, Register new_pp = kNoRegister) {
    USE(new_pp);
    RestoreCodePointer();
    LoadPoolPointer();
    if (extra_size > 0) {
      AddImmediate(SP, SP, -extra_size);
    }
  }
  void LeaveDartFrame() {
    if (!FLAG_precompiled_mode) {
      Load(PP, Address(FP, target::frame_layout.saved_caller_pp_from_fp *
                               target::kWordSize));
      AddImmediate(PP, PP, -kHeapObjectTag);
    }
    set_constant_pool_allowed(false);
    AddImmediate(SP, FP, -2 * target::kWordSize);
    Load(RA, Address(SP, target::kWordSize));
    Load(FP, Address(SP));
    AddImmediate(SP, SP, 2 * target::kWordSize);
  }
  void LeaveDartFrame(intptr_t fp_sp_dist) {
    const intptr_t pp_offset =
        target::frame_layout.saved_caller_pp_from_fp * target::kWordSize -
        fp_sp_dist;
    const intptr_t fp_offset =
        target::frame_layout.saved_caller_fp_from_fp * target::kWordSize -
        fp_sp_dist;
    const intptr_t ra_offset =
        target::frame_layout.saved_caller_pc_from_fp * target::kWordSize -
        fp_sp_dist;
    if (!FLAG_precompiled_mode) {
      Load(PP, Address(SP, pp_offset));
      AddImmediate(PP, PP, -kHeapObjectTag);
    }
    set_constant_pool_allowed(false);
    Load(RA, Address(SP, ra_offset));
    Load(FP, Address(SP, fp_offset));
    AddImmediate(SP, SP, -fp_sp_dist);
  }
  void CallRuntime(const RuntimeEntry& entry,
                   intptr_t argument_count,
                   bool tsan_enter_exit = true) {
    USE(tsan_enter_exit);
    Load(T5, Address(THR, entry.OffsetFromThread()));
    LoadImmediate(T4, argument_count);
    Call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
  }
  void EnterStubFrame() { EnterDartFrame(0); }
  void LeaveStubFrame() { LeaveDartFrame(); }
  void EnterCFrame(intptr_t frame_space) {
    COMPILE_ASSERT(IsCalleeSavedRegister(THR));
    COMPILE_ASSERT(IsCalleeSavedRegister(NULL_REG));
    COMPILE_ASSERT(IsCalleeSavedRegister(WRITE_BARRIER_STATE));
    COMPILE_ASSERT(IsCalleeSavedRegister(DISPATCH_TABLE_REG));
    COMPILE_ASSERT(!IsCalleeSavedRegister(PP));

    AddImmediate(SP, SP, -(frame_space + 3 * target::kWordSize));
    Store(RA, Address(SP, frame_space + 2 * target::kWordSize));
    Store(FP, Address(SP, frame_space + 1 * target::kWordSize));
    Store(PP, Address(SP, frame_space + 0 * target::kWordSize));
    AddImmediate(FP, SP, frame_space + 3 * target::kWordSize);
    const intptr_t kAbiStackAlignment = 16;
    AndImmediate(SP, SP, ~(kAbiStackAlignment - 1));
  }
  void LeaveCFrame() {
    AddImmediate(SP, FP, -3 * target::kWordSize);
    Load(PP, Address(SP, 0 * target::kWordSize));
    Load(FP, Address(SP, 1 * target::kWordSize));
    Load(RA, Address(SP, 2 * target::kWordSize));
    AddImmediate(SP, SP, 3 * target::kWordSize);
  }

  void MonomorphicCheckedEntryJIT() {
    has_monomorphic_entry_ = true;
    const intptr_t start = CodeSize();

    Label miss;
    Bind(&miss);
    Load(TMP, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
    jr(TMP);

    ASSERT_EQUAL(CodeSize() - start,
                 target::Instructions::kMonomorphicEntryOffsetJIT);

    const Register entries_reg = IC_DATA_REG;
    const intptr_t cid_offset = target::Array::element_offset(0);
    const intptr_t count_offset = target::Array::element_offset(1);
    ASSERT(A1 != PP);
    ASSERT(A1 != entries_reg);
    ASSERT(A1 != CODE_REG);

    Load(TMP, FieldAddress(entries_reg, cid_offset));
    LoadTaggedClassIdMayBeSmi(A1, A0);
    bne(TMP, A1, &miss, kNearJump);

    Load(TMP, FieldAddress(entries_reg, count_offset));
    AddImmediate(TMP, TMP, target::ToRawSmi(1));
    Store(TMP, FieldAddress(entries_reg, count_offset));
    LoadImmediate(ARGS_DESC_REG, 0);

    ASSERT_EQUAL(CodeSize() - start,
                 target::Instructions::kPolymorphicEntryOffsetJIT);
  }

  void MonomorphicCheckedEntryAOT() {
    has_monomorphic_entry_ = true;
    const intptr_t start = CodeSize();

    Label miss;
    Bind(&miss);
    Load(TMP, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
    jr(TMP);

    ASSERT_EQUAL(CodeSize() - start,
                 target::Instructions::kMonomorphicEntryOffsetAOT);
    LoadClassId(TMP, A0);
    SmiTag(TMP);
    bne(IC_DATA_REG, TMP, &miss, kNearJump);

    ASSERT_EQUAL(CodeSize() - start,
                 target::Instructions::kPolymorphicEntryOffsetAOT);
  }

  void BranchOnMonomorphicCheckedEntryJIT(Label* label) {
    has_monomorphic_entry_ = true;
    while (CodeSize() < target::Instructions::kMonomorphicEntryOffsetJIT) {
      Breakpoint();
    }
    j(label);
    while (CodeSize() < target::Instructions::kPolymorphicEntryOffsetJIT) {
      Breakpoint();
    }
  }

  void MaybeTraceAllocation(intptr_t cid,
                            Label* trace,
                            Register temp_reg,
                            JumpDistance distance = kFarJump) {
  }
  void MaybeTraceAllocation(Register cid,
                            Label* trace,
                            Register temp_reg,
                            JumpDistance distance = kFarJump) {
  }
  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        Register instance,
                        Register end_address,
                        Register temp1,
                        Register temp2) {
    if (FLAG_inline_alloc &&
        target::Heap::IsAllocatableInNewSpace(instance_size)) {
      NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp1));

      Load(instance, Address(THR, target::Thread::top_offset()));
      AddImmediate(end_address, instance, instance_size);
      bltu(end_address, instance, failure);

      Load(temp2, Address(THR, target::Thread::end_offset()));
      bgeu(end_address, temp2, failure);
      CheckAllocationCanary(instance, temp2);

      Store(end_address, Address(THR, target::Thread::top_offset()));
      AddImmediate(instance, instance, kHeapObjectTag);

      const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
      LoadImmediate(temp2, tags);
      InitializeHeader(temp2, instance);
    } else {
      j(failure);
    }
  }
  void CheckAllocationCanary(Register top, Register tmp = TMP) {
  }
  void WriteAllocationCanary(Register top) {  }
  void CopyMemoryWords(Register src, Register dst, Register size, Register temp) {
    Label loop, done;
    beqz(size, &done, kNearJump);
    Bind(&loop);
    Load(temp, Address(src));
    AddImmediate(src, src, target::kWordSize);
    Store(temp, Address(dst));
    AddImmediate(dst, dst, target::kWordSize);
    AddImmediate(size, size, -target::kWordSize);
    bnez(size, &loop, kNearJump);
    Bind(&done);
  }

  void GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target = 0) {
    bl(offset_into_target);
  }
  void GenerateUnRelocatedPcRelativeTailCall(intptr_t offset_into_target = 0) {
    b(offset_into_target);
  }

  static bool AddressCanHoldConstantIndex(const Object& constant,
                                          bool is_external,
                                          intptr_t cid,
                                          intptr_t index_scale) {
    if (!IsSafeSmi(constant)) return false;
    const int64_t index = target::SmiValue(constant);
    const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
    return Utils::IsInt(32, offset);
  }
  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const {
    const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
    ASSERT(Utils::IsInt(32, offset));
    return Address(array, static_cast<int32_t>(offset));
  }
  void ComputeElementAddressForIntIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        Register array,
                                        intptr_t index) {
    const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
    AddImmediate(address, array, offset);
  }
  Address ElementAddressForRegIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    bool index_unboxed,
                                    Register array,
                                    Register index,
                                    Register temp) {
    const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
    const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
    const int32_t offset = HeapDataOffset(is_external, cid);
    ASSERT(array != temp);
    ASSERT(index != temp);
    AddShifted(temp, array, index, shift);
    return Address(temp, offset);
  }
  void ComputeElementAddressForRegIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        bool index_unboxed,
                                        Register array,
                                        Register index) {
    const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
    const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
    const int32_t offset = HeapDataOffset(is_external, cid);
    ASSERT(array != address);
    ASSERT(index != address);
    AddShifted(address, array, index, shift);
    if (offset != 0) {
      AddImmediate(address, address, offset);
    }
  }
  void LoadStaticFieldAddress(Register address,
                              Register field,
                              Register scratch,
                              bool is_shared) {
    LoadCompressedSmiFieldFromOffset(
        scratch, field, target::Field::host_offset_or_field_id_offset());
    const intptr_t field_table_offset =
        is_shared ? compiler::target::Thread::shared_field_table_values_offset()
                  : compiler::target::Thread::field_table_values_offset();
    LoadMemoryValue(address, THR, static_cast<int32_t>(field_table_offset));
    slli_d(scratch, scratch, target::kWordSizeLog2 - kSmiTagShift);
    add_d(address, address, scratch);
  }

  static int32_t HeapDataOffset(bool is_external, intptr_t cid) {
    return is_external ? 0 : (target::Instance::DataOffsetFor(cid) -
                             kHeapObjectTag);
  }

  void AddImmediateBranchOverflow(Register rd,
                                  Register rs1,
                                  intx_t imm,
                                  Label* overflow) {
    ASSERT(rd != TMP2);
    if (rd == rs1) {
      mv(TMP2, rs1);
      AddImmediate(rd, rs1, imm);
      if (imm > 0) {
        blt(rd, TMP2, overflow);
      } else if (imm < 0) {
        blt(TMP2, rd, overflow);
      }
    } else {
      AddImmediate(rd, rs1, imm);
      if (imm > 0) {
        blt(rd, rs1, overflow);
      } else if (imm < 0) {
        blt(rs1, rd, overflow);
      }
    }
  }
  void SubtractImmediateBranchOverflow(Register rd,
                                       Register rs1,
                                       intx_t imm,
                                       Label* overflow) {
    // TODO(loong64): Match other backends' MIN_INTX_T handling exactly.
    AddImmediateBranchOverflow(rd, rs1, -imm, overflow);
  }
  void MultiplyImmediateBranchOverflow(Register rd,
                                       Register rs1,
                                       intx_t imm,
                                       Label* overflow) {
    ASSERT(rd != TMP);
    ASSERT(rd != TMP2);
    ASSERT(rs1 != TMP);
    ASSERT(rs1 != TMP2);

    LoadImmediate(TMP2, imm);
    mulh_d(TMP, rs1, TMP2);
    mul_d(rd, rs1, TMP2);
    srai_d(TMP2, rd, XLEN - 1);
    bne(TMP, TMP2, overflow);
  }
  void AddBranchOverflow(Register rd,
                         Register rs1,
                         Register rs2,
                         Label* overflow) {
    ASSERT(rd != TMP);
    ASSERT(rd != TMP2);
    ASSERT(rs1 != TMP);
    ASSERT(rs1 != TMP2);
    ASSERT(rs2 != TMP);
    ASSERT(rs2 != TMP2);

    if ((rd == rs1) && (rd == rs2)) {
      ASSERT(rs1 == rs2);
      mv(TMP, rs1);
      add_d(rd, rs1, rs2);
      xor_(TMP, TMP, rd);
      blt(TMP, ZR, overflow);
    } else if (rs1 == rs2) {
      ASSERT(rd != rs1);
      ASSERT(rd != rs2);
      add_d(rd, rs1, rs2);
      xor_(TMP, rd, rs1);
      blt(TMP, ZR, overflow);
    } else if (rd == rs1) {
      ASSERT(rs1 != rs2);
      slt(TMP, rs1, ZR);
      add_d(rd, rs1, rs2);
      slt(TMP2, rd, rs2);
      bne(TMP, TMP2, overflow);
    } else if (rd == rs2) {
      ASSERT(rs1 != rs2);
      slt(TMP, rs2, ZR);
      add_d(rd, rs1, rs2);
      slt(TMP2, rd, rs1);
      bne(TMP, TMP2, overflow);
    } else {
      add_d(rd, rs1, rs2);
      slt(TMP, rs2, ZR);
      slt(TMP2, rd, rs1);
      bne(TMP, TMP2, overflow);
    }
  }
  void SubtractBranchOverflow(Register rd,
                              Register rs1,
                              Register rs2,
                              Label* overflow) {
    ASSERT(rd != TMP);
    ASSERT(rd != TMP2);
    ASSERT(rs1 != TMP);
    ASSERT(rs1 != TMP2);
    ASSERT(rs2 != TMP);
    ASSERT(rs2 != TMP2);

    if ((rd == rs1) && (rd == rs2)) {
      ASSERT(rs1 == rs2);
      mv(TMP, rs1);
      sub_d(rd, rs1, rs2);
      xor_(TMP, TMP, rd);
      blt(TMP, ZR, overflow);
    } else if (rs1 == rs2) {
      ASSERT(rd != rs1);
      ASSERT(rd != rs2);
      sub_d(rd, rs1, rs2);
      xor_(TMP, rd, rs1);
      blt(TMP, ZR, overflow);
    } else if (rd == rs1) {
      ASSERT(rs1 != rs2);
      slt(TMP, rs1, ZR);
      sub_d(rd, rs1, rs2);
      slt(TMP2, rd, rs2);
      bne(TMP, TMP2, overflow);
    } else if (rd == rs2) {
      ASSERT(rs1 != rs2);
      slt(TMP, rs2, ZR);
      sub_d(rd, rs1, rs2);
      slt(TMP2, rd, rs1);
      bne(TMP, TMP2, overflow);
    } else {
      sub_d(rd, rs1, rs2);
      slt(TMP, rs2, ZR);
      slt(TMP2, rs1, rd);
      bne(TMP, TMP2, overflow);
    }
  }
  void MultiplyBranchOverflow(Register rd,
                              Register rs1,
                              Register rs2,
                              Label* overflow) {
    ASSERT(rd != TMP);
    ASSERT(rd != TMP2);
    ASSERT(rs1 != TMP);
    ASSERT(rs1 != TMP2);
    ASSERT(rs2 != TMP);
    ASSERT(rs2 != TMP2);

    mulh_d(TMP, rs1, rs2);
    mul_d(rd, rs1, rs2);
    srai_d(TMP2, rd, XLEN - 1);
    bne(TMP, TMP2, overflow);
  }
  void CountLeadingZeroes(Register rd, Register rs) { clz_d(rd, rs); }

  void dbar(uint32_t hint) { Emit32(kDbar | (hint & 0x7fff)); }
  void ibar(uint32_t hint) { Emit32(kIbar | (hint & 0x7fff)); }

  void jirl(Register rd, Register rj, intptr_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    ASSERT(Utils::IsInt(18, offset));
    Emit32(kJirl | EncodeI16Shift2(offset) | Rj(rj) | Rd(rd));
  }
  void jr(Register rj) { jirl(ZR, rj, 0); }
  void ret() { jirl(ZR, RA, 0); }

  void b(Label* label, JumpDistance distance = kFarJump) {
    USE(distance);
    EmitBranch(kBranch, label);
  }
  void bl(Label* label, JumpDistance distance = kFarJump) {
    USE(distance);
    EmitBranch(kBranchLink, label);
  }
  void b(intptr_t offset) { Emit32(kBranch | EncodeBranchOffset(offset)); }
  void bl(intptr_t offset) { Emit32(kBranchLink | EncodeBranchOffset(offset)); }
  void j(Label* label, JumpDistance distance = kFarJump) { b(label, distance); }

  void beq(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    EmitCondBranch(kBeq, rj, rd, label, d);
  }
  void bne(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    EmitCondBranch(kBne, rj, rd, label, d);
  }
  void blt(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    EmitCondBranch(kBlt, rj, rd, label, d);
  }
  void bge(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    EmitCondBranch(kBge, rj, rd, label, d);
  }
  void bltu(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    EmitCondBranch(kBltu, rj, rd, label, d);
  }
  void bgeu(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    EmitCondBranch(kBgeu, rj, rd, label, d);
  }
  void beqz(Register rj, Label* label, JumpDistance d = kFarJump) {
    beq(rj, ZR, label, d);
  }
  void bnez(Register rj, Label* label, JumpDistance d = kFarJump) {
    bne(rj, ZR, label, d);
  }
  void bleu(Register rj, Register rd, Label* label, JumpDistance d = kFarJump) {
    bgeu(rd, rj, label, d);
  }

  void ld_d(Register rd, Address addr) { EmitRegRegImm12(kLoadD, rd, addr.base(), addr.offset()); }
  void st_d(Register rd, Address addr) { EmitRegRegImm12(kStoreD, rd, addr.base(), addr.offset()); }
  void ld_w(Register rd, Address addr) { EmitRegRegImm12(kLoadW, rd, addr.base(), addr.offset()); }
  void ld_wu(Register rd, Address addr) { EmitRegRegImm12(kLoadWU, rd, addr.base(), addr.offset()); }
  void st_w(Register rd, Address addr) { EmitRegRegImm12(kStoreW, rd, addr.base(), addr.offset()); }
  void ld_b(Register rd, Address addr) { EmitRegRegImm12(kLoadB, rd, addr.base(), addr.offset()); }
  void ld_bu(Register rd, Address addr) { EmitRegRegImm12(kLoadBU, rd, addr.base(), addr.offset()); }
  void st_b(Register rd, Address addr) { EmitRegRegImm12(kStoreB, rd, addr.base(), addr.offset()); }
  void ld_h(Register rd, Address addr) { EmitRegRegImm12(kLoadH, rd, addr.base(), addr.offset()); }
  void ld_hu(Register rd, Address addr) { EmitRegRegImm12(kLoadHU, rd, addr.base(), addr.offset()); }
  void st_h(Register rd, Address addr) { EmitRegRegImm12(kStoreH, rd, addr.base(), addr.offset()); }

  void fld_s(FRegister fd, Address addr) { EmitFRegRegImm12(kFLoadS, fd, addr.base(), addr.offset()); }
  void fst_s(FRegister fd, Address addr) { EmitFRegRegImm12(kFStoreS, fd, addr.base(), addr.offset()); }
  void fld_d(FRegister fd, Address addr) { EmitFRegRegImm12(kFLoadD, fd, addr.base(), addr.offset()); }
  void fst_d(FRegister fd, Address addr) { EmitFRegRegImm12(kFStoreD, fd, addr.base(), addr.offset()); }
  void vld(FRegister vd, Address addr) { EmitFRegRegImm12(kVLoad, vd, addr.base(), addr.offset()); }
  void vst(FRegister vd, Address addr) { EmitFRegRegImm12(kVStore, vd, addr.base(), addr.offset()); }
  void fl_s(FRegister fd, Address addr) { fld_s(fd, addr); }
  void fs_s(FRegister fd, Address addr) { fst_s(fd, addr); }
  void fl_d(FRegister fd, Address addr) { fld_d(fd, addr); }
  void fs_d(FRegister fd, Address addr) { fst_d(fd, addr); }
  void movgr2fr_w(FRegister fd, Register rj) {
    Emit32(kMovgr2frW | Rj(rj) | Fd(fd));
  }
  void movgr2fr_d(FRegister fd, Register rj) {
    Emit32(kMovgr2frD | Rj(rj) | Fd(fd));
  }
  void movfr2gr_s(Register rd, FRegister fj) {
    Emit32(kMovfr2grS | Fj(fj) | Rd(rd));
  }
  void movfr2gr_d(Register rd, FRegister fj) {
    Emit32(kMovfr2grD | Fj(fj) | Rd(rd));
  }
  void ffint_s_w(FRegister fd, FRegister fj) {
    Emit32(kFfintSW | Fj(fj) | Fd(fd));
  }
  void ffint_d_w(FRegister fd, FRegister fj) {
    Emit32(kFfintDW | Fj(fj) | Fd(fd));
  }
  void ffint_s_l(FRegister fd, FRegister fj) {
    Emit32(kFfintSL | Fj(fj) | Fd(fd));
  }
  void ffint_d_l(FRegister fd, FRegister fj) {
    Emit32(kFfintDL | Fj(fj) | Fd(fd));
  }
  void fcmp_ceq_s(FRegister fj, FRegister fk) {
    EmitFcmp(kFcmpCeqS, fj, fk);
  }
  void fcmp_clt_s(FRegister fj, FRegister fk) {
    EmitFcmp(kFcmpCltS, fj, fk);
  }
  void fcmp_cle_s(FRegister fj, FRegister fk) {
    EmitFcmp(kFcmpCleS, fj, fk);
  }
  void fcmp_ceq_d(FRegister fj, FRegister fk) {
    EmitFcmp(kFcmpCeqD, fj, fk);
  }
  void fcmp_clt_d(FRegister fj, FRegister fk) {
    EmitFcmp(kFcmpCltD, fj, fk);
  }
  void fcmp_cle_d(FRegister fj, FRegister fk) {
    EmitFcmp(kFcmpCleD, fj, fk);
  }
  void movcf2gr(Register rd) { Emit32(kMovcf2gr | Rd(rd)); }
  void fadd_s(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFaddS, fd, fj, fk);
  }
  void fadd_d(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFaddD, fd, fj, fk);
  }
  void fsub_s(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFsubS, fd, fj, fk);
  }
  void fsub_d(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFsubD, fd, fj, fk);
  }
  void fmul_s(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFmulS, fd, fj, fk);
  }
  void fmul_d(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFmulD, fd, fj, fk);
  }
  void fdiv_s(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFdivS, fd, fj, fk);
  }
  void fdiv_d(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFdivD, fd, fj, fk);
  }
  void fmax_s(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFmaxS, fd, fj, fk);
  }
  void fmax_d(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFmaxD, fd, fj, fk);
  }
  void fmin_s(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFminS, fd, fj, fk);
  }
  void fmin_d(FRegister fd, FRegister fj, FRegister fk) {
    EmitFpuRegRegReg(kFminD, fd, fj, fk);
  }
  void fabs_s(FRegister fd, FRegister fj) { EmitFpuRegReg(kFabsS, fd, fj); }
  void fabs_d(FRegister fd, FRegister fj) { EmitFpuRegReg(kFabsD, fd, fj); }
  void fneg_s(FRegister fd, FRegister fj) { EmitFpuRegReg(kFnegS, fd, fj); }
  void fneg_d(FRegister fd, FRegister fj) { EmitFpuRegReg(kFnegD, fd, fj); }
  void fmov_s(FRegister fd, FRegister fj) { EmitFpuRegReg(kFmovS, fd, fj); }
  void fmov_d(FRegister fd, FRegister fj) { EmitFpuRegReg(kFmovD, fd, fj); }
  void vor_v(FRegister vd, FRegister vj, FRegister vk) {
    EmitFpuRegRegReg(kVorV, vd, vj, vk);
  }
  void fsqrt_s(FRegister fd, FRegister fj) { EmitFpuRegReg(kFsqrtS, fd, fj); }
  void fsqrt_d(FRegister fd, FRegister fj) { EmitFpuRegReg(kFsqrtD, fd, fj); }
  void fcvt_s_d(FRegister fd, FRegister fj) { EmitFpuRegReg(kFcvtSD, fd, fj); }
  void fcvt_d_s(FRegister fd, FRegister fj) { EmitFpuRegReg(kFcvtDS, fd, fj); }
  void ftintrm_l_s(FRegister fd, FRegister fj) {
    EmitFpuRegReg(kFtintrmLS, fd, fj);
  }
  void ftintrm_l_d(FRegister fd, FRegister fj) {
    EmitFpuRegReg(kFtintrmLD, fd, fj);
  }
  void ftintrp_l_s(FRegister fd, FRegister fj) {
    EmitFpuRegReg(kFtintrpLS, fd, fj);
  }
  void ftintrp_l_d(FRegister fd, FRegister fj) {
    EmitFpuRegReg(kFtintrpLD, fd, fj);
  }
  void ftintrz_l_s(FRegister fd, FRegister fj) {
    EmitFpuRegReg(kFtintrzLS, fd, fj);
  }
  void ftintrz_l_d(FRegister fd, FRegister fj) {
    EmitFpuRegReg(kFtintrzLD, fd, fj);
  }

  void addi_d(Register rd, Register rj, intptr_t imm) {
    EmitRegRegImm12(kAddiD, rd, rj, imm);
  }
  void add_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kAddD, rd, rj, rk); }
  void sub_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kSubD, rd, rj, rk); }
  void mul_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kMulD, rd, rj, rk); }
  void mulh_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kMulhD, rd, rj, rk); }
  void mulh_du(Register rd, Register rj, Register rk) { EmitRegRegReg(kMulhDU, rd, rj, rk); }
  void div_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kDivD, rd, rj, rk); }
  void mod_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kModD, rd, rj, rk); }
  void and_(Register rd, Register rj, Register rk) { EmitRegRegReg(kAnd, rd, rj, rk); }
  void or_(Register rd, Register rj, Register rk) { EmitRegRegReg(kOr, rd, rj, rk); }
  void xor_(Register rd, Register rj, Register rk) { EmitRegRegReg(kXor, rd, rj, rk); }
  void sll_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kSllD, rd, rj, rk); }
  void srl_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kSrlD, rd, rj, rk); }
  void sra_d(Register rd, Register rj, Register rk) { EmitRegRegReg(kSraD, rd, rj, rk); }
  void amoand_db_d(Register rd, Register rk, Address addr) {
    ASSERT(addr.offset() == 0);
    ASSERT((rd == ZR) || ((rd != addr.base()) && (rd != rk)));
    Emit32(kAmandDbD | Rk(rk) | Rj(addr.base()) | Rd(rd));
  }
  void amoor_db_d(Register rd, Register rk, Address addr) {
    ASSERT(addr.offset() == 0);
    ASSERT((rd == ZR) || ((rd != addr.base()) && (rd != rk)));
    Emit32(kAmorDbD | Rk(rk) | Rj(addr.base()) | Rd(rd));
  }
  void ll_d(Register rd, Address addr) {
    EmitRegRegImm14Shift2(kLlD, rd, addr.base(), addr.offset());
  }
  void sc_d(Register rd, Address addr) {
    EmitRegRegImm14Shift2(kScD, rd, addr.base(), addr.offset());
  }
  void slt(Register rd, Register rj, Register rk) { EmitRegRegReg(kSlt, rd, rj, rk); }
  void sltu(Register rd, Register rj, Register rk) { EmitRegRegReg(kSltu, rd, rj, rk); }

  void ori(Register rd, Register rj, intptr_t imm) { EmitRegRegUImm12(kOri, rd, rj, imm); }
  void andi(Register rd, Register rj, intptr_t imm) { EmitRegRegUImm12(kAndi, rd, rj, imm); }
  void xori(Register rd, Register rj, intptr_t imm) { EmitRegRegUImm12(kXori, rd, rj, imm); }
  void slli_d(Register rd, Register rj, intptr_t shamt) { EmitRegRegShamt6(kSlliD, rd, rj, shamt); }
  void srli_d(Register rd, Register rj, intptr_t shamt) { EmitRegRegShamt6(kSrliD, rd, rj, shamt); }
  void srai_d(Register rd, Register rj, intptr_t shamt) { EmitRegRegShamt6(kSraiD, rd, rj, shamt); }
  void clz_d(Register rd, Register rj) { Emit32(kClzD | Rj(rj) | Rd(rd)); }
  void clz_w(Register rd, Register rj) { Emit32(kClzW | Rj(rj) | Rd(rd)); }
  void ctz_d(Register rd, Register rj) { Emit32(kCtzD | Rj(rj) | Rd(rd)); }
  void ctz_w(Register rd, Register rj) { Emit32(kCtzW | Rj(rj) | Rd(rd)); }

  void lu12i_w(Register rd, intptr_t imm20) { EmitRegImm20(kLu12iW, rd, imm20); }
  void lu32i_d(Register rd, intptr_t imm20) { EmitRegImm20(kLu32iD, rd, imm20); }
  void pcaddu12i(Register rd, intptr_t imm20) { EmitRegImm20(kPcAddU12I, rd, imm20); }
  void lu52i_d(Register rd, Register rj, intptr_t imm12) { EmitRegRegImm12(kLu52iD, rd, rj, imm12); }
  void addu16i_d(Register rd, Register rj, intptr_t imm16) {
    ASSERT(Utils::IsInt(16, imm16));
    Emit32(kAddu16iD | ((static_cast<uint32_t>(imm16) & 0xffff) << 10) |
           Rj(rj) | Rd(rd));
  }

  void li(Register rd, intptr_t imm) { LoadImmediate(rd, imm); }
  void mv(Register rd, Register rj) { MoveRegister(rd, rj); }
  void sx(Register src, Address addr) { Store(src, addr); }
  void lx(Register dst, Address addr) { Load(dst, addr); }

 private:
  static constexpr intptr_t kInstrSize = 4;

  static constexpr uint32_t kAddiD = 0x02c00000;
  static constexpr uint32_t kAddu16iD = 0x10000000;
  static constexpr uint32_t kAndi = 0x03400000;
  static constexpr uint32_t kBeq = 0x58000000;
  static constexpr uint32_t kBne = 0x5c000000;
  static constexpr uint32_t kBlt = 0x60000000;
  static constexpr uint32_t kBge = 0x64000000;
  static constexpr uint32_t kBltu = 0x68000000;
  static constexpr uint32_t kBgeu = 0x6c000000;
  static constexpr uint32_t kBranch = 0x50000000;
  static constexpr uint32_t kBranchLink = 0x54000000;
  static constexpr uint32_t kAmandDbD = 0x386b8000;
  static constexpr uint32_t kAmorDbD = 0x386c8000;
  static constexpr uint32_t kDbar = 0x38720000;
  static constexpr uint32_t kIbar = 0x38728000;
  static constexpr uint32_t kJirl = 0x4c000000;
  static constexpr uint32_t kLoadB = 0x28000000;
  static constexpr uint32_t kLoadH = 0x28400000;
  static constexpr uint32_t kLoadW = 0x28800000;
  static constexpr uint32_t kLoadD = 0x28c00000;
  static constexpr uint32_t kStoreB = 0x29000000;
  static constexpr uint32_t kStoreH = 0x29400000;
  static constexpr uint32_t kStoreW = 0x29800000;
  static constexpr uint32_t kStoreD = 0x29c00000;
  static constexpr uint32_t kLoadBU = 0x2a000000;
  static constexpr uint32_t kLoadHU = 0x2a400000;
  static constexpr uint32_t kLoadWU = 0x2a800000;
  static constexpr uint32_t kLlD = 0x22000000;
  static constexpr uint32_t kScD = 0x23000000;
  static constexpr uint32_t kFLoadS = 0x2b000000;
  static constexpr uint32_t kFStoreS = 0x2b400000;
  static constexpr uint32_t kFLoadD = 0x2b800000;
  static constexpr uint32_t kFStoreD = 0x2bc00000;
  static constexpr uint32_t kVLoad = 0x2c000000;
  static constexpr uint32_t kVStore = 0x2c400000;
  static constexpr uint32_t kLu12iW = 0x14000000;
  static constexpr uint32_t kLu32iD = 0x16000000;
  static constexpr uint32_t kLu52iD = 0x03000000;
  static constexpr uint32_t kNop = 0x03400000;
  static constexpr uint32_t kOri = 0x03800000;
  static constexpr uint32_t kXori = 0x03c00000;
  static constexpr uint32_t kPcAddU12I = 0x1c000000;
  static constexpr uint32_t kAddD = 0x00108000;
  static constexpr uint32_t kSubD = 0x00118000;
  static constexpr uint32_t kSlt = 0x00120000;
  static constexpr uint32_t kSltu = 0x00128000;
  static constexpr uint32_t kAnd = 0x00148000;
  static constexpr uint32_t kOr = 0x00150000;
  static constexpr uint32_t kXor = 0x00158000;
  static constexpr uint32_t kSllD = 0x00188000;
  static constexpr uint32_t kSrlD = 0x00190000;
  static constexpr uint32_t kSraD = 0x00198000;
  static constexpr uint32_t kMulD = 0x001d8000;
  static constexpr uint32_t kMulhD = 0x001e0000;
  static constexpr uint32_t kMulhDU = 0x001e8000;
  static constexpr uint32_t kDivD = 0x00220000;
  static constexpr uint32_t kModD = 0x00228000;
  static constexpr uint32_t kSlliD = 0x00410000;
  static constexpr uint32_t kSrliD = 0x00450000;
  static constexpr uint32_t kSraiD = 0x00490000;
  static constexpr uint32_t kClzW = 0x00001400;
  static constexpr uint32_t kCtzW = 0x00001c00;
  static constexpr uint32_t kClzD = 0x00002400;
  static constexpr uint32_t kCtzD = 0x00002c00;
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
  static constexpr uint32_t kVorV = 0x71268000;
  static constexpr uint32_t kFsqrtS = 0x01144400;
  static constexpr uint32_t kFsqrtD = 0x01144800;
  static constexpr uint32_t kMovfr2grS = 0x0114b400;
  static constexpr uint32_t kMovfr2grD = 0x0114b800;
  static constexpr uint32_t kMovgr2frW = 0x0114a400;
  static constexpr uint32_t kMovgr2frD = 0x0114a800;
  static constexpr uint32_t kMovcf2gr = 0x0114dc00;
  static constexpr uint32_t kFcvtSD = 0x01191800;
  static constexpr uint32_t kFcvtDS = 0x01192400;
  static constexpr uint32_t kFtintrmLS = 0x011a2400;
  static constexpr uint32_t kFtintrmLD = 0x011a2800;
  static constexpr uint32_t kFtintrpLS = 0x011a6400;
  static constexpr uint32_t kFtintrpLD = 0x011a6800;
  static constexpr uint32_t kFtintrzLS = 0x011aa400;
  static constexpr uint32_t kFtintrzLD = 0x011aa800;
  static constexpr uint32_t kFfintSW = 0x011d1000;
  static constexpr uint32_t kFfintDW = 0x011d2000;
  static constexpr uint32_t kFfintSL = 0x011d1800;
  static constexpr uint32_t kFfintDL = 0x011d2800;
  static constexpr uint32_t kFcmpCltS = 0x0c110000;
  static constexpr uint32_t kFcmpCeqS = 0x0c120000;
  static constexpr uint32_t kFcmpCleS = 0x0c130000;
  static constexpr uint32_t kFcmpCltD = 0x0c210000;
  static constexpr uint32_t kFcmpCeqD = 0x0c220000;
  static constexpr uint32_t kFcmpCleD = 0x0c230000;

  static uint32_t Rd(Register reg) { return static_cast<uint32_t>(reg); }
  static uint32_t Fd(FRegister reg) { return static_cast<uint32_t>(reg); }
  static uint32_t Rj(Register reg) { return static_cast<uint32_t>(reg) << 5; }
  static uint32_t Fj(FRegister reg) { return static_cast<uint32_t>(reg) << 5; }
  static uint32_t Rk(Register reg) { return static_cast<uint32_t>(reg) << 10; }
  static uint32_t Fk(FRegister reg) { return static_cast<uint32_t>(reg) << 10; }

  void EmitFcmp(uint32_t opcode, FRegister fj, FRegister fk) {
    Emit32(opcode | Fk(fk) | Fj(fj));
  }

  void EmitFpuRegRegReg(uint32_t opcode,
                        FRegister fd,
                        FRegister fj,
                        FRegister fk) {
    Emit32(opcode | Fk(fk) | Fj(fj) | Fd(fd));
  }

  void EmitFpuRegReg(uint32_t opcode, FRegister fd, FRegister fj) {
    Emit32(opcode | Fj(fj) | Fd(fd));
  }

  static uint32_t EncodeI12(intptr_t imm) {
    ASSERT(Utils::IsInt(12, imm));
    return (static_cast<uint32_t>(imm) & 0xfff) << 10;
  }

  static uint32_t EncodeU12(intptr_t imm) {
    ASSERT(Utils::IsUint(12, imm));
    return (static_cast<uint32_t>(imm) & 0xfff) << 10;
  }

  static uint32_t EncodeI16Shift2(intptr_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    const intptr_t imm = offset >> 2;
    ASSERT(Utils::IsInt(16, imm));
    return (static_cast<uint32_t>(imm) & 0xffff) << 10;
  }

  static uint32_t EncodeI14Shift2(intptr_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    const intptr_t imm = offset >> 2;
    ASSERT(Utils::IsInt(14, imm));
    return (static_cast<uint32_t>(imm) & 0x3fff) << 10;
  }

  static uint32_t EncodeBranchOffset(intptr_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    const intptr_t imm = offset >> 2;
    ASSERT(Utils::IsInt(26, imm));
    return ((static_cast<uint32_t>(imm) & 0xffff) << 10) |
           ((static_cast<uint32_t>(imm) >> 16) & 0x3ff);
  }

  static intptr_t SignExtend(int bits, uint32_t value) {
    return static_cast<int32_t>(value << (32 - bits)) >> (32 - bits);
  }

  static intptr_t DecodeI16Shift2(uint32_t instr) {
    return SignExtend(16, (instr >> 10) & 0xffff) << 2;
  }

  static intptr_t DecodeBranchOffset(uint32_t instr) {
    const uint32_t encoded =
        ((instr >> 10) & 0xffff) | ((instr & 0x3ff) << 16);
    return SignExtend(26, encoded) << 2;
  }

  void EmitRegRegImm12(uint32_t opcode,
                       Register rd,
                       Register rj,
                       intptr_t imm) {
    Emit32(opcode | EncodeI12(imm) | Rj(rj) | Rd(rd));
  }

  void EmitRegRegUImm12(uint32_t opcode,
                        Register rd,
                        Register rj,
                        intptr_t imm) {
    Emit32(opcode | EncodeU12(imm) | Rj(rj) | Rd(rd));
  }

  void EmitRegRegImm14Shift2(uint32_t opcode,
                             Register rd,
                             Register rj,
                             intptr_t offset) {
    Emit32(opcode | EncodeI14Shift2(offset) | Rj(rj) | Rd(rd));
  }

  void EmitRegRegReg(uint32_t opcode, Register rd, Register rj, Register rk) {
    Emit32(opcode | Rk(rk) | Rj(rj) | Rd(rd));
  }

  void EmitRegRegShamt6(uint32_t opcode,
                        Register rd,
                        Register rj,
                        intptr_t shamt) {
    ASSERT(Utils::IsUint(6, shamt));
    Emit32(opcode | ((static_cast<uint32_t>(shamt) & 0x3f) << 10) | Rj(rj) |
           Rd(rd));
  }

  void EmitRegImm20(uint32_t opcode, Register rd, intptr_t imm20) {
    ASSERT(Utils::IsInt(20, imm20) || Utils::IsUint(20, imm20));
    Emit32(opcode | ((static_cast<uint32_t>(imm20) & 0xfffff) << 5) | Rd(rd));
  }

  void EmitFRegRegImm12(uint32_t opcode,
                        FRegister fd,
                        Register rj,
                        intptr_t imm) {
    Emit32(opcode | EncodeI12(imm) | Rj(rj) | Fd(fd));
  }

  Address PrepareAddress(Register base, intptr_t offset) {
    if (Utils::IsInt(12, offset)) {
      return Address(base, offset);
    }
    const Register scratch = (base == FAR_TMP) ? TMP2 : FAR_TMP;
    LoadImmediate(scratch, offset);
    add_d(scratch, base, scratch);
    return Address(scratch, 0);
  }

  void EmitBranch(uint32_t opcode, Label* label) {
    const intptr_t offset =
        label->IsBound() ? label->Position() - CodeSize() : label->position_;
    Emit32(opcode | EncodeBranchOffset(offset));
    if (!label->IsBound()) {
      label->LinkTo(CodeSize() - 4);
    }
  }

  void EmitCondBranch(uint32_t opcode,
                      Register rj,
                      Register rd,
                      Label* label,
                      JumpDistance distance) {
    USE(distance);
    if (label->IsBound()) {
      const intptr_t offset = label->Position() - CodeSize();
      if (CanEncodeI16Shift2(offset)) {
        EmitCondBranchOpcode(opcode, rj, rd, offset);
        return;
      }
    }

    // The Label link chain stores the previous unresolved branch position in
    // the emitted instruction. LoongArch64 conditional branches only carry a
    // signed 16-bit word offset, which is too small once a generated stub grows
    // beyond 128 KiB. Emit a far conditional branch so the link lives in the
    // following 26-bit unconditional branch instead.
    EmitCondBranchOpcode(InvertBranchOpcode(opcode), rj, rd, 2 * kInstrSize);
    EmitBranch(kBranch, label);
  }

  intptr_t DecodeAndPatchBranch(intptr_t position,
                                uint32_t instr,
                                intptr_t dest) {
    const uint32_t op6 = instr & 0xfc000000;
    if ((op6 == kBranch) || (op6 == kBranchLink)) {
      Write32(position, (instr & 0xfc000000) | EncodeBranchOffset(dest));
      return DecodeBranchOffset(instr);
    }
    if ((op6 == kBeq) || (op6 == kBne) || (op6 == kBlt) || (op6 == kBge) ||
        (op6 == kBltu) || (op6 == kBgeu) || (op6 == kJirl)) {
      Write32(position, (instr & 0xfc0003ff) | EncodeI16Shift2(dest));
      return DecodeI16Shift2(instr);
    }
    UNREACHABLE();
    return 0;
  }

  static bool CanEncodeI16Shift2(intptr_t offset) {
    return Utils::IsAligned(offset, 4) && Utils::IsInt(16, offset >> 2);
  }

  void EmitCondBranchOpcode(uint32_t opcode,
                            Register rj,
                            Register rd,
                            intptr_t offset) {
    Emit32(opcode | EncodeI16Shift2(offset) | Rj(rj) | Rd(rd));
  }

  static uint32_t InvertBranchOpcode(uint32_t opcode) {
    switch (opcode) {
      case kBeq:
        return kBne;
      case kBne:
        return kBeq;
      case kBlt:
        return kBge;
      case kBge:
        return kBlt;
      case kBltu:
        return kBgeu;
      case kBgeu:
        return kBltu;
      default:
        UNREACHABLE();
        return opcode;
    }
  }

  void BranchOnCondition(Condition condition,
                         Register left,
                         Register right,
                         Label* label,
                         JumpDistance distance) {
    switch (condition) {
      case EQ:
        beq(left, right, label, distance);
        break;
      case NE:
        bne(left, right, label, distance);
        break;
      case LT:
        blt(left, right, label, distance);
        break;
      case GE:
        bge(left, right, label, distance);
        break;
      case GT:
        blt(right, left, label, distance);
        break;
      case LE:
        bge(right, left, label, distance);
        break;
      case CC:
        bltu(left, right, label, distance);
        break;
      case CS:
        bgeu(left, right, label, distance);
        break;
      case HI:
        bltu(right, left, label, distance);
        break;
      case LS:
        bgeu(right, left, label, distance);
        break;
      default:
        UNREACHABLE();
    }
  }

  bool constant_pool_allowed_ = false;
  Register compare_left_ = kNoRegister;
  Register compare_right_ = kNoRegister;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_
