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
#include "vm/tags.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, precompiled_mode);

DEFINE_FLAG(bool, use_far_branches, false, "Always use far branches");

// For use by LR related macros (e.g. CLOBBERS_LR).
#define __ this->

namespace compiler {

Assembler::Assembler(ObjectPoolBuilder* object_pool_builder,
                     intptr_t far_branch_level)
    : AssemblerBase(object_pool_builder),
      use_far_branches_(far_branch_level != 0),
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

int32_t Assembler::BindImm26Branch(int64_t position, int64_t dest) {
  ASSERT(CanEncodeImm26BranchOffset(dest));
  const int32_t next = buffer_.Load<int32_t>(position);
  const int32_t encoded = EncodeImm26BranchOffset(dest, next);
  buffer_.Store<int32_t>(position, encoded);
  return DecodeImm26BranchOffset(next);
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
    ASSERT(c != NV);

    // Grab the link to the next branch.
    const int32_t next = DecodeImm26BranchOffset(far_branch);

    // dest is the offset is from the guarding branch instruction.
    // Correct it to be from the following instruction.
    const int64_t offset = dest - Instr::kInstrSize;

    // Encode the branch.
    const int32_t encoded_branch = EncodeImm26BranchOffset(offset, far_branch);

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
    ASSERT(c != NV);

    // Grab the link to the next branch.
    const int32_t next = DecodeImm26BranchOffset(far_branch);

    // dest is the offset is from the guarding branch instruction.
    // Correct it to be from the following instruction.
    const int64_t offset = dest - Instr::kInstrSize;

    // Encode the branch.
    const int32_t encoded_branch = EncodeImm26BranchOffset(offset, far_branch);

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

void Assembler::ExtendValue(Register rd, Register rn, OperandSize sz) {
  switch (sz) {
    case kEightBytes:
      if (rd == rn) return;  // No operation needed.
      return mov(rd, rn);
    case kUnsignedFourBytes:
      return uxtw(rd, rn);
    case kFourBytes:
      return sxtw(rd, rn);
    case kUnsignedTwoBytes:
      return uxth(rd, rn);
    case kTwoBytes:
      return sxth(rd, rn);
    case kUnsignedByte:
      return uxtb(rd, rn);
    case kByte:
      return sxtb(rd, rn);
    default:
      UNIMPLEMENTED();
      break;
  }
}

// Equivalent to left rotate of kSmiTagSize.
static constexpr intptr_t kBFMTagRotate = kBitsPerInt64 - kSmiTagSize;

void Assembler::ExtendAndSmiTagValue(Register rd, Register rn, OperandSize sz) {
  switch (sz) {
    case kEightBytes:
      return sbfm(rd, rn, kBFMTagRotate, target::kSmiBits + 1);
    case kUnsignedFourBytes:
      return ubfm(rd, rn, kBFMTagRotate, kBitsPerInt32 - 1);
    case kFourBytes:
      return sbfm(rd, rn, kBFMTagRotate, kBitsPerInt32 - 1);
    case kUnsignedTwoBytes:
      return ubfm(rd, rn, kBFMTagRotate, kBitsPerInt16 - 1);
    case kTwoBytes:
      return sbfm(rd, rn, kBFMTagRotate, kBitsPerInt16 - 1);
    case kUnsignedByte:
      return ubfm(rd, rn, kBFMTagRotate, kBitsPerInt8 - 1);
    case kByte:
      return sbfm(rd, rn, kBFMTagRotate, kBitsPerInt8 - 1);
    default:
      UNIMPLEMENTED();
      break;
  }
}

void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  const intptr_t bound_pc = buffer_.Size();

  while (label->IsLinked()) {
    const int64_t position = label->Position();
    const int64_t dest = bound_pc - position;
    const int32_t instr = buffer_.Load<int32_t>(position);
    if (IsTestAndBranch(instr)) {
      label->position_ = BindImm14Branch(position, dest);
    } else if (IsConditionalBranch(instr) || IsCompareAndBranch(instr)) {
      label->position_ = BindImm19Branch(position, dest);
    } else if (IsUnconditionalBranch(instr)) {
      label->position_ = BindImm26Branch(position, dest);
    } else {
      UNREACHABLE();
    }
  }
  label->BindTo(bound_pc, lr_state());
}

#if defined(TARGET_USES_THREAD_SANITIZER)
void Assembler::TsanLoadAcquire(Register addr) {
  LeafRuntimeScope rt(this, /*frame_size=*/0, /*preserve_registers=*/true);
  MoveRegister(R0, addr);
  rt.Call(kTsanLoadAcquireRuntimeEntry, /*argument_count=*/1);
}

void Assembler::TsanStoreRelease(Register addr) {
  LeafRuntimeScope rt(this, /*frame_size=*/0, /*preserve_registers=*/true);
  MoveRegister(R0, addr);
  rt.Call(kTsanStoreReleaseRuntimeEntry, /*argument_count=*/1);
}
#endif

static int CountLeadingZeros(uint64_t value, int width) {
  if (width == 64) return Utils::CountLeadingZeros64(value);
  if (width == 32) return Utils::CountLeadingZeros32(value);
  UNREACHABLE();
  return 0;
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
  ASSERT(imm_op != nullptr);
  ASSERT((width == kWRegSizeInBits) || (width == kXRegSizeInBits));
  if (width == kWRegSizeInBits) {
    value &= 0xffffffffUL;
  }
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

bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(IsOriginalObject(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  DEBUG_ASSERT(IsNotTemporaryScopedHandle(object));
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

void Assembler::LoadIsolateGroup(Register rd) {
  ldr(rd, Address(THR, target::Thread::isolate_group_offset()));
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
    if (target::IsSmi(object)) {
      LoadImmediate(dst, target::ToRawSmi(object));
      return;
    }
  }
  RELEASE_ASSERT(CanLoadFromObjectPool(object));
  const intptr_t index =
      is_unique ? object_pool_builder().AddObject(
                      object, ObjectPoolBuilderEntry::kPatchable)
                : object_pool_builder().FindObject(
                      object, ObjectPoolBuilderEntry::kNotPatchable);
  LoadWordFromPoolIndex(dst, index);
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
  if (IsSameObject(compiler::NullObject(), object)) {
    CompareObjectRegisters(reg, NULL_REG);
  } else if (target::IsSmi(object)) {
    CompareImmediate(reg, target::ToRawSmi(object), kObjectBytes);
  } else {
    LoadObject(TMP, object);
    CompareObjectRegisters(reg, TMP);
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
    const intptr_t index = object_pool_builder().FindImmediate(imm);
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
  if (fmovdi(vd, immd)) return;

  int64_t imm64 = bit_cast<int64_t, double>(immd);
  if (imm64 == 0) {
    veor(vd, vd, vd);
  } else if (constant_pool_allowed()) {
    intptr_t index = object_pool_builder().FindImmediate64(imm64);
    intptr_t offset = target::ObjectPool::element_offset(index);
    LoadDFromOffset(vd, PP, offset);
  } else {
    LoadImmediate(TMP, imm64);
    fmovdr(vd, TMP);
  }
}

void Assembler::LoadQImmediate(VRegister vd, simd128_value_t immq) {
  ASSERT(constant_pool_allowed());
  intptr_t index = object_pool_builder().FindImmediate128(immq);
  intptr_t offset = target::ObjectPool::element_offset(index);
  LoadQFromOffset(vd, PP, offset);
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

void Assembler::BranchLinkWithEquivalence(const Code& target,
                                          const Object& equivalence,
                                          CodeEntryKind entry_kind) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), equivalence);
  LoadWordFromPoolIndex(CODE_REG, index);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::AddImmediate(Register dest,
                             Register rn,
                             int64_t imm,
                             OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand op;
  if (imm == 0) {
    if (dest != rn) {
      mov(dest, rn);
    }
    return;
  }
  if (Operand::CanHold(imm, width, &op) == Operand::Immediate) {
    add(dest, rn, op, sz);
  } else if (Operand::CanHold(-static_cast<uint64_t>(imm), width, &op) ==
             Operand::Immediate) {
    sub(dest, rn, op, sz);
  } else {
    // TODO(zra): Try adding top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    add(dest, rn, Operand(TMP2), sz);
  }
}

void Assembler::AddImmediateSetFlags(Register dest,
                                     Register rn,
                                     int64_t imm,
                                     OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand op;
  if (Operand::CanHold(imm, width, &op) == Operand::Immediate) {
    // Handles imm == kMinInt64.
    adds(dest, rn, op, sz);
  } else if (Operand::CanHold(-static_cast<uint64_t>(imm), width, &op) ==
             Operand::Immediate) {
    ASSERT(imm != kMinInt64);  // Would cause erroneous overflow detection.
    subs(dest, rn, op, sz);
  } else {
    // TODO(zra): Try adding top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    adds(dest, rn, Operand(TMP2), sz);
  }
}

void Assembler::SubImmediateSetFlags(Register dest,
                                     Register rn,
                                     int64_t imm,
                                     OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand op;
  if (Operand::CanHold(imm, width, &op) == Operand::Immediate) {
    // Handles imm == kMinInt64.
    subs(dest, rn, op, sz);
  } else if (Operand::CanHold(-static_cast<uint64_t>(imm), width, &op) ==
             Operand::Immediate) {
    ASSERT(imm != kMinInt64);  // Would cause erroneous overflow detection.
    adds(dest, rn, op, sz);
  } else {
    // TODO(zra): Try subtracting top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    subs(dest, rn, Operand(TMP2), sz);
  }
}

void Assembler::AndImmediate(Register rd,
                             Register rn,
                             int64_t imm,
                             OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand imm_op;
  if (Operand::IsImmLogical(imm, width, &imm_op)) {
    andi(rd, rn, Immediate(imm), sz);
  } else {
    LoadImmediate(TMP, imm);
    and_(rd, rn, Operand(TMP), sz);
  }
}

void Assembler::OrImmediate(Register rd,
                            Register rn,
                            int64_t imm,
                            OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand imm_op;
  if (Operand::IsImmLogical(imm, width, &imm_op)) {
    orri(rd, rn, Immediate(imm), sz);
  } else {
    LoadImmediate(TMP, imm);
    orr(rd, rn, Operand(TMP), sz);
  }
}

void Assembler::XorImmediate(Register rd,
                             Register rn,
                             int64_t imm,
                             OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand imm_op;
  if (Operand::IsImmLogical(imm, width, &imm_op)) {
    eori(rd, rn, Immediate(imm), sz);
  } else {
    LoadImmediate(TMP, imm);
    eor(rd, rn, Operand(TMP), sz);
  }
}

void Assembler::TestImmediate(Register rn, int64_t imm, OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand imm_op;
  if (Operand::IsImmLogical(imm, width, &imm_op)) {
    tsti(rn, Immediate(imm), sz);
  } else {
    LoadImmediate(TMP, imm);
    tst(rn, Operand(TMP), sz);
  }
}

void Assembler::CompareImmediate(Register rn, int64_t imm, OperandSize sz) {
  ASSERT(sz == kEightBytes || sz == kFourBytes);
  int width = sz == kEightBytes ? kXRegSizeInBits : kWRegSizeInBits;
  Operand op;
  if (Operand::CanHold(imm, width, &op) == Operand::Immediate) {
    cmp(rn, op, sz);
  } else if (Operand::CanHold(-static_cast<uint64_t>(imm), width, &op) ==
             Operand::Immediate) {
    cmn(rn, op, sz);
  } else {
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    cmp(rn, Operand(TMP2), sz);
  }
}

Address Assembler::PrepareLargeOffset(Register base,
                                      int32_t offset,
                                      OperandSize sz,
                                      Address::AddressType addr_type) {
  ASSERT(addr_type == Address::AddressType::Offset ||
         addr_type == Address::AddressType::PairOffset);
  if (Address::CanHoldOffset(offset, addr_type, sz)) {
    return Address(base, offset, addr_type);
  }
  ASSERT(base != TMP2);
  Operand op;
  const uint32_t upper20 = offset & 0xfffff000;
  const uint32_t lower12 = offset & 0x00000fff;
  if ((base != CSP) &&
      (Operand::CanHold(upper20, kXRegSizeInBits, &op) == Operand::Immediate) &&
      Address::CanHoldOffset(lower12, addr_type, sz)) {
    add(TMP2, base, op);
    return Address(TMP2, lower12, addr_type);
  }
  LoadImmediate(TMP2, offset);
  if (addr_type == Address::AddressType::Offset) {
    return Address(base, TMP2);
  } else {
    add(TMP2, TMP2, Operand(base));
    return Address(TMP2, 0, Address::AddressType::PairOffset);
  }
}

void Assembler::LoadFromOffset(Register dest,
                               const Address& addr,
                               OperandSize sz) {
  ldr(dest, PrepareLargeOffset(addr.base(), addr.offset(), sz), sz);
}

void Assembler::LoadSFromOffset(VRegister dest, Register base, int32_t offset) {
  fldrs(dest, PrepareLargeOffset(base, offset, kSWord));
}

void Assembler::LoadDFromOffset(VRegister dest, Register base, int32_t offset) {
  fldrd(dest, PrepareLargeOffset(base, offset, kDWord));
}

void Assembler::LoadQFromOffset(VRegister dest, Register base, int32_t offset) {
  fldrq(dest, PrepareLargeOffset(base, offset, kQWord));
}

void Assembler::StoreToOffset(Register src,
                              const Address& addr,
                              OperandSize sz) {
  str(src, PrepareLargeOffset(addr.base(), addr.offset(), sz), sz);
}

void Assembler::StorePairToOffset(Register low,
                                  Register high,
                                  Register base,
                                  int32_t offset,
                                  OperandSize sz) {
  stp(low, high,
      PrepareLargeOffset(base, offset, sz, Address::AddressType::PairOffset),
      sz);
}

void Assembler::StoreSToOffset(VRegister src, Register base, int32_t offset) {
  fstrs(src, PrepareLargeOffset(base, offset, kSWord));
}

void Assembler::StoreDToOffset(VRegister src, Register base, int32_t offset) {
  fstrd(src, PrepareLargeOffset(base, offset, kDWord));
}

void Assembler::StoreQToOffset(VRegister src, Register base, int32_t offset) {
  fstrq(src, PrepareLargeOffset(base, offset, kQWord));
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

void Assembler::LoadCompressed(Register dest, const Address& slot) {
#if !defined(DART_COMPRESSED_POINTERS)
  ldr(dest, slot);
#else
  ldr(dest, slot, kUnsignedFourBytes);  // Zero-extension.
  add(dest, dest, Operand(HEAP_BITS, LSL, 32));
#endif
}

void Assembler::LoadCompressedFromOffset(Register dest,
                                         Register base,
                                         int32_t offset) {
#if !defined(DART_COMPRESSED_POINTERS)
  LoadFromOffset(dest, base, offset, kObjectBytes);
#else
  LoadFromOffset(dest, base, offset, kUnsignedFourBytes);  // Zero-extension.
  add(dest, dest, Operand(HEAP_BITS, LSL, 32));
#endif
}

void Assembler::LoadCompressedSmi(Register dest, const Address& slot) {
#if !defined(DART_COMPRESSED_POINTERS)
  ldr(dest, slot);
#else
  ldr(dest, slot, kUnsignedFourBytes);  // Zero-extension.
#endif
#if defined(DEBUG)
  Label done;
  BranchIfSmi(dest, &done, kNearJump);
  Stop("Expected Smi");
  Bind(&done);
#endif
}

void Assembler::LoadCompressedSmiFromOffset(Register dest,
                                            Register base,
                                            int32_t offset) {
#if !defined(DART_COMPRESSED_POINTERS)
  LoadFromOffset(dest, base, offset);
#else
  LoadFromOffset(dest, base, offset, kUnsignedFourBytes);  // Zero-extension.
#endif
#if defined(DEBUG)
  Label done;
  BranchIfSmi(dest, &done);
  Stop("Expected Smi");
  Bind(&done);
#endif
}

void Assembler::StoreIntoObjectOffset(Register object,
                                      int32_t offset,
                                      Register value,
                                      CanBeSmi value_can_be_smi,
                                      MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreRelease(value, object, offset);
  } else {
    StoreToOffset(value, object, offset - kHeapObjectTag);
  }
  StoreBarrier(object, value, value_can_be_smi);
}

void Assembler::StoreCompressedIntoObjectOffset(Register object,
                                                int32_t offset,
                                                Register value,
                                                CanBeSmi value_can_be_smi,
                                                MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreReleaseCompressed(value, object, offset);
  } else {
    StoreToOffset(value, object, offset - kHeapObjectTag, kObjectBytes);
  }
  StoreBarrier(object, value, value_can_be_smi);
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_be_smi,
                                MemoryOrder memory_order) {
  // stlr does not feature an address operand.
  ASSERT(memory_order == kRelaxedNonAtomic);
  str(value, dest);
  StoreBarrier(object, value, can_be_smi);
}

void Assembler::StoreCompressedIntoObject(Register object,
                                          const Address& dest,
                                          Register value,
                                          CanBeSmi can_be_smi,
                                          MemoryOrder memory_order) {
  // stlr does not feature an address operand.
  ASSERT(memory_order == kRelaxedNonAtomic);
  str(value, dest, kObjectBytes);
  StoreBarrier(object, value, can_be_smi);
}

void Assembler::StoreBarrier(Register object,
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

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare UntaggedObject::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done);
  }
  ldr(TMP, FieldAddress(object, target::Object::tags_offset()), kUnsignedByte);
  ldr(TMP2, FieldAddress(value, target::Object::tags_offset()), kUnsignedByte);
  and_(TMP, TMP2,
       Operand(TMP, LSR, target::UntaggedObject::kBarrierOverlapShift));
  tst(TMP, Operand(HEAP_BITS, LSR, 32));
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
  str(value, Address(slot, 0));
  StoreIntoArrayBarrier(object, slot, value, can_be_smi);
}

void Assembler::StoreCompressedIntoArray(Register object,
                                         Register slot,
                                         Register value,
                                         CanBeSmi can_be_smi) {
  str(value, Address(slot, 0), kObjectBytes);
  StoreIntoArrayBarrier(object, slot, value, can_be_smi);
}

void Assembler::StoreIntoArrayBarrier(Register object,
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

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare UntaggedObject::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done);
  }
  ldr(TMP, FieldAddress(object, target::Object::tags_offset()), kUnsignedByte);
  ldr(TMP2, FieldAddress(value, target::Object::tags_offset()), kUnsignedByte);
  and_(TMP, TMP2,
       Operand(TMP, LSR, target::UntaggedObject::kBarrierOverlapShift));
  tst(TMP, Operand(HEAP_BITS, LSR, 32));
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
                                         Register value,
                                         MemoryOrder memory_order) {
  // stlr does not feature an address operand.
  ASSERT(memory_order == kRelaxedNonAtomic);
  str(value, dest);
#if defined(DEBUG)
  // We can't assert the incremental barrier is not needed here, only the
  // generational barrier. We sometimes omit the write barrier when 'value' is
  // a constant, but we don't eagerly mark 'value' and instead assume it is also
  // reachable via a constant pool, so it doesn't matter if it is not traced via
  // 'object'.
  Label done;
  BranchIfSmi(value, &done, kNearJump);
  ldr(TMP, FieldAddress(value, target::Object::tags_offset()), kUnsignedByte);
  tbz(&done, TMP, target::UntaggedObject::kNewBit);
  ldr(TMP, FieldAddress(object, target::Object::tags_offset()), kUnsignedByte);
  tbz(&done, TMP, target::UntaggedObject::kOldAndNotRememberedBit);
  Stop("Write barrier is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::StoreCompressedIntoObjectNoBarrier(Register object,
                                                   const Address& dest,
                                                   Register value,
                                                   MemoryOrder memory_order) {
  // stlr does not feature an address operand.
  ASSERT(memory_order == kRelaxedNonAtomic);
  str(value, dest, kObjectBytes);
#if defined(DEBUG)
  // We can't assert the incremental barrier is not needed here, only the
  // generational barrier. We sometimes omit the write barrier when 'value' is
  // a constant, but we don't eagerly mark 'value' and instead assume it is also
  // reachable via a constant pool, so it doesn't matter if it is not traced via
  // 'object'.
  Label done;
  BranchIfSmi(value, &done, kNearJump);
  ldr(TMP, FieldAddress(value, target::Object::tags_offset()), kUnsignedByte);
  tbz(&done, TMP, target::UntaggedObject::kNewBit);
  ldr(TMP, FieldAddress(object, target::Object::tags_offset()), kUnsignedByte);
  tbz(&done, TMP, target::UntaggedObject::kOldAndNotRememberedBit);
  Stop("Write barrier is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::StoreIntoObjectOffsetNoBarrier(Register object,
                                               int32_t offset,
                                               Register value,
                                               MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreRelease(value, object, offset);
  } else if (FieldAddress::CanHoldOffset(offset)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(TMP), value);
  }
}

void Assembler::StoreCompressedIntoObjectOffsetNoBarrier(
    Register object,
    int32_t offset,
    Register value,
    MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreReleaseCompressed(value, object, offset);
  } else if (FieldAddress::CanHoldOffset(offset)) {
    StoreCompressedIntoObjectNoBarrier(object, FieldAddress(object, offset),
                                       value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreCompressedIntoObjectNoBarrier(object, Address(TMP), value);
  }
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value,
                                         MemoryOrder memory_order) {
  RELEASE_ASSERT(memory_order == kRelaxedNonAtomic);
  ASSERT(IsOriginalObject(value));
  DEBUG_ASSERT(IsNotTemporaryScopedHandle(value));
  if (IsSameObject(compiler::NullObject(), value)) {
    str(NULL_REG, dest);
  } else if (target::IsSmi(value) && (target::ToRawSmi(value) == 0)) {
    str(ZR, dest);
  } else {
    LoadObject(TMP2, value);
    str(TMP2, dest);
  }
}

void Assembler::StoreCompressedIntoObjectNoBarrier(Register object,
                                                   const Address& dest,
                                                   const Object& value,
                                                   MemoryOrder memory_order) {
  // stlr does not feature an address operand.
  RELEASE_ASSERT(memory_order == kRelaxedNonAtomic);
  ASSERT(IsOriginalObject(value));
  DEBUG_ASSERT(IsNotTemporaryScopedHandle(value));
  // No store buffer update.
  if (IsSameObject(compiler::NullObject(), value)) {
    str(NULL_REG, dest, kObjectBytes);
  } else if (target::IsSmi(value) && (target::ToRawSmi(value) == 0)) {
    str(ZR, dest, kObjectBytes);
  } else {
    LoadObject(TMP2, value);
    str(TMP2, dest, kObjectBytes);
  }
}

void Assembler::StoreIntoObjectOffsetNoBarrier(Register object,
                                               int32_t offset,
                                               const Object& value,
                                               MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    Register value_reg = TMP2;
    if (IsSameObject(compiler::NullObject(), value)) {
      value_reg = NULL_REG;
    } else if (target::IsSmi(value) && (target::ToRawSmi(value) == 0)) {
      value_reg = ZR;
    } else {
      LoadObject(value_reg, value);
    }
    StoreIntoObjectOffsetNoBarrier(object, offset, value_reg, memory_order);
  } else if (FieldAddress::CanHoldOffset(offset)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(TMP), value);
  }
}

void Assembler::StoreCompressedIntoObjectOffsetNoBarrier(
    Register object,
    int32_t offset,
    const Object& value,
    MemoryOrder memory_order) {
  Register value_reg = TMP2;
  if (memory_order == kRelease) {
    if (IsSameObject(compiler::NullObject(), value)) {
      value_reg = NULL_REG;
    } else if (target::IsSmi(value) && (target::ToRawSmi(value) == 0)) {
      value_reg = ZR;
    } else {
      LoadObject(value_reg, value);
    }
    StoreCompressedIntoObjectOffsetNoBarrier(object, offset, value_reg,
                                             memory_order);
  } else if (FieldAddress::CanHoldOffset(offset)) {
    StoreCompressedIntoObjectNoBarrier(object, FieldAddress(object, offset),
                                       value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreCompressedIntoObjectNoBarrier(object, Address(TMP), value);
  }
}

void Assembler::StoreInternalPointer(Register object,
                                     const Address& dest,
                                     Register value) {
  str(value, dest);
}

void Assembler::ExtractClassIdFromTags(Register result, Register tags) {
  ASSERT(target::UntaggedObject::kClassIdTagPos == 12);
  ASSERT(target::UntaggedObject::kClassIdTagSize == 20);
  ubfx(result, tags, target::UntaggedObject::kClassIdTagPos,
       target::UntaggedObject::kClassIdTagSize);
}

void Assembler::ExtractInstanceSizeFromTags(Register result, Register tags) {
  ASSERT(target::UntaggedObject::kSizeTagPos == 8);
  ASSERT(target::UntaggedObject::kSizeTagSize == 4);
  ubfx(result, tags, target::UntaggedObject::kSizeTagPos,
       target::UntaggedObject::kSizeTagSize);
  LslImmediate(result, result, target::ObjectAlignment::kObjectAlignmentLog2);
}

void Assembler::LoadClassId(Register result, Register object) {
  ldr(result, FieldAddress(object, target::Object::tags_offset()));
  ExtractClassIdFromTags(result, result);
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);

  const intptr_t table_offset =
      target::IsolateGroup::cached_class_table_table_offset();

  LoadIsolateGroup(result);
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

void Assembler::EnsureHasClassIdInDEBUG(intptr_t cid,
                                        Register src,
                                        Register scratch,
                                        bool can_be_null) {
#if defined(DEBUG)
  Comment("Check that object in register has cid %" Pd "", cid);
  Label matches;
  LoadClassIdMayBeSmi(scratch, src);
  CompareImmediate(scratch, cid);
  BranchIf(EQUAL, &matches, Assembler::kNearJump);
  if (can_be_null) {
    CompareImmediate(scratch, kNullCid);
    BranchIf(EQUAL, &matches, Assembler::kNearJump);
  }
  Breakpoint();
  Bind(&matches);
#endif
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
  ldr(HEAP_BITS,
      compiler::Address(THR, target::Thread::write_barrier_mask_offset()));
  LslImmediate(HEAP_BITS, HEAP_BITS, 32);
  ldr(NULL_REG, compiler::Address(THR, target::Thread::object_null_offset()));
#if defined(DART_COMPRESSED_POINTERS)
  ldr(TMP, compiler::Address(THR, target::Thread::heap_base_offset()));
  orr(HEAP_BITS, HEAP_BITS, Operand(TMP, LSR, 32));
#endif
}

void Assembler::SetupGlobalPoolAndDispatchTable() {
  ASSERT(FLAG_precompiled_mode);
  ldr(PP, Address(THR, target::Thread::global_object_pool_offset()));
  sub(PP, PP, Operand(kHeapObjectTag));  // Pool in PP is untagged!
  ldr(DISPATCH_TABLE_REG,
      Address(THR, target::Thread::dispatch_table_array_offset()));
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
  ldr(TMP, FieldAddress(CODE_REG, target::Code::instructions_offset()));
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

  // TODO(47824): This will probably cause signal handlers on Windows to crash.
  // Windows requires the stack to grow in order, one page at a time, but
  // pushing CSP to near the stack limit likely skips over many pages.
}

void Assembler::RestoreCSP() {
  mov(CSP, SP);
}

void Assembler::SetReturnAddress(Register value) {
  RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR(MoveRegister(LR, value));
}

void Assembler::ArithmeticShiftRightImmediate(Register reg, intptr_t shift) {
  AsrImmediate(reg, reg, shift);
}

void Assembler::CompareWords(Register reg1,
                             Register reg2,
                             intptr_t offset,
                             Register count,
                             Register temp,
                             Label* equals) {
  Label loop;

  AddImmediate(reg1, offset - kHeapObjectTag);
  AddImmediate(reg2, offset - kHeapObjectTag);

  COMPILE_ASSERT(target::kWordSize == 8);
  Bind(&loop);
  BranchIfZero(count, equals, Assembler::kNearJump);
  AddImmediate(count, -1);
  ldr(temp, Address(reg1, 8, Address::PostIndex));
  ldr(TMP, Address(reg2, 8, Address::PostIndex));
  cmp(temp, Operand(TMP));
  BranchIf(EQUAL, &loop, Assembler::kNearJump);
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

  if (!FLAG_precompiled_mode) {
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

void Assembler::LeaveDartFrame() {
  if (!FLAG_precompiled_mode) {
    // Restore and untag PP.
    LoadFromOffset(
        PP, FP,
        target::frame_layout.saved_caller_pp_from_fp * target::kWordSize);
    sub(PP, PP, Operand(kHeapObjectTag));
  }
  set_constant_pool_allowed(false);
  LeaveFrame();
}

void Assembler::EnterFullSafepoint(Register state) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced. This simplifies GenerateJitCallbackTrampolines.
  // For TSAN, we always go to the runtime so TSAN is aware of the release
  // semantics of entering the safepoint.

  Register addr = TMP2;
  ASSERT(addr != state);

  Label slow_path, done, retry;
  if (FLAG_use_slow_path || kTargetUsesThreadSanitizer) {
    b(&slow_path);
  }

  movz(addr, Immediate(target::Thread::safepoint_state_offset()), 0);
  add(addr, THR, Operand(addr));
  Bind(&retry);
  ldxr(state, addr);
  cmp(state, Operand(target::Thread::full_safepoint_state_unacquired()));
  b(&slow_path, NE);

  movz(state, Immediate(target::Thread::full_safepoint_state_acquired()), 0);
  stxr(TMP, state, addr);
  cbz(&done, TMP);  // 0 means stxr was successful.

  if (!FLAG_use_slow_path && !kTargetUsesThreadSanitizer) {
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
    EnterFullSafepoint(tmp);
  }
}

void Assembler::ExitFullSafepoint(Register state,
                                  bool ignore_unwind_in_progress) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterFullSafepoint.
  // For TSAN, we always go to the runtime so TSAN is aware of the acquire
  // semantics of leaving the safepoint.
  Register addr = TMP2;
  ASSERT(addr != state);

  Label slow_path, done, retry;
  if (FLAG_use_slow_path || kTargetUsesThreadSanitizer) {
    b(&slow_path);
  }

  movz(addr, Immediate(target::Thread::safepoint_state_offset()), 0);
  add(addr, THR, Operand(addr));
  Bind(&retry);
  ldxr(state, addr);
  cmp(state, Operand(target::Thread::full_safepoint_state_acquired()));
  b(&slow_path, NE);

  movz(state, Immediate(target::Thread::full_safepoint_state_unacquired()), 0);
  stxr(TMP, state, addr);
  cbz(&done, TMP);  // 0 means stxr was successful.

  if (!FLAG_use_slow_path && !kTargetUsesThreadSanitizer) {
    b(&retry);
  }

  Bind(&slow_path);
  if (ignore_unwind_in_progress) {
    ldr(addr,
        Address(THR,
                target::Thread::
                    exit_safepoint_ignore_unwind_in_progress_stub_offset()));
  } else {
    ldr(addr, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  }
  ldr(addr, FieldAddress(addr, target::Code::entry_point_offset()));
  blr(addr);

  Bind(&done);
}

void Assembler::TransitionNativeToGenerated(Register state,
                                            bool exit_safepoint,
                                            bool ignore_unwind_in_progress) {
  if (exit_safepoint) {
    ExitFullSafepoint(state, ignore_unwind_in_progress);
  } else {
    // flag only makes sense if we are leaving safepoint
    ASSERT(!ignore_unwind_in_progress);
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    ASSERT(target::Thread::full_safepoint_state_acquired() != 0);
    LoadImmediate(state, target::Thread::full_safepoint_state_acquired());
    ldr(TMP, Address(THR, target::Thread::safepoint_state_offset()));
    and_(TMP, TMP, Operand(state));
    Label ok;
    cbz(&ok, TMP);
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

void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  ASSERT(!entry.is_leaf());
  // Argument count is not checked here, but in the runtime entry for a more
  // informative error message.
  ldr(R5, compiler::Address(THR, entry.OffsetFromThread()));
  LoadImmediate(R4, argument_count);
  Call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
}

// FPU: Only the bottom 64-bits of v8-v15 are preserved by the caller. The upper
// bits might be in use by Dart, so we save the whole register.
static const RegisterSet kRuntimeCallSavedRegisters(kDartVolatileCpuRegs,
                                                    kAllFpuRegistersList);

#undef __
#define __ assembler_->

LeafRuntimeScope::LeafRuntimeScope(Assembler* assembler,
                                   intptr_t frame_size,
                                   bool preserve_registers)
    : assembler_(assembler), preserve_registers_(preserve_registers) {
  __ Comment("EnterCallRuntimeFrame");
  __ EnterFrame(0);

  if (preserve_registers) {
    __ PushRegisters(kRuntimeCallSavedRegisters);
  } else {
    // These registers must always be preserved.
    COMPILE_ASSERT(IsCalleeSavedRegister(THR));
    COMPILE_ASSERT(IsCalleeSavedRegister(PP));
    COMPILE_ASSERT(IsCalleeSavedRegister(CODE_REG));
    COMPILE_ASSERT(IsCalleeSavedRegister(NULL_REG));
    COMPILE_ASSERT(IsCalleeSavedRegister(HEAP_BITS));
    COMPILE_ASSERT(IsCalleeSavedRegister(DISPATCH_TABLE_REG));
  }

  __ ReserveAlignedFrameSpace(frame_size);
}

void LeafRuntimeScope::Call(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  ASSERT(argument_count == entry.argument_count());
  // Since we are entering C++ code, we must restore the C stack pointer from
  // the stack limit to an aligned value nearer to the top of the stack.
  // We cache the stack limit in callee-saved registers, then align and call,
  // restoring CSP and SP on return from the call.
  // This sequence may occur in an intrinsic, so don't use registers an
  // intrinsic must preserve.
  __ mov(CSP, SP);
  __ ldr(TMP, compiler::Address(THR, entry.OffsetFromThread()));
  __ str(TMP, compiler::Address(THR, target::Thread::vm_tag_offset()));
  __ blr(TMP);
  __ LoadImmediate(TMP, VMTag::kDartTagId);
  __ str(TMP, compiler::Address(THR, target::Thread::vm_tag_offset()));
  __ SetupCSPFromThread(THR);
}

LeafRuntimeScope::~LeafRuntimeScope() {
  if (preserve_registers_) {
    // SP might have been modified to reserve space for arguments
    // and ensure proper alignment of the stack frame.
    // We need to restore it before restoring registers.
    const intptr_t kPushedRegistersSize =
        kRuntimeCallSavedRegisters.CpuRegisterCount() * target::kWordSize +
        kRuntimeCallSavedRegisters.FpuRegisterCount() * kFpuRegisterSize;
    __ AddImmediate(SP, FP, -kPushedRegistersSize);
    __ PopRegisters(kRuntimeCallSavedRegisters);
  }

  __ LeaveFrame();
}

// For use by LR related macros (e.g. CLOBBERS_LR).
#undef __
#define __ this->

void Assembler::EnterStubFrame() {
  EnterDartFrame(0);
}

void Assembler::LeaveStubFrame() {
  LeaveDartFrame();
}

void Assembler::EnterCFrame(intptr_t frame_space) {
  // Already saved.
  COMPILE_ASSERT(IsCalleeSavedRegister(THR));
  COMPILE_ASSERT(IsCalleeSavedRegister(PP));
  COMPILE_ASSERT(IsCalleeSavedRegister(NULL_REG));
  COMPILE_ASSERT(IsCalleeSavedRegister(HEAP_BITS));
  COMPILE_ASSERT(IsCalleeSavedRegister(DISPATCH_TABLE_REG));

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
  ldr(R1, FieldAddress(R5, cid_offset), kObjectBytes);
  ldr(R2, FieldAddress(R5, count_offset), kObjectBytes);
  LoadClassIdMayBeSmi(IP0, R0);
  add(R2, R2, Operand(target::ToRawSmi(1)), kObjectBytes);
  cmp(R1, Operand(IP0, LSL, 1), kObjectBytes);
  b(&miss, NE);
  str(R2, FieldAddress(R5, count_offset), kObjectBytes);
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
  cmp(R5, Operand(IP0, LSL, 1), kObjectBytes);
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

void Assembler::CombineHashes(Register hash, Register other) {
  // hash += other_hash
  add(hash, hash, Operand(other), kFourBytes);
  // hash += hash << 10
  add(hash, hash, Operand(hash, LSL, 10), kFourBytes);
  // hash ^= hash >> 6
  eor(hash, hash, Operand(hash, LSR, 6), kFourBytes);
}

void Assembler::FinalizeHashForSize(intptr_t bit_size,
                                    Register hash,
                                    Register scratch) {
  ASSERT(bit_size > 0);  // Can't avoid returning 0 if there are no hash bits!
  // While any 32-bit hash value fits in X bits, where X > 32, the caller may
  // reasonably expect that the returned values fill the entire bit space.
  ASSERT(bit_size <= kBitsPerInt32);
  // hash += hash << 3;
  add(hash, hash, Operand(hash, LSL, 3), kFourBytes);
  // hash ^= hash >> 11;  // Logical shift, unsigned hash.
  eor(hash, hash, Operand(hash, LSR, 11), kFourBytes);
  // hash += hash << 15;
  if (bit_size < kBitsPerInt32) {
    add(hash, hash, Operand(hash, LSL, 15), kFourBytes);
    // Size to fit.
    andis(hash, hash, Immediate(Utils::NBitMask(bit_size)));
  } else {
    adds(hash, hash, Operand(hash, LSL, 15), kFourBytes);
  }
  // return (hash == 0) ? 1 : hash;
  cinc(hash, hash, ZERO);
}

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Label* trace,
                                     Register temp_reg,
                                     JumpDistance distance) {
  ASSERT(cid > 0);

  LoadIsolateGroup(temp_reg);
  ldr(temp_reg, Address(temp_reg, target::IsolateGroup::class_table_offset()));
  ldr(temp_reg,
      Address(temp_reg,
              target::ClassTable::allocation_tracing_state_table_offset()));
  LoadFromOffset(temp_reg, temp_reg,
                 target::ClassTable::AllocationTracingStateSlotOffsetFor(cid),
                 kUnsignedByte);
  cbnz(trace, temp_reg);
}
#endif  // !PRODUCT

void Assembler::TryAllocateObject(intptr_t cid,
                                  intptr_t instance_size,
                                  Label* failure,
                                  JumpDistance distance,
                                  Register instance_reg,
                                  Register temp_reg) {
  ASSERT(failure != nullptr);
  ASSERT(instance_size != 0);
  ASSERT(instance_reg != temp_reg);
  ASSERT(temp_reg != kNoRegister);
  ASSERT(Utils::IsAligned(instance_size,
                          target::ObjectAlignment::kObjectAlignment));
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp_reg));
    RELEASE_ASSERT((target::Thread::top_offset() + target::kWordSize) ==
                   target::Thread::end_offset());
    ldp(instance_reg, temp_reg,
        Address(THR, target::Thread::top_offset(), Address::PairOffset));
    // instance_reg: current top (next object start).
    // temp_reg: heap end

    // TODO(koda): Protect against unsigned overflow here.
    AddImmediate(instance_reg, instance_size);
    // instance_reg: potential top (next object start).
    // fail if heap end unsigned less than or equal to new heap top.
    cmp(temp_reg, Operand(instance_reg));
    b(failure, LS);
    CheckAllocationCanary(instance_reg, temp_reg);

    // Successfully allocated the object, now update temp to point to
    // next object start and store the class in the class field of object.
    str(instance_reg, Address(THR, target::Thread::top_offset()));
    // Move instance_reg back to the start of the object and tag it.
    AddImmediate(instance_reg, -instance_size + kHeapObjectTag);

    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(temp_reg, tags);
    StoreToOffset(temp_reg,
                  FieldAddress(instance_reg, target::Object::tags_offset()));
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
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp1));
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
    CheckAllocationCanary(instance, temp2);

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

void Assembler::CopyMemoryWords(Register src,
                                Register dst,
                                Register size,
                                Register temp) {
  Label loop, done;
  __ cbz(&done, size);
  __ Bind(&loop);
  __ ldr(temp, Address(src, target::kWordSize, Address::PostIndex));
  __ str(temp, Address(dst, target::kWordSize, Address::PostIndex));
  __ subs(size, size, Operand(target::kWordSize));
  __ b(&loop, NOT_ZERO);
  __ Bind(&done);
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
  return Address(array, static_cast<int32_t>(offset));
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
#if !defined(DART_COMPRESSED_POINTERS)
  const bool index_is_32bit = false;
#else
  const bool index_is_32bit = !index_unboxed;
#endif
  ASSERT(array != temp);
  ASSERT(index != temp);
  if ((offset == 0) && (shift == 0)) {
    if (index_is_32bit) {
      return Address(array, index, SXTW, Address::Unscaled);
    } else {
      return Address(array, index, UXTX, Address::Unscaled);
    }
  } else if (shift < 0) {
    ASSERT(shift == -1);
    if (index_is_32bit) {
      AsrImmediate(temp, index, 1, kFourBytes);
      add(temp, array, Operand(temp, SXTW, 0));
    } else {
      add(temp, array, Operand(index, ASR, 1));
    }
  } else {
    if (index_is_32bit) {
      add(temp, array, Operand(index, SXTW, shift));
    } else {
      add(temp, array, Operand(index, LSL, shift));
    }
  }
  ASSERT(Address::CanHoldOffset(offset, Address::Offset, size));
  return Address(temp, offset);
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
#if !defined(DART_COMPRESSED_POINTERS)
  const bool index_is_32bit = false;
#else
  const bool index_is_32bit = !index_unboxed;
#endif
  if (shift == 0) {
    if (index_is_32bit) {
      add(address, array, Operand(index, SXTW, 0));
    } else {
      add(address, array, Operand(index));
    }
  } else if (shift < 0) {
    ASSERT(shift == -1);
    if (index_is_32bit) {
      sxtw(index, index);
      add(address, array, Operand(index, ASR, 1));
    } else {
      add(address, array, Operand(index, ASR, 1));
    }
  } else {
    if (index_is_32bit) {
      add(address, array, Operand(index, SXTW, shift));
    } else {
      add(address, array, Operand(index, LSL, shift));
    }
  }
  if (offset != 0) {
    AddImmediate(address, offset);
  }
}

void Assembler::LoadStaticFieldAddress(Register address,
                                       Register field,
                                       Register scratch) {
  LoadCompressedSmiFieldFromOffset(
      scratch, field, target::Field::host_offset_or_field_id_offset());
  const intptr_t field_table_offset =
      compiler::target::Thread::field_table_values_offset();
  LoadMemoryValue(address, THR, static_cast<int32_t>(field_table_offset));
  add(address, address,
      Operand(scratch, LSL, target::kWordSizeLog2 - kSmiTagShift));
}

void Assembler::LoadCompressedFieldAddressForRegOffset(
    Register address,
    Register instance,
    Register offset_in_compressed_words_as_smi) {
  add(address, instance,
      Operand(offset_in_compressed_words_as_smi, LSL,
              target::kCompressedWordSizeLog2 - kSmiTagShift));
  AddImmediate(address, -kHeapObjectTag);
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
  VRegister vprev = kNoVRegister;
  // Store fpu registers with the lowest register number at the lowest
  // address.
  for (intptr_t i = kNumberOfVRegisters - 1; i >= 0; --i) {
    VRegister fpu_reg = static_cast<VRegister>(i);
    if (regs.ContainsFpuRegister(fpu_reg)) {
      if (vprev != kNoVRegister) {
        PushQuadPair(/*low=*/fpu_reg, /*high=*/vprev);
        vprev = kNoVRegister;
      } else {
        vprev = fpu_reg;
      }
    }
  }
  if (vprev != kNoVRegister) {
    PushQuad(vprev);
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

  pop_single = (regs.FpuRegisterCount() & 1) == 1;
  VRegister vprev = kNoVRegister;
  // Fpu registers have the lowest register number at the lowest address.
  for (intptr_t i = 0; i < kNumberOfVRegisters; ++i) {
    VRegister fpu_reg = static_cast<VRegister>(i);
    if (regs.ContainsFpuRegister(fpu_reg)) {
      if (pop_single) {
        PopQuad(fpu_reg);
        pop_single = false;
      } else if (vprev != kNoVRegister) {
        PopQuadPair(/*low=*/vprev, /*high=*/fpu_reg);
        vprev = kNoVRegister;
      } else {
        vprev = fpu_reg;
      }
    }
  }
  ASSERT(vprev == kNoVRegister);
}

void Assembler::PushRegistersInOrder(std::initializer_list<Register> regs) {
  // Use STP to push registers in pairs.
  Register pending_reg = kNoRegister;
  for (Register reg : regs) {
    if (pending_reg != kNoRegister) {
      PushPair(reg, pending_reg);
      pending_reg = kNoRegister;
    } else {
      pending_reg = reg;
    }
  }
  if (pending_reg != kNoRegister) {
    Push(pending_reg);
  }
}

void Assembler::PushNativeCalleeSavedRegisters() {
  // Save the callee-saved registers.
  // We use str instead of the Push macro because we will be pushing the PP
  // register when it is not holding a pool-pointer since we are coming from
  // C++ code.
  Register prev = kNoRegister;
  for (int i = kAbiFirstPreservedCpuReg; i <= kAbiLastPreservedCpuReg; i++) {
    const Register r = static_cast<Register>(i);
    if (prev != kNoRegister) {
      stp(/*low=*/r, /*high=*/prev,
          Address(SP, -2 * target::kWordSize, Address::PairPreIndex));
      prev = kNoRegister;
    } else {
      prev = r;
    }
  }
  if (prev != kNoRegister) {
    str(prev, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  }

  // Save the bottom 64-bits of callee-saved V registers.
  VRegister vprev = kNoVRegister;
  for (int i = kAbiFirstPreservedFpuReg; i <= kAbiLastPreservedFpuReg; i++) {
    const VRegister r = static_cast<VRegister>(i);
    if (vprev != kNoVRegister) {
      PushDoublePair(/*low=*/r, /*high=*/vprev);
      vprev = kNoVRegister;
    } else {
      vprev = r;
    }
  }
  if (vprev != kNoVRegister) {
    PushDouble(vprev);
  }
}

void Assembler::PopNativeCalleeSavedRegisters() {
  // Restore the bottom 64-bits of callee-saved V registers.
  bool pop_single = (kAbiPreservedFpuRegCount & 1) != 0;
  VRegister vprev = kNoVRegister;
  for (int i = kAbiLastPreservedFpuReg; i >= kAbiFirstPreservedFpuReg; i--) {
    const VRegister r = static_cast<VRegister>(i);
    if (pop_single) {
      PopDouble(r);
      pop_single = false;
    } else if (vprev != kNoVRegister) {
      PopDoublePair(/*low=*/vprev, /*high=*/r);
      vprev = kNoVRegister;
    } else {
      vprev = r;
    }
  }

  // Restore C++ ABI callee-saved registers.
  // We use ldr instead of the Pop macro because we will be popping the PP
  // register when it is not holding a pool-pointer since we are returning to
  // C++ code. We also skip the dart stack pointer SP, since we are still
  // using it as the stack pointer.
  pop_single = (kAbiPreservedCpuRegCount & 1) != 0;
  Register prev = kNoRegister;
  for (int i = kAbiLastPreservedCpuReg; i >= kAbiFirstPreservedCpuReg; i--) {
    Register r = static_cast<Register>(i);
    if (pop_single) {
      ldr(r, Address(SP, 1 * target::kWordSize, Address::PostIndex));
      pop_single = false;
    } else if (prev != kNoRegister) {
      ldp(/*low=*/prev, /*high=*/r,
          Address(SP, 2 * target::kWordSize, Address::PairPostIndex));
      prev = kNoRegister;
    } else {
      prev = r;
    }
  }
}

bool Assembler::CanGenerateCbzTbz(Register rn, Condition cond) {
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

void Assembler::GenerateCbzTbz(Register rn,
                               Condition cond,
                               Label* label,
                               OperandSize sz) {
  ASSERT((sz == kEightBytes) || (sz == kFourBytes));
  const int32_t sign_bit = sz == kEightBytes ? 63 : 31;
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
      tbnz(label, rn, sign_bit);
      return;
    case PL:  // plus/positive or zero
    case GE:  // signed greater than or equal
      tbz(label, rn, sign_bit);
      return;
    default:
      // Only conditions above allow single instruction emission.
      UNREACHABLE();
  }
}

void Assembler::RangeCheck(Register value,
                           Register temp,
                           intptr_t low,
                           intptr_t high,
                           RangeCheckCondition condition,
                           Label* target) {
  auto cc = condition == kIfInRange ? LS : HI;
  Register to_check = temp != kNoRegister ? temp : value;
  AddImmediate(to_check, value, -low);
  CompareImmediate(to_check, high - low);
  b(target, cc);
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
