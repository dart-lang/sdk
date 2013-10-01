// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/constants_arm.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(Array::Handle(code.ObjectPool())),
      end_(pc),
      args_desc_load_end_(0),
      ic_data_load_end_(0),
      target_address_pool_index_(-1),
      args_desc_(Array::Handle()),
      ic_data_(ICData::Handle()) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uword*>(end_) - 1) == 0xe12fff3e);

  Register reg;
  ic_data_load_end_ =
      InstructionPattern::DecodeLoadWordFromPool(end_ - Instr::kInstrSize,
                                                 &reg,
                                                 &target_address_pool_index_);
  ASSERT(reg == LR);
}


// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded object in the output parameters 'reg' and 'obj'
// respectively.
uword InstructionPattern::DecodeLoadObject(uword end,
                                           const Array& object_pool,
                                           Register* reg,
                                           Object* obj) {
  uword start = 0;
  Instr* instr = Instr::At(end - Instr::kInstrSize);
  if ((instr->InstructionBits() & 0xfff00000) == 0xe5900000) {
    // ldr reg, [reg, #+offset]
    intptr_t index = 0;
    start = DecodeLoadWordFromPool(end, reg, &index);
    *obj = object_pool.At(index);
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
  if ((instr & 0xffff0000) == 0xe59a0000) {  // ldr reg, [pp, #+offset]
    offset = instr & 0xfff;
    *reg = static_cast<Register>((instr & 0xf000) >> 12);
  } else {
    ASSERT((instr & 0xfff00000) == 0xe5900000);  // ldr reg, [reg, #+offset]
    offset = instr & 0xfff;
    start -= Instr::kInstrSize;
    instr = Instr::At(start)->InstructionBits();
    if ((instr & 0xffff0000) == 0xe28a0000) {  // add reg, pp, shifter_op
      const intptr_t rot = (instr & 0xf00) >> 7;
      const intptr_t imm8 = instr & 0xff;
      offset += (imm8 >> rot) | (imm8 << (32 - rot));
      *reg = static_cast<Register>((instr & 0xf000) >> 12);
    } else {
      ASSERT((instr & 0xffff0000) == 0xe08a0000);  // add reg, pp, reg
      end = DecodeLoadWordImmediate(end, reg, &offset);
    }
  }
  offset += kHeapObjectTag;
  ASSERT(Utils::IsAligned(offset, 4));
  *index = (offset - Array::data_offset()) / 4;
  return start;
}


RawICData* CallPattern::IcData() {
  if (ic_data_.IsNull()) {
    Register reg;
    args_desc_load_end_ =
        InstructionPattern::DecodeLoadObject(ic_data_load_end_,
                                             object_pool_,
                                             &reg,
                                             &ic_data_);
    ASSERT(reg == R5);
  }
  return ic_data_.raw();
}


RawArray* CallPattern::ClosureArgumentsDescriptor() {
  if (args_desc_.IsNull()) {
    IcData();  // Loading of the ic_data must be decoded first, if not already.
    Register reg;
    InstructionPattern::DecodeLoadObject(args_desc_load_end_,
                                         object_pool_,
                                         &reg,
                                         &args_desc_);
    ASSERT(reg == R4);
  }
  return args_desc_.raw();
}


uword CallPattern::TargetAddress() const {
  ASSERT(target_address_pool_index_ >= 0);
  const Object& target_address =
      Object::Handle(object_pool_.At(target_address_pool_index_));
  ASSERT(target_address.IsSmi());
  // The address is stored in the object array as a RawSmi.
  return reinterpret_cast<uword>(target_address.raw());
}


void CallPattern::SetTargetAddress(uword target_address) const {
  ASSERT(Utils::IsAligned(target_address, 4));
  // The address is stored in the object array as a RawSmi.
  const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(target_address));
  object_pool_.SetAt(target_address_pool_index_, smi);
  // No need to flush the instruction cache, since the code is not modified.
}


void CallPattern::InsertAt(uword pc, uword target_address) {
  uint16_t target_lo = target_address & 0xffff;
  uint16_t target_hi = target_address >> 16;
  uword movw_ip = 0xe300c000 | ((target_lo >> 12) << 16) | (target_lo & 0xfff);
  uword movt_ip = 0xe340c000 | ((target_hi >> 12) << 16) | (target_hi & 0xfff);
  uword blx_ip = 0xe12fff3c;
  *reinterpret_cast<uword*>(pc + (0 * Instr::kInstrSize)) = movw_ip;
  *reinterpret_cast<uword*>(pc + (1 * Instr::kInstrSize)) = movt_ip;
  *reinterpret_cast<uword*>(pc + (2 * Instr::kInstrSize)) = blx_ip;
  ASSERT(kFixedLengthInBytes == 3 * Instr::kInstrSize);
  CPU::FlushICache(pc, kFixedLengthInBytes);
}


JumpPattern::JumpPattern(uword pc, const Code& code) : pc_(pc) { }


bool JumpPattern::IsValid() const {
  Instr* movw_ip = Instr::At(pc_ + (0 * Instr::kInstrSize));  // target_lo
  Instr* movt_ip = Instr::At(pc_ + (1 * Instr::kInstrSize));  // target_hi
  Instr* bx_ip = Instr::At(pc_ + (2 * Instr::kInstrSize));
  return (movw_ip->InstructionBits() & 0xfff0f000) == 0xe300c000 &&
         (movt_ip->InstructionBits() & 0xfff0f000) == 0xe340c000 &&
         (bx_ip->InstructionBits() & 0xffffffff) == 0xe12fff1c;
}


uword JumpPattern::TargetAddress() const {
  Instr* movw_ip = Instr::At(pc_ + (0 * Instr::kInstrSize));  // target_lo
  Instr* movt_ip = Instr::At(pc_ + (1 * Instr::kInstrSize));  // target_hi
  uint16_t target_lo = movw_ip->MovwField();
  uint16_t target_hi = movt_ip->MovwField();
  return (target_hi << 16) | target_lo;
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  uint16_t target_lo = target_address & 0xffff;
  uint16_t target_hi = target_address >> 16;
  uword movw_ip = 0xe300c000 | ((target_lo >> 12) << 16) | (target_lo & 0xfff);
  uword movt_ip = 0xe340c000 | ((target_hi >> 12) << 16) | (target_hi & 0xfff);
  *reinterpret_cast<uword*>(pc_ + (0 * Instr::kInstrSize)) = movw_ip;
  *reinterpret_cast<uword*>(pc_ + (1 * Instr::kInstrSize)) = movt_ip;
  CPU::FlushICache(pc_, 2 * Instr::kInstrSize);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
