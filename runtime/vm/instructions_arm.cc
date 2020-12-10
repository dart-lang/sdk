// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/instructions.h"
#include "vm/instructions_arm.h"

#include "vm/constants.h"
#include "vm/cpu.h"
#include "vm/object.h"
#include "vm/reverse_pc_lookup_cache.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xe12fff3e);

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
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xe12fff3e);

  Register reg;
  uword data_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - 2 * Instr::kInstrSize, &reg, &target_pool_index_);
  ASSERT(reg == CODE_REG);

  InstructionPattern::DecodeLoadWordFromPool(data_load_end, &reg,
                                             &data_pool_index_);
  ASSERT(reg == R9);
}

NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(end_) - 1) == 0xe12fff3e);

  Register reg;
  uword native_function_load_end = InstructionPattern::DecodeLoadWordFromPool(
      end_ - 2 * Instr::kInstrSize, &reg, &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end, &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == R9);
}

CodePtr NativeCallPattern::target() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_code_pool_index_));
}

void NativeCallPattern::set_target(const Code& new_target) const {
  object_pool_.SetObjectAt(target_code_pool_index_, new_target);
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
  uword start = 0;
  Instr* instr = Instr::At(end - Instr::kInstrSize);
  if ((instr->InstructionBits() & 0xfff00000) == 0xe5900000) {
    // ldr reg, [reg, #+offset]
    intptr_t index = 0;
    start = DecodeLoadWordFromPool(end, reg, &index);
    *obj = object_pool.ObjectAt(index);
  } else {
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
  uword start = end - Instr::kInstrSize;
  int32_t instr = Instr::At(start)->InstructionBits();
  intptr_t imm = 0;
  if ((instr & 0xfff00000) == 0xe3400000) {  // movt reg, #imm_hi
    imm |= (instr & 0xf0000) << 12;
    imm |= (instr & 0xfff) << 16;
    start -= Instr::kInstrSize;
    instr = Instr::At(start)->InstructionBits();
  }
  ASSERT((instr & 0xfff00000) == 0xe3000000);  // movw reg, #imm_lo
  imm |= (instr & 0xf0000) >> 4;
  imm |= instr & 0xfff;
  *reg = static_cast<Register>((instr & 0xf000) >> 12);
  *value = imm;
  return start;
}

void InstructionPattern::EncodeLoadWordImmediate(uword end,
                                                 Register reg,
                                                 intptr_t value) {
  uint16_t low16 = value & 0xffff;
  uint16_t high16 = (value >> 16) & 0xffff;

  // movw reg, #imm_lo
  uint32_t movw_instr = 0xe3000000;
  movw_instr |= (low16 >> 12) << 16;
  movw_instr |= (reg << 12);
  movw_instr |= (low16 & 0xfff);

  // movt reg, #imm_hi
  uint32_t movt_instr = 0xe3400000;
  movt_instr |= (high16 >> 12) << 16;
  movt_instr |= (reg << 12);
  movt_instr |= (high16 & 0xfff);

  uint32_t* cursor = reinterpret_cast<uint32_t*>(end);
  *(--cursor) = movt_instr;
  *(--cursor) = movw_instr;

#if defined(DEBUG)
  Register decoded_reg;
  intptr_t decoded_value;
  DecodeLoadWordImmediate(end, &decoded_reg, &decoded_value);
  ASSERT(reg == decoded_reg);
  ASSERT(value == decoded_value);
#endif
}

static bool IsLoadWithOffset(int32_t instr,
                             Register base,
                             intptr_t* offset,
                             Register* dst) {
  if ((instr & 0xffff0000) == (0xe5900000 | (base << 16))) {
    // ldr reg, [base, #+offset]
    *offset = instr & 0xfff;
    *dst = static_cast<Register>((instr & 0xf000) >> 12);
    return true;
  }
  return false;
}

// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the index in the pool being read from in the output parameters 'reg'
// and 'index' respectively.
uword InstructionPattern::DecodeLoadWordFromPool(uword end,
                                                 Register* reg,
                                                 intptr_t* index) {
  uword start = end - Instr::kInstrSize;
  int32_t instr = Instr::At(start)->InstructionBits();
  intptr_t offset = 0;
  if (IsLoadWithOffset(instr, PP, &offset, reg)) {
    // ldr reg, [PP, #+offset]
  } else {
    ASSERT((instr & 0xfff00000) == 0xe5900000);  // ldr reg, [reg, #+offset]
    offset = instr & 0xfff;
    start -= Instr::kInstrSize;
    instr = Instr::At(start)->InstructionBits();
    if ((instr & 0xffff0000) == (0xe2850000 | (PP << 16))) {
      // add reg, pp, operand
      const intptr_t rot = (instr & 0xf00) >> 7;
      const intptr_t imm8 = instr & 0xff;
      offset += (imm8 >> rot) | (imm8 << (32 - rot));
      *reg = static_cast<Register>((instr & 0xf000) >> 12);
    } else {
      ASSERT((instr & 0xffff0000) == (0xe0800000 | (PP << 16)));
      // add reg, pp, reg
      intptr_t value = 0;
      start = DecodeLoadWordImmediate(start, reg, &value);
      offset += value;
    }
  }
  *index = ObjectPool::IndexFromOffset(offset);
  return start;
}

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));

  int32_t instr = Instr::At(pc)->InstructionBits();
  intptr_t offset;
  Register dst;
  if (IsLoadWithOffset(instr, PP, &offset, &dst)) {
    intptr_t index = ObjectPool::IndexFromOffset(offset);
    const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
    if (!pool.IsNull()) {
      if (pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject) {
        *obj = pool.ObjectAt(index);
        return true;
      }
    }
  } else if (IsLoadWithOffset(instr, THR, &offset, &dst)) {
    return Thread::ObjectAtOffset(offset, obj);
  }
  // TODO(rmacnak): Sequence for loads beyond 12 bits.

  return false;
}

CodePtr CallPattern::TargetCode() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_code_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target_code) const {
  object_pool_.SetObjectAt(target_code_pool_index_, target_code);
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

void ICCallPattern::SetTargetCode(const Code& target_code) const {
  object_pool_.SetObjectAt(target_pool_index_, target_code);
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
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xe12fff3e);

  Register reg;
  uword data_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - Instr::kInstrSize, &reg, &data_pool_index_);
  ASSERT(reg == R9);
  InstructionPattern::DecodeLoadWordFromPool(data_load_end - Instr::kInstrSize,
                                             &reg, &target_pool_index_);
  ASSERT(reg == CODE_REG);
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
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xe12fff3e);

  Register reg;
  uword data_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - Instr::kInstrSize, &reg, &data_pool_index_);
  ASSERT(reg == R9);

  InstructionPattern::DecodeLoadWordFromPool(data_load_end, &reg,
                                             &target_pool_index_);
  ASSERT(reg == LINK_REGISTER);
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
  const int32_t B4 = 1 << 4;
  const int32_t B21 = 1 << 21;
  const int32_t B24 = 1 << 24;
  int32_t instruction = (static_cast<int32_t>(AL) << kConditionShift) | B24 |
                        B21 | (0xfff << 8) | B4 |
                        (LINK_REGISTER.code << kRmShift);
  return bx_lr->InstructionBits() == instruction;
}

bool PcRelativeCallPattern::IsValid() const {
  // bl.<cond> <offset>
  const uint32_t word = *reinterpret_cast<uint32_t*>(pc_);
  const uint32_t branch = 0x05;
  const uword type = ((word >> kTypeShift) & ((1 << kTypeBits) - 1));
  const uword link = ((word >> kLinkShift) & ((1 << kLinkBits) - 1));
  return type == branch && link == 1;
}

bool PcRelativeTailCallPattern::IsValid() const {
  // b.<cond> <offset>
  const uint32_t word = *reinterpret_cast<uint32_t*>(pc_);
  const uint32_t branch = 0x05;
  const uword type = ((word >> kTypeShift) & ((1 << kTypeBits) - 1));
  const uword link = ((word >> kLinkShift) & ((1 << kLinkBits) - 1));
  return type == branch && link == 0;
}

void PcRelativeTrampolineJumpPattern::Initialize() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t* add_pc =
      reinterpret_cast<uint32_t*>(pattern_start_ + 2 * Instr::kInstrSize);
  *add_pc = kAddPcEncoding;
  set_distance(0);
#else
  UNREACHABLE();
#endif
}

int32_t PcRelativeTrampolineJumpPattern::distance() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const uword end = pattern_start_ + 2 * Instr::kInstrSize;
  Register reg;
  intptr_t value;
  InstructionPattern::DecodeLoadWordImmediate(end, &reg, &value);
  value -= kDistanceOffset;
  ASSERT(reg == TMP);
  return value;
#else
  UNREACHABLE();
  return 0;
#endif
}

void PcRelativeTrampolineJumpPattern::set_distance(int32_t distance) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const uword end = pattern_start_ + 2 * Instr::kInstrSize;
  InstructionPattern::EncodeLoadWordImmediate(end, TMP,
                                              distance + kDistanceOffset);
#else
  UNREACHABLE();
#endif
}

bool PcRelativeTrampolineJumpPattern::IsValid() const {
#if !defined(DART_PRECOMPILED_RUNTIME)
  const uword end = pattern_start_ + 2 * Instr::kInstrSize;
  Register reg;
  intptr_t value;
  InstructionPattern::DecodeLoadWordImmediate(end, &reg, &value);

  uint32_t* add_pc =
      reinterpret_cast<uint32_t*>(pattern_start_ + 2 * Instr::kInstrSize);

  return reg == TMP && *add_pc == kAddPcEncoding;
#else
  UNREACHABLE();
  return false;
#endif
}

intptr_t TypeTestingStubCallPattern::GetSubtypeTestCachePoolIndex() {
  // Calls to the type testing stubs look like:
  //   ldr R9, ...
  //   ldr Rn, [PP+idx]
  //   blx R9
  // or
  //   ldr Rn, [PP+idx]
  //   blx pc+<offset>
  // where Rn = TypeTestABI::kSubtypeTestCacheReg.

  // Ensure the caller of the type testing stub (whose return address is [pc_])
  // branched via `blx R9` or a pc-relative call.
  uword pc = pc_ - Instr::kInstrSize;
  const uint32_t blx_r9 = 0xe12fff39;
  if (*reinterpret_cast<uint32_t*>(pc) != blx_r9) {
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

#endif  // defined TARGET_ARCH_ARM
