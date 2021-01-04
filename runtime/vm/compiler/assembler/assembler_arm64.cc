// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_ARM64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/simulator.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, inline_alloc);
DECLARE_FLAG(bool, precompiled_mode);
DECLARE_FLAG(bool, use_slow_path);

DEFINE_FLAG(bool, use_far_branches, false, "Always use far branches");

// For use by LR related macros (e.g. CLOBBERS_LR).
#define __ this->

namespace compiler {

Assembler::Assembler(ObjectPoolBuilder* object_pool_builder,
                     bool use_far_branches)
    : AssemblerBase(object_pool_builder),
      use_far_branches_(use_far_branches),
      constant_pool_allowed_(false) {
  generate_invoke_write_barrier_wrapper_ = [&](Register reg) {
    Call(Address(THR,
                 target::Thread::write_barrier_wrappers_thread_offset(reg)));
  };
  generate_invoke_array_write_barrier_ = [&]() {
    Call(
        Address(THR, target::Thread::array_write_barrier_entry_point_offset()));
  };
}

void Assembler::Emit(int32_t value) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<int32_t>(value);
}

void Assembler::Emit64(int64_t value) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<int64_t>(value);
}

int32_t Assembler::BindImm19Branch(int64_t position, int64_t dest) {
  if (use_far_branches() && !CanEncodeImm19BranchOffset(dest)) {
    // Far branches are enabled, and we can't encode the branch offset in
    // 19 bits.

    // Grab the guarding branch instruction.
    const int32_t guard_branch =
        buffer_.Load<int32_t>(position + 0 * Instr::kInstrSize);

    // Grab the far branch instruction.
    const int32_t far_branch =
        buffer_.Load<int32_t>(position + 1 * Instr::kInstrSize);
    const Condition c = DecodeImm19BranchCondition(guard_branch);

    // Grab the link to the next branch.
    const int32_t next = DecodeImm26BranchOffset(far_branch);

    // dest is the offset is from the guarding branch instruction.
    // Correct it to be from the following instruction.
    const int64_t offset = dest - Instr::kInstrSize;

    // Encode the branch.
    const int32_t encoded_branch = EncodeImm26BranchOffset(offset, far_branch);

    // If the guard branch is conditioned on NV, replace it with a nop.
    if (c == NV) {
      buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize,
                             Instr::kNopInstruction);
    }

    // Write the far branch into the buffer and link to the next branch.
    buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize, encoded_branch);
    return next;
  } else if (use_far_branches() && CanEncodeImm19BranchOffset(dest)) {
    // We assembled a far branch, but we don't need it. Replace it with a near
    // branch.

    // Grab the guarding branch instruction.
    const int32_t guard_branch =
        buffer_.Load<int32_t>(position + 0 * Instr::kInstrSize);

    // Grab the far branch instruction.
    const int32_t far_branch =
        buffer_.Load<int32_t>(position + 1 * Instr::kInstrSize);

    // Grab the link to the next branch.
    const int32_t next = DecodeImm26BranchOffset(far_branch);

    // Re-target the guarding branch and flip the conditional sense.
    int32_t encoded_guard_branch = EncodeImm19BranchOffset(dest, guard_branch);
    const Condition c = DecodeImm19BranchCondition(encoded_guard_branch);
    encoded_guard_branch =
        EncodeImm19BranchCondition(InvertCondition(c), encoded_guard_branch);

    // Write back the re-encoded instructions. The far branch becomes a nop.
    buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize,
                           encoded_guard_branch);
    buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize,
                           Instr::kNopInstruction);
    return next;
  } else {
    const int32_t next = buffer_.Load<int32_t>(position);
    const int32_t encoded = EncodeImm19BranchOffset(dest, next);
    buffer_.Store<int32_t>(position, encoded);
    return DecodeImm19BranchOffset(next);
  }
}

int32_t Assembler::BindImm14Branch(int64_t position, int64_t dest) {
  if (use_far_branches() && !CanEncodeImm14BranchOffset(dest)) {
    // Far branches are enabled, and we can't encode the branch offset in
    // 14 bits.

    // Grab the guarding branch instruction.
    const int32_t guard_branch =
        buffer_.Load<int32_t>(position + 0 * Instr::kInstrSize);

    // Grab the far branch instruction.
    const int32_t far_branch =
        buffer_.Load<int32_t>(position + 1 * Instr::kInstrSize);
    const Condition c = DecodeImm14BranchCondition(guard_branch);

    // Grab the link to the next branch.
    const int32_t next = DecodeImm26BranchOffset(far_branch);

    // dest is the offset is from the guarding branch instruction.
    // Correct it to be from the following instruction.
    const int64_t offset = dest - Instr::kInstrSize;

    // Encode the branch.
    const int32_t encoded_branch = EncodeImm26BranchOffset(offset, far_branch);

    // If the guard branch is conditioned on NV, replace it with a nop.
    if (c == NV) {
      buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize,
                             Instr::kNopInstruction);
    }

    // Write the far branch into the buffer and link to the next branch.
    buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize, encoded_branch);
    return next;
  } else if (use_far_branches() && CanEncodeImm14BranchOffset(dest)) {
    // We assembled a far branch, but we don't need it. Replace it with a near
    // branch.

    // Grab the guarding branch instruction.
    const int32_t guard_branch =
        buffer_.Load<int32_t>(position + 0 * Instr::kInstrSize);

    // Grab the far branch instruction.
    const int32_t far_branch =
        buffer_.Load<int32_t>(position + 1 * Instr::kInstrSize);

    // Grab the link to the next branch.
    const int32_t next = DecodeImm26BranchOffset(far_branch);

    // Re-target the guarding branch and flip the conditional sense.
    int32_t encoded_guard_branch = EncodeImm14BranchOffset(dest, guard_branch);
    const Condition c = DecodeImm14BranchCondition(encoded_guard_branch);
    encoded_guard_branch =
        EncodeImm14BranchCondition(InvertCondition(c), encoded_guard_branch);

    // Write back the re-encoded instructions. The far branch becomes a nop.
    buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize,
                           encoded_guard_branch);
    buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize,
                           Instr::kNopInstruction);
    return next;
  } else {
    const int32_t next = buffer_.Load<int32_t>(position);
    const int32_t encoded = EncodeImm14BranchOffset(dest, next);
    buffer_.Store<int32_t>(position, encoded);
    return DecodeImm14BranchOffset(next);
  }
}

void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  const intptr_t bound_pc = buffer_.Size();

  while (label->IsLinked()) {
    const int64_t position = label->Position();
    const int64_t dest = bound_pc - position;
    if (IsTestAndBranch(buffer_.Load<int32_t>(position))) {
      label->position_ = BindImm14Branch(position, dest);
    } else {
      label->position_ = BindImm19Branch(position, dest);
    }
  }
  label->BindTo(bound_pc, lr_state());
}

static int CountLeadingZeros(uint64_t value, int width) {
  ASSERT((width == 32) || (width == 64));
  if (value == 0) {
    return width;
  }
  int count = 0;
  do {
    count++;
  } while (value >>= 1);
  return width - count;
}

static int CountOneBits(uint64_t value, int width) {
  // Mask out unused bits to ensure that they are not counted.
  value &= (0xffffffffffffffffULL >> (64 - width));

  value = ((value >> 1) & 0x5555555555555555) + (value & 0x5555555555555555);
  value = ((value >> 2) & 0x3333333333333333) + (value & 0x3333333333333333);
  value = ((value >> 4) & 0x0f0f0f0f0f0f0f0f) + (value & 0x0f0f0f0f0f0f0f0f);
  value = ((value >> 8) & 0x00ff00ff00ff00ff) + (value & 0x00ff00ff00ff00ff);
  value = ((value >> 16) & 0x0000ffff0000ffff) + (value & 0x0000ffff0000ffff);
  value = ((value >> 32) & 0x00000000ffffffff) + (value & 0x00000000ffffffff);

  return value;
}

// Test if a given value can be encoded in the immediate field of a logical
// instruction.
// If it can be encoded, the function returns true, and values pointed to by n,
// imm_s and imm_r are updated with immediates encoded in the format required
// by the corresponding fields in the logical instruction.
// If it can't be encoded, the function returns false, and the operand is
// undefined.
bool Operand::IsImmLogical(uint64_t value, uint8_t width, Operand* imm_op) {
  ASSERT(imm_op != NULL);
  ASSERT((width == kWRegSizeInBits) || (width == kXRegSizeInBits));
  ASSERT((width == kXRegSizeInBits) || (value <= 0xffffffffUL));
  uint8_t n = 0;
  uint8_t imm_s = 0;
  uint8_t imm_r = 0;

  // Logical immediates are encoded using parameters n, imm_s and imm_r using
  // the following table:
  //
  //  N   imms    immr    size        S             R
  //  1  ssssss  rrrrrr    64    UInt(ssssss)  UInt(rrrrrr)
  //  0  0sssss  xrrrrr    32    UInt(sssss)   UInt(rrrrr)
  //  0  10ssss  xxrrrr    16    UInt(ssss)    UInt(rrrr)
  //  0  110sss  xxxrrr     8    UInt(sss)     UInt(rrr)
  //  0  1110ss  xxxxrr     4    UInt(ss)      UInt(rr)
  //  0  11110s  xxxxxr     2    UInt(s)       UInt(r)
  // (s bits must not be all set)
  //
  // A pattern is constructed of size bits, where the least significant S+1
  // bits are set. The pattern is rotated right by R, and repeated across a
  // 32 or 64-bit value, depending on destination register width.
  //
  // To test if an arbitrary immediate can be encoded using this scheme, an
  // iterative algorithm is used.

  // 1. If the value has all set or all clear bits, it can't be encoded.
  if ((value == 0) || (value == 0xffffffffffffffffULL) ||
      ((width == kWRegSizeInBits) && (value == 0xffffffff))) {
    return false;
  }

  int lead_zero = CountLeadingZeros(value, width);
  int lead_one = CountLeadingZeros(~value, width);
  int trail_zero = Utils::CountTrailingZerosWord(value);
  int trail_one = Utils::CountTrailingZerosWord(~value);
  int set_bits = CountOneBits(value, width);

  // The fixed bits in the immediate s field.
  // If width == 64 (X reg), start at 0xFFFFFF80.
  // If width == 32 (W reg), start at 0xFFFFFFC0, as the iteration for 64-bit
  // widths won't be executed.
  int imm_s_fixed = (width == kXRegSizeInBits) ? -128 : -64;
  int imm_s_mask = 0x3F;

  for (;;) {
    // 2. If the value is two bits wide, it can be encoded.
    if (width == 2) {
      n = 0;
      imm_s = 0x3C;
      imm_r = (value & 3) - 1;
      *imm_op = Operand(n, imm_s, imm_r);
      return true;
    }

    n = (width == 64) ? 1 : 0;
    imm_s = ((imm_s_fixed | (set_bits - 1)) & imm_s_mask);
    if ((lead_zero + set_bits) == width) {
      imm_r = 0;
    } else {
      imm_r = (lead_zero > 0) ? (width - trail_zero) : lead_one;
    }

    // 3. If the sum of leading zeros, trailing zeros and set bits is equal to
    //    the bit width of the value, it can be encoded.
    if (lead_zero + trail_zero + set_bits == width) {
      *imm_op = Operand(n, imm_s, imm_r);
      return true;
    }

    // 4. If the sum of leading ones, trailing ones and unset bits in the
    //    value is equal to the bit width of the value, it can be encoded.
    if (lead_one + trail_one + (width - set_bits) == width) {
      *imm_op = Operand(n, imm_s, imm_r);
      return true;
    }

    // 5. If the most-significant half of the bitwise value is equal to the
    //    least-significant half, return to step 2 using the least-significant
    //    half of the value.
    uint64_t mask = (1ULL << (width >> 1)) - 1;
    if ((value & mask) == ((value >> (width >> 1)) & mask)) {
      width >>= 1;
      set_bits >>= 1;
      imm_s_fixed >>= 1;
      continue;
    }

    // 6. Otherwise, the value can't be encoded.
    return false;
  }
}

void Assembler::LoadPoolPointer(Register pp) {
  CheckCodePointer();
  ldr(pp, FieldAddress(CODE_REG, target::Code::object_pool_offset()));

  // When in the PP register, the pool pointer is untagged. When we
  // push it on the stack with TagAndPushPP it is tagged again. PopAndUntagPP
  // then untags when restoring from the stack. This will make loading from the
  // object pool only one instruction for the first 4096 entries. Otherwise,
  // because the offset wouldn't be aligned, it would be only one instruction
  // for the first 64 entries.
  sub(pp, pp, Operand(kHeapObjectTag));
  set_constant_pool_allowed(pp == PP);
}

void Assembler::LoadWordFromPoolIndex(Register dst,
                                      intptr_t index,
                                      Register pp) {
  ASSERT((pp != PP) || constant_pool_allowed());
  ASSERT(dst != pp);
  Operand op;
  // PP is _un_tagged on ARM64.
  const uint32_t offset = target::ObjectPool::element_offset(index);
  const uint32_t upper20 = offset & 0xfffff000;
  if (Address::CanHoldOffset(offset)) {
    ldr(dst, Address(pp, offset));
  } else if (Operand::CanHold(upper20, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    const uint32_t lower12 = offset & 0x00000fff;
    ASSERT(Address::CanHoldOffset(lower12));
    add(dst, pp, op);
    ldr(dst, Address(dst, lower12));
  } else {
    const uint16_t offset_low = Utils::Low16Bits(offset);
    const uint16_t offset_high = Utils::High16Bits(offset);
    movz(dst, Immediate(offset_low), 0);
    if (offset_high != 0) {
      movk(dst, Immediate(offset_high), 1);
    }
    ldr(dst, Address(pp, dst));
  }
}

void Assembler::LoadWordFromPoolIndexFixed(Register dst, intptr_t index) {
  ASSERT(constant_pool_allowed());
  ASSERT(dst != PP);
  Operand op;
  // PP is _un_tagged on ARM64.
  const uint32_t offset = target::ObjectPool::element_offset(index);
  const uint32_t upper20 = offset & 0xfffff000;
  const uint32_t lower12 = offset & 0x00000fff;
  const Operand::OperandType ot =
      Operand::CanHold(upper20, kXRegSizeInBits, &op);
  ASSERT(ot == Operand::Immediate);
  ASSERT(Address::CanHoldOffset(lower12));
  add(dst, PP, op);
  ldr(dst, Address(dst, lower12));
}

void Assembler::LoadDoubleWordFromPoolIndex(Register lower,
                                            Register upper,
                                            intptr_t index) {
  // This implementation needs to be kept in sync with
  // [InstructionPattern::DecodeLoadDoubleWordFromPool].
  ASSERT(constant_pool_allowed());
  ASSERT(lower != PP && upper != PP);

  Operand op;
  // PP is _un_tagged on ARM64.
  const uint32_t offset = target::ObjectPool::element_offset(index);
  ASSERT(offset < (1 << 24));
  const uint32_t upper20 = offset & 0xfffff000;
  const uint32_t lower12 = offset & 0x00000fff;
  if (Address::CanHoldOffset(offset, Address::PairOffset)) {
    ldp(lower, upper, Address(PP, offset, Address::PairOffset));
  } else if (Operand::CanHold(offset, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    add(TMP, PP, op);
    ldp(lower, upper, Address(TMP, 0, Address::PairOffset));
  } else if (Operand::CanHold(upper20, kXRegSizeInBits, &op) ==
                 Operand::Immediate &&
             Address::CanHoldOffset(lower12, Address::PairOffset)) {
    add(TMP, PP, op);
    ldp(lower, upper, Address(TMP, lower12, Address::PairOffset));
  } else {
    const uint32_t lower12 = offset & 0xfff;
    const uint32_t higher12 = offset & 0xfff000;

    Operand op_high, op_low;
    bool ok = Operand::CanHold(higher12, kXRegSizeInBits, &op_high) ==
                  Operand::Immediate &&
              Operand::CanHold(lower12, kXRegSizeInBits, &op_low) ==
                  Operand::Immediate;
    RELEASE_ASSERT(ok);

    add(TMP, PP, op_high);
    add(TMP, TMP, op_low);
    ldp(lower, upper, Address(TMP, 0, Address::PairOffset));
  }
}

intptr_t Assembler::FindImmediate(int64_t imm) {
  return object_pool_builder().FindImmediate(imm);
}

bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(IsOriginalObject(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  // TODO(zra, kmillikin): Also load other large immediates from the object
  // pool
  if (target::IsSmi(object)) {
    // If the raw smi does not fit into a 32-bit signed int, then we'll keep
    // the raw value in the object pool.
    return !Utils::IsInt(32, target::ToRawSmi(object));
  }
  ASSERT(IsNotTemporaryScopedHandle(object));
  ASSERT(IsInOldSpace(object));
  return true;
}

void Assembler::LoadNativeEntry(
    Register dst,
    const ExternalLabel* label,
    ObjectPoolBuilderEntry::Patchability patchable) {
  const intptr_t index =
      object_pool_builder().FindNativeFunction(label, patchable);
  LoadWordFromPoolIndex(dst, index);
}

void Assembler::LoadIsolate(Register dst) {
  ldr(dst, Address(THR, target::Thread::isolate_offset()));
}

void Assembler::LoadObjectHelper(Register dst,
                                 const Object& object,
                                 bool is_unique) {
  ASSERT(IsOriginalObject(object));
  // `is_unique == true` effectively means object has to be patchable.
  // (even if the object is null)
  if (!is_unique) {
    if (IsSameObject(compiler::NullObject(), object)) {
      mov(dst, NULL_REG);
      return;
    }
    if (IsSameObject(CastHandle<Object>(compiler::TrueObject()), object)) {
      AddImmediate(dst, NULL_REG, kTrueOffsetFromNull);
      return;
    }
    if (IsSameObject(CastHandle<Object>(compiler::FalseObject()), object)) {
      AddImmediate(dst, NULL_REG, kFalseOffsetFromNull);
      return;
    }
    word offset = 0;
    if (target::CanLoadFromThread(object, &offset)) {
      ldr(dst, Address(THR, offset));
      return;
    }
  }
  if (CanLoadFromObjectPool(object)) {
    const intptr_t index = is_unique ? object_pool_builder().AddObject(object)
                                     : object_pool_builder().FindObject(object);
    LoadWordFromPoolIndex(dst, index);
    return;
  }
  ASSERT(target::IsSmi(object));
  LoadImmediate(dst, target::ToRawSmi(object));
}

void Assembler::LoadObject(Register dst, const Object& object) {
  LoadObjectHelper(dst, object, false);
}

void Assembler::LoadUniqueObject(Register dst, const Object& object) {
  LoadObjectHelper(dst, object, true);
}

void Assembler::LoadFromStack(Register dst, intptr_t depth) {
  ASSERT(depth >= 0);
  LoadFromOffset(dst, SPREG, depth * target::kWordSize);
}

void Assembler::StoreToStack(Register src, intptr_t depth) {
  ASSERT(depth >= 0);
  StoreToOffset(src, SPREG, depth * target::kWordSize);
}

void Assembler::CompareToStack(Register src, intptr_t depth) {
  LoadFromStack(TMP, depth);
  CompareRegisters(src, TMP);
}

void Assembler::CompareObject(Register reg, const Object& object) {
  ASSERT(IsOriginalObject(object));
  word offset = 0;
  if (IsSameObject(compiler::NullObject(), object)) {
    CompareRegisters(reg, NULL_REG);
  } else if (target::CanLoadFromThread(object, &offset)) {
    ldr(TMP, Address(THR, offset));
    CompareRegisters(reg, TMP);
  } else if (CanLoadFromObjectPool(object)) {
    LoadObject(TMP, object);
    CompareRegisters(reg, TMP);
  } else {
    ASSERT(target::IsSmi(object));
    CompareImmediate(reg, target::ToRawSmi(object));
  }
}

void Assembler::LoadImmediate(Register reg, int64_t imm) {
  // Is it 0?
  if (imm == 0) {
    movz(reg, Immediate(0), 0);
    return;
  }

  // Can we use one orri operation?
  Operand op;
  Operand::OperandType ot;
  ot = Operand::CanHold(imm, kXRegSizeInBits, &op);
  if (ot == Operand::BitfieldImm) {
    orri(reg, ZR, Immediate(imm));
    return;
  }

  // We may fall back on movz, movk, movn.
  const uint32_t w0 = Utils::Low32Bits(imm);
  const uint32_t w1 = Utils::High32Bits(imm);
  const uint16_t h0 = Utils::Low16Bits(w0);
  const uint16_t h1 = Utils::High16Bits(w0);
  const uint16_t h2 = Utils::Low16Bits(w1);
  const uint16_t h3 = Utils::High16Bits(w1);

  // Special case for w1 == 0xffffffff
  if (w1 == 0xffffffff) {
    if (h1 == 0xffff) {
      movn(reg, Immediate(~h0), 0);
    } else {
      movn(reg, Immediate(~h1), 1);
      movk(reg, Immediate(h0), 0);
    }
    return;
  }

  // Special case for h3 == 0xffff
  if (h3 == 0xffff) {
    // We know h2 != 0xffff.
    movn(reg, Immediate(~h2), 2);
    if (h1 != 0xffff) {
      movk(reg, Immediate(h1), 1);
    }
    if (h0 != 0xffff) {
      movk(reg, Immediate(h0), 0);
    }
    return;
  }

  // Use constant pool if allowed, unless we can load imm with 2 instructions.
  if ((w1 != 0) && constant_pool_allowed()) {
    const intptr_t index = FindImmediate(imm);
    LoadWordFromPoolIndex(reg, index);
    return;
  }

  bool initialized = false;
  if (h0 != 0) {
    movz(reg, Immediate(h0), 0);
    initialized = true;
  }
  if (h1 != 0) {
    if (initialized) {
      movk(reg, Immediate(h1), 1);
    } else {
      movz(reg, Immediate(h1), 1);
      initialized = true;
    }
  }
  if (h2 != 0) {
    if (initialized) {
      movk(reg, Immediate(h2), 2);
    } else {
      movz(reg, Immediate(h2), 2);
      initialized = true;
    }
  }
  if (h3 != 0) {
    if (initialized) {
      movk(reg, Immediate(h3), 3);
    } else {
      movz(reg, Immediate(h3), 3);
    }
  }
}

void Assembler::LoadDImmediate(VRegister vd, double immd) {
  if (!fmovdi(vd, immd)) {
    int64_t imm = bit_cast<int64_t, double>(immd);
    LoadImmediate(TMP, imm);
    fmovdr(vd, TMP);
  }
}

void Assembler::Branch(const Code& target,
                       Register pp,
                       ObjectPoolBuilderEntry::Patchability patchable) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), patchable);
  LoadWordFromPoolIndex(CODE_REG, index, pp);
  ldr(TMP, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  br(TMP);
}

void Assembler::BranchLink(const Code& target,
                           ObjectPoolBuilderEntry::Patchability patchable,
                           CodeEntryKind entry_kind) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), patchable);
  LoadWordFromPoolIndex(CODE_REG, index);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::BranchLinkToRuntime() {
  Call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
}

void Assembler::BranchLinkWithEquivalence(const Code& target,
                                          const Object& equivalence,
                                          CodeEntryKind entry_kind) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), equivalence);
  LoadWordFromPoolIndex(CODE_REG, index);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::AddImmediate(Register dest, Register rn, int64_t imm) {
  Operand op;
  if (imm == 0) {
    if (dest != rn) {
      mov(dest, rn);
    }
    return;
  }
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    add(dest, rn, op);
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    sub(dest, rn, op);
  } else {
    // TODO(zra): Try adding top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    add(dest, rn, Operand(TMP2));
  }
}

void Assembler::AddImmediateSetFlags(Register dest,
                                     Register rn,
                                     int64_t imm,
                                     OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  Operand op;
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    // Handles imm == kMinInt64.
    if (sz == kEightBytes) {
      adds(dest, rn, op);
    } else {
      addsw(dest, rn, op);
    }
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    ASSERT(imm != kMinInt64);  // Would cause erroneous overflow detection.
    if (sz == kEightBytes) {
      subs(dest, rn, op);
    } else {
      subsw(dest, rn, op);
    }
  } else {
    // TODO(zra): Try adding top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    if (sz == kEightBytes) {
      adds(dest, rn, Operand(TMP2));
    } else {
      addsw(dest, rn, Operand(TMP2));
    }
  }
}

void Assembler::SubImmediateSetFlags(Register dest,
                                     Register rn,
                                     int64_t imm,
                                     OperandSize sz) {
  Operand op;
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    // Handles imm == kMinInt64.
    if (sz == kEightBytes) {
      subs(dest, rn, op);
    } else {
      subsw(dest, rn, op);
    }
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    ASSERT(imm != kMinInt64);  // Would cause erroneous overflow detection.
    if (sz == kEightBytes) {
      adds(dest, rn, op);
    } else {
      addsw(dest, rn, op);
    }
  } else {
    // TODO(zra): Try subtracting top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    if (sz == kEightBytes) {
      subs(dest, rn, Operand(TMP2));
    } else {
      subsw(dest, rn, Operand(TMP2));
    }
  }
}

void Assembler::AndImmediate(Register rd, Register rn, int64_t imm) {
  Operand imm_op;
  if (Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op)) {
    andi(rd, rn, Immediate(imm));
  } else {
    LoadImmediate(TMP, imm);
    and_(rd, rn, Operand(TMP));
  }
}

void Assembler::OrImmediate(Register rd, Register rn, int64_t imm) {
  Operand imm_op;
  if (Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op)) {
    orri(rd, rn, Immediate(imm));
  } else {
    LoadImmediate(TMP, imm);
    orr(rd, rn, Operand(TMP));
  }
}

void Assembler::XorImmediate(Register rd, Register rn, int64_t imm) {
  Operand imm_op;
  if (Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op)) {
    eori(rd, rn, Immediate(imm));
  } else {
    LoadImmediate(TMP, imm);
    eor(rd, rn, Operand(TMP));
  }
}

void Assembler::TestImmediate(Register rn, int64_t imm) {
  Operand imm_op;
  if (Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op)) {
    tsti(rn, Immediate(imm));
  } else {
    LoadImmediate(TMP, imm);
    tst(rn, Operand(TMP));
  }
}

void Assembler::CompareImmediate(Register rn, int64_t imm) {
  Operand op;
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    cmp(rn, op);
  } else if (Operand::CanHold(-static_cast<uint64_t>(imm), kXRegSizeInBits,
                              &op) == Operand::Immediate) {
    cmn(rn, op);
  } else {
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    cmp(rn, Operand(TMP2));
  }
}

void Assembler::LoadFromOffset(Register dest,
                               Register base,
                               int32_t offset,
                               OperandSize sz) {
  if (Address::CanHoldOffset(offset, Address::Offset, sz)) {
    ldr(dest, Address(base, offset, Address::Offset, sz), sz);
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    ldr(dest, Address(TMP2), sz);
  }
}

void Assembler::LoadSFromOffset(VRegister dest, Register base, int32_t offset) {
  if (Address::CanHoldOffset(offset, Address::Offset, kSWord)) {
    fldrs(dest, Address(base, offset, Address::Offset, kSWord));
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    fldrs(dest, Address(TMP2));
  }
}

void Assembler::LoadDFromOffset(VRegister dest, Register base, int32_t offset) {
  if (Address::CanHoldOffset(offset, Address::Offset, kDWord)) {
    fldrd(dest, Address(base, offset, Address::Offset, kDWord));
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    fldrd(dest, Address(TMP2));
  }
}

void Assembler::LoadQFromOffset(VRegister dest, Register base, int32_t offset) {
  if (Address::CanHoldOffset(offset, Address::Offset, kQWord)) {
    fldrq(dest, Address(base, offset, Address::Offset, kQWord));
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    fldrq(dest, Address(TMP2));
  }
}

void Assembler::StoreToOffset(Register src,
                              Register base,
                              int32_t offset,
                              OperandSize sz) {
  ASSERT(base != TMP2);
  if (Address::CanHoldOffset(offset, Address::Offset, sz)) {
    str(src, Address(base, offset, Address::Offset, sz), sz);
  } else {
    ASSERT(src != TMP2);
    AddImmediate(TMP2, base, offset);
    str(src, Address(TMP2), sz);
  }
}

void Assembler::StoreSToOffset(VRegister src, Register base, int32_t offset) {
  if (Address::CanHoldOffset(offset, Address::Offset, kSWord)) {
    fstrs(src, Address(base, offset, Address::Offset, kSWord));
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    fstrs(src, Address(TMP2));
  }
}

void Assembler::StoreDToOffset(VRegister src, Register base, int32_t offset) {
  if (Address::CanHoldOffset(offset, Address::Offset, kDWord)) {
    fstrd(src, Address(base, offset, Address::Offset, kDWord));
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    fstrd(src, Address(TMP2));
  }
}

void Assembler::StoreQToOffset(VRegister src, Register base, int32_t offset) {
  if (Address::CanHoldOffset(offset, Address::Offset, kQWord)) {
    fstrq(src, Address(base, offset, Address::Offset, kQWord));
  } else {
    ASSERT(base != TMP2);
    AddImmediate(TMP2, base, offset);
    fstrq(src, Address(TMP2));
  }
}

void Assembler::VRecps(VRegister vd, VRegister vn) {
  ASSERT(vn != VTMP);
  ASSERT(vd != VTMP);

  // Reciprocal estimate.
  vrecpes(vd, vn);
  // 2 Newton-Raphson steps.
  vrecpss(VTMP, vn, vd);
  vmuls(vd, vd, VTMP);
  vrecpss(VTMP, vn, vd);
  vmuls(vd, vd, VTMP);
}

void Assembler::VRSqrts(VRegister vd, VRegister vn) {
  ASSERT(vd != VTMP);
  ASSERT(vn != VTMP);

  // Reciprocal square root estimate.
  vrsqrtes(vd, vn);
  // 2 Newton-Raphson steps. xn+1 = xn * (3 - V1*xn^2) / 2.
  // First step.
  vmuls(VTMP, vd, vd);       // VTMP <- xn^2
  vrsqrtss(VTMP, vn, VTMP);  // VTMP <- (3 - V1*VTMP) / 2.
  vmuls(vd, vd, VTMP);       // xn+1 <- xn * VTMP
  // Second step.
  vmuls(VTMP, vd, vd);
  vrsqrtss(VTMP, vn, VTMP);
  vmuls(vd, vd, VTMP);
}

// Preserves object and value registers.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* label,
                                      CanBeSmi value_can_be_smi,
                                      BarrierFilterMode how_to_jump) {
  COMPILE_ASSERT((target::ObjectAlignment::kNewObjectAlignmentOffset ==
                  target::kWordSize) &&
                 (target::ObjectAlignment::kOldObjectAlignmentOffset == 0));

  // Write-barrier triggers if the value is in the new space (has bit set) and
  // the object is in the old space (has bit cleared).
  if (value_can_be_smi == kValueIsNotSmi) {
#if defined(DEBUG)
    Label okay;
    BranchIfNotSmi(value, &okay);
    Stop("Unexpected Smi!");
    Bind(&okay);
#endif
    // To check that, we compute value & ~object and skip the write barrier
    // if the bit is not set. We can't destroy the object.
    bic(TMP, value, Operand(object));
  } else {
    // For the value we are only interested in the new/old bit and the tag bit.
    // And the new bit with the tag bit. The resulting bit will be 0 for a Smi.
    and_(TMP, value,
         Operand(value, LSL, target::ObjectAlignment::kNewObjectBitPosition));
    // And the result with the negated space bit of the object.
    bic(TMP, TMP, Operand(object));
  }
  if (how_to_jump == kJumpToNoUpdate) {
    tbz(label, TMP, target::ObjectAlignment::kNewObjectBitPosition);
  } else {
    tbnz(label, TMP, target::ObjectAlignment::kNewObjectBitPosition);
  }
}

void Assembler::StoreIntoObjectOffset(Register object,
                                      int32_t offset,
                                      Register value,
                                      CanBeSmi value_can_be_smi) {
  if (Address::CanHoldOffset(offset - kHeapObjectTag)) {
    StoreIntoObject(object, FieldAddress(object, offset), value,
                    value_can_be_smi);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObject(object, Address(TMP), value, value_can_be_smi);
  }
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_be_smi) {
  const bool spill_lr = lr_state().LRContainsReturnAddress();
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);
  ASSERT(object != LINK_REGISTER);
  ASSERT(value != LINK_REGISTER);
  ASSERT(object != TMP);
  ASSERT(object != TMP2);
  ASSERT(value != TMP);
  ASSERT(value != TMP2);

  str(value, dest);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare ObjectLayout::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done);
  }
  ldr(TMP, FieldAddress(object, target::Object::tags_offset(), kByte),
      kUnsignedByte);
  ldr(TMP2, FieldAddress(value, target::Object::tags_offset(), kByte),
      kUnsignedByte);
  and_(TMP, TMP2,
       Operand(TMP, LSR, target::ObjectLayout::kBarrierOverlapShift));
  tst(TMP, Operand(BARRIER_MASK));
  b(&done, ZERO);

  if (spill_lr) {
    SPILLS_LR_TO_FRAME(Push(LR));
  }
  Register objectForCall = object;
  if (value != kWriteBarrierValueReg) {
    // Unlikely. Only non-graph intrinsics.
    // TODO(rmacnak): Shuffle registers in intrinsics.
    if (object != kWriteBarrierValueReg) {
      Push(kWriteBarrierValueReg);
    } else {
      COMPILE_ASSERT(R2 != kWriteBarrierValueReg);
      COMPILE_ASSERT(R3 != kWriteBarrierValueReg);
      objectForCall = (value == R2) ? R3 : R2;
      PushPair(kWriteBarrierValueReg, objectForCall);
      mov(objectForCall, object);
    }
    mov(kWriteBarrierValueReg, value);
  }

  generate_invoke_write_barrier_wrapper_(objectForCall);

  if (value != kWriteBarrierValueReg) {
    if (object != kWriteBarrierValueReg) {
      Pop(kWriteBarrierValueReg);
    } else {
      PopPair(kWriteBarrierValueReg, objectForCall);
    }
  }
  if (spill_lr) {
    RESTORES_LR_FROM_FRAME(Pop(LR));
  }
  Bind(&done);
}

void Assembler::StoreIntoArray(Register object,
                               Register slot,
                               Register value,
                               CanBeSmi can_be_smi) {
  const bool spill_lr = lr_state().LRContainsReturnAddress();
  ASSERT(object != TMP);
  ASSERT(object != TMP2);
  ASSERT(value != TMP);
  ASSERT(value != TMP2);
  ASSERT(slot != TMP);
  ASSERT(slot != TMP2);

  str(value, Address(slot, 0));

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare ObjectLayout::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done);
  }
  ldr(TMP, FieldAddress(object, target::Object::tags_offset(), kByte),
      kUnsignedByte);
  ldr(TMP2, FieldAddress(value, target::Object::tags_offset(), kByte),
      kUnsignedByte);
  and_(TMP, TMP2,
       Operand(TMP, LSR, target::ObjectLayout::kBarrierOverlapShift));
  tst(TMP, Operand(BARRIER_MASK));
  b(&done, ZERO);
  if (spill_lr) {
    SPILLS_LR_TO_FRAME(Push(LR));
  }
  if ((object != kWriteBarrierObjectReg) || (value != kWriteBarrierValueReg) ||
      (slot != kWriteBarrierSlotReg)) {
    // Spill and shuffle unimplemented. Currently StoreIntoArray is only used
    // from StoreIndexInstr, which gets these exact registers from the register
    // allocator.
    UNIMPLEMENTED();
  }
  generate_invoke_array_write_barrier_();
  if (spill_lr) {
    RESTORES_LR_FROM_FRAME(Pop(LR));
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  str(value, dest);
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value, &done, kValueCanBeSmi, kJumpToNoUpdate);

  ldr(TMP, FieldAddress(object, target::Object::tags_offset(), kByte),
      kUnsignedByte);
  tsti(TMP, Immediate(1 << target::ObjectLayout::kOldAndNotRememberedBit));
  b(&done, ZERO);

  Stop("Store buffer update is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::StoreIntoObjectOffsetNoBarrier(Register object,
                                               int32_t offset,
                                               Register value) {
  if (Address::CanHoldOffset(offset - kHeapObjectTag)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(TMP), value);
  }
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  ASSERT(IsOriginalObject(value));
  ASSERT(IsNotTemporaryScopedHandle(value));
  // No store buffer update.
  if (IsSameObject(compiler::NullObject(), value)) {
    str(NULL_REG, dest);
  } else {
    LoadObject(TMP2, value);
    str(TMP2, dest);
  }
}

void Assembler::StoreIntoObjectOffsetNoBarrier(Register object,
                                               int32_t offset,
                                               const Object& value) {
  if (Address::CanHoldOffset(offset - kHeapObjectTag)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(TMP), value);
  }
}

void Assembler::StoreInternalPointer(Register object,
                                     const Address& dest,
                                     Register value) {
  str(value, dest);
}

void Assembler::ExtractClassIdFromTags(Register result, Register tags) {
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  LsrImmediate(result, tags, target::ObjectLayout::kClassIdTagPos, kFourBytes);
}

void Assembler::ExtractInstanceSizeFromTags(Register result, Register tags) {
  ASSERT(target::ObjectLayout::kSizeTagPos == 8);
  ASSERT(target::ObjectLayout::kSizeTagSize == 8);
  ubfx(result, tags, target::ObjectLayout::kSizeTagPos,
       target::ObjectLayout::kSizeTagSize);
  LslImmediate(result, result, target::ObjectAlignment::kObjectAlignmentLog2);
}

void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  const intptr_t class_id_offset =
      target::Object::tags_offset() +
      target::ObjectLayout::kClassIdTagPos / kBitsPerByte;
  LoadFromOffset(result, object, class_id_offset - kHeapObjectTag,
                 kUnsignedTwoBytes);
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);

  const intptr_t table_offset =
      target::Isolate::cached_class_table_table_offset();

  LoadIsolate(result);
  LoadFromOffset(result, result, table_offset);
  ldr(result, Address(result, class_id, UXTX, Address::Scaled));
}

void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  LoadClassId(TMP, object);
  CompareImmediate(TMP, class_id);
}

void Assembler::LoadClassIdMayBeSmi(Register result, Register object) {
  ASSERT(result != object);
  Label done;
  LoadImmediate(result, kSmiCid);
  BranchIfSmi(object, &done);
  LoadClassId(result, object);
  Bind(&done);
}

void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  if (result == object) {
    LoadClassIdMayBeSmi(TMP, object);
    SmiTag(result, TMP);
  } else {
    Label done;
    LoadImmediate(result, target::ToRawSmi(kSmiCid));
    BranchIfSmi(object, &done);
    LoadClassId(result, object);
    SmiTag(result);
    Bind(&done);
  }
}

// Frame entry and exit.
void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  if (frame_space != 0) {
    AddImmediate(SP, -frame_space);
  }
  if (OS::ActivationFrameAlignment() > 1) {
    andi(SP, SP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }
}

void Assembler::EmitEntryFrameVerification() {
#if defined(DEBUG)
  Label done;
  ASSERT(!constant_pool_allowed());
  LoadImmediate(TMP, target::frame_layout.exit_link_slot_from_entry_fp *
                         target::kWordSize);
  add(TMP, TMP, Operand(FPREG));
  cmp(TMP, Operand(SPREG));
  b(&done, EQ);

  Breakpoint();

  Bind(&done);
#endif
}

void Assembler::RestoreCodePointer() {
  ldr(CODE_REG,
      Address(FP, target::frame_layout.code_from_fp * target::kWordSize));
  CheckCodePointer();
}

void Assembler::RestorePinnedRegisters() {
  ldr(BARRIER_MASK,
      compiler::Address(THR, target::Thread::write_barrier_mask_offset()));
  ldr(NULL_REG, compiler::Address(THR, target::Thread::object_null_offset()));
}

void Assembler::SetupGlobalPoolAndDispatchTable() {
  ASSERT(FLAG_precompiled_mode && FLAG_use_bare_instructions);
  ldr(PP, Address(THR, target::Thread::global_object_pool_offset()));
  sub(PP, PP, Operand(kHeapObjectTag));  // Pool in PP is untagged!
  if (FLAG_use_table_dispatch) {
    ldr(DISPATCH_TABLE_REG,
        Address(THR, target::Thread::dispatch_table_array_offset()));
  }
}

void Assembler::CheckCodePointer() {
#ifdef DEBUG
  if (!FLAG_check_code_pointer) {
    return;
  }
  Comment("CheckCodePointer");
  Label cid_ok, instructions_ok;
  Push(R0);
  CompareClassId(CODE_REG, kCodeCid);
  b(&cid_ok, EQ);
  brk(0);
  Bind(&cid_ok);

  const intptr_t entry_offset =
      CodeSize() + target::Instructions::HeaderSize() - kHeapObjectTag;
  adr(R0, Immediate(-entry_offset));
  ldr(TMP, FieldAddress(CODE_REG, target::Code::saved_instructions_offset()));
  cmp(R0, Operand(TMP));
  b(&instructions_ok, EQ);
  brk(1);
  Bind(&instructions_ok);
  Pop(R0);
#endif
}

// The ARM64 ABI requires at all times
//   - stack limit < CSP <= stack base
//   - CSP mod 16 = 0
//   - we do not access stack memory below CSP
// Practically, this means we need to keep the C stack pointer ahead of the
// Dart stack pointer and 16-byte aligned for signal handlers. We set
// CSP to a value near the stack limit during SetupDartSP*, and use a different
// register within our generated code to avoid the alignment requirement.
// Note that Fuchsia does not have signal handlers.

void Assembler::SetupDartSP(intptr_t reserve /* = 4096 */) {
  mov(SP, CSP);
  // The caller doesn't have a Thread available. Just kick CSP forward a bit.
  AddImmediate(CSP, CSP, -Utils::RoundUp(reserve, 16));
}

void Assembler::SetupCSPFromThread(Register thr) {
  // Thread::saved_stack_limit_ is OSThread::overflow_stack_limit(), which is
  // OSThread::stack_limit() with some headroom. Set CSP a bit below this value
  // so that signal handlers won't stomp on the stack of Dart code that pushs a
  // bit past overflow_stack_limit before its next overflow check. (We build
  // frames before doing an overflow check.)
  ldr(TMP, Address(thr, target::Thread::saved_stack_limit_offset()));
  AddImmediate(CSP, TMP, -4096);
}

void Assembler::RestoreCSP() {
  mov(CSP, SP);
}

void Assembler::EnterFrame(intptr_t frame_size) {
  SPILLS_LR_TO_FRAME(PushPair(FP, LR));  // low: FP, high: LR.
  mov(FP, SP);

  if (frame_size > 0) {
    sub(SP, SP, Operand(frame_size));
  }
}

void Assembler::LeaveFrame() {
  mov(SP, FP);
  RESTORES_LR_FROM_FRAME(PopPair(FP, LR));  // low: FP, high: LR.
}

void Assembler::EnterDartFrame(intptr_t frame_size, Register new_pp) {
  ASSERT(!constant_pool_allowed());
  // Setup the frame.
  EnterFrame(0);

  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    TagAndPushPPAndPcMarker();  // Save PP and PC marker.

    // Load the pool pointer.
    if (new_pp == kNoRegister) {
      LoadPoolPointer();
    } else {
      mov(PP, new_pp);
    }
  }
  set_constant_pool_allowed(true);

  // Reserve space.
  if (frame_size > 0) {
    AddImmediate(SP, -frame_size);
  }
}

// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate. We must also set up the pool pointer for the function.
void Assembler::EnterOsrFrame(intptr_t extra_size, Register new_pp) {
  ASSERT(!constant_pool_allowed());
  Comment("EnterOsrFrame");
  RestoreCodePointer();
  LoadPoolPointer();

  if (extra_size > 0) {
    AddImmediate(SP, -extra_size);
  }
}

void Assembler::LeaveDartFrame(RestorePP restore_pp) {
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    if (restore_pp == kRestoreCallerPP) {
      // Restore and untag PP.
      LoadFromOffset(
          PP, FP,
          target::frame_layout.saved_caller_pp_from_fp * target::kWordSize);
      sub(PP, PP, Operand(kHeapObjectTag));
    }
  }
  set_constant_pool_allowed(false);
  LeaveFrame();
}

void Assembler::EnterSafepoint(Register state) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced. This simplifies GenerateJitCallbackTrampolines.

  Register addr = TMP2;
  ASSERT(addr != state);

  Label slow_path, done, retry;
  if (FLAG_use_slow_path) {
    b(&slow_path);
  }

  movz(addr, Immediate(target::Thread::safepoint_state_offset()), 0);
  add(addr, THR, Operand(addr));
  Bind(&retry);
  ldxr(state, addr);
  cmp(state, Operand(target::Thread::safepoint_state_unacquired()));
  b(&slow_path, NE);

  movz(state, Immediate(target::Thread::safepoint_state_acquired()), 0);
  stxr(TMP, state, addr);
  cbz(&done, TMP);  // 0 means stxr was successful.

  if (!FLAG_use_slow_path) {
    b(&retry);
  }

  Bind(&slow_path);
  ldr(addr, Address(THR, target::Thread::enter_safepoint_stub_offset()));
  ldr(addr, FieldAddress(addr, target::Code::entry_point_offset()));
  blr(addr);

  Bind(&done);
}

void Assembler::TransitionGeneratedToNative(Register destination,
                                            Register new_exit_frame,
                                            Register new_exit_through_ffi,
                                            bool enter_safepoint) {
  // Save exit frame information to enable stack walking.
  StoreToOffset(new_exit_frame, THR,
                target::Thread::top_exit_frame_info_offset());

  StoreToOffset(new_exit_through_ffi, THR,
                target::Thread::exit_through_ffi_offset());
  Register tmp = new_exit_through_ffi;

  // Mark that the thread is executing native code.
  StoreToOffset(destination, THR, target::Thread::vm_tag_offset());
  LoadImmediate(tmp, target::Thread::native_execution_state());
  StoreToOffset(tmp, THR, target::Thread::execution_state_offset());

  if (enter_safepoint) {
    EnterSafepoint(tmp);
  }
}

void Assembler::ExitSafepoint(Register state) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterSafepoint.
  Register addr = TMP2;
  ASSERT(addr != state);

  Label slow_path, done, retry;
  if (FLAG_use_slow_path) {
    b(&slow_path);
  }

  movz(addr, Immediate(target::Thread::safepoint_state_offset()), 0);
  add(addr, THR, Operand(addr));
  Bind(&retry);
  ldxr(state, addr);
  cmp(state, Operand(target::Thread::safepoint_state_acquired()));
  b(&slow_path, NE);

  movz(state, Immediate(target::Thread::safepoint_state_unacquired()), 0);
  stxr(TMP, state, addr);
  cbz(&done, TMP);  // 0 means stxr was successful.

  if (!FLAG_use_slow_path) {
    b(&retry);
  }

  Bind(&slow_path);
  ldr(addr, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  ldr(addr, FieldAddress(addr, target::Code::entry_point_offset()));
  blr(addr);

  Bind(&done);
}

void Assembler::TransitionNativeToGenerated(Register state,
                                            bool exit_safepoint) {
  if (exit_safepoint) {
    ExitSafepoint(state);
  } else {
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    ldr(TMP, Address(THR, target::Thread::safepoint_state_offset()));
    Label ok;
    tbz(&ok, TMP, target::Thread::safepoint_state_inside_bit());
    Breakpoint();
    Bind(&ok);
#endif
  }

  // Mark that the thread is executing Dart code.
  LoadImmediate(state, target::Thread::vm_tag_dart_id());
  StoreToOffset(state, THR, target::Thread::vm_tag_offset());
  LoadImmediate(state, target::Thread::generated_execution_state());
  StoreToOffset(state, THR, target::Thread::execution_state_offset());

  // Reset exit frame information in Isolate's mutator thread structure.
  StoreToOffset(ZR, THR, target::Thread::top_exit_frame_info_offset());
  LoadImmediate(state, 0);
  StoreToOffset(state, THR, target::Thread::exit_through_ffi_offset());
}

void Assembler::EnterCallRuntimeFrame(intptr_t frame_size, bool is_leaf) {
  Comment("EnterCallRuntimeFrame");
  EnterFrame(0);
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    TagAndPushPPAndPcMarker();  // Save PP and PC marker.
  }

  // Store fpu registers with the lowest register number at the lowest
  // address.
  for (int i = kNumberOfVRegisters - 1; i >= 0; i--) {
    if ((i >= kAbiFirstPreservedFpuReg) && (i <= kAbiLastPreservedFpuReg)) {
      // TODO(zra): When SIMD is added, we must also preserve the top
      // 64-bits of the callee-saved registers.
      continue;
    }
    // TODO(zra): Save the whole V register.
    VRegister reg = static_cast<VRegister>(i);
    PushDouble(reg);
  }

  for (int i = kDartFirstVolatileCpuReg; i <= kDartLastVolatileCpuReg; i++) {
    const Register reg = static_cast<Register>(i);
    Push(reg);
  }

  if (!is_leaf) {  // Leaf calling sequence aligns the stack itself.
    ReserveAlignedFrameSpace(frame_size);
  } else {
    PushPair(kCallLeafRuntimeCalleeSaveScratch1,
             kCallLeafRuntimeCalleeSaveScratch2);
  }
}

void Assembler::LeaveCallRuntimeFrame(bool is_leaf) {
  // SP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  const intptr_t fixed_frame_words_without_pc_and_fp =
      target::frame_layout.dart_fixed_frame_size - 2;
  const intptr_t kPushedRegistersSize =
      kDartVolatileFpuRegCount * sizeof(double) +
      (kDartVolatileCpuRegCount + (is_leaf ? 2 : 0) +
       fixed_frame_words_without_pc_and_fp) *
          target::kWordSize;
  AddImmediate(SP, FP, -kPushedRegistersSize);
  if (is_leaf) {
    PopPair(kCallLeafRuntimeCalleeSaveScratch1,
            kCallLeafRuntimeCalleeSaveScratch2);
  }
  for (int i = kDartLastVolatileCpuReg; i >= kDartFirstVolatileCpuReg; i--) {
    const Register reg = static_cast<Register>(i);
    Pop(reg);
  }

  for (int i = 0; i < kNumberOfVRegisters; i++) {
    if ((i >= kAbiFirstPreservedFpuReg) && (i <= kAbiLastPreservedFpuReg)) {
      // TODO(zra): When SIMD is added, we must also restore the top
      // 64-bits of the callee-saved registers.
      continue;
    }
    // TODO(zra): Restore the whole V register.
    VRegister reg = static_cast<VRegister>(i);
    PopDouble(reg);
  }

  LeaveStubFrame();
}

void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}

void Assembler::CallRuntimeScope::Call(intptr_t argument_count) {
  assembler_->CallRuntime(entry_, argument_count);
}

Assembler::CallRuntimeScope::~CallRuntimeScope() {
  if (preserve_registers_) {
    assembler_->LeaveCallRuntimeFrame(entry_.is_leaf());
    if (restore_code_reg_) {
      assembler_->Pop(CODE_REG);
    }
  }
}

Assembler::CallRuntimeScope::CallRuntimeScope(Assembler* assembler,
                                              const RuntimeEntry& entry,
                                              intptr_t frame_size,
                                              bool preserve_registers,
                                              const Address* caller)
    : assembler_(assembler),
      entry_(entry),
      preserve_registers_(preserve_registers),
      restore_code_reg_(caller != nullptr) {
  if (preserve_registers_) {
    if (caller != nullptr) {
      assembler_->Push(CODE_REG);
      assembler_->ldr(CODE_REG, *caller);
    }
    assembler_->EnterCallRuntimeFrame(frame_size, entry.is_leaf());
  }
}

void Assembler::EnterStubFrame() {
  EnterDartFrame(0);
}

void Assembler::LeaveStubFrame() {
  LeaveDartFrame();
}

void Assembler::EnterCFrame(intptr_t frame_space) {
  Push(FP);
  mov(FP, SP);
  ReserveAlignedFrameSpace(frame_space);
}

void Assembler::LeaveCFrame() {
  mov(SP, FP);
  Pop(FP);
}

// R0 receiver, R5 ICData entries array
// Preserve R4 (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryJIT() {
  has_monomorphic_entry_ = true;
  const bool saved_use_far_branches = use_far_branches();
  set_use_far_branches(false);
  const intptr_t start = CodeSize();

  Label immediate, miss;
  Bind(&miss);
  ldr(IP0, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  br(IP0);

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetJIT);

  const intptr_t cid_offset = target::Array::element_offset(0);
  const intptr_t count_offset = target::Array::element_offset(1);

  // Sadly this cannot use ldp because ldp requires aligned offsets.
  ldr(R1, FieldAddress(R5, cid_offset));
  ldr(R2, FieldAddress(R5, count_offset));
  LoadClassIdMayBeSmi(IP0, R0);
  add(R2, R2, Operand(target::ToRawSmi(1)));
  cmp(R1, Operand(IP0, LSL, 1));
  b(&miss, NE);
  str(R2, FieldAddress(R5, count_offset));
  LoadImmediate(R4, 0);  // GC-safe for OptimizeInvokedFunction

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetJIT);

  set_use_far_branches(saved_use_far_branches);
}

// R0 receiver, R5 guarded cid as Smi.
// Preserve R4 (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryAOT() {
  has_monomorphic_entry_ = true;
  bool saved_use_far_branches = use_far_branches();
  set_use_far_branches(false);

  const intptr_t start = CodeSize();

  Label immediate, miss;
  Bind(&miss);
  ldr(IP0, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  br(IP0);

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetAOT);
  LoadClassId(IP0, R0);
  cmp(R5, Operand(IP0, LSL, 1));
  b(&miss, NE);

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetAOT);

  set_use_far_branches(saved_use_far_branches);
}

void Assembler::BranchOnMonomorphicCheckedEntryJIT(Label* label) {
  has_monomorphic_entry_ = true;
  while (CodeSize() < target::Instructions::kMonomorphicEntryOffsetJIT) {
    brk(0);
  }
  b(label);
  while (CodeSize() < target::Instructions::kPolymorphicEntryOffsetJIT) {
    brk(0);
  }
}

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Register temp_reg,
                                     Label* trace) {
  ASSERT(cid > 0);

  const intptr_t shared_table_offset =
      target::Isolate::shared_class_table_offset();
  const intptr_t table_offset =
      target::SharedClassTable::class_heap_stats_table_offset();
  const intptr_t class_offset = target::ClassTable::ClassOffsetFor(cid);

  LoadIsolate(temp_reg);
  ldr(temp_reg, Address(temp_reg, shared_table_offset));
  ldr(temp_reg, Address(temp_reg, table_offset));
  AddImmediate(temp_reg, class_offset);
  ldr(temp_reg, Address(temp_reg, 0), kUnsignedByte);
  cbnz(trace, temp_reg);
}
#endif  // !PRODUCT

void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            Register instance_reg,
                            Register top_reg,
                            bool tag_result) {
  ASSERT(failure != NULL);
  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    const classid_t cid = target::Class::GetId(cls);
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, /*temp_reg=*/top_reg, failure));

    const Register kEndReg = TMP;

    // instance_reg: potential next object start.
    RELEASE_ASSERT((target::Thread::top_offset() + target::kWordSize) ==
                   target::Thread::end_offset());
    ldp(instance_reg, kEndReg,
        Address(THR, target::Thread::top_offset(), Address::PairOffset));

    // TODO(koda): Protect against unsigned overflow here.
    AddImmediate(top_reg, instance_reg, instance_size);
    cmp(kEndReg, Operand(top_reg));
    b(failure, LS);  // Unsigned lower or equal.

    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    str(top_reg, Address(THR, target::Thread::top_offset()));

    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(TMP, tags);
    StoreToOffset(TMP, instance_reg, target::Object::tags_offset());

    if (tag_result) {
      AddImmediate(instance_reg, kHeapObjectTag);
    }
  } else {
    b(failure);
  }
}

void Assembler::TryAllocateArray(intptr_t cid,
                                 intptr_t instance_size,
                                 Label* failure,
                                 Register instance,
                                 Register end_address,
                                 Register temp1,
                                 Register temp2) {
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, temp1, failure));
    // Potential new object start.
    ldr(instance, Address(THR, target::Thread::top_offset()));
    AddImmediateSetFlags(end_address, instance, instance_size);
    b(failure, CS);  // Fail on unsigned overflow.

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start.
    // end_address: potential next object start.
    ldr(temp2, Address(THR, target::Thread::end_offset()));
    cmp(end_address, Operand(temp2));
    b(failure, CS);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    str(end_address, Address(THR, target::Thread::top_offset()));
    add(instance, instance, Operand(kHeapObjectTag));
    NOT_IN_PRODUCT(LoadImmediate(temp2, instance_size));

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(temp2, tags);
    str(temp2, FieldAddress(instance, target::Object::tags_offset()));
  } else {
    b(failure);
  }
}

void Assembler::GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target) {
  // Emit "bl <offset>".
  EmitUnconditionalBranchOp(BL, 0);

  PcRelativeCallPattern pattern(buffer_.contents() + buffer_.Size() -
                                PcRelativeCallPattern::kLengthInBytes);
  pattern.set_distance(offset_into_target);
}

void Assembler::GenerateUnRelocatedPcRelativeTailCall(
    intptr_t offset_into_target) {
  // Emit "b <offset>".
  EmitUnconditionalBranchOp(B, 0);
  PcRelativeTailCallPattern pattern(buffer_.contents() + buffer_.Size() -
                                    PcRelativeTailCallPattern::kLengthInBytes);
  pattern.set_distance(offset_into_target);
}

Address Assembler::ElementAddressForIntIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             intptr_t index) const {
  const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
  ASSERT(Utils::IsInt(32, offset));
  const OperandSize size = Address::OperandSizeFor(cid);
  ASSERT(Address::CanHoldOffset(offset, Address::Offset, size));
  return Address(array, static_cast<int32_t>(offset), Address::Offset, size);
}

void Assembler::ComputeElementAddressForIntIndex(Register address,
                                                 bool is_external,
                                                 intptr_t cid,
                                                 intptr_t index_scale,
                                                 Register array,
                                                 intptr_t index) {
  const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
  AddImmediate(address, array, offset);
}

Address Assembler::ElementAddressForRegIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             bool index_unboxed,
                                             Register array,
                                             Register index,
                                             Register temp) {
  return ElementAddressForRegIndexWithSize(
      is_external, cid, Address::OperandSizeFor(cid), index_scale,
      index_unboxed, array, index, temp);
}

Address Assembler::ElementAddressForRegIndexWithSize(bool is_external,
                                                     intptr_t cid,
                                                     OperandSize size,
                                                     intptr_t index_scale,
                                                     bool index_unboxed,
                                                     Register array,
                                                     Register index,
                                                     Register temp) {
  // If unboxed, index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
  const int32_t offset = HeapDataOffset(is_external, cid);
  ASSERT(array != temp);
  ASSERT(index != temp);
  if ((offset == 0) && (shift == 0)) {
    return Address(array, index, UXTX, Address::Unscaled);
  } else if (shift < 0) {
    ASSERT(shift == -1);
    add(temp, array, Operand(index, ASR, 1));
  } else {
    add(temp, array, Operand(index, LSL, shift));
  }
  ASSERT(Address::CanHoldOffset(offset, Address::Offset, size));
  return Address(temp, offset, Address::Offset, size);
}

void Assembler::ComputeElementAddressForRegIndex(Register address,
                                                 bool is_external,
                                                 intptr_t cid,
                                                 intptr_t index_scale,
                                                 bool index_unboxed,
                                                 Register array,
                                                 Register index) {
  // If unboxed, index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
  const int32_t offset = HeapDataOffset(is_external, cid);
  if (shift == 0) {
    add(address, array, Operand(index));
  } else if (shift < 0) {
    ASSERT(shift == -1);
    add(address, array, Operand(index, ASR, 1));
  } else {
    add(address, array, Operand(index, LSL, shift));
  }
  if (offset != 0) {
    AddImmediate(address, offset);
  }
}

void Assembler::LoadFieldAddressForRegOffset(Register address,
                                             Register instance,
                                             Register offset_in_words_as_smi) {
  add(address, instance,
      Operand(offset_in_words_as_smi, LSL,
              target::kWordSizeLog2 - kSmiTagShift));
  AddImmediate(address, -kHeapObjectTag);
}

void Assembler::PushRegisters(const RegisterSet& regs) {
  const intptr_t fpu_regs_count = regs.FpuRegisterCount();
  if (fpu_regs_count > 0) {
    // Store fpu registers with the lowest register number at the lowest
    // address.
    for (intptr_t i = kNumberOfVRegisters - 1; i >= 0; --i) {
      VRegister fpu_reg = static_cast<VRegister>(i);
      if (regs.ContainsFpuRegister(fpu_reg)) {
        PushQuad(fpu_reg);
      }
    }
  }

  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safe point's stack map.
  Register prev = kNoRegister;
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      if (prev != kNoRegister) {
        PushPair(/*low=*/reg, /*high=*/prev);
        prev = kNoRegister;
      } else {
        prev = reg;
      }
    }
  }
  if (prev != kNoRegister) {
    Push(prev);
  }
}

void Assembler::PopRegisters(const RegisterSet& regs) {
  bool pop_single = (regs.CpuRegisterCount() & 1) == 1;
  Register prev = kNoRegister;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      if (pop_single) {
        // Emit the leftover pop at the beginning instead of the end to
        // mirror PushRegisters.
        Pop(reg);
        pop_single = false;
      } else if (prev != kNoRegister) {
        PopPair(/*low=*/prev, /*high=*/reg);
        prev = kNoRegister;
      } else {
        prev = reg;
      }
    }
  }
  ASSERT(prev == kNoRegister);

  const intptr_t fpu_regs_count = regs.FpuRegisterCount();
  if (fpu_regs_count > 0) {
    // Fpu registers have the lowest register number at the lowest address.
    for (intptr_t i = 0; i < kNumberOfVRegisters; ++i) {
      VRegister fpu_reg = static_cast<VRegister>(i);
      if (regs.ContainsFpuRegister(fpu_reg)) {
        PopQuad(fpu_reg);
      }
    }
  }
}

void Assembler::PushNativeCalleeSavedRegisters() {
  // Save the callee-saved registers.
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    // We use str instead of the Push macro because we will be pushing the PP
    // register when it is not holding a pool-pointer since we are coming from
    // C++ code.
    str(r, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  }

  // Save the bottom 64-bits of callee-saved V registers.
  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    PushDouble(r);
  }
}

void Assembler::PopNativeCalleeSavedRegisters() {
  // Restore the bottom 64-bits of callee-saved V registers.
  for (int i = kAbiLastPreservedFpuReg; i >= kAbiFirstPreservedFpuReg; i--) {
    const VRegister r = static_cast<VRegister>(i);
    PopDouble(r);
  }

  // Restore C++ ABI callee-saved registers.
  for (int i = kAbiLastPreservedCpuReg; i >= kAbiFirstPreservedCpuReg; i--) {
    Register r = static_cast<Register>(i);
    // We use ldr instead of the Pop macro because we will be popping the PP
    // register when it is not holding a pool-pointer since we are returning to
    // C++ code. We also skip the dart stack pointer SP, since we are still
    // using it as the stack pointer.
    ldr(r, Address(SP, 1 * target::kWordSize, Address::PostIndex));
  }
}

bool Assembler::CanGenerateXCbzTbz(Register rn, Condition cond) {
  if (rn == CSP) {
    return false;
  }
  switch (cond) {
    case EQ:  // equal
    case NE:  // not equal
    case MI:  // minus/negative
    case LT:  // signed less than
    case PL:  // plus/positive or zero
    case GE:  // signed greater than or equal
      return true;
    default:
      return false;
  }
}

void Assembler::GenerateXCbzTbz(Register rn, Condition cond, Label* label) {
  constexpr int32_t bit_no = 63;
  constexpr OperandSize sz = kEightBytes;
  ASSERT(rn != CSP);
  switch (cond) {
    case EQ:  // equal
      cbz(label, rn, sz);
      return;
    case NE:  // not equal
      cbnz(label, rn, sz);
      return;
    case MI:  // minus/negative
    case LT:  // signed less than
      tbnz(label, rn, bit_no);
      return;
    case PL:  // plus/positive or zero
    case GE:  // signed greater than or equal
      tbz(label, rn, bit_no);
      return;
    default:
      // Only conditions above allow single instruction emission.
      UNREACHABLE();
  }
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
