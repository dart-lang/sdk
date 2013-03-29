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
    : end_(reinterpret_cast<uword*>(pc)),
      target_address_pool_index_(-1),
      args_desc_load_end_(-1),
      args_desc_(Array::Handle()),
      ic_data_load_end_(-1),
      ic_data_(ICData::Handle()),
      object_pool_(Array::Handle(code.ObjectPool())) {
  ASSERT(code.ContainsInstructionAt(pc));
  ASSERT(Back(1) == 0xe12fff3e);  // Last instruction: blx lr
  Register reg;
  ic_data_load_end_ =
      DecodeLoadWordFromPool(1, &reg, &target_address_pool_index_);
  ASSERT(reg == LR);
}


uword CallPattern::Back(int n) const {
  ASSERT(n > 0);
  return *(end_ - n);
}


// Decodes a load sequence ending at end. Returns the register being loaded and
// the loaded object.
// Returns the location of the load sequence, counting the number of
// instructions back from the end of the call pattern.
int CallPattern::DecodeLoadObject(int end, Register* reg, Object* obj) {
  ASSERT(end > 0);
  uword instr = Back(end + 1);
  if ((instr & 0xfff00000) == 0xe5900000) {  // ldr reg, [reg, #+offset]
    int index = 0;
    end = DecodeLoadWordFromPool(end, reg, &index);
    *obj = object_pool_.At(index);
  } else {
    int value = 0;
    end = DecodeLoadWordImmediate(end, reg, &value);
    *obj = reinterpret_cast<RawObject*>(value);
  }
  return end;
}


// Decodes a load sequence ending at end. Returns the register being loaded and
// the loaded immediate value.
// Returns the location of the load sequence, counting the number of
// instructions back from the end of the call pattern.
int CallPattern::DecodeLoadWordImmediate(int end, Register* reg, int* value) {
  ASSERT(end > 0);
  uword instr = Back(++end);
  int imm = 0;
  if ((instr & 0xfff00000) == 0xe3400000) {  // movt reg, #imm_hi
    imm |= (instr & 0xf0000) << 12;
    imm |= (instr & 0xfff) << 16;
    instr = Back(++end);
  }
  ASSERT((instr & 0xfff00000) == 0xe3000000);  // movw reg, #imm_lo
  imm |= (instr & 0xf0000) >> 4;
  imm |= instr & 0xfff;
  *reg = static_cast<Register>((instr & 0xf000) >> 12);
  *value = imm;
  return end;
}


// Decodes a load sequence ending at end. Returns the register being loaded and
// the index in the pool being read from.
// Returns the location of the load sequence, counting the number of
// instructions back from the end of the call pattern.
int CallPattern::DecodeLoadWordFromPool(int end, Register* reg, int* index) {
  ASSERT(end > 0);
  uword instr = Back(++end);
  int offset = 0;
  if ((instr & 0xffff0000) == 0xe59a0000) {  // ldr reg, [pp, #+offset]
    offset = instr & 0xfff;
    *reg = static_cast<Register>((instr & 0xf000) >> 12);
  } else {
    ASSERT((instr & 0xfff00000) == 0xe5900000);  // ldr reg, [reg, #+offset]
    offset = instr & 0xfff;
    instr = Back(++end);
    if ((instr & 0xffff0000) == 0xe28a0000) {  // add reg, pp, shifter_op
      const int rot = (instr & 0xf00) * 2;
      const int imm8 = instr & 0xff;
      offset |= (imm8 >> rot) | (imm8 << (32 - rot));
      *reg = static_cast<Register>((instr & 0xf000) >> 12);
    } else {
      ASSERT((instr & 0xffff0000) == 0xe08a0000);  // add reg, pp, reg
      end = DecodeLoadWordImmediate(end, reg, &offset);
    }
  }
  offset += kHeapObjectTag;
  ASSERT(Utils::IsAligned(offset, 4));
  *index = (offset - Array::data_offset())/4;
  return end;
}


RawICData* CallPattern::IcData() {
  if (ic_data_.IsNull()) {
    Register reg;
    args_desc_load_end_ = DecodeLoadObject(ic_data_load_end_, &reg, &ic_data_);
    ASSERT(reg == R5);
  }
  return ic_data_.raw();
}


RawArray* CallPattern::ArgumentsDescriptor() {
  if (args_desc_.IsNull()) {
    IcData();  // Loading of the ic_data must be decoded first, if not already.
    Register reg;
    DecodeLoadObject(args_desc_load_end_, &reg, &args_desc_);
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


JumpPattern::JumpPattern(uword pc) : pc_(pc) { }


bool JumpPattern::IsValid() const {
  Instr* movw = Instr::At(pc_ + (0 * Instr::kInstrSize));  // movw ip, target_lo
  Instr* movt = Instr::At(pc_ + (1 * Instr::kInstrSize));  // movw ip, target_lo
  Instr* bxip = Instr::At(pc_ + (2 * Instr::kInstrSize));  // bx ip
  return (movw->InstructionBits() & 0xfff0f000) == 0xe300c000 &&
         (movt->InstructionBits() & 0xfff0f000) == 0xe340c000 &&
         (bxip->InstructionBits() & 0xffffffff) == 0xe12fff1c;
}


uword JumpPattern::TargetAddress() const {
  Instr* movw = Instr::At(pc_ + (0 * Instr::kInstrSize));  // movw ip, target_lo
  Instr* movt = Instr::At(pc_ + (1 * Instr::kInstrSize));  // movw ip, target_lo
  uint16_t target_lo = movw->MovwField();
  uint16_t target_hi = movt->MovwField();
  return (target_hi << 16) | target_lo;
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  uint16_t target_lo = target_address & 0xffff;
  uint16_t target_hi = target_address >> 16;
  uword movw = 0xe300c000 | ((target_lo >> 12) << 16) | (target_lo & 0xfff);
  uword movt = 0xe340c000 | ((target_hi >> 12) << 16) | (target_hi & 0xfff);
  *reinterpret_cast<uword*>(pc_ + (0 * Instr::kInstrSize)) = movw;
  *reinterpret_cast<uword*>(pc_ + (1 * Instr::kInstrSize)) = movt;
  CPU::FlushICache(pc_, 2 * Instr::kInstrSize);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM

