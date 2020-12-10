// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/instructions.h"
#include "vm/instructions_arm64.h"

#include "vm/constants.h"
#include "vm/cpu.h"
#include "vm/object.h"
#include "vm/reverse_pc_lookup_cache.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr ip0.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xd63f0200);

  Register reg;
  InstructionPattern::DecodeLoadWordFromPool(pc - 2 * Instr::kInstrSize, &reg,
                                             &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
}

ICCallPattern::ICCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      target_pool_index_(-1),
      data_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xd63f03c0);

  Register data_reg, code_reg;
  intptr_t pool_index;
  InstructionPattern::DecodeLoadDoubleWordFromPool(
      pc - 2 * Instr::kInstrSize, &data_reg, &code_reg, &pool_index);
  ASSERT(data_reg == R5);
  ASSERT(code_reg == CODE_REG);

  data_pool_index_ = pool_index;
  target_pool_index_ = pool_index + 1;
}

NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr ip0.
  ASSERT(*(reinterpret_cast<uint32_t*>(end_) - 1) == 0xd63f0200);

  Register reg;
  uword native_function_load_end = InstructionPattern::DecodeLoadWordFromPool(
      end_ - 2 * Instr::kInstrSize, &reg, &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end, &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == R5);
}

CodePtr NativeCallPattern::target() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_code_pool_index_));
}

void NativeCallPattern::set_target(const Code& target) const {
  object_pool_.SetObjectAt(target_code_pool_index_, target);
  // No need to flush the instruction cache, since the code is not modified.
}

NativeFunction NativeCallPattern::native_function() const {
  return reinterpret_cast<NativeFunction>(
      object_pool_.RawValueAt(native_function_pool_index_));
}

void NativeCallPattern::set_native_function(NativeFunction func) const {
  object_pool_.SetRawValueAt(native_function_pool_index_,
                             reinterpret_cast<uword>(func));
}

// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded object in the output parameters 'reg' and 'obj'
// respectively.
uword InstructionPattern::DecodeLoadObject(uword end,
                                           const ObjectPool& object_pool,
                                           Register* reg,
                                           Object* obj) {
  // 1. LoadWordFromPool
  // or
  // 2. LoadDecodableImmediate
  uword start = 0;
  Instr* instr = Instr::At(end - Instr::kInstrSize);
  if (instr->IsLoadStoreRegOp()) {
    // Case 1.
    intptr_t index = 0;
    start = DecodeLoadWordFromPool(end, reg, &index);
    *obj = object_pool.ObjectAt(index);
  } else {
    // Case 2.
    intptr_t value = 0;
    start = DecodeLoadWordImmediate(end, reg, &value);
    *obj = static_cast<ObjectPtr>(value);
  }
  return start;
}

// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded immediate value in the output parameters 'reg' and 'value'
// respectively.
uword InstructionPattern::DecodeLoadWordImmediate(uword end,
                                                  Register* reg,
                                                  intptr_t* value) {
  // 1. LoadWordFromPool
  // or
  // 2. LoadWordFromPool
  //    orri
  // or
  // 3. LoadPatchableImmediate
  uword start = end - Instr::kInstrSize;
  Instr* instr = Instr::At(start);
  bool odd = false;

  // Case 2.
  if (instr->IsLogicalImmOp()) {
    ASSERT(instr->Bit(29) == 1);
    odd = true;
    // end points at orri so that we can pass it to DecodeLoadWordFromPool.
    end = start;
    start -= Instr::kInstrSize;
    instr = Instr::At(start);
    // Case 2 falls through to case 1.
  }

  // Case 1.
  if (instr->IsLoadStoreRegOp()) {
    start = DecodeLoadWordFromPool(end, reg, value);
    if (odd) {
      *value |= 1;
    }
    return start;
  }

  // Case 3.
  // movk dst, imm3, 3; movk dst, imm2, 2; movk dst, imm1, 1; movz dst, imm0, 0
  ASSERT(instr->IsMoveWideOp());
  ASSERT(instr->Bits(29, 2) == 3);
  ASSERT(instr->HWField() == 3);  // movk dst, imm3, 3
  *reg = instr->RdField();
  *value = static_cast<int64_t>(instr->Imm16Field()) << 48;

  start -= Instr::kInstrSize;
  instr = Instr::At(start);
  ASSERT(instr->IsMoveWideOp());
  ASSERT(instr->Bits(29, 2) == 3);
  ASSERT(instr->HWField() == 2);  // movk dst, imm2, 2
  ASSERT(instr->RdField() == *reg);
  *value |= static_cast<int64_t>(instr->Imm16Field()) << 32;

  start -= Instr::kInstrSize;
  instr = Instr::At(start);
  ASSERT(instr->IsMoveWideOp());
  ASSERT(instr->Bits(29, 2) == 3);
  ASSERT(instr->HWField() == 1);  // movk dst, imm1, 1
  ASSERT(instr->RdField() == *reg);
  *value |= static_cast<int64_t>(instr->Imm16Field()) << 16;

  start -= Instr::kInstrSize;
  instr = Instr::At(start);
  ASSERT(instr->IsMoveWideOp());
  ASSERT(instr->Bits(29, 2) == 2);
  ASSERT(instr->HWField() == 0);  // movz dst, imm0, 0
  ASSERT(instr->RdField() == *reg);
  *value |= static_cast<int64_t>(instr->Imm16Field());

  return start;
}

// See comment in instructions_arm64.h
uword InstructionPattern::DecodeLoadWordFromPool(uword end,
                                                 Register* reg,
                                                 intptr_t* index) {
  // 1. ldr dst, [pp, offset]
  // or
  // 2. add dst, pp, #offset_hi12
  //    ldr dst [dst, #offset_lo12]
  // or
  // 3. movz dst, low_offset, 0
  //    movk dst, hi_offset, 1 (optional)
  //    ldr dst, [pp, dst]
  uword start = end - Instr::kInstrSize;
  Instr* instr = Instr::At(start);
  intptr_t offset = 0;

  // Last instruction is always an ldr into a 64-bit X register.
  ASSERT(instr->IsLoadStoreRegOp() && (instr->Bit(22) == 1) &&
         (instr->Bits(30, 2) == 3));

  // Grab the destination register from the ldr instruction.
  *reg = instr->RtField();

  if (instr->Bit(24) == 1) {
    // base + scaled unsigned 12-bit immediate offset.
    // Case 1.
    offset |= (instr->Imm12Field() << 3);
    if (instr->RnField() == *reg) {
      start -= Instr::kInstrSize;
      instr = Instr::At(start);
      ASSERT(instr->IsAddSubImmOp());
      ASSERT(instr->RnField() == PP);
      ASSERT(instr->RdField() == *reg);
      offset |= (instr->Imm12Field() << 12);
    }
  } else {
    ASSERT(instr->Bits(10, 2) == 2);
    // We have to look at the preceding one or two instructions to find the
    // offset.

    start -= Instr::kInstrSize;
    instr = Instr::At(start);
    ASSERT(instr->IsMoveWideOp());
    ASSERT(instr->RdField() == *reg);
    if (instr->Bits(29, 2) == 2) {  // movz dst, low_offset, 0
      ASSERT(instr->HWField() == 0);
      offset = instr->Imm16Field();
      // no high offset.
    } else {
      ASSERT(instr->Bits(29, 2) == 3);  // movk dst, high_offset, 1
      ASSERT(instr->HWField() == 1);
      offset = instr->Imm16Field() << 16;

      start -= Instr::kInstrSize;
      instr = Instr::At(start);
      ASSERT(instr->IsMoveWideOp());
      ASSERT(instr->RdField() == *reg);
      ASSERT(instr->Bits(29, 2) == 2);  // movz dst, low_offset, 0
      ASSERT(instr->HWField() == 0);
      offset |= instr->Imm16Field();
    }
  }
  // PP is untagged on ARM64.
  ASSERT(Utils::IsAligned(offset, 8));
  *index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
  return start;
}

// See comment in instructions_arm64.h
uword InstructionPattern::DecodeLoadDoubleWordFromPool(uword end,
                                                       Register* reg1,
                                                       Register* reg2,
                                                       intptr_t* index) {
  // Cases:
  //
  //   1. ldp reg1, reg2, [pp, offset]
  //
  //   2. add tmp, pp, #upper12
  //      ldp reg1, reg2, [tmp, #lower12]
  //
  //   3. add tmp, pp, #upper12
  //      add tmp, tmp, #lower12
  //      ldp reg1, reg2, [tmp, 0]
  //
  // Note that the pp register is untagged!
  //
  uword start = end - Instr::kInstrSize;
  Instr* ldr_instr = Instr::At(start);

  // Last instruction is always an ldp into two 64-bit X registers.
  ASSERT(ldr_instr->IsLoadStoreRegPairOp() && (ldr_instr->Bit(22) == 1));

  // Grab the destination register from the ldp instruction.
  *reg1 = ldr_instr->RtField();
  *reg2 = ldr_instr->Rt2Field();

  Register base_reg = ldr_instr->RnField();
  const int base_offset = 8 * ldr_instr->Imm7Field();

  intptr_t pool_offset = 0;
  if (base_reg == PP) {
    // Case 1.
    pool_offset = base_offset;
  } else {
    // Case 2 & 3.
    ASSERT(base_reg == TMP);

    pool_offset = base_offset;

    start -= Instr::kInstrSize;
    Instr* add_instr = Instr::At(start);
    ASSERT(add_instr->IsAddSubImmOp());
    ASSERT(add_instr->RdField() == TMP);

    const auto shift = add_instr->Imm12ShiftField();
    ASSERT(shift == 0 || shift == 1);
    pool_offset += (add_instr->Imm12Field() << (shift == 1 ? 12 : 0));

    if (add_instr->RnField() == TMP) {
      start -= Instr::kInstrSize;
      Instr* prev_add_instr = Instr::At(start);
      ASSERT(prev_add_instr->IsAddSubImmOp());
      ASSERT(prev_add_instr->RnField() == PP);

      const auto shift = prev_add_instr->Imm12ShiftField();
      ASSERT(shift == 0 || shift == 1);
      pool_offset += (prev_add_instr->Imm12Field() << (shift == 1 ? 12 : 0));
    } else {
      ASSERT(add_instr->RnField() == PP);
    }
  }
  *index = ObjectPool::IndexFromOffset(pool_offset - kHeapObjectTag);
  return start;
}

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));

  Instr* instr = Instr::At(pc);
  if (instr->IsLoadStoreRegOp() && (instr->Bit(22) == 1) &&
      (instr->Bits(30, 2) == 3) && instr->Bit(24) == 1) {
    intptr_t offset = (instr->Imm12Field() << 3);
    if (instr->RnField() == PP) {
      // PP is untagged on ARM64.
      ASSERT(Utils::IsAligned(offset, 8));
      // A code object may have an object pool attached in bare instructions
      // mode if the v8 snapshot profile writer is active, but this pool cannot
      // be used for object loading.
      if (FLAG_use_bare_instructions) return false;
      intptr_t index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
      const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
      if (!pool.IsNull()) {
        if (pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject) {
          *obj = pool.ObjectAt(index);
          return true;
        }
      }
    } else if (instr->RnField() == THR) {
      return Thread::ObjectAtOffset(offset, obj);
    }
  }
  // TODO(rmacnak): Loads with offsets beyond 12 bits.

  return false;
}

// Encodes a load sequence ending at 'end'. Encodes a fixed length two
// instruction load from the pool pointer in PP using the destination
// register reg as a temporary for the base address.
// Assumes that the location has already been validated for patching.
void InstructionPattern::EncodeLoadWordFromPoolFixed(uword end,
                                                     int32_t offset) {
  uword start = end - Instr::kInstrSize;
  Instr* instr = Instr::At(start);
  const int32_t upper12 = offset & 0x00fff000;
  const int32_t lower12 = offset & 0x00000fff;
  ASSERT((offset & 0xff000000) == 0);        // Can't encode > 24 bits.
  ASSERT(((lower12 >> 3) << 3) == lower12);  // 8-byte aligned.
  instr->SetImm12Bits(instr->InstructionBits(), lower12 >> 3);

  start -= Instr::kInstrSize;
  instr = Instr::At(start);
  instr->SetImm12Bits(instr->InstructionBits(), upper12 >> 12);
  instr->SetInstructionBits(instr->InstructionBits() | B22);
}

CodePtr CallPattern::TargetCode() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_code_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt(target_code_pool_index_, target);
  // No need to flush the instruction cache, since the code is not modified.
}

ObjectPtr ICCallPattern::Data() const {
  return object_pool_.ObjectAt(data_pool_index_);
}

void ICCallPattern::SetData(const Object& data) const {
  ASSERT(data.IsArray() || data.IsICData() || data.IsMegamorphicCache());
  object_pool_.SetObjectAt(data_pool_index_, data);
}

CodePtr ICCallPattern::TargetCode() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_pool_index_));
}

void ICCallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt(target_pool_index_, target);
  // No need to flush the instruction cache, since the code is not modified.
}

SwitchableCallPatternBase::SwitchableCallPatternBase(const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      data_pool_index_(-1),
      target_pool_index_(-1) {}

ObjectPtr SwitchableCallPatternBase::data() const {
  return object_pool_.ObjectAt(data_pool_index_);
}

void SwitchableCallPatternBase::SetData(const Object& data) const {
  ASSERT(!Object::Handle(object_pool_.ObjectAt(data_pool_index_)).IsCode());
  object_pool_.SetObjectAt(data_pool_index_, data);
}

SwitchableCallPattern::SwitchableCallPattern(uword pc, const Code& code)
    : SwitchableCallPatternBase(code) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xd63f03c0);

  Register ic_data_reg, code_reg;
  intptr_t pool_index;
  InstructionPattern::DecodeLoadDoubleWordFromPool(
      pc - 2 * Instr::kInstrSize, &ic_data_reg, &code_reg, &pool_index);
  ASSERT(ic_data_reg == R5);
  ASSERT(code_reg == CODE_REG);

  data_pool_index_ = pool_index;
  target_pool_index_ = pool_index + 1;
}

CodePtr SwitchableCallPattern::target() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_pool_index_));
}

void SwitchableCallPattern::SetTarget(const Code& target) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt(target_pool_index_)).IsCode());
  object_pool_.SetObjectAt(target_pool_index_, target);
}

BareSwitchableCallPattern::BareSwitchableCallPattern(uword pc, const Code& code)
    : SwitchableCallPatternBase(code) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xd63f03c0);

  Register ic_data_reg, code_reg;
  intptr_t pool_index;
  InstructionPattern::DecodeLoadDoubleWordFromPool(
      pc - Instr::kInstrSize, &ic_data_reg, &code_reg, &pool_index);
  ASSERT(ic_data_reg == R5);
  ASSERT(code_reg == LINK_REGISTER);

  data_pool_index_ = pool_index;
  target_pool_index_ = pool_index + 1;
}

CodePtr BareSwitchableCallPattern::target() const {
  const uword pc = object_pool_.RawValueAt(target_pool_index_);
  CodePtr result = ReversePc::Lookup(IsolateGroup::Current(), pc);
  if (result != Code::null()) {
    return result;
  }
  result = ReversePc::Lookup(Dart::vm_isolate()->group(), pc);
  if (result != Code::null()) {
    return result;
  }
  UNREACHABLE();
}

void BareSwitchableCallPattern::SetTarget(const Code& target) const {
  ASSERT(object_pool_.TypeAt(target_pool_index_) ==
         ObjectPool::EntryType::kImmediate);
  object_pool_.SetRawValueAt(target_pool_index_,
                             target.MonomorphicEntryPoint());
}

ReturnPattern::ReturnPattern(uword pc) : pc_(pc) {}

bool ReturnPattern::IsValid() const {
  Instr* bx_lr = Instr::At(pc_);
  const Register crn = ConcreteRegister(LINK_REGISTER);
  const int32_t instruction = RET | (static_cast<int32_t>(crn) << kRnShift);
  return bx_lr->InstructionBits() == instruction;
}

bool PcRelativeCallPattern::IsValid() const {
  // bl <offset>
  const uint32_t word = *reinterpret_cast<uint32_t*>(pc_);
  const uint32_t branch_link = 0x25;
  return (word >> 26) == branch_link;
}

bool PcRelativeTailCallPattern::IsValid() const {
  // b <offset>
  const uint32_t word = *reinterpret_cast<uint32_t*>(pc_);
  const uint32_t branch_link = 0x5;
  return (word >> 26) == branch_link;
}

void PcRelativeTrampolineJumpPattern::Initialize() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t* pattern = reinterpret_cast<uint32_t*>(pattern_start_);
  pattern[0] = kAdrEncoding;
  pattern[1] = kMovzEncoding;
  pattern[2] = kAddTmpTmp2;
  pattern[3] = kJumpEncoding;
  set_distance(0);
#else
  UNREACHABLE();
#endif
}

int32_t PcRelativeTrampolineJumpPattern::distance() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t* pattern = reinterpret_cast<uint32_t*>(pattern_start_);
  const uint32_t adr = pattern[0];
  const uint32_t movz = pattern[1];
  const uint32_t lower16 =
      (((adr >> 5) & ((1 << 19) - 1)) << 2) | ((adr >> 29) & 0x3);
  const uint32_t higher16 = (movz >> kImm16Shift) & 0xffff;
  return (higher16 << 16) | lower16;
#else
  UNREACHABLE();
  return 0;
#endif
}

void PcRelativeTrampolineJumpPattern::set_distance(int32_t distance) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t* pattern = reinterpret_cast<uint32_t*>(pattern_start_);
  uint32_t low16 = distance & 0xffff;
  uint32_t high16 = (distance >> 16) & 0xffff;
  pattern[0] = kAdrEncoding | ((low16 & 0x3) << 29) | ((low16 >> 2) << 5);
  pattern[1] = kMovzEncoding | (high16 << kImm16Shift);
  ASSERT(IsValid());
#else
  UNREACHABLE();
#endif
}

bool PcRelativeTrampolineJumpPattern::IsValid() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const uint32_t adr_mask = (3 << 29) | (((1 << 19) - 1) << 5);
  const uint32_t movz_mask = 0xffff << 5;
  uint32_t* pattern = reinterpret_cast<uint32_t*>(pattern_start_);
  return ((pattern[0] & ~adr_mask) == kAdrEncoding) &&
         ((pattern[1] & ~movz_mask) == kMovzEncoding) &&
         (pattern[2] == kAddTmpTmp2) && (pattern[3] == kJumpEncoding);
#else
  UNREACHABLE();
  return false;
#endif
}

intptr_t TypeTestingStubCallPattern::GetSubtypeTestCachePoolIndex() {
  // Calls to the type testing stubs look like:
  //   ldr R9, ...
  //   ldr Rn, [PP+idx]
  //   blr R9
  // or
  //   ldr Rn, [PP+idx]
  //   blr pc+<offset>
  // where Rn = TypeTestABI::kSubtypeTestCacheReg.

  // Ensure the caller of the type testing stub (whose return address is [pc_])
  // branched via `blr R9` or a pc-relative call.
  uword pc = pc_ - Instr::kInstrSize;
  const uword blr_r9 = 0xd63f0120;
  if (*reinterpret_cast<uint32_t*>(pc) != blr_r9) {
    PcRelativeCallPattern pattern(pc);
    RELEASE_ASSERT(pattern.IsValid());
  }

  const uword load_instr_end = pc;

  Register reg;
  intptr_t pool_index = -1;
  InstructionPattern::DecodeLoadWordFromPool(load_instr_end, &reg, &pool_index);
  ASSERT_EQUAL(reg, TypeTestABI::kSubtypeTestCacheReg);
  return pool_index;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
