// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_RISCV*.
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/instructions.h"
#include "vm/instructions_riscv.h"

#include "vm/constants.h"
#include "vm/cpu.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/reverse_pc_lookup_cache.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  //          [lui,add,]lx CODE_REG, ##(pp)
  // xxxxxxxx lx ra, ##(CODE_REG)
  //     xxxx jalr ra

  // Last instruction: jalr ra.
  ASSERT(*reinterpret_cast<uint16_t*>(pc - 2) == 0x9082);
  Register reg;
  InstructionPattern::DecodeLoadWordFromPool(pc - 6, &reg,
                                             &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
}

ICCallPattern::ICCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      target_pool_index_(-1),
      data_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  //          [lui,add,]lx IC_DATA_REG, ##(pp)
  //          [lui,add,]lx CODE_REG, ##(pp)
  // xxxxxxxx lx ra, ##(CODE_REG)
  //     xxxx jalr ra

  // Last instruction: jalr ra.
  ASSERT(*reinterpret_cast<uint16_t*>(pc - 2) == 0x9082);

  Register reg;
  uword data_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - 6, &reg, &target_pool_index_);
  ASSERT(reg == CODE_REG);

  InstructionPattern::DecodeLoadWordFromPool(data_load_end, &reg,
                                             &data_pool_index_);
  ASSERT(reg == IC_DATA_REG);
}

NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_code_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(pc));
  //          [lui,add,]lx t5, ##(pp)
  //          [lui,add,]lx CODE_REG, ##(pp)
  // xxxxxxxx lx ra, ##(CODE_REG)
  //     xxxx jalr ra

  // Last instruction: jalr ra.
  ASSERT(*reinterpret_cast<uint16_t*>(pc - 2) == 0x9082);

  Register reg;
  uword native_function_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - 6, &reg, &target_code_pool_index_);
  ASSERT(reg == CODE_REG);
  InstructionPattern::DecodeLoadWordFromPool(native_function_load_end, &reg,
                                             &native_function_pool_index_);
  ASSERT(reg == T5);
}

CodePtr NativeCallPattern::target() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_code_pool_index_));
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

// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded immediate value in the output parameters 'reg' and 'value'
// respectively.
uword InstructionPattern::DecodeLoadWordImmediate(uword end,
                                                  Register* reg,
                                                  intptr_t* value) {
  UNIMPLEMENTED();
  return 0;
}

static bool DecodeLoadX(uword end,
                        Register* dst,
                        Register* base,
                        intptr_t* offset,
                        intptr_t* length) {
  Instr instr(LoadUnaligned(reinterpret_cast<uint32_t*>(end - 4)));
#if XLEN == 32
  if (instr.opcode() == LOAD && instr.funct3() == LW) {
#elif XLEN == 64
  if (instr.opcode() == LOAD && instr.funct3() == LD) {
#endif
    *dst = instr.rd();
    *base = instr.rs1();
    *offset = instr.itype_imm();
    *length = 4;
    return true;
  }

  CInstr cinstr(*reinterpret_cast<uint16_t*>(end - 2));
#if XLEN == 32
  if (cinstr.opcode() == C_LW) {
#elif XLEN == 64
  if (cinstr.opcode() == C_LD) {
#endif
    *dst = cinstr.rdp();
    *base = cinstr.rs1p();
#if XLEN == 32
    *offset = cinstr.mem4_imm();
#elif XLEN == 64
    *offset = cinstr.mem8_imm();
#endif
    *length = 2;
    return true;
  }

  return false;
}

static bool DecodeLUI(uword end,
                      Register* dst,
                      intptr_t* imm,
                      intptr_t* length) {
  Instr instr(LoadUnaligned(reinterpret_cast<uint32_t*>(end - 4)));
  if (instr.opcode() == LUI) {
    *dst = instr.rd();
    *imm = instr.utype_imm();
    *length = 4;
    return true;
  }

  CInstr cinstr(*reinterpret_cast<uint16_t*>(end - 2));
  if (cinstr.opcode() == C_LUI) {
    *dst = cinstr.rd();
    *imm = cinstr.u_imm();
    *length = 2;
    return true;
  }

  return false;
}

// See comment in instructions_arm64.h
uword InstructionPattern::DecodeLoadWordFromPool(uword end,
                                                 Register* reg,
                                                 intptr_t* index) {
  // [c.]lx dst, offset(pp)
  // or
  // [c.]lui dst, hi
  // c.add dst, dst, pp
  // [c.]lx dst, lo(dst)

  Register base;
  intptr_t lo, length;
  if (!DecodeLoadX(end, reg, &base, &lo, &length)) {
    UNREACHABLE();
  }

  if (base == PP) {
    // PP is untagged on RISCV.
    *index = ObjectPool::IndexFromOffset(lo - kHeapObjectTag);
    return end - length;
  }
  ASSERT(base == *reg);
  end -= length;

  CInstr add_instr(*reinterpret_cast<uint16_t*>(end - 2));
  ASSERT(add_instr.opcode() ==
         C_MV);  // Not C_ADD, which extends past the opcode proper.
  ASSERT(add_instr.rd() == base);
  ASSERT(add_instr.rs1() == base);
  ASSERT(add_instr.rs2() == PP);
  end -= 2;

  Register dst;
  intptr_t hi;
  if (!DecodeLUI(end, &dst, &hi, &length)) {
    UNREACHABLE();
  }
  ASSERT(dst == base);
  // PP is untagged on RISC-V.
  *index = ObjectPool::IndexFromOffset(hi + lo - kHeapObjectTag);
  return end - length;
}

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));
  uint16_t parcel = *reinterpret_cast<uint16_t*>(pc);
  if (IsCInstruction(parcel)) {
    CInstr instr(parcel);
#if XLEN == 32
    if (instr.opcode() == C_LW) {
      intptr_t offset = instr.mem4_imm();
#elif XLEN == 64
    if (instr.opcode() == C_LD) {
      intptr_t offset = instr.mem8_imm();
#endif
      if (instr.rs1p() == PP) {
        // PP is untagged on RISC-V.
        if (!Utils::IsAligned(offset, kWordSize)) {
          return false;  // Being used as argument register A5.
        }
        intptr_t index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
        return ObjectAtPoolIndex(code, index, obj);
      } else if (instr.rs1p() == THR) {
        return Thread::ObjectAtOffset(offset, obj);
      }
    }
  } else {
    Instr instr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc)));
#if XLEN == 32
    if (instr.opcode() == LOAD && instr.funct3() == LW) {
#elif XLEN == 64
    if (instr.opcode() == LOAD && instr.funct3() == LD) {
#endif
      intptr_t offset = instr.itype_imm();
      if (instr.rs1() == PP) {
        // PP is untagged on RISC-V.
        if (!Utils::IsAligned(offset, kWordSize)) {
          return false;  // Being used as argument register A5.
        }
        intptr_t index = ObjectPool::IndexFromOffset(offset - kHeapObjectTag);
        return ObjectAtPoolIndex(code, index, obj);
      } else if (instr.rs1() == THR) {
        return Thread::ObjectAtOffset(offset, obj);
      }
    }
    if ((instr.opcode() == OPIMM) && (instr.funct3() == ADDI) &&
        (instr.rs1() == NULL_REG)) {
      if (instr.itype_imm() == 0) {
        *obj = Object::null();
        return true;
      }
      if (instr.itype_imm() == kTrueOffsetFromNull) {
        *obj = Object::bool_true().ptr();
        return true;
      }
      if (instr.itype_imm() == kFalseOffsetFromNull) {
        *obj = Object::bool_false().ptr();
        return true;
      }
    }
  }

  // TODO(riscv): Loads with offsets beyond 12 bits.
  return false;
}

// Encodes a load sequence ending at 'end'. Encodes a fixed length two
// instruction load from the pool pointer in PP using the destination
// register reg as a temporary for the base address.
// Assumes that the location has already been validated for patching.
void InstructionPattern::EncodeLoadWordFromPoolFixed(uword end,
                                                     int32_t offset) {
  UNIMPLEMENTED();
}

CodePtr CallPattern::TargetCode() const {
  return static_cast<CodePtr>(object_pool_.ObjectAt(target_code_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt(target_code_pool_index_, target);
  // No need to flush the instruction cache, since the code is not modified.
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

void ICCallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt(target_pool_index_, target);
  // No need to flush the instruction cache, since the code is not modified.
}

SwitchableCallPatternBase::SwitchableCallPatternBase(
    const ObjectPool& object_pool)
    : object_pool_(object_pool), data_pool_index_(-1), target_pool_index_(-1) {}

ObjectPtr SwitchableCallPatternBase::data() const {
  return object_pool_.ObjectAt(data_pool_index_);
}

void SwitchableCallPatternBase::SetData(const Object& data) const {
  ASSERT(!Object::Handle(object_pool_.ObjectAt(data_pool_index_)).IsCode());
  object_pool_.SetObjectAt(data_pool_index_, data);
}

SwitchableCallPattern::SwitchableCallPattern(uword pc, const Code& code)
    : SwitchableCallPatternBase(ObjectPool::Handle(code.GetObjectPool())) {
  ASSERT(code.ContainsInstructionAt(pc));
  UNIMPLEMENTED();
}

uword SwitchableCallPattern::target_entry() const {
  return Code::Handle(Code::RawCast(object_pool_.ObjectAt(target_pool_index_)))
      .MonomorphicEntryPoint();
}

void SwitchableCallPattern::SetTarget(const Code& target) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt(target_pool_index_)).IsCode());
  object_pool_.SetObjectAt(target_pool_index_, target);
}

BareSwitchableCallPattern::BareSwitchableCallPattern(uword pc)
    : SwitchableCallPatternBase(ObjectPool::Handle(
          IsolateGroup::Current()->object_store()->global_object_pool())) {
  //      [lui,add,]lx RA, ##(pp)
  //      [lui,add,]lx IC_DATA_REG, ##(pp)
  // xxxx jalr RA

  // Last instruction: jalr ra.
  ASSERT(*reinterpret_cast<uint16_t*>(pc - 2) == 0x9082);

  Register reg;
  uword target_load_end = InstructionPattern::DecodeLoadWordFromPool(
      pc - 2, &reg, &data_pool_index_);
  ASSERT_EQUAL(reg, IC_DATA_REG);

  InstructionPattern::DecodeLoadWordFromPool(target_load_end, &reg,
                                             &target_pool_index_);
  ASSERT_EQUAL(reg, RA);
}

uword BareSwitchableCallPattern::target_entry() const {
  return object_pool_.RawValueAt(target_pool_index_);
}

void BareSwitchableCallPattern::SetTarget(const Code& target) const {
  ASSERT(object_pool_.TypeAt(target_pool_index_) ==
         ObjectPool::EntryType::kImmediate);
  object_pool_.SetRawValueAt(target_pool_index_,
                             target.MonomorphicEntryPoint());
}

ReturnPattern::ReturnPattern(uword pc) : pc_(pc) {}

bool ReturnPattern::IsValid() const {
  return *reinterpret_cast<uint16_t*>(pc_) == 0x8082;
}

bool PcRelativeCallPattern::IsValid() const {
  Instr aupic(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
  if (aupic.opcode() != AUIPC) return false;
  Instr jalr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_ + 4)));
  if (jalr.opcode() != JALR) return false;
  if (aupic.rd() != jalr.rs1()) return false;
  if (jalr.rd() != RA) return false;
  return true;
}

bool PcRelativeTailCallPattern::IsValid() const {
  Instr aupic(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
  if (aupic.opcode() != AUIPC) return false;
  Instr jr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_ + 4)));
  if (jr.opcode() != JALR) return false;
  if (aupic.rd() != jr.rs1()) return false;
  if (jr.rd() != ZR) return false;
  return true;
}

void PcRelativeTrampolineJumpPattern::Initialize() {
  StoreUnaligned(reinterpret_cast<uint32_t*>(pc_),
                 EncodeOpcode(AUIPC) | EncodeRd(TMP) | EncodeUTypeImm(0));
  StoreUnaligned(reinterpret_cast<uint32_t*>(pc_ + 4),
                 EncodeOpcode(JALR) | EncodeFunct3(F3_0) | EncodeRd(ZR) |
                     EncodeRs1(TMP) | EncodeITypeImm(0));
}

intptr_t TypeTestingStubCallPattern::GetSubtypeTestCachePoolIndex() {
  // Calls to the type testing stubs look like:
  //   lx s4, ...
  //   lx Rn, idx(pp)
  //   jalr s4
  // where Rn = TypeTestABI::kSubtypeTestCacheReg.

  // Ensure the caller of the type testing stub (whose return address is [pc_])
  // branched via `jalr s3` or a pc-relative call.
  if (*reinterpret_cast<uint16_t*>(pc_ - 2) == 0x9982) {  // jalr s3
    // indirect call
    //     xxxx c.jalr s3
    Register reg;
    intptr_t pool_index = -1;
    InstructionPattern::DecodeLoadWordFromPool(pc_ - 2, &reg, &pool_index);
    ASSERT_EQUAL(reg, TypeTestABI::kSubtypeTestCacheReg);
    return pool_index;
  } else {
    ASSERT(FLAG_precompiled_mode);
    // pc-relative call
    // xxxxxxxx aupic ra, hi
    // xxxxxxxx jalr ra, lo
    Instr jalr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_ - 4)));
    ASSERT(jalr.opcode() == JALR);
    Instr auipc(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_ - 8)));
    ASSERT(auipc.opcode() == AUIPC);

    Register reg;
    intptr_t pool_index = -1;
    InstructionPattern::DecodeLoadWordFromPool(pc_ - 8, &reg, &pool_index);
    ASSERT_EQUAL(reg, TypeTestABI::kSubtypeTestCacheReg);
    return pool_index;
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_RISCV
