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
      args_desc_pool_index_(-1),
      ic_data_load_end_(-1),
      ic_data_pool_index_(-1),
      object_pool_(Array::Handle(code.ObjectPool())) {
  ASSERT(code.ContainsInstructionAt(pc));
  ASSERT(Back(2) == 0x0020f809);  // Last instruction: jalr RA, TMP(=R1)
  Register reg;
  // First end is 0 so that we begin from the delay slot of the jalr.
  args_desc_load_end_ =
     DecodeLoadWordFromPool(2, &reg, &target_address_pool_index_);
  ASSERT(reg == TMP);
}


uword CallPattern::Back(int n) const {
  ASSERT(n > 0);
  return *(end_ - n);
}


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
    if (instr->OpcodeField() == LUI) {
      ASSERT(instr->RtField() == *reg);
      offset |= (instr->UImmField() << 16);
    } else {
      ASSERT(instr->OpcodeField() == ORI);
      ASSERT(instr->RtField() == *reg);
      offset |= instr->UImmField();

      if (instr->RsField() != ZR) {
        ASSERT(instr->RsField() == *reg);
        i = Back(++end);
        instr = Instr::At(reinterpret_cast<uword>(&i));
        ASSERT(instr->OpcodeField() == LUI);
        ASSERT(instr->RtField() == *reg);
        offset |= (instr->UImmField() << 16);
      }
    }
  }
  offset += kHeapObjectTag;
  ASSERT(Utils::IsAligned(offset, 4));
  *index = (offset - Array::data_offset())/4;
  return end;
}


RawICData* CallPattern::IcData() {
  UNIMPLEMENTED();
  return NULL;
}


RawArray* CallPattern::ArgumentsDescriptor() {
  UNIMPLEMENTED();
  return NULL;
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
  UNIMPLEMENTED();
}


JumpPattern::JumpPattern(uword pc) : pc_(pc) { }


bool JumpPattern::IsValid() const {
  UNIMPLEMENTED();
  return false;
}


uword JumpPattern::TargetAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

