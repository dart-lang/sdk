// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/instructions.h"
#include "vm/instructions_arm64.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/constants_arm64.h"
#include "vm/cpu.h"
#include "vm/object.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      ic_data_load_end_(0),
      target_code_pool_index_(-1),
      ic_data_(ICData::Handle()) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr ip0.
  ASSERT(*(reinterpret_cast<uint32_t*>(end_) - 1) == 0xd63f0200);

  Register reg;
  ic_data_load_end_ = InstructionPattern::DecodeLoadWordFromPool(
      end_ - 2 * Instr::kInstrSize, &reg, &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
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

RawCode* NativeCallPattern::target() const {
  return reinterpret_cast<RawCode*>(
      object_pool_.ObjectAt(target_code_pool_index_));
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

intptr_t InstructionPattern::OffsetFromPPIndex(intptr_t index) {
  return Array::element_offset(index);
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
    *obj = reinterpret_cast<RawObject*>(value);
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

// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the index in the pool being read from in the output parameters 'reg'
// and 'index' respectively.
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

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));

  Instr* instr = Instr::At(pc);
  if (instr->IsLoadStoreRegOp() && (instr->Bit(22) == 1) &&
      (instr->Bits(30, 2) == 3) && instr->Bit(24) == 1) {
    intptr_t offset = (instr->Imm12Field() << 3);
    if (instr->RnField() == PP) {
      // PP is untagged on ARM64.
      ASSERT(Utils::IsAligned(offset, 8));
      intptr_t index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
      const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
      if (pool.InfoAt(index) == ObjectPool::kTaggedObject) {
        *obj = pool.ObjectAt(index);
        return true;
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

RawICData* CallPattern::IcData() {
  if (ic_data_.IsNull()) {
    Register reg;
    InstructionPattern::DecodeLoadObject(ic_data_load_end_, object_pool_, &reg,
                                         &ic_data_);
    ASSERT(reg == R5);
  }
  return ic_data_.raw();
}

RawCode* CallPattern::TargetCode() const {
  return reinterpret_cast<RawCode*>(
      object_pool_.ObjectAt(target_code_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt(target_code_pool_index_, target);
  // No need to flush the instruction cache, since the code is not modified.
}

SwitchableCallPattern::SwitchableCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      data_pool_index_(-1),
      target_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blr ip0.
  ASSERT(*(reinterpret_cast<uint32_t*>(pc) - 1) == 0xd63f0200);

  Register reg;
  uword data_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - Instr::kInstrSize, &reg, &data_pool_index_);
  ASSERT(reg == R5);
  InstructionPattern::DecodeLoadWordFromPool(data_load_end - Instr::kInstrSize,
                                             &reg, &target_pool_index_);
  ASSERT(reg == CODE_REG);
}

RawObject* SwitchableCallPattern::data() const {
  return object_pool_.ObjectAt(data_pool_index_);
}

RawCode* SwitchableCallPattern::target() const {
  return reinterpret_cast<RawCode*>(object_pool_.ObjectAt(target_pool_index_));
}

void SwitchableCallPattern::SetData(const Object& data) const {
  ASSERT(!Object::Handle(object_pool_.ObjectAt(data_pool_index_)).IsCode());
  object_pool_.SetObjectAt(data_pool_index_, data);
}

void SwitchableCallPattern::SetTarget(const Code& target) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt(target_pool_index_)).IsCode());
  object_pool_.SetObjectAt(target_pool_index_, target);
}

ReturnPattern::ReturnPattern(uword pc) : pc_(pc) {}

bool ReturnPattern::IsValid() const {
  Instr* bx_lr = Instr::At(pc_);
  const Register crn = ConcreteRegister(LR);
  const int32_t instruction = RET | (static_cast<int32_t>(crn) << kRnShift);
  return bx_lr->InstructionBits() == instruction;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
