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
      pool_index_(DecodePoolIndex()),
      object_pool_(Array::Handle(code.ObjectPool())) { }


uword CallPattern::Back(int n) const {
  ASSERT(n > 0);
  return *(end_ - n);
}


int CallPattern::DecodePoolIndex() {
  ASSERT(Back(1) == 0xe12fff3e);  // Last instruction: blx lr
  // Decode the second to last instruction.
  uword instr = Back(2);
  int offset = 0;
  if ((instr & 0xfffff000) == 0xe59ae000) {  // ldr lr, [pp, #+offset]
    offset = instr & 0xfff;
  } else {
    ASSERT((instr & 0xfffff000) == 0xe59ee000);  // ldr lr, [lr, #+offset]
    offset = instr & 0xfff;
    instr = Back(3);
    if ((instr & 0xfffff000) == 0xe28ae000) {  // add lr, pp, shifter_op
      const int rot = (instr & 0xf00) * 2;
      const int imm8 = instr & 0xff;
      offset |= (imm8 >> rot) | (imm8 << (32 - rot));
    } else {
      ASSERT(instr == 0xe08ae00e);  // add lr, pp, lr
      instr = Back(4);
      if ((instr & 0xfff0f000) == 0xe340e000) {  // movt lr, offset_hi
        offset |= (instr & 0xf0000) << 12;
        offset |= (instr & 0xfff) << 16;
        instr = Back(5);
      }
      ASSERT((instr & 0xfff0f000) == 0xe300e000);  // movw lr, offset_lo
      ASSERT((offset & 0xffff) == 0);
      offset |= (instr & 0xf0000) >> 4;
      offset |= instr & 0xfff;
    }
  }
  offset += kHeapObjectTag;
  ASSERT(Utils::IsAligned(offset, 4));
  return (offset - Array::data_offset())/4;
}


uword CallPattern::TargetAddress() const {
  const Object& target_address = Object::Handle(object_pool_.At(pool_index_));
  ASSERT(target_address.IsSmi());
  // The address is stored in the object array as a RawSmi.
  return reinterpret_cast<uword>(target_address.raw());
}


void CallPattern::SetTargetAddress(uword target_address) const {
  ASSERT(Utils::IsAligned(target_address, 4));
  // The address is stored in the object array as a RawSmi.
  const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(target_address));
  object_pool_.SetAt(pool_index_, smi);
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

