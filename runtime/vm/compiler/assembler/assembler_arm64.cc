// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_ARM64) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler.h"
#include "vm/cpu.h"
#include "vm/longjump.h"
#include "vm/runtime_entry.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, inline_alloc);

DEFINE_FLAG(bool, use_far_branches, false, "Always use far branches");

Assembler::Assembler(bool use_far_branches)
    : buffer_(),
      prologue_offset_(-1),
      has_single_entry_point_(true),
      use_far_branches_(use_far_branches),
      comments_(),
      constant_pool_allowed_(false) {}

void Assembler::InitializeMemoryWithBreakpoints(uword data, intptr_t length) {
  ASSERT(Utils::IsAligned(data, 4));
  ASSERT(Utils::IsAligned(length, 4));
  const uword end = data + length;
  while (data < end) {
    *reinterpret_cast<int32_t*>(data) = Instr::kBreakPointInstruction;
    data += 4;
  }
}

void Assembler::Emit(int32_t value) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<int32_t>(value);
}

static const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",  "r8",  "r9",  "r10",
    "r11", "r12", "r13", "r14", "r15", "r16", "r17", "r18", "r19", "r20", "r21",
    "r22", "r23", "r24", "ip0", "ip1", "pp",  "ctx", "fp",  "lr",  "r31",
};

const char* Assembler::RegisterName(Register reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
  return cpu_reg_names[reg];
}

static const char* fpu_reg_names[kNumberOfFpuRegisters] = {
    "v0",  "v1",  "v2",  "v3",  "v4",  "v5",  "v6",  "v7",  "v8",  "v9",  "v10",
    "v11", "v12", "v13", "v14", "v15", "v16", "v17", "v18", "v19", "v20", "v21",
    "v22", "v23", "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31",
};

const char* Assembler::FpuRegisterName(FpuRegister reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfFpuRegisters));
  return fpu_reg_names[reg];
}

void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  const intptr_t bound_pc = buffer_.Size();

  while (label->IsLinked()) {
    const int64_t position = label->Position();
    const int64_t dest = bound_pc - position;
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
      const int32_t encoded_branch =
          EncodeImm26BranchOffset(offset, far_branch);

      // If the guard branch is conditioned on NV, replace it with a nop.
      if (c == NV) {
        buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize,
                               Instr::kNopInstruction);
      }

      // Write the far branch into the buffer and link to the next branch.
      buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize, encoded_branch);
      label->position_ = next;
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
      int32_t encoded_guard_branch =
          EncodeImm19BranchOffset(dest, guard_branch);
      const Condition c = DecodeImm19BranchCondition(encoded_guard_branch);
      encoded_guard_branch =
          EncodeImm19BranchCondition(InvertCondition(c), encoded_guard_branch);

      // Write back the re-encoded instructions. The far branch becomes a nop.
      buffer_.Store<int32_t>(position + 0 * Instr::kInstrSize,
                             encoded_guard_branch);
      buffer_.Store<int32_t>(position + 1 * Instr::kInstrSize,
                             Instr::kNopInstruction);
      label->position_ = next;
    } else {
      const int32_t next = buffer_.Load<int32_t>(position);
      const int32_t encoded = EncodeImm19BranchOffset(dest, next);
      buffer_.Store<int32_t>(position, encoded);
      label->position_ = DecodeImm19BranchOffset(next);
    }
  }
  label->BindTo(bound_pc);
}

void Assembler::Stop(const char* message) {
  if (FLAG_print_stop_message) {
    UNIMPLEMENTED();
  }
  Label stop;
  b(&stop);
  Emit(Utils::Low32Bits(reinterpret_cast<int64_t>(message)));
  Emit(Utils::High32Bits(reinterpret_cast<int64_t>(message)));
  Bind(&stop);
  brk(Instr::kStopMessageCode);
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
  int trail_zero = Utils::CountTrailingZeros(value);
  int trail_one = Utils::CountTrailingZeros(~value);
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
  ldr(pp, FieldAddress(CODE_REG, Code::object_pool_offset()));

  // When in the PP register, the pool pointer is untagged. When we
  // push it on the stack with TagAndPushPP it is tagged again. PopAndUntagPP
  // then untags when restoring from the stack. This will make loading from the
  // object pool only one instruction for the first 4096 entries. Otherwise,
  // because the offset wouldn't be aligned, it would be only one instruction
  // for the first 64 entries.
  sub(pp, pp, Operand(kHeapObjectTag));
  set_constant_pool_allowed(pp == PP);
}

void Assembler::LoadWordFromPoolOffset(Register dst,
                                       uint32_t offset,
                                       Register pp) {
  ASSERT((pp != PP) || constant_pool_allowed());
  ASSERT(dst != pp);
  Operand op;
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

void Assembler::LoadWordFromPoolOffsetFixed(Register dst, uint32_t offset) {
  ASSERT(constant_pool_allowed());
  ASSERT(dst != PP);
  Operand op;
  const uint32_t upper20 = offset & 0xfffff000;
  const uint32_t lower12 = offset & 0x00000fff;
  const Operand::OperandType ot =
      Operand::CanHold(upper20, kXRegSizeInBits, &op);
  ASSERT(ot == Operand::Immediate);
  ASSERT(Address::CanHoldOffset(lower12));
  add(dst, PP, op);
  ldr(dst, Address(dst, lower12));
}

intptr_t Assembler::FindImmediate(int64_t imm) {
  return object_pool_wrapper_.FindImmediate(imm);
}

bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(!object.IsICData() || ICData::Cast(object).IsOriginal());
  ASSERT(!object.IsField() || Field::Cast(object).IsOriginal());
  ASSERT(!Thread::CanLoadFromThread(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  // TODO(zra, kmillikin): Also load other large immediates from the object
  // pool
  if (object.IsSmi()) {
    // If the raw smi does not fit into a 32-bit signed int, then we'll keep
    // the raw value in the object pool.
    return !Utils::IsInt(32, reinterpret_cast<int64_t>(object.raw()));
  }
  ASSERT(object.IsNotTemporaryScopedHandle());
  ASSERT(object.IsOld());
  return true;
}

void Assembler::LoadNativeEntry(Register dst, const ExternalLabel* label) {
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindNativeEntry(label, kNotPatchable));
  LoadWordFromPoolOffset(dst, offset);
}

void Assembler::LoadIsolate(Register dst) {
  ldr(dst, Address(THR, Thread::isolate_offset()));
}

void Assembler::LoadObjectHelper(Register dst,
                                 const Object& object,
                                 bool is_unique) {
  ASSERT(!object.IsICData() || ICData::Cast(object).IsOriginal());
  ASSERT(!object.IsField() || Field::Cast(object).IsOriginal());
  if (Thread::CanLoadFromThread(object)) {
    ldr(dst, Address(THR, Thread::OffsetFromThread(object)));
  } else if (CanLoadFromObjectPool(object)) {
    const int32_t offset = ObjectPool::element_offset(
        is_unique ? object_pool_wrapper_.AddObject(object)
                  : object_pool_wrapper_.FindObject(object));
    LoadWordFromPoolOffset(dst, offset);
  } else {
    ASSERT(object.IsSmi());
    LoadDecodableImmediate(dst, reinterpret_cast<int64_t>(object.raw()));
  }
}

void Assembler::LoadFunctionFromCalleePool(Register dst,
                                           const Function& function,
                                           Register new_pp) {
  ASSERT(!constant_pool_allowed());
  ASSERT(new_pp != PP);
  const int32_t offset =
      ObjectPool::element_offset(object_pool_wrapper_.FindObject(function));
  ASSERT(Address::CanHoldOffset(offset));
  ldr(dst, Address(new_pp, offset));
}

void Assembler::LoadObject(Register dst, const Object& object) {
  LoadObjectHelper(dst, object, false);
}

void Assembler::LoadUniqueObject(Register dst, const Object& object) {
  LoadObjectHelper(dst, object, true);
}

void Assembler::CompareObject(Register reg, const Object& object) {
  ASSERT(!object.IsICData() || ICData::Cast(object).IsOriginal());
  ASSERT(!object.IsField() || Field::Cast(object).IsOriginal());
  if (Thread::CanLoadFromThread(object)) {
    ldr(TMP, Address(THR, Thread::OffsetFromThread(object)));
    CompareRegisters(reg, TMP);
  } else if (CanLoadFromObjectPool(object)) {
    LoadObject(TMP, object);
    CompareRegisters(reg, TMP);
  } else {
    ASSERT(object.IsSmi());
    CompareImmediate(reg, reinterpret_cast<int64_t>(object.raw()));
  }
}

void Assembler::LoadDecodableImmediate(Register reg, int64_t imm) {
  if (constant_pool_allowed()) {
    const int32_t offset = ObjectPool::element_offset(FindImmediate(imm));
    LoadWordFromPoolOffset(reg, offset);
  } else {
    // TODO(zra): Since this sequence only needs to be decodable, it can be
    // of variable length.
    LoadImmediateFixed(reg, imm);
  }
}

void Assembler::LoadImmediateFixed(Register reg, int64_t imm) {
  const uint32_t w0 = Utils::Low32Bits(imm);
  const uint32_t w1 = Utils::High32Bits(imm);
  const uint16_t h0 = Utils::Low16Bits(w0);
  const uint16_t h1 = Utils::High16Bits(w0);
  const uint16_t h2 = Utils::Low16Bits(w1);
  const uint16_t h3 = Utils::High16Bits(w1);
  movz(reg, Immediate(h0), 0);
  movk(reg, Immediate(h1), 1);
  movk(reg, Immediate(h2), 2);
  movk(reg, Immediate(h3), 3);
}

void Assembler::LoadImmediate(Register reg, int64_t imm) {
  Comment("LoadImmediate");
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
    const int32_t offset = ObjectPool::element_offset(FindImmediate(imm));
    LoadWordFromPoolOffset(reg, offset);
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

void Assembler::Branch(const StubEntry& stub_entry,
                       Register pp,
                       Patchability patchable) {
  const Code& target = Code::ZoneHandle(stub_entry.code());
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindObject(target, patchable));
  LoadWordFromPoolOffset(CODE_REG, offset, pp);
  ldr(TMP, FieldAddress(CODE_REG, Code::entry_point_offset()));
  br(TMP);
}

void Assembler::BranchPatchable(const StubEntry& stub_entry) {
  Branch(stub_entry, PP, kPatchable);
}

void Assembler::BranchLink(const StubEntry& stub_entry,
                           Patchability patchable) {
  const Code& target = Code::ZoneHandle(stub_entry.code());
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindObject(target, patchable));
  LoadWordFromPoolOffset(CODE_REG, offset);
  ldr(TMP, FieldAddress(CODE_REG, Code::entry_point_offset()));
  blr(TMP);
}

void Assembler::BranchLinkPatchable(const StubEntry& stub_entry) {
  BranchLink(stub_entry, kPatchable);
}

void Assembler::BranchLinkToRuntime() {
  ldr(LR, Address(THR, Thread::call_to_runtime_entry_point_offset()));
  ldr(CODE_REG, Address(THR, Thread::call_to_runtime_stub_offset()));
  blr(LR);
}

void Assembler::BranchLinkWithEquivalence(const StubEntry& stub_entry,
                                          const Object& equivalence) {
  const Code& target = Code::ZoneHandle(stub_entry.code());
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindObject(target, equivalence));
  LoadWordFromPoolOffset(CODE_REG, offset);
  ldr(TMP, FieldAddress(CODE_REG, Code::entry_point_offset()));
  blr(TMP);
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

void Assembler::AddImmediateSetFlags(Register dest, Register rn, int64_t imm) {
  Operand op;
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    // Handles imm == kMinInt64.
    adds(dest, rn, op);
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    ASSERT(imm != kMinInt64);  // Would cause erroneous overflow detection.
    subs(dest, rn, op);
  } else {
    // TODO(zra): Try adding top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    adds(dest, rn, Operand(TMP2));
  }
}

void Assembler::SubImmediateSetFlags(Register dest, Register rn, int64_t imm) {
  Operand op;
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    // Handles imm == kMinInt64.
    subs(dest, rn, op);
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    ASSERT(imm != kMinInt64);  // Would cause erroneous overflow detection.
    adds(dest, rn, op);
  } else {
    // TODO(zra): Try subtracting top 12 bits, then bottom 12 bits.
    ASSERT(rn != TMP2);
    LoadImmediate(TMP2, imm);
    subs(dest, rn, Operand(TMP2));
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
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
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

// Store into object.
// Preserves object and value registers.
void Assembler::StoreIntoObjectFilterNoSmi(Register object,
                                           Register value,
                                           Label* no_update) {
  COMPILE_ASSERT((kNewObjectAlignmentOffset == kWordSize) &&
                 (kOldObjectAlignmentOffset == 0));

  // Write-barrier triggers if the value is in the new space (has bit set) and
  // the object is in the old space (has bit cleared).
  // To check that, we compute value & ~object and skip the write barrier
  // if the bit is not set. We can't destroy the object.
  bic(TMP, value, Operand(object));
  tsti(TMP, Immediate(kNewObjectAlignmentOffset));
  b(no_update, EQ);
}

// Preserves object and value registers.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* no_update) {
  // For the value we are only interested in the new/old bit and the tag bit.
  // And the new bit with the tag bit. The resulting bit will be 0 for a Smi.
  and_(TMP, value, Operand(value, LSL, kObjectAlignmentLog2 - 1));
  // And the result with the negated space bit of the object.
  bic(TMP, TMP, Operand(object));
  tsti(TMP, Immediate(kNewObjectAlignmentOffset));
  b(no_update, EQ);
}

void Assembler::StoreIntoObjectOffset(Register object,
                                      int32_t offset,
                                      Register value,
                                      bool can_value_be_smi) {
  if (Address::CanHoldOffset(offset - kHeapObjectTag)) {
    StoreIntoObject(object, FieldAddress(object, offset), value,
                    can_value_be_smi);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObject(object, Address(TMP), value, can_value_be_smi);
  }
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                bool can_value_be_smi) {
  ASSERT(object != value);
  str(value, dest);
  Label done;
  if (can_value_be_smi) {
    StoreIntoObjectFilter(object, value, &done);
  } else {
    StoreIntoObjectFilterNoSmi(object, value, &done);
  }
  // A store buffer update is required.
  if (value != R0) {
    // Preserve R0.
    Push(R0);
  }
  Push(LR);
  if (object != R0) {
    mov(R0, object);
  }
  ldr(TMP, Address(THR, Thread::update_store_buffer_entry_point_offset()));
  ldr(CODE_REG, Address(THR, Thread::update_store_buffer_code_offset()));
  blr(TMP);
  Pop(LR);
  if (value != R0) {
    // Restore R0.
    Pop(R0);
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  str(value, dest);
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value, &done);
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
  ASSERT(!value.IsICData() || ICData::Cast(value).IsOriginal());
  ASSERT(!value.IsField() || Field::Cast(value).IsOriginal());
  ASSERT(value.IsSmi() || value.InVMHeap() ||
         (value.IsOld() && value.IsNotTemporaryScopedHandle()));
  // No store buffer update.
  LoadObject(TMP2, value);
  str(TMP2, dest);
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

void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(RawObject::kClassIdTagPos == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset =
      Object::tags_offset() + RawObject::kClassIdTagPos / kBitsPerByte;
  LoadFromOffset(result, object, class_id_offset - kHeapObjectTag,
                 kUnsignedHalfword);
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);
  LoadIsolate(result);
  const intptr_t offset =
      Isolate::class_table_offset() + ClassTable::table_offset();
  LoadFromOffset(result, result, offset);
  ldr(result, Address(result, class_id, UXTX, Address::Scaled));
}

void Assembler::LoadClass(Register result, Register object) {
  ASSERT(object != TMP);
  LoadClassId(TMP, object);
  LoadClassById(result, TMP);
}

void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  ASSERT(scratch == kNoRegister);
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
  LoadClassIdMayBeSmi(TMP, object);
  // Finally, tag the result.
  SmiTag(result, TMP);
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

void Assembler::RestoreCodePointer() {
  ldr(CODE_REG, Address(FP, kPcMarkerSlotFromFp * kWordSize));
  CheckCodePointer();
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
      CodeSize() + Instructions::HeaderSize() - kHeapObjectTag;
  adr(R0, Immediate(-entry_offset));
  ldr(TMP, FieldAddress(CODE_REG, Code::saved_instructions_offset()));
  cmp(R0, Operand(TMP));
  b(&instructions_ok, EQ);
  brk(1);
  Bind(&instructions_ok);
  Pop(R0);
#endif
}

void Assembler::SetupDartSP() {
  mov(SP, CSP);
}

void Assembler::RestoreCSP() {
  mov(CSP, SP);
}

void Assembler::EnterFrame(intptr_t frame_size) {
  // The ARM64 ABI requires at all times
  //   - stack limit < CSP <= stack base
  //   - CSP mod 16 = 0
  //   - we do not access stack memory below CSP
  // Pratically, this means we need to keep the C stack pointer ahead of the
  // Dart stack pointer and 16-byte aligned for signal handlers. If we knew the
  // real stack limit, we could just set CSP to a value near it during
  // SetupDartSP, but we do not know the real stack limit for the initial
  // thread or threads created by the embedder.
  // TODO(26472): It would be safer to use CSP as the Dart stack pointer, but
  // this requires adjustments to stack handling to maintain the 16-byte
  // alignment.
  const intptr_t kMaxDartFrameSize = 4096;
  sub(TMP, SP, Operand(kMaxDartFrameSize));
  andi(CSP, TMP, Immediate(~15));

  PushPair(FP, LR);  // low: FP, high: LR.
  mov(FP, SP);

  if (frame_size > 0) {
    sub(SP, SP, Operand(frame_size));
  }
}

void Assembler::LeaveFrame() {
  mov(SP, FP);
  PopPair(FP, LR);  // low: FP, high: LR.
}

void Assembler::EnterDartFrame(intptr_t frame_size, Register new_pp) {
  ASSERT(!constant_pool_allowed());
  // Setup the frame.
  EnterFrame(0);
  TagAndPushPPAndPcMarker();  // Save PP and PC marker.

  // Load the pool pointer.
  if (new_pp == kNoRegister) {
    LoadPoolPointer();
  } else {
    mov(PP, new_pp);
    set_constant_pool_allowed(true);
  }

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
  if (restore_pp == kRestoreCallerPP) {
    set_constant_pool_allowed(false);
    // Restore and untag PP.
    LoadFromOffset(PP, FP, kSavedCallerPpSlotFromFp * kWordSize);
    sub(PP, PP, Operand(kHeapObjectTag));
  }
  LeaveFrame();
}

void Assembler::EnterCallRuntimeFrame(intptr_t frame_size) {
  Comment("EnterCallRuntimeFrame");
  EnterStubFrame();

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

  ReserveAlignedFrameSpace(frame_size);
}

void Assembler::LeaveCallRuntimeFrame() {
  // SP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  const intptr_t kPushedRegistersSize =
      kDartVolatileCpuRegCount * kWordSize +
      kDartVolatileFpuRegCount * kWordSize +
      2 * kWordSize;  // PP and pc marker from EnterStubFrame.
  AddImmediate(SP, FP, -kPushedRegistersSize);
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

void Assembler::EnterStubFrame() {
  EnterDartFrame(0);
}

void Assembler::LeaveStubFrame() {
  LeaveDartFrame();
}

// R0 receiver, R5 guarded cid as Smi.
// Preserve R4 (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntry() {
  ASSERT(has_single_entry_point_);
  has_single_entry_point_ = false;
  bool saved_use_far_branches = use_far_branches();
  set_use_far_branches(false);

  Label immediate, have_cid, miss;
  Bind(&miss);
  ldr(IP0, Address(THR, Thread::monomorphic_miss_entry_offset()));
  br(IP0);

  Bind(&immediate);
  movz(IP0, Immediate(kSmiCid), 0);
  b(&have_cid);

  Comment("MonomorphicCheckedEntry");
  ASSERT(CodeSize() == Instructions::kCheckedEntryOffset);
  tsti(R0, Immediate(kSmiTagMask));
  SmiUntag(R5);
  b(&immediate, EQ);

  LoadClassId(IP0, R0);

  Bind(&have_cid);
  cmp(IP0, Operand(R5));
  b(&miss, NE);

  // Fall through to unchecked entry.
  ASSERT(CodeSize() == Instructions::kUncheckedEntryOffset);

  set_use_far_branches(saved_use_far_branches);
}

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Register temp_reg,
                                     Label* trace) {
  ASSERT(cid > 0);
  intptr_t state_offset = ClassTable::StateOffsetFor(cid);
  LoadIsolate(temp_reg);
  intptr_t table_offset =
      Isolate::class_table_offset() + ClassTable::TableOffsetFor(cid);
  ldr(temp_reg, Address(temp_reg, table_offset));
  AddImmediate(temp_reg, state_offset);
  ldr(temp_reg, Address(temp_reg, 0));
  tsti(temp_reg, Immediate(ClassHeapStats::TraceAllocationMask()));
  b(trace, NE);
}

void Assembler::UpdateAllocationStats(intptr_t cid, Heap::Space space) {
  ASSERT(cid > 0);
  intptr_t counter_offset =
      ClassTable::CounterOffsetFor(cid, space == Heap::kNew);
  LoadIsolate(TMP2);
  intptr_t table_offset =
      Isolate::class_table_offset() + ClassTable::TableOffsetFor(cid);
  ldr(TMP, Address(TMP2, table_offset));
  AddImmediate(TMP2, TMP, counter_offset);
  ldr(TMP, Address(TMP2, 0));
  AddImmediate(TMP, 1);
  str(TMP, Address(TMP2, 0));
}

void Assembler::UpdateAllocationStatsWithSize(intptr_t cid,
                                              Register size_reg,
                                              Heap::Space space) {
  ASSERT(cid > 0);
  const uword class_offset = ClassTable::ClassOffsetFor(cid);
  const uword count_field_offset =
      (space == Heap::kNew)
          ? ClassHeapStats::allocated_since_gc_new_space_offset()
          : ClassHeapStats::allocated_since_gc_old_space_offset();
  const uword size_field_offset =
      (space == Heap::kNew)
          ? ClassHeapStats::allocated_size_since_gc_new_space_offset()
          : ClassHeapStats::allocated_size_since_gc_old_space_offset();
  LoadIsolate(TMP2);
  intptr_t table_offset =
      Isolate::class_table_offset() + ClassTable::TableOffsetFor(cid);
  ldr(TMP, Address(TMP2, table_offset));
  AddImmediate(TMP2, TMP, class_offset);
  ldr(TMP, Address(TMP2, count_field_offset));
  AddImmediate(TMP, 1);
  str(TMP, Address(TMP2, count_field_offset));
  ldr(TMP, Address(TMP2, size_field_offset));
  add(TMP, TMP, Operand(size_reg));
  str(TMP, Address(TMP2, size_field_offset));
}
#endif  // !PRODUCT

void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            Register instance_reg,
                            Register temp_reg) {
  ASSERT(failure != NULL);
  const intptr_t instance_size = cls.instance_size();
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cls.id(), temp_reg, failure));
    NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
    ldr(instance_reg, Address(THR, Thread::top_offset()));
    // TODO(koda): Protect against unsigned overflow here.
    AddImmediateSetFlags(instance_reg, instance_reg, instance_size);

    // instance_reg: potential next object start.
    ldr(TMP, Address(THR, Thread::end_offset()));
    CompareRegisters(TMP, instance_reg);
    // fail if heap end unsigned less than or equal to instance_reg.
    b(failure, LS);

    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    str(instance_reg, Address(THR, Thread::top_offset()));

    ASSERT(instance_size >= kHeapObjectTag);
    AddImmediate(instance_reg, -instance_size + kHeapObjectTag);
    NOT_IN_PRODUCT(UpdateAllocationStats(cls.id(), space));

    uint32_t tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    // Extends the 32 bit tags with zeros, which is the uninitialized
    // hash code.
    LoadImmediate(TMP, tags);
    StoreFieldToOffset(TMP, instance_reg, Object::tags_offset());
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
  if (FLAG_inline_alloc && Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, temp1, failure));
    NOT_IN_PRODUCT(Heap::Space space = Heap::kNew);
    // Potential new object start.
    ldr(instance, Address(THR, Thread::top_offset()));
    AddImmediateSetFlags(end_address, instance, instance_size);
    b(failure, CS);  // Fail on unsigned overflow.

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start.
    // end_address: potential next object start.
    ldr(temp2, Address(THR, Thread::end_offset()));
    cmp(end_address, Operand(temp2));
    b(failure, CS);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    str(end_address, Address(THR, Thread::top_offset()));
    add(instance, instance, Operand(kHeapObjectTag));
    LoadImmediate(temp2, instance_size);
    NOT_IN_PRODUCT(UpdateAllocationStatsWithSize(cid, temp2, space));

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    uint32_t tags = 0;
    tags = RawObject::ClassIdTag::update(cid, tags);
    tags = RawObject::SizeTag::update(instance_size, tags);
    // Extends the 32 bit tags with zeros, which is the uninitialized
    // hash code.
    LoadImmediate(temp2, tags);
    str(temp2, FieldAddress(instance, Array::tags_offset()));  // Store tags.
  } else {
    b(failure);
  }
}

Address Assembler::ElementAddressForIntIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             intptr_t index) const {
  const int64_t offset =
      index * index_scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  ASSERT(Utils::IsInt(32, offset));
  const OperandSize size = Address::OperandSizeFor(cid);
  ASSERT(Address::CanHoldOffset(offset, Address::Offset, size));
  return Address(array, static_cast<int32_t>(offset), Address::Offset, size);
}

void Assembler::LoadElementAddressForIntIndex(Register address,
                                              bool is_external,
                                              intptr_t cid,
                                              intptr_t index_scale,
                                              Register array,
                                              intptr_t index) {
  const int64_t offset =
      index * index_scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  AddImmediate(address, array, offset);
}

Address Assembler::ElementAddressForRegIndex(bool is_load,
                                             bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             Register index) {
  // Note that index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) - kSmiTagShift;
  const int32_t offset =
      is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag);
  ASSERT(array != TMP);
  ASSERT(index != TMP);
  const Register base = is_load ? TMP : index;
  if ((offset == 0) && (shift == 0)) {
    return Address(array, index, UXTX, Address::Unscaled);
  } else if (shift < 0) {
    ASSERT(shift == -1);
    add(base, array, Operand(index, ASR, 1));
  } else {
    add(base, array, Operand(index, LSL, shift));
  }
  const OperandSize size = Address::OperandSizeFor(cid);
  ASSERT(Address::CanHoldOffset(offset, Address::Offset, size));
  return Address(base, offset, Address::Offset, size);
}

void Assembler::LoadElementAddressForRegIndex(Register address,
                                              bool is_load,
                                              bool is_external,
                                              intptr_t cid,
                                              intptr_t index_scale,
                                              Register array,
                                              Register index) {
  // Note that index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) - kSmiTagShift;
  const int32_t offset =
      is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag);
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

void Assembler::LoadUnaligned(Register dst,
                              Register addr,
                              Register tmp,
                              OperandSize sz) {
  ASSERT(dst != addr);
  ldr(dst, Address(addr, 0), kUnsignedByte);
  if (sz == kHalfword) {
    ldr(tmp, Address(addr, 1), kByte);
    orr(dst, dst, Operand(tmp, LSL, 8));
    return;
  }
  ldr(tmp, Address(addr, 1), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 8));
  if (sz == kUnsignedHalfword) {
    return;
  }
  ldr(tmp, Address(addr, 2), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 16));
  if (sz == kWord) {
    ldr(tmp, Address(addr, 3), kByte);
    orr(dst, dst, Operand(tmp, LSL, 24));
    return;
  }
  ldr(tmp, Address(addr, 3), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 24));
  if (sz == kUnsignedWord) {
    return;
  }
  ldr(tmp, Address(addr, 4), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 32));
  ldr(tmp, Address(addr, 5), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 40));
  ldr(tmp, Address(addr, 6), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 48));
  ldr(tmp, Address(addr, 7), kUnsignedByte);
  orr(dst, dst, Operand(tmp, LSL, 56));
  if (sz == kDoubleWord) {
    return;
  }
  UNIMPLEMENTED();
}

void Assembler::StoreUnaligned(Register src,
                               Register addr,
                               Register tmp,
                               OperandSize sz) {
  str(src, Address(addr, 0), kUnsignedByte);
  LsrImmediate(tmp, src, 8);
  str(tmp, Address(addr, 1), kUnsignedByte);
  if ((sz == kHalfword) || (sz == kUnsignedHalfword)) {
    return;
  }
  LsrImmediate(tmp, src, 16);
  str(tmp, Address(addr, 2), kUnsignedByte);
  LsrImmediate(tmp, src, 24);
  str(tmp, Address(addr, 3), kUnsignedByte);
  if ((sz == kWord) || (sz == kUnsignedWord)) {
    return;
  }
  LsrImmediate(tmp, src, 32);
  str(tmp, Address(addr, 4), kUnsignedByte);
  LsrImmediate(tmp, src, 40);
  str(tmp, Address(addr, 5), kUnsignedByte);
  LsrImmediate(tmp, src, 48);
  str(tmp, Address(addr, 6), kUnsignedByte);
  LsrImmediate(tmp, src, 56);
  str(tmp, Address(addr, 7), kUnsignedByte);
  if (sz == kDoubleWord) {
    return;
  }
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64) && !defined(DART_PRECOMPILED_RUNTIME)
