// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_LOONG64)

#include "vm/instructions.h"
#include "vm/instructions_loong64.h"

#include "platform/unaligned.h"
#include "platform/utils.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/thread.h"

namespace dart {

static constexpr uint32_t kInstrSize = 4;
static constexpr uint32_t kAddiD = 0x02c00000;
static constexpr uint32_t kLoadD = 0x28c00000;
static constexpr uint32_t kJirl = 0x4c000000;
static constexpr uint32_t kBranch = 0x50000000;
static constexpr uint32_t kBranchLink = 0x54000000;
static constexpr uint32_t kLu12iW = 0x14000000;
static constexpr uint32_t kLu32iD = 0x16000000;
static constexpr uint32_t kLu52iD = 0x03000000;
static constexpr uint32_t kOri = 0x03800000;
static constexpr uint32_t kAddD = 0x00108000;
static constexpr uint32_t kOp7Mask = 0xfe000000;
static constexpr uint32_t kOp10Mask = 0xffc00000;
static constexpr uint32_t kRegRegRegMask = 0xffff8000;
static constexpr uint32_t kBranchOpcodeMask = 0xfc000000;
static constexpr uint32_t kRetInstruction = kJirl | (RA << 5) | ZR;
static constexpr uint32_t kIndirectCallInstruction = kJirl | (RA << 5) | RA;

static int32_t SignExtend32(int bits, uint32_t value) {
  return static_cast<int32_t>(value << (32 - bits)) >> (32 - bits);
}

static Register DecodeRd(uint32_t instr) {
  return static_cast<Register>(instr & 0x1f);
}

static Register DecodeRj(uint32_t instr) {
  return static_cast<Register>((instr >> 5) & 0x1f);
}

static Register DecodeRk(uint32_t instr) {
  return static_cast<Register>((instr >> 10) & 0x1f);
}

static int32_t DecodeSImm12(uint32_t instr) {
  return SignExtend32(12, (instr >> 10) & 0xfff);
}

static uint32_t DecodeUImm12(uint32_t instr) {
  return (instr >> 10) & 0xfff;
}

static uint32_t DecodeImm20(uint32_t instr) {
  return (instr >> 5) & 0xfffff;
}

static uint32_t EncodeSImm12(int32_t imm) {
  ASSERT(Utils::IsInt(12, imm));
  return (static_cast<uint32_t>(imm) & 0xfff) << 10;
}

static bool DecodeLoadD(uword pc,
                        Register* dst,
                        Register* base,
                        intptr_t* offset) {
  const uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(pc));
  if ((instr & kOp10Mask) != kLoadD) {
    return false;
  }
  *dst = DecodeRd(instr);
  *base = DecodeRj(instr);
  *offset = DecodeSImm12(instr);
  return true;
}

static bool DecodeAddD(uword pc,
                       Register* dst,
                       Register* left,
                       Register* right) {
  const uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(pc));
  if ((instr & kRegRegRegMask) != kAddD) {
    return false;
  }
  *dst = DecodeRd(instr);
  *left = DecodeRj(instr);
  *right = DecodeRk(instr);
  return true;
}

static uint32_t EncodeBranchOffset(int32_t distance) {
  ASSERT(Utils::IsAligned(distance, kInstrSize));
  const int32_t offset = distance >> 2;
  ASSERT(Utils::IsInt(26, offset));
  return ((static_cast<uint32_t>(offset) & 0xffff) << 10) |
         ((static_cast<uint32_t>(offset) >> 16) & 0x3ff);
}

static int32_t DecodeBranchOffset(uint32_t instr) {
  const uint32_t offset = ((instr >> 10) & 0xffff) | ((instr & 0x3ff) << 16);
  return SignExtend32(26, offset) << 2;
}

static bool IsBranchOpcode(uint32_t instr, uint32_t opcode) {
  return (instr & kBranchOpcodeMask) == opcode;
}

uword InstructionPattern::DecodeLoadWordImmediate(uword end,
                                                  Register* reg,
                                                  intptr_t* value) {
  uword start = end - kInstrSize;
  uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(start));

  if (((instr & kOp10Mask) == kAddiD) && (DecodeRj(instr) == ZR)) {
    *reg = DecodeRd(instr);
    *value = DecodeSImm12(instr);
    return start;
  }

  bool has_reg = false;
  bool has_upper = false;
  Register dst = kNoRegister;
  uint64_t lo12 = 0;
  uint64_t hi20 = 0;
  uint64_t hi32 = 0;
  uint64_t hi52 = 0;

  if ((instr & kOp10Mask) == kLu52iD) {
    dst = DecodeRd(instr);
    ASSERT(DecodeRj(instr) == dst);
    hi52 = DecodeUImm12(instr);
    has_reg = true;
    has_upper = true;

    start -= kInstrSize;
    instr = LoadUnaligned(reinterpret_cast<uint32_t*>(start));
    ASSERT((instr & kOp7Mask) == kLu32iD);
    ASSERT(DecodeRd(instr) == dst);
    hi32 = DecodeImm20(instr);
  }

  if (has_reg) {
    start -= kInstrSize;
    instr = LoadUnaligned(reinterpret_cast<uint32_t*>(start));
  }

  if ((instr & kOp10Mask) == kOri) {
    const Register ori_dst = DecodeRd(instr);
    if (!has_reg) {
      dst = ori_dst;
      has_reg = true;
    }
    ASSERT(ori_dst == dst);
    ASSERT(DecodeRj(instr) == dst);
    lo12 = DecodeUImm12(instr);

    start -= kInstrSize;
    instr = LoadUnaligned(reinterpret_cast<uint32_t*>(start));
  }

  ASSERT((instr & kOp7Mask) == kLu12iW);
  const Register lu12_dst = DecodeRd(instr);
  if (!has_reg) {
    dst = lu12_dst;
  }
  ASSERT(lu12_dst == dst);
  hi20 = DecodeImm20(instr);

  const uint64_t low32 = ((hi20 & 0xfffff) << 12) | lo12;
  *reg = dst;
  if (has_upper) {
    *value = static_cast<intptr_t>(low32 | (hi32 << 32) | (hi52 << 52));
  } else {
    *value = SignExtend32(32, static_cast<uint32_t>(low32));
  }
  return start;
}

uword InstructionPattern::DecodeLoadWordFromPool(uword end,
                                                 Register* reg,
                                                 intptr_t* index) {
  Register base;
  intptr_t offset;
  if (!DecodeLoadD(end - kInstrSize, reg, &base, &offset)) {
    UNREACHABLE();
  }

  if (base == PP) {
    *index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
    return end - kInstrSize;
  }

  ASSERT(offset == 0);
  Register dst;
  Register left;
  Register right;
  const uword add_pc = end - (2 * kInstrSize);
  if (!DecodeAddD(add_pc, &dst, &left, &right)) {
    UNREACHABLE();
  }
  ASSERT(dst == base);
  ASSERT(((left == PP) && (right == base)) ||
         ((left == base) && (right == PP)));

  Register offset_reg;
  intptr_t pool_offset;
  const uword start =
      DecodeLoadWordImmediate(add_pc, &offset_reg, &pool_offset);
  ASSERT(offset_reg == base);
  *index = ObjectPool::IndexFromOffset(pool_offset - kHeapObjectTag);
  return start;
}

void InstructionPattern::EncodeLoadWordFromPoolFixed(uword end,
                                                     int32_t offset) {
  Register dst;
  Register base;
  intptr_t old_offset;
  const uword pc = end - kInstrSize;
  if (!DecodeLoadD(pc, &dst, &base, &old_offset) || (base != PP)) {
    UNREACHABLE();
  }
  ASSERT(Utils::IsAligned(offset, kWordSize));
  StoreUnaligned(reinterpret_cast<uint32_t*>(pc),
                 kLoadD | EncodeSImm12(offset) |
                     (static_cast<uint32_t>(base) << 5) |
                     static_cast<uint32_t>(dst));
}

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));
  Register dst;
  Register base;
  intptr_t offset;
  if (!DecodeLoadD(pc, &dst, &base, &offset)) {
    return false;
  }

  if (base == PP) {
    if (!Utils::IsAligned(offset, kWordSize)) {
      return false;
    }
    const intptr_t index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
    return ObjectAtPoolIndex(code, index, obj);
  }

  if (base == THR) {
    return Thread::ObjectAtOffset(offset, obj);
  }

  return false;
}

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  ASSERT(LoadUnaligned(reinterpret_cast<uint32_t*>(pc - kInstrSize)) ==
         kIndirectCallInstruction);

  Register dst;
  Register base;
  intptr_t offset;
  ASSERT(DecodeLoadD(pc - (2 * kInstrSize), &dst, &base, &offset));
  ASSERT(dst == RA);

  Register reg;
  InstructionPattern::DecodeLoadWordFromPool(pc - (2 * kInstrSize), &reg,
                                             &target_code_pool_index_);
  ASSERT(reg == base);
}

CodePtr CallPattern::TargetCode() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt<std::memory_order_acquire>(
      target_code_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt<std::memory_order_release>(target_code_pool_index_,
                                                      target);
}

ICCallPattern::ICCallPattern(uword pc, const Code& caller_code)
    : object_pool_(ObjectPool::Handle(caller_code.GetObjectPool())),
      target_pool_index_(-1),
      data_pool_index_(-1) {
  ASSERT(caller_code.ContainsInstructionAt(pc));
  ASSERT(LoadUnaligned(reinterpret_cast<uint32_t*>(pc - kInstrSize)) ==
         kIndirectCallInstruction);

  Register dst;
  Register base;
  intptr_t offset;
  ASSERT(DecodeLoadD(pc - (2 * kInstrSize), &dst, &base, &offset));
  ASSERT(dst == RA);

  Register reg;
  uword target_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - (2 * kInstrSize), &reg, &data_pool_index_);
  ASSERT(reg == IC_DATA_REG);

  InstructionPattern::DecodeLoadWordFromPool(target_load_end, &reg,
                                             &target_pool_index_);
  ASSERT(reg == base);
}

ObjectPtr ICCallPattern::Data() const {
  return object_pool_.ObjectAt<std::memory_order_acquire>(data_pool_index_);
}

void ICCallPattern::SetData(const Object& data) const {
  ASSERT(data.IsArray() || data.IsICData() || data.IsMegamorphicCache());
  object_pool_.SetObjectAt<std::memory_order_release>(data_pool_index_, data);
}

CodePtr ICCallPattern::TargetCode() const {
  return static_cast<CodePtr>(
      object_pool_.ObjectAt<std::memory_order_acquire>(target_pool_index_));
}

void ICCallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt<std::memory_order_release>(target_pool_index_,
                                                      target);
}

NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      native_function_pool_index_(-1),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  ASSERT(LoadUnaligned(reinterpret_cast<uint32_t*>(pc - kInstrSize)) ==
         kIndirectCallInstruction);

  Register dst;
  Register base;
  intptr_t offset;
  ASSERT(DecodeLoadD(pc - (2 * kInstrSize), &dst, &base, &offset));
  ASSERT(dst == RA);

  Register reg;
  uword native_function_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - (2 * kInstrSize), &reg, &target_code_pool_index_);
  ASSERT(reg == base);

  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end, &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == T5);
}

CodePtr NativeCallPattern::target() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt<std::memory_order_acquire>(
      target_code_pool_index_));
}

void NativeCallPattern::set_target(const Code& target) const {
  object_pool_.SetObjectAt<std::memory_order_release>(target_code_pool_index_,
                                                      target);
}

NativeFunction NativeCallPattern::native_function() const {
  return reinterpret_cast<NativeFunction>(
      object_pool_.RawValueAt(native_function_pool_index_));
}

void NativeCallPattern::set_native_function(NativeFunction target) const {
  object_pool_.SetRawValueAt<std::memory_order_relaxed>(
      native_function_pool_index_, reinterpret_cast<uword>(target));
}

SwitchableCallPatternBase::SwitchableCallPatternBase(
    const ObjectPool& object_pool)
    : object_pool_(object_pool), data_pool_index_(-1), target_pool_index_(-1) {}

ObjectPtr SwitchableCallPatternBase::data() const {
  return object_pool_.ObjectAt<std::memory_order_acquire>(data_pool_index_);
}

void SwitchableCallPatternBase::SetDataRelease(const Object& data) const {
  ASSERT(!Object::Handle(object_pool_.ObjectAt<std::memory_order_relaxed>(
                             data_pool_index_))
              .IsCode());
  object_pool_.SetObjectAt<std::memory_order_release>(data_pool_index_, data);
}

SwitchableCallPattern::SwitchableCallPattern(uword pc, const Code& code)
    : SwitchableCallPatternBase(ObjectPool::Handle(code.GetObjectPool())) {
  ASSERT(code.ContainsInstructionAt(pc));
  ASSERT(LoadUnaligned(reinterpret_cast<uint32_t*>(pc - kInstrSize)) ==
         kIndirectCallInstruction);

  Register dst;
  Register base;
  intptr_t offset;
  ASSERT(DecodeLoadD(pc - (2 * kInstrSize), &dst, &base, &offset));
  ASSERT(dst == RA);

  Register reg;
  uword target_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - (2 * kInstrSize), &reg, &data_pool_index_);
  ASSERT(reg == IC_DATA_REG);

  InstructionPattern::DecodeLoadWordFromPool(target_load_end, &reg,
                                             &target_pool_index_);
  ASSERT(reg == CODE_REG);
  ASSERT(base == CODE_REG);
}

ObjectPtr SwitchableCallPattern::target() const {
  return object_pool_.ObjectAt<std::memory_order_acquire>(target_pool_index_);
}

void SwitchableCallPattern::SetTargetRelease(const Code& target) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt<std::memory_order_relaxed>(
                            target_pool_index_))
             .IsCode());
  object_pool_.SetObjectAt<std::memory_order_release>(target_pool_index_,
                                                      target);
}

BareSwitchableCallPattern::BareSwitchableCallPattern(uword pc)
    : SwitchableCallPatternBase(ObjectPool::Handle(
          IsolateGroup::Current()->object_store()->global_object_pool())) {
  ASSERT(LoadUnaligned(reinterpret_cast<uint32_t*>(pc - kInstrSize)) ==
         kIndirectCallInstruction);

  Register reg;
  uword target_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - kInstrSize, &reg, &data_pool_index_);
  ASSERT(reg == IC_DATA_REG);

  InstructionPattern::DecodeLoadWordFromPool(target_load_end, &reg,
                                             &target_pool_index_);
  ASSERT(reg == RA);
}

uword BareSwitchableCallPattern::target_entry() const {
  return object_pool_.RawValueAt<std::memory_order_relaxed>(target_pool_index_);
}

void BareSwitchableCallPattern::SetTargetRelease(const Code& target) const {
  ASSERT(object_pool_.TypeAt(target_pool_index_) ==
         ObjectPool::EntryType::kImmediate);
  object_pool_.SetRawValueAt<std::memory_order_release>(
      target_pool_index_, target.MonomorphicEntryPoint());
}

ReturnPattern::ReturnPattern(uword pc) : pc_(pc) {}

bool ReturnPattern::IsValid() const {
  return LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)) == kRetInstruction;
}

int32_t PcRelativePatternBase::distance() {
  return DecodeBranchOffset(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
}

void PcRelativePatternBase::set_distance(int32_t distance) {
  uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(pc_));
  ASSERT(IsValid());
  instr = (instr & kBranchOpcodeMask) | EncodeBranchOffset(distance);
  StoreUnaligned(reinterpret_cast<uint32_t*>(pc_), instr);
}

bool PcRelativePatternBase::IsValid() const {
  const uint32_t instr = LoadUnaligned(reinterpret_cast<uint32_t*>(pc_));
  return IsBranchOpcode(instr, kBranch) || IsBranchOpcode(instr, kBranchLink);
}

bool PcRelativeCallPattern::IsValid() const {
  return IsBranchOpcode(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)),
                        kBranchLink);
}

bool PcRelativeTailCallPattern::IsValid() const {
  return IsBranchOpcode(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)),
                        kBranch);
}

void PcRelativeTrampolineJumpPattern::Initialize() {
  StoreUnaligned(reinterpret_cast<uint32_t*>(pc_), kBranch);
}

intptr_t TypeTestingStubCallPattern::GetSubtypeTestCachePoolIndex() {
  // Calls to the type testing stubs look like:
  //   ld.d TypeTestABI::kSubtypeTestCacheReg, PP, ...
  //   jirl RA, TTSInternalRegs::kScratchReg, 0
  // or in precompiled code:
  //   ld.d TypeTestABI::kSubtypeTestCacheReg, PP, ...
  //   bl pc+<offset>
  const uword call_pc = pc_ - kInstrSize;
  const uint32_t indirect_call =
      kJirl | (static_cast<uint32_t>(TTSInternalRegs::kScratchReg) << 5) | RA;
  if (LoadUnaligned(reinterpret_cast<uint32_t*>(call_pc)) != indirect_call) {
    PcRelativeCallPattern pattern(call_pc);
    RELEASE_ASSERT(pattern.IsValid());
  }

  Register reg;
  intptr_t pool_index = -1;
  InstructionPattern::DecodeLoadWordFromPool(call_pc, &reg, &pool_index);
  ASSERT(reg == TypeTestABI::kSubtypeTestCacheReg);
  return pool_index;
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_LOONG64)
