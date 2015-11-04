// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/constants_mips.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      ic_data_load_end_(0),
      target_code_pool_index_(-1),
      ic_data_(ICData::Handle()) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: jalr RA, T9(=R25).
  ASSERT(*(reinterpret_cast<uword*>(end_) - 2) == 0x0320f809);
  Register reg;
  // The end of the pattern is the instruction after the delay slot of the jalr.
  ic_data_load_end_ =
      InstructionPattern::DecodeLoadWordFromPool(end_ - (3 * Instr::kInstrSize),
                                                 &reg,
                                                 &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
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
  if (instr->OpcodeField() == LW) {
    intptr_t index = 0;
    start = DecodeLoadWordFromPool(end, reg, &index);
    *obj = object_pool.ObjectAt(index);
  } else {
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
  // The pattern is a fixed size, but match backwards for uniformity with
  // DecodeLoadWordFromPool.
  uword start = end - Instr::kInstrSize;
  Instr* instr = Instr::At(start);
  intptr_t imm = 0;
  ASSERT(instr->OpcodeField() == ORI);
  imm = instr->UImmField();
  *reg = instr->RtField();

  start -= Instr::kInstrSize;
  instr = Instr::At(start);
  ASSERT(instr->OpcodeField() == LUI);
  ASSERT(instr->RtField() == *reg);
  imm |= (instr->UImmField() << 16);
  *value = imm;
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
  uword start = end - Instr::kInstrSize;
  Instr* instr = Instr::At(start);
  intptr_t offset = 0;
  if ((instr->OpcodeField() == LW) && (instr->RsField() == PP)) {
    offset = instr->SImmField();
    *reg = instr->RtField();
  } else {
    ASSERT(instr->OpcodeField() == LW);
    offset = instr->SImmField();
    *reg = instr->RtField();

    start -= Instr::kInstrSize;
    instr = Instr::At(start);
    ASSERT(instr->OpcodeField() == SPECIAL);
    ASSERT(instr->FunctionField() == ADDU);
    ASSERT(instr->RdField() == *reg);
    ASSERT(instr->RsField() == *reg);
    ASSERT(instr->RtField() == PP);

    start -= Instr::kInstrSize;
    instr = Instr::At(start);
    ASSERT(instr->OpcodeField() == LUI);
    ASSERT(instr->RtField() == *reg);
    // Offset is signed, so add the upper 16 bits.
    offset += (instr->UImmField() << 16);
  }
  *index = ObjectPool::IndexFromOffset(offset);
  return start;
}


RawICData* CallPattern::IcData() {
  if (ic_data_.IsNull()) {
    Register reg;
    InstructionPattern::DecodeLoadObject(ic_data_load_end_,
                                         object_pool_,
                                         &reg,
                                         &ic_data_);
    ASSERT(reg == S5);
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


NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: jalr RA, T9(=R25).
  ASSERT(*(reinterpret_cast<uword*>(end_) - 2) == 0x0320f809);

  Register reg;
  uword native_function_load_end =
      InstructionPattern::DecodeLoadWordFromPool(end_ - 3 * Instr::kInstrSize,
                                                 &reg,
                                                 &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end,
                                             &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == T5);
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


void CallPattern::InsertDeoptCallAt(uword pc, uword target_address) {
  Instr* lui = Instr::At(pc + (0 * Instr::kInstrSize));
  Instr* ori = Instr::At(pc + (1 * Instr::kInstrSize));
  Instr* jr = Instr::At(pc + (2 * Instr::kInstrSize));
  Instr* nop = Instr::At(pc + (3 * Instr::kInstrSize));
  uint16_t target_lo = target_address & 0xffff;
  uint16_t target_hi = target_address >> 16;

  lui->SetImmInstrBits(LUI, ZR, T9, target_hi);
  ori->SetImmInstrBits(ORI, T9, T9, target_lo);
  jr->SetSpecialInstrBits(JALR, T9, ZR, RA);
  nop->SetInstructionBits(Instr::kNopInstruction);

  ASSERT(kDeoptCallLengthInBytes == 4 * Instr::kInstrSize);
  CPU::FlushICache(pc, kDeoptCallLengthInBytes);
}


SwitchableCallPattern::SwitchableCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      cache_pool_index_(-1),
      stub_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: jalr t1.
  ASSERT(*(reinterpret_cast<uword*>(pc) - 1) == 0);  // Delay slot.
  ASSERT(*(reinterpret_cast<uword*>(pc) - 2) == 0x0120f809);

  Register reg;
  uword stub_load_end =
      InstructionPattern::DecodeLoadWordFromPool(pc - 5 * Instr::kInstrSize,
                                                 &reg,
                                                 &stub_pool_index_);
  ASSERT(reg == CODE_REG);
  InstructionPattern::DecodeLoadWordFromPool(stub_load_end,
                                             &reg,
                                             &cache_pool_index_);
  ASSERT(reg == S5);
}


RawObject* SwitchableCallPattern::cache() const {
  return reinterpret_cast<RawCode*>(
      object_pool_.ObjectAt(cache_pool_index_));
}


void SwitchableCallPattern::SetCache(const MegamorphicCache& cache) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt(cache_pool_index_)).IsICData());
  object_pool_.SetObjectAt(cache_pool_index_, cache);
}


void SwitchableCallPattern::SetLookupStub(const Code& lookup_stub) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt(stub_pool_index_)).IsCode());
  object_pool_.SetObjectAt(stub_pool_index_, lookup_stub);
}


ReturnPattern::ReturnPattern(uword pc)
    : pc_(pc) {
}


bool ReturnPattern::IsValid() const {
  Instr* jr = Instr::At(pc_);
  return (jr->OpcodeField() == SPECIAL) &&
         (jr->FunctionField() == JR) &&
         (jr->RsField() == RA);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
