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

#include "vm/compiler/assembler/assembler_base.h"
#include "vm/constants.h"

namespace dart {

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

  void Breakpoint() override { Emit32(0x002a0000); }
  void StoreStoreFence() override {  }
  void SmiTag(Register r) override {  }
  void Bind(Label* label) override {
    if (label->IsUnused()) {
      label->BindTo(CodeSize());
    }
  }
  void ExtendValue(Register dst, Register src, OperandSize sz) override {
  }
  void TryAllocateObject(intptr_t cid,
                         intptr_t instance_size,
                         Label* failure,
                         JumpDistance distance,
                         Register instance_reg,
                         Register temp) override {
  }
  void BranchIfSmi(Register reg,
                   Label* label,
                   JumpDistance distance = kFarJump) override {
  }
  void LslImmediate(Register reg,
                    int32_t shift,
                    OperandSize sz = kWordBytes) override {
  }
  void LslImmediate(Register dst,
                    Register src,
                    int32_t shift,
                    OperandSize sz = kWordBytes) override {
  }
  void ArithmeticShiftRightImmediate(Register reg,
                                     int32_t shift,
                                     OperandSize sz = kWordBytes) override {
  }
  void ArithmeticShiftRightImmediate(Register dst,
                                     Register src,
                                     int32_t shift,
                                     OperandSize sz = kWordBytes) override {
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
  }
  void LoadFieldAddressForRegOffset(Register address,
                                    Register instance,
                                    Register offset_in_words_as_smi) override {
  }
  void LoadAcquire(Register dst,
                   const Address& address,
                   OperandSize size = kWordBytes) override {
  }
  void StoreRelease(Register src,
                    const Address& address,
                    OperandSize size = kWordBytes) override {
  }
  void Load(Register dst,
            const Address& address,
            OperandSize sz = kWordBytes) override {
  }
  void Store(Register src,
             const Address& address,
             OperandSize sz = kWordBytes) override {
  }
  void StoreObjectIntoObjectNoBarrier(
      Register object,
      const Address& address,
      const Object& value,
      MemoryOrder memory_order = kRelaxedNonAtomic,
      OperandSize size = kWordBytes) override {
  }
  void LoadIndexedPayload(Register dst,
                          Register base,
                          int32_t offset,
                          Register index,
                          ScaleFactor scale,
                          OperandSize sz = kWordBytes) override {
  }
  void LoadInt32FromBoxOrSmi(Register result, Register value) override {
  }
  void LoadInt64FromBoxOrSmi(Register result, Register value) override {
  }
  void AddScaled(Register dst,
                 Register base,
                 Register index,
                 ScaleFactor scale,
                 int32_t disp) override {
  }
  void LoadImmediate(Register dst, target::word imm) override {
  }
  void CompareImmediate(Register reg,
                        target::word imm,
                        OperandSize width = kWordBytes) override {
  }
  void CompareWithMemoryValue(Register value,
                              Address address,
                              OperandSize size = kWordBytes) override {
  }
  void AndImmediate(Register reg,
                    target::word imm,
                    OperandSize sz = kWordBytes) override {
  }
  void AndImmediate(Register dst,
                    Register src,
                    target::word imm,
                    OperandSize sz = kWordBytes) override {
  }
  void LsrImmediate(Register dst, int32_t shift) override {  }
  void MulImmediate(Register dst,
                    target::word imm,
                    OperandSize sz = kWordBytes) override {
  }
  void AndRegisters(Register dst,
                    Register src1,
                    Register src2 = kNoRegister) override {
  }
  void LslRegister(Register dst, Register shift) override {  }
  void ExtractBitField(Register dst,
                       Register src,
                       intptr_t low_bit,
                       intptr_t width) override {
  }
  void CombineHashes(Register dst, Register other) override {  }
  void FinalizeHashForSize(intptr_t bit_size,
                           Register hash,
                           Register scratch = TMP) override {
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
  }
  void StoreBarrier(Register object,
                    Register value,
                    CanBeSmi can_be_smi,
                    Register scratch) override {
  }
  void ArrayStoreBarrier(Register object,
                         Register slot,
                         Register value,
                         CanBeSmi can_be_smi,
                         Register scratch) override {
  }
  void VerifyStoreNeedsNoWriteBarrier(Register object,
                                      Register value) override {
  }

  void PushRegister(Register reg) {  }
  void PopRegister(Register reg) {  }
  void PushRegisterPair(Register r0, Register r1) {  }
  void PopRegisterPair(Register r0, Register r1) {  }
  void PushRegisters(const RegisterSet& registers) {  }
  void PopRegisters(const RegisterSet& registers) {  }
  void PushRegistersAligned(const RegisterSet& registers, intptr_t space) {
  }
  void PopRegistersAligned(const RegisterSet& registers, intptr_t space) {
  }
  void PushRegistersInOrder(std::initializer_list<Register> regs) {
  }
  void PushValueAtOffset(Register base, int32_t offset) {  }
  void PushNativeCalleeSavedRegisters() {  }
  void PopNativeCalleeSavedRegisters() {  }

  void Drop(intptr_t stack_elements) {  }
  void Jump(Label* label, JumpDistance distance = kFarJump) {  }
  void Jump(Register target) {  }
  void Jump(const Address& address) {  }

  void LoadMemoryValue(Register dst, Register base, int32_t offset) {
  }
  void StoreMemoryValue(Register src, Register base, int32_t offset) {
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
  void ReserveAlignedFrameSpace(intptr_t frame_space) {  }
  void EmitEntryFrameVerification() {  }

  static constexpr intptr_t kEntryPointToPcMarkerOffset = 0;
  static intptr_t EntryPointToPcMarkerOffset() {
    return kEntryPointToPcMarkerOffset;
  }

  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return target::IsSmi(object); }

  void CompareRegisters(Register rn, Register rm) {  }
  void CompareObjectRegisters(Register rn, Register rm) {  }
  void TestRegisters(Register rn, Register rm) {  }
  void BranchIf(Condition condition,
                Label* label,
                JumpDistance distance = kFarJump) {
  }
  void BranchIfZero(Register rn,
                    Label* label,
                    JumpDistance distance = kFarJump) {
  }
  void BranchIfBit(Register rn,
                   intptr_t bit_number,
                   Condition condition,
                   Label* label,
                   JumpDistance distance = kFarJump) {
  }
  void SetIf(Condition condition, Register rd) {  }
  void ZeroIf(Condition condition, Register rd, Register rs) {  }

  void SmiUntag(Register reg) {  }
  void SmiUntag(Register dst, Register src) {  }
  void SmiTag(Register dst, Register src) {  }
  void BranchIfNotSmi(Register reg,
                      Label* label,
                      JumpDistance distance = kFarJump) {
  }

  void JumpAndLink(
      const Code& code,
      ObjectPoolBuilderEntry::Patchability patchable =
          ObjectPoolBuilderEntry::kNotPatchable,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
  }
  void JumpAndLinkPatchable(
      const Code& code,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
  }
  void JumpAndLinkWithEquivalence(const Code& code,
                                  const Object& equivalence,
                                  CodeEntryKind entry_kind =
                                      CodeEntryKind::kNormal) {
  }

  void Call(Address target) {  }
  void Call(Register target) {  }
  void Call(const Code& code) {  }
  void CallCFunction(Address target) {  }
  void CallCFunction(Register target) {  }

  void AddRegisters(Register dst, Register src) {  }
  void AddShifted(Register dst, Register base, Register index, intx_t shift) {
  }
  void SubRegisters(Register dst, Register src) {  }
  void OrImmediate(Register rd,
                   Register rn,
                   intx_t imm,
                   OperandSize sz = kWordBytes) {
  }
  void OrImmediate(Register rd, intx_t imm) {  }
  void XorImmediate(Register rd,
                    Register rn,
                    intx_t imm,
                    OperandSize sz = kWordBytes) {
  }
  void TestImmediate(Register rn, intx_t imm, OperandSize sz = kWordBytes) {
  }

  void LoadS(FRegister dst, const Address& address) {  }
  void LoadD(FRegister dst, const Address& address) {  }
  void LoadSFromOffset(FRegister dst, Register base, int32_t offset) {
  }
  void LoadDFromOffset(FRegister dst, Register base, int32_t offset) {
  }
  void LoadSFieldFromOffset(FRegister dst, Register base, int32_t offset) {
  }
  void LoadDFieldFromOffset(FRegister dst, Register base, int32_t offset) {
  }
  void LoadFromStack(Register dst, intptr_t depth) {  }
  void StoreToStack(Register src, intptr_t depth) {  }
  void CompareToStack(Register src, intptr_t depth) {  }

  void StoreZero(const Address& address, Register temp = kNoRegister) {
  }
  void StoreS(FRegister src, const Address& address) {  }
  void StoreD(FRegister src, const Address& address) {  }
  void StoreSToOffset(FRegister src, Register base, int32_t offset) {
  }
  void StoreSFieldToOffset(FRegister src, Register base, int32_t offset) {
  }
  void StoreDToOffset(FRegister src, Register base, int32_t offset) {
  }
  void StoreDFieldToOffset(FRegister src, Register base, int32_t offset) {
  }

  void LoadUnboxedDouble(FpuRegister dst, Register base, int32_t offset) {
  }
  void StoreUnboxedDouble(FpuRegister src, Register base, int32_t offset) {
  }
  void MoveUnboxedDouble(FpuRegister dst, FpuRegister src) {  }
  void LoadUnboxedSimd128(FpuRegister dst, Register base, int32_t offset) {
  }
  void StoreUnboxedSimd128(FpuRegister src, Register base, int32_t offset) {
  }
  void MoveUnboxedSimd128(FpuRegister dst, FpuRegister src) {  }

  void InitializeHeader(Register tags, Register object) {  }
  void InitializeHeaderUntagged(Register tags, Register object) {
  }
  void StoreInternalPointer(Register object,
                            const Address& dest,
                            Register value) {
  }

  void LoadPoolPointer(Register pp = PP) {  }
  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool value) { constant_pool_allowed_ = value; }
  bool CanLoadFromObjectPool(const Object& object) const { return false; }
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       ObjectPoolBuilderEntry::Patchability patchable) {
  }
  void LoadIsolate(Register dst) {  }
  void LoadIsolateGroup(Register dst) {  }
  void LoadUniqueObject(
      Register dst,
      const Object& object,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
  }

  void LoadSImmediate(FRegister reg, float imms) {  }
  void LoadDImmediate(FRegister reg, double immd) {  }
  void LoadQImmediate(FRegister reg, simd128_value_t immq) {  }
  void LoadWordFromPoolIndex(Register dst, intptr_t index, Register pp = PP) {
  }
  void StoreWordToPoolIndex(Register src, intptr_t index, Register pp = PP) {
  }

  void PushObject(const Object& object) {  }
  void PushImmediate(int64_t immediate) {  }
  void CompareObject(Register reg, const Object& object) {  }

  void ExtractClassIdFromTags(Register result, Register tags) {
  }
  void ExtractInstanceSizeFromTags(Register result, Register tags) {
  }
  void LoadClassId(Register result, Register object) {  }
  void LoadClassById(Register result, Register class_id) {  }
  void CompareClassId(Register object,
                      intptr_t class_id,
                      Register scratch = kNoRegister) {
  }
  void LoadClassIdMayBeSmi(Register result, Register object) {
  }
  void LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  }

  void AddImmediate(Register rd, target::word imm) {  }
  void AddImmediate(Register rd, Register rn, target::word imm) {
  }
  void LoadObject(Register dst, const Object& object) {  }
  void Ret() { Emit32(0x4c000020); }

  void EnterFrame(intptr_t frame_size) {  }
  void LeaveFrame() {  }
  void SetReturnAddress(Register value) {  }

  void TransitionGeneratedToNative(Register destination_address,
                                   Register new_exit_frame,
                                   Register new_exit_through_ffi,
                                   bool enter_safepoint) {
  }
  void TransitionNativeToGenerated(Register scratch,
                                   bool exit_safepoint,
                                   bool set_tag = true) {
  }
  void VerifyInGenerated(Register scratch) {  }
  void VerifyNotInGenerated(Register scratch) {  }
  void EnterFullSafepoint(Register scratch) {  }
  void ExitFullSafepoint(Register scratch) {  }

  void CheckFpSpDist(intptr_t fp_sp_dist) {  }
  void CheckCodePointer() {  }
  void RestoreCodePointer() {  }
  void RestorePoolPointer() {  }
  void RestorePinnedRegisters() {  }
  void SetupGlobalPoolAndDispatchTable() {  }

  void EnterDartFrame(intptr_t frame_size, Register new_pp = kNoRegister) {
  }
  void EnterOsrFrame(intptr_t extra_size, Register new_pp = kNoRegister) {
  }
  void LeaveDartFrame() {  }
  void LeaveDartFrame(intptr_t fp_sp_dist) {  }
  void CallRuntime(const RuntimeEntry& entry,
                   intptr_t argument_count,
                   bool tsan_enter_exit = true) {
  }
  void EnterStubFrame() { EnterDartFrame(0); }
  void LeaveStubFrame() { LeaveDartFrame(); }
  void EnterCFrame(intptr_t frame_space) {  }
  void LeaveCFrame() {  }

  void MonomorphicCheckedEntryJIT() {  }
  void MonomorphicCheckedEntryAOT() {  }
  void BranchOnMonomorphicCheckedEntryJIT(Label* label) {  }

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
  }
  void CheckAllocationCanary(Register top, Register tmp = TMP) {
  }
  void WriteAllocationCanary(Register top) {  }
  void CopyMemoryWords(Register src, Register dst, Register size, Register temp) {
  }

  void GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target = 0) {
  }
  void GenerateUnRelocatedPcRelativeTailCall(intptr_t offset_into_target = 0) {
  }

  static bool AddressCanHoldConstantIndex(const Object& constant,
                                          bool is_external,
                                          intptr_t cid,
                                          intptr_t index_scale) {
    return false;
  }
  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const {
    return Address(SP);
  }
  void ComputeElementAddressForIntIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        Register array,
                                        intptr_t index) {
  }
  Address ElementAddressForRegIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    bool index_unboxed,
                                    Register array,
                                    Register index,
                                    Register temp) {
    return Address(SP);
  }
  void ComputeElementAddressForRegIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        bool index_unboxed,
                                        Register array,
                                        Register index) {
  }
  void LoadStaticFieldAddress(Register address,
                              Register field,
                              Register scratch,
                              bool is_shared) {
  }

  static int32_t HeapDataOffset(bool is_external, intptr_t cid) {
    return is_external ? 0 : (target::Instance::DataOffsetFor(cid) -
                             kHeapObjectTag);
  }

  void AddImmediateBranchOverflow(Register rd,
                                  Register rs1,
                                  intx_t imm,
                                  Label* overflow) {
  }
  void SubtractImmediateBranchOverflow(Register rd,
                                       Register rs1,
                                       intx_t imm,
                                       Label* overflow) {
  }
  void MultiplyImmediateBranchOverflow(Register rd,
                                       Register rs1,
                                       intx_t imm,
                                       Label* overflow) {
  }
  void AddBranchOverflow(Register rd,
                         Register rs1,
                         Register rs2,
                         Label* overflow) {
  }
  void SubtractBranchOverflow(Register rd,
                              Register rs1,
                              Register rs2,
                              Label* overflow) {
  }
  void MultiplyBranchOverflow(Register rd,
                              Register rs1,
                              Register rs2,
                              Label* overflow) {
  }
  void CountLeadingZeroes(Register rd, Register rs) {  }

 private:
  bool constant_pool_allowed_ = true;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_
