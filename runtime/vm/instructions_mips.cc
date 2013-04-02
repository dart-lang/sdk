// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/constants_mips.h"
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
  ASSERT(Back(2) == 0x0020f809);  // Last instruction: jalr RA, TMP(=R1)
  Register reg;
  // First end is 0 so that we begin from the delay slot of the jalr.
  ic_data_load_end_ =
      DecodeLoadWordFromPool(2, &reg, &target_address_pool_index_);
  ASSERT(reg == TMP);
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
  uword i = Back(end + 1);
  Instr* instr = Instr::At(reinterpret_cast<uword>(&i));
  if (instr->OpcodeField() == LW) {
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
  int imm = 0;
  uword i = Back(++end);
  Instr* instr = Instr::At(reinterpret_cast<uword>(&i));
  ASSERT(instr->OpcodeField() == ORI);
  imm = instr->UImmField();
  *reg = instr->RtField();

  i = Back(++end);
  instr = Instr::At(reinterpret_cast<uword>(&i));
  ASSERT(instr->OpcodeField() == LUI);
  ASSERT(instr->RtField() == *reg);
  imm |= instr->UImmField();
  *value = imm;
  return end;
}


// Decodes a load sequence ending at end. Returns the register being loaded and
// the index in the pool being read from.
// Returns the location of the load sequence, counting the number of
// instructions back from the end of the call pattern.
int CallPattern::DecodeLoadWordFromPool(int end, Register* reg, int* index) {
  ASSERT(end > 0);
  uword i = Back(++end);
  Instr* instr = Instr::At(reinterpret_cast<uword>(&i));
  int offset = 0;
  if ((instr->OpcodeField() == LW) && (instr->RsField() == PP)) {
    offset = instr->SImmField();
    *reg = instr->RtField();
  } else {
    ASSERT(instr->OpcodeField() == LW);
    offset = instr->SImmField();
    *reg = instr->RtField();

    i = Back(++end);
    instr = Instr::At(reinterpret_cast<uword>(&i));
    ASSERT(instr->OpcodeField() == SPECIAL);
    ASSERT(instr->FunctionField() == ADDU);
    ASSERT(instr->RdField() == *reg);
    ASSERT(instr->RsField() == *reg);
    ASSERT(instr->RtField() == PP);

    i = Back(++end);
    instr = Instr::At(reinterpret_cast<uword>(&i));
    ASSERT(instr->OpcodeField() == LUI);
    ASSERT(instr->RtField() == *reg);
    // Offset is signed, so add the upper 16 bits.
    offset += (instr->UImmField() << 16);
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
    ASSERT(reg == S5);
  }
  return ic_data_.raw();
}


RawArray* CallPattern::ArgumentsDescriptor() {
  if (args_desc_.IsNull()) {
    IcData();  // Loading of the ic_data must be decoded first, if not already.
    Register reg;
    DecodeLoadObject(args_desc_load_end_, &reg, &args_desc_);
    ASSERT(reg == S4);
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

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

