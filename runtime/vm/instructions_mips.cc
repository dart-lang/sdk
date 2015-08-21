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
      target_address_pool_index_(-1),
      ic_data_(ICData::Handle()) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: jalr RA, T9(=R25).
  ASSERT(*(reinterpret_cast<uword*>(end_) - 2) == 0x0320f809);
  Register reg;
  // The end of the pattern is the instruction after the delay slot of the jalr.
  ic_data_load_end_ =
      InstructionPattern::DecodeLoadWordFromPool(end_ - (2 * Instr::kInstrSize),
                                                 &reg,
                                                 &target_address_pool_index_);
  ASSERT(reg == T9);
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


uword CallPattern::TargetAddress() const {
  return object_pool_.RawValueAt(target_address_pool_index_);
}


void CallPattern::SetTargetAddress(uword target_address) const {
  object_pool_.SetRawValueAt(target_address_pool_index_, target_address);
  // No need to flush the instruction cache, since the code is not modified.
}


NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_address_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: jalr RA, T9(=R25).
  ASSERT(*(reinterpret_cast<uword*>(end_) - 2) == 0x0320f809);

  Register reg;
  uword native_function_load_end =
      InstructionPattern::DecodeLoadWordFromPool(end_ - 2 * Instr::kInstrSize,
                                                 &reg,
                                                 &target_address_pool_index_);
  ASSERT(reg == T9);
  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end,
                                             &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == T5);
}


uword NativeCallPattern::target() const {
  return object_pool_.RawValueAt(target_address_pool_index_);
}


void NativeCallPattern::set_target(uword target_address) const {
  object_pool_.SetRawValueAt(target_address_pool_index_, target_address);
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


void CallPattern::InsertAt(uword pc, uword target_address) {
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

  ASSERT(kFixedLengthInBytes == 4 * Instr::kInstrSize);
  CPU::FlushICache(pc, kFixedLengthInBytes);
}


JumpPattern::JumpPattern(uword pc, const Code& code) : pc_(pc) { }


bool JumpPattern::IsValid() const {
  Instr* lui = Instr::At(pc_ + (0 * Instr::kInstrSize));
  Instr* ori = Instr::At(pc_ + (1 * Instr::kInstrSize));
  Instr* jr = Instr::At(pc_ + (2 * Instr::kInstrSize));
  Instr* nop = Instr::At(pc_ + (3 * Instr::kInstrSize));
  return (lui->OpcodeField() == LUI) &&
         (ori->OpcodeField() == ORI) &&
         (jr->OpcodeField() == SPECIAL) &&
         (jr->FunctionField() == JR) &&
         (nop->InstructionBits() == Instr::kNopInstruction);
}


uword JumpPattern::TargetAddress() const {
  Instr* lui = Instr::At(pc_ + (0 * Instr::kInstrSize));
  Instr* ori = Instr::At(pc_ + (1 * Instr::kInstrSize));
  const uint16_t target_lo = ori->UImmField();
  const uint16_t target_hi = lui->UImmField();
  return (target_hi << 16) | target_lo;
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  Instr* lui = Instr::At(pc_ + (0 * Instr::kInstrSize));
  Instr* ori = Instr::At(pc_ + (1 * Instr::kInstrSize));
  const int32_t lui_bits = lui->InstructionBits();
  const int32_t ori_bits = ori->InstructionBits();
  const uint16_t target_lo = target_address & 0xffff;
  const uint16_t target_hi = target_address >> 16;

  lui->SetInstructionBits((lui_bits & 0xffff0000) | target_hi);
  ori->SetInstructionBits((ori_bits & 0xffff0000) | target_lo);
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
