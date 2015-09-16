// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler.h"
#include "vm/constants_arm.h"
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
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uword*>(end_) - 1) == 0xe12fff3e);

  Register reg;
  ic_data_load_end_ =
      InstructionPattern::DecodeLoadWordFromPool(end_ - Instr::kInstrSize,
                                                 &reg,
                                                 &target_address_pool_index_);
  ASSERT(reg == LR);
}


int CallPattern::LengthInBytes() {
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    return 5 * Instr::kInstrSize;
  } else {
    ASSERT(version == ARMv7);
    return 3 * Instr::kInstrSize;
  }
}


NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_address_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  // Last instruction: blx lr.
  ASSERT(*(reinterpret_cast<uword*>(end_) - 1) == 0xe12fff3e);

  Register reg;
  uword native_function_load_end =
      InstructionPattern::DecodeLoadWordFromPool(end_ - Instr::kInstrSize,
                                                 &reg,
                                                 &target_address_pool_index_);
  ASSERT(reg == LR);
  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end,
                                             &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == R5);
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
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    ASSERT((instr & 0xfff00000) == 0xe3800000);  // orr rd, rd, byte0
    imm |= (instr & 0x000000ff);

    start -= Instr::kInstrSize;
    instr = Instr::At(start)->InstructionBits();
    ASSERT((instr & 0xfff00000) == 0xe3800c00);  // orr rd, rd, (byte1 rot 12)
    imm |= (instr & 0x000000ff);

    start -= Instr::kInstrSize;
    instr = Instr::At(start)->InstructionBits();
    ASSERT((instr & 0xfff00f00) == 0xe3800800);  // orr rd, rd, (byte2 rot 8)
    imm |= (instr & 0x000000ff);

    start -= Instr::kInstrSize;
    instr = Instr::At(start)->InstructionBits();
    ASSERT((instr & 0xffff0f00) == 0xe3a00400);  // mov rd, (byte3 rot 4)
    imm |= (instr & 0x000000ff);

    *reg = static_cast<Register>((instr & 0x0000f000) >> 12);
    *value = imm;
  } else {
    ASSERT(version == ARMv7);
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
  }
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
    if ((instr & 0xffff0000) == 0xe28a0000) {  // add reg, pp, operand
      const intptr_t rot = (instr & 0xf00) >> 7;
      const intptr_t imm8 = instr & 0xff;
      offset += (imm8 >> rot) | (imm8 << (32 - rot));
      *reg = static_cast<Register>((instr & 0xf000) >> 12);
    } else {
      ASSERT((instr & 0xffff0000) == 0xe08a0000);  // add reg, pp, reg
      end = DecodeLoadWordImmediate(end, reg, &offset);
    }
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
    ASSERT(reg == R5);
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


void CallPattern::InsertAt(uword pc, uword target_address) {
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    const uint32_t byte0 = (target_address & 0x000000ff);
    const uint32_t byte1 = (target_address & 0x0000ff00) >> 8;
    const uint32_t byte2 = (target_address & 0x00ff0000) >> 16;
    const uint32_t byte3 = (target_address & 0xff000000) >> 24;

    const uword mov_ip = 0xe3a0c400 | byte3;  // mov ip, (byte3 rot 4)
    const uword or1_ip = 0xe38cc800 | byte2;  // orr ip, ip, (byte2 rot 8)
    const uword or2_ip = 0xe38ccc00 | byte1;  // orr ip, ip, (byte1 rot 12)
    const uword or3_ip = 0xe38cc000 | byte0;  // orr ip, ip, byte0
    const uword blx_ip = 0xe12fff3c;

    *reinterpret_cast<uword*>(pc + (0 * Instr::kInstrSize)) = mov_ip;
    *reinterpret_cast<uword*>(pc + (1 * Instr::kInstrSize)) = or1_ip;
    *reinterpret_cast<uword*>(pc + (2 * Instr::kInstrSize)) = or2_ip;
    *reinterpret_cast<uword*>(pc + (3 * Instr::kInstrSize)) = or3_ip;
    *reinterpret_cast<uword*>(pc + (4 * Instr::kInstrSize)) = blx_ip;

    ASSERT(LengthInBytes() == 5 * Instr::kInstrSize);
    CPU::FlushICache(pc, LengthInBytes());
  } else {
    ASSERT(version == ARMv7);
    const uint16_t target_lo = target_address & 0xffff;
    const uint16_t target_hi = target_address >> 16;

    const uword movw_ip =
        0xe300c000 | ((target_lo >> 12) << 16) | (target_lo & 0xfff);
    const uword movt_ip =
        0xe340c000 | ((target_hi >> 12) << 16) | (target_hi & 0xfff);
    const uword blx_ip = 0xe12fff3c;

    *reinterpret_cast<uword*>(pc + (0 * Instr::kInstrSize)) = movw_ip;
    *reinterpret_cast<uword*>(pc + (1 * Instr::kInstrSize)) = movt_ip;
    *reinterpret_cast<uword*>(pc + (2 * Instr::kInstrSize)) = blx_ip;

    ASSERT(LengthInBytes() == 3 * Instr::kInstrSize);
    CPU::FlushICache(pc, LengthInBytes());
  }
}


JumpPattern::JumpPattern(uword pc, const Code& code) : pc_(pc) { }


int JumpPattern::pattern_length_in_bytes() {
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    return 5 * Instr::kInstrSize;
  } else {
    ASSERT(version == ARMv7);
    return 3 * Instr::kInstrSize;
  }
}


bool JumpPattern::IsValid() const {
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    Instr* mov_ip = Instr::At(pc_ + (0 * Instr::kInstrSize));
    Instr* or1_ip = Instr::At(pc_ + (1 * Instr::kInstrSize));
    Instr* or2_ip = Instr::At(pc_ + (2 * Instr::kInstrSize));
    Instr* or3_ip = Instr::At(pc_ + (3 * Instr::kInstrSize));
    Instr* bx_ip = Instr::At(pc_ + (4 * Instr::kInstrSize));
    return ((mov_ip->InstructionBits() & 0xffffff00) == 0xe3a0c400) &&
           ((or1_ip->InstructionBits() & 0xffffff00) == 0xe38cc800) &&
           ((or2_ip->InstructionBits() & 0xffffff00) == 0xe38ccc00) &&
           ((or3_ip->InstructionBits() & 0xffffff00) == 0xe38cc000) &&
           ((bx_ip->InstructionBits() & 0xffffffff) == 0xe12fff1c);
  } else {
    ASSERT(version == ARMv7);
    Instr* movw_ip = Instr::At(pc_ + (0 * Instr::kInstrSize));  // target_lo
    Instr* movt_ip = Instr::At(pc_ + (1 * Instr::kInstrSize));  // target_hi
    Instr* bx_ip = Instr::At(pc_ + (2 * Instr::kInstrSize));
    return (movw_ip->InstructionBits() & 0xfff0f000) == 0xe300c000 &&
           (movt_ip->InstructionBits() & 0xfff0f000) == 0xe340c000 &&
           (bx_ip->InstructionBits() & 0xffffffff) == 0xe12fff1c;
  }
}


uword JumpPattern::TargetAddress() const {
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    Instr* mov_ip = Instr::At(pc_ + (0 * Instr::kInstrSize));
    Instr* or1_ip = Instr::At(pc_ + (1 * Instr::kInstrSize));
    Instr* or2_ip = Instr::At(pc_ + (2 * Instr::kInstrSize));
    Instr* or3_ip = Instr::At(pc_ + (3 * Instr::kInstrSize));
    uword imm = 0;
    imm |= or3_ip->Immed8Field();
    imm |= or2_ip->Immed8Field() << 8;
    imm |= or1_ip->Immed8Field() << 16;
    imm |= mov_ip->Immed8Field() << 24;
    return imm;
  } else {
    ASSERT(version == ARMv7);
    Instr* movw_ip = Instr::At(pc_ + (0 * Instr::kInstrSize));  // target_lo
    Instr* movt_ip = Instr::At(pc_ + (1 * Instr::kInstrSize));  // target_hi
    uint16_t target_lo = movw_ip->MovwField();
    uint16_t target_hi = movt_ip->MovwField();
    return (target_hi << 16) | target_lo;
  }
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    const uint32_t byte0 = (target_address & 0x000000ff);
    const uint32_t byte1 = (target_address & 0x0000ff00) >> 8;
    const uint32_t byte2 = (target_address & 0x00ff0000) >> 16;
    const uint32_t byte3 = (target_address & 0xff000000) >> 24;

    const uword mov_ip = 0xe3a0c400 | byte3;  // mov ip, (byte3 rot 4)
    const uword or1_ip = 0xe38cc800 | byte2;  // orr ip, ip, (byte2 rot 8)
    const uword or2_ip = 0xe38ccc00 | byte1;  // orr ip, ip, (byte1 rot 12)
    const uword or3_ip = 0xe38cc000 | byte0;  // orr ip, ip, byte0

    *reinterpret_cast<uword*>(pc_ + (0 * Instr::kInstrSize)) = mov_ip;
    *reinterpret_cast<uword*>(pc_ + (1 * Instr::kInstrSize)) = or1_ip;
    *reinterpret_cast<uword*>(pc_ + (2 * Instr::kInstrSize)) = or2_ip;
    *reinterpret_cast<uword*>(pc_ + (3 * Instr::kInstrSize)) = or3_ip;
    CPU::FlushICache(pc_, 4 * Instr::kInstrSize);
  } else {
    ASSERT(version == ARMv7);
    const uint16_t target_lo = target_address & 0xffff;
    const uint16_t target_hi = target_address >> 16;

    const uword movw_ip =
        0xe300c000 | ((target_lo >> 12) << 16) | (target_lo & 0xfff);
    const uword movt_ip =
        0xe340c000 | ((target_hi >> 12) << 16) | (target_hi & 0xfff);

    *reinterpret_cast<uword*>(pc_ + (0 * Instr::kInstrSize)) = movw_ip;
    *reinterpret_cast<uword*>(pc_ + (1 * Instr::kInstrSize)) = movt_ip;
    CPU::FlushICache(pc_, 2 * Instr::kInstrSize);
  }
}


ReturnPattern::ReturnPattern(uword pc)
    : pc_(pc) {
}


bool ReturnPattern::IsValid() const {
  Instr* bx_lr = Instr::At(pc_);
  const int32_t B4 = 1 << 4;
  const int32_t B21 = 1 << 21;
  const int32_t B24 = 1 << 24;
  int32_t instruction = (static_cast<int32_t>(AL) << kConditionShift) |
                         B24 | B21 | (0xfff << 8) | B4 |
                        (static_cast<int32_t>(LR) << kRmShift);
  const ARMVersion version = TargetCPUFeatures::arm_version();
  if ((version == ARMv5TE) || (version == ARMv6)) {
    return bx_lr->InstructionBits() == instruction;
  } else {
    ASSERT(version == ARMv7);
    return bx_lr->InstructionBits() == instruction;
  }
  return false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
