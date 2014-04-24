// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/longjump.h"
#include "vm/runtime_entry.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

// An extra check since we are assuming the existence of /proc/cpuinfo below.
#if !defined(USING_SIMULATOR) && !defined(__linux__) && !defined(ANDROID)
#error ARM64 cross-compile only supported on Linux
#endif

namespace dart {

DEFINE_FLAG(bool, print_stop_message, false, "Print stop message.");
DECLARE_FLAG(bool, inline_alloc);


Assembler::Assembler(bool use_far_branches)
    : buffer_(),
      object_pool_(GrowableObjectArray::Handle()),
      patchable_pool_entries_(),
      prologue_offset_(-1),
      use_far_branches_(use_far_branches),
      comments_() {
  if (Isolate::Current() != Dart::vm_isolate()) {
    object_pool_ = GrowableObjectArray::New(Heap::kOld);

    // These objects and labels need to be accessible through every pool-pointer
    // at the same index.
    object_pool_.Add(Object::null_object(), Heap::kOld);
    patchable_pool_entries_.Add(kNotPatchable);
    // Not adding Object::null() to the index table. It is at index 0 in the
    // object pool, but the HashMap uses 0 to indicate not found.

    object_pool_.Add(Bool::True(), Heap::kOld);
    patchable_pool_entries_.Add(kNotPatchable);
    object_pool_index_table_.Insert(ObjIndexPair(Bool::True().raw(), 1));

    object_pool_.Add(Bool::False(), Heap::kOld);
    patchable_pool_entries_.Add(kNotPatchable);
    object_pool_index_table_.Insert(ObjIndexPair(Bool::False().raw(), 2));
  }
}


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
  "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",
  "r8",  "r9",  "r10", "r11", "r12", "r13", "r14", "r15",
  "r16", "r17", "r18", "r19", "r20", "r21", "r22", "r23",
  "r24", "ip0", "ip1", "pp",  "ctx", "fp",  "lr",  "r31",
};


const char* Assembler::RegisterName(Register reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
  return cpu_reg_names[reg];
}


static const char* fpu_reg_names[kNumberOfFpuRegisters] = {
  "v0",  "v1",  "v2",  "v3",  "v4",  "v5",  "v6",  "v7",
  "v8",  "v9",  "v10", "v11", "v12", "v13", "v14", "v15",
  "v16", "v17", "v18", "v19", "v20", "v21", "v22", "v23",
  "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31",
};


const char* Assembler::FpuRegisterName(FpuRegister reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfFpuRegisters));
  return fpu_reg_names[reg];
}


// TODO(zra): Support for far branches. Requires loading large immediates.
void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  intptr_t bound_pc = buffer_.Size();

  while (label->IsLinked()) {
    const int64_t position = label->Position();
    const int64_t dest = bound_pc - position;
    const int32_t next = buffer_.Load<int32_t>(position);
    const int32_t encoded = EncodeImm19BranchOffset(dest, next);
    buffer_.Store<int32_t>(position, encoded);
    label->position_ = DecodeImm19BranchOffset(next);
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
  hlt(kImmExceptionIsDebug);
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
  value &= (0xffffffffffffffffUL >> (64-width));

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
    uint64_t mask = (1UL << (width >> 1)) - 1;
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
  const intptr_t object_pool_pc_dist =
    Instructions::HeaderSize() - Instructions::object_pool_offset() +
    CodeSize();
  // PP <- Read(PC - object_pool_pc_dist).
  ldr(pp, Address::PC(-object_pool_pc_dist));

  // When in the PP register, the pool pointer is untagged. When we
  // push it on the stack with PushPP it is tagged again. PopPP then untags
  // when restoring from the stack. This will make loading from the object
  // pool only one instruction for the first 4096 entries. Otherwise, because
  // the offset wouldn't be aligned, it would be only one instruction for the
  // first 64 entries.
  sub(pp, pp, Operand(kHeapObjectTag));
}

void Assembler::LoadWordFromPoolOffset(Register dst, Register pp,
                                       uint32_t offset) {
  ASSERT(dst != pp);
  if (Address::CanHoldOffset(offset)) {
    ldr(dst, Address(pp, offset));
  } else {
    const uint16_t offset_low = Utils::Low16Bits(offset);
    const uint16_t offset_high = Utils::High16Bits(offset);
    movz(dst, offset_low, 0);
    if (offset_high != 0) {
      movk(dst, offset_high, 1);
    }
    ldr(dst, Address(pp, dst));
  }
}


intptr_t Assembler::FindExternalLabel(const ExternalLabel* label,
                                      Patchability patchable) {
  // The object pool cannot be used in the vm isolate.
  ASSERT(Isolate::Current() != Dart::vm_isolate());
  ASSERT(!object_pool_.IsNull());
  const uword address = label->address();
  ASSERT(Utils::IsAligned(address, 4));
  // The address is stored in the object array as a RawSmi.
  const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(address));
  if (patchable == kNotPatchable) {
    // If the call site is not patchable, we can try to re-use an existing
    // entry.
    return FindObject(smi, kNotPatchable);
  }
  // If the call is patchable, do not reuse an existing entry since each
  // reference may be patched independently.
  object_pool_.Add(smi, Heap::kOld);
  patchable_pool_entries_.Add(patchable);
  return object_pool_.Length() - 1;
}


intptr_t Assembler::FindObject(const Object& obj, Patchability patchable) {
  // The object pool cannot be used in the vm isolate.
  ASSERT(Isolate::Current() != Dart::vm_isolate());
  ASSERT(!object_pool_.IsNull());

  // If the object is not patchable, check if we've already got it in the
  // object pool.
  if (patchable == kNotPatchable) {
    // Special case for Object::null(), which is always at object_pool_ index 0
    // because Lookup() below returns 0 when the object is not mapped in the
    // table.
    if (obj.raw() == Object::null()) {
      return 0;
    }

    intptr_t idx = object_pool_index_table_.Lookup(obj.raw());
    if (idx != 0) {
      ASSERT(patchable_pool_entries_[idx] == kNotPatchable);
      return idx;
    }
  }

  object_pool_.Add(obj, Heap::kOld);
  patchable_pool_entries_.Add(patchable);
  if (patchable == kNotPatchable) {
    // The object isn't patchable. Record the index for fast lookup.
    object_pool_index_table_.Insert(
        ObjIndexPair(obj.raw(), object_pool_.Length() - 1));
  }
  return object_pool_.Length() - 1;
}


intptr_t Assembler::FindImmediate(int64_t imm) {
  ASSERT(Isolate::Current() != Dart::vm_isolate());
  ASSERT(!object_pool_.IsNull());
  const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(imm));
  return FindObject(smi, kNotPatchable);
}


bool Assembler::CanLoadObjectFromPool(const Object& object) {
  // TODO(zra, kmillikin): Also load other large immediates from the object
  // pool
  if (object.IsSmi()) {
    // If the raw smi does not fit into a 32-bit signed int, then we'll keep
    // the raw value in the object pool.
    return !Utils::IsInt(32, reinterpret_cast<int64_t>(object.raw()));
  }
  ASSERT(object.IsNotTemporaryScopedHandle());
  ASSERT(object.IsOld());
  return (Isolate::Current() != Dart::vm_isolate()) &&
         // Not in the VMHeap, OR is one of the VMHeap objects we put in every
         // object pool.
         // TODO(zra): Evaluate putting all VM heap objects into the pool.
         (!object.InVMHeap() || (object.raw() == Object::null()) ||
                                (object.raw() == Bool::True().raw()) ||
                                (object.raw() == Bool::False().raw()));
}


bool Assembler::CanLoadImmediateFromPool(int64_t imm, Register pp) {
  return !Utils::IsInt(32, imm) &&
         (pp != kNoRegister) &&
         (Isolate::Current() != Dart::vm_isolate());
}


void Assembler::LoadExternalLabel(Register dst,
                                  const ExternalLabel* label,
                                  Patchability patchable,
                                  Register pp) {
  const int32_t offset =
      Array::element_offset(FindExternalLabel(label, patchable));
  LoadWordFromPoolOffset(dst, pp, offset);
}


void Assembler::LoadObject(Register dst, const Object& object, Register pp) {
  if (CanLoadObjectFromPool(object)) {
    const int32_t offset =
        Array::element_offset(FindObject(object, kNotPatchable));
    LoadWordFromPoolOffset(dst, pp, offset);
  } else {
    ASSERT((Isolate::Current() == Dart::vm_isolate()) ||
           object.IsSmi() ||
           object.InVMHeap());
    LoadDecodableImmediate(dst, reinterpret_cast<int64_t>(object.raw()), pp);
  }
}


void Assembler::LoadDecodableImmediate(Register reg, int64_t imm, Register pp) {
  if ((pp != kNoRegister) && (Isolate::Current() != Dart::vm_isolate())) {
    int64_t val_smi_tag = imm & kSmiTagMask;
    imm &= ~kSmiTagMask;  // Mask off the tag bits.
    const int32_t offset = Array::element_offset(FindImmediate(imm));
    LoadWordFromPoolOffset(reg, pp, offset);
    if (val_smi_tag != 0) {
      // Add back the tag bits.
      orri(reg, reg, val_smi_tag);
    }
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
  movz(reg, h0, 0);
  movk(reg, h1, 1);
  movk(reg, h2, 2);
  movk(reg, h3, 3);
}


void Assembler::LoadImmediate(Register reg, int64_t imm, Register pp) {
  Comment("LoadImmediate");
  if (CanLoadImmediateFromPool(imm, pp)) {
    // It's a 64-bit constant and we're not in the VM isolate, so load from
    // object pool.
    // Save the bits that must be masked-off for the SmiTag
    int64_t val_smi_tag = imm & kSmiTagMask;
    imm &= ~kSmiTagMask;  // Mask off the tag bits.
    const int32_t offset = Array::element_offset(FindImmediate(imm));
    LoadWordFromPoolOffset(reg, pp, offset);
    if (val_smi_tag != 0) {
      // Add back the tag bits.
      orri(reg, reg, val_smi_tag);
    }
  } else {
    // 0. Is it 0?
    if (imm == 0) {
      movz(reg, 0, 0);
      return;
    }

    // 1. Can we use one orri operation?
    Operand op;
    Operand::OperandType ot;
    ot = Operand::CanHold(imm, kXRegSizeInBits, &op);
    if (ot == Operand::BitfieldImm) {
      orri(reg, ZR, imm);
      return;
    }

    // 2. Fall back on movz, movk, movn.
    const uint32_t w0 = Utils::Low32Bits(imm);
    const uint32_t w1 = Utils::High32Bits(imm);
    const uint16_t h0 = Utils::Low16Bits(w0);
    const uint16_t h1 = Utils::High16Bits(w0);
    const uint16_t h2 = Utils::Low16Bits(w1);
    const uint16_t h3 = Utils::High16Bits(w1);

    // Special case for w1 == 0xffffffff
    if (w1 == 0xffffffff) {
      if (h1 == 0xffff) {
        movn(reg, ~h0, 0);
      } else {
        movn(reg, ~h1, 1);
        movk(reg, h0, 0);
      }
      return;
    }

    // Special case for h3 == 0xffff
    if (h3 == 0xffff) {
      // We know h2 != 0xffff.
      movn(reg, ~h2, 2);
      if (h1 != 0xffff) {
        movk(reg, h1, 1);
      }
      if (h0 != 0xffff) {
        movk(reg, h0, 0);
      }
      return;
    }

    bool initialized = false;
    if (h0 != 0) {
      movz(reg, h0, 0);
      initialized = true;
    }
    if (h1 != 0) {
      if (initialized) {
        movk(reg, h1, 1);
      } else {
        movz(reg, h1, 1);
        initialized = true;
      }
    }
    if (h2 != 0) {
      if (initialized) {
        movk(reg, h2, 2);
      } else {
        movz(reg, h2, 2);
        initialized = true;
      }
    }
    if (h3 != 0) {
      if (initialized) {
        movk(reg, h3, 3);
      } else {
        movz(reg, h3, 3);
      }
    }
  }
}


void Assembler::AddImmediate(
    Register dest, Register rn, int64_t imm, Register pp) {
  ASSERT(rn != TMP2);
  Operand op;
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    add(dest, rn, op);
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    sub(dest, rn, op);
  } else {
    LoadImmediate(TMP2, imm, pp);
    add(dest, rn, Operand(TMP2));
  }
}


void Assembler::CompareImmediate(Register rn, int64_t imm, Register pp) {
  ASSERT(rn != TMP2);
  Operand op;
  if (Operand::CanHold(imm, kXRegSizeInBits, &op) == Operand::Immediate) {
    cmp(rn, op);
  } else if (Operand::CanHold(-imm, kXRegSizeInBits, &op) ==
             Operand::Immediate) {
    cmn(rn, op);
  } else {
    LoadImmediate(TMP2, imm, pp);
    cmp(rn, Operand(TMP2));
  }
}


void Assembler::LoadFromOffset(Register dest, Register base, int32_t offset) {
  ASSERT(base != TMP2);
  if (Address::CanHoldOffset(offset)) {
    ldr(dest, Address(base, offset));
  } else {
    // Since offset is 32-bits, it won't be loaded from the pool.
    AddImmediate(TMP2, base, offset, kNoRegister);
    ldr(dest, Address(TMP2));
  }
}


void Assembler::StoreToOffset(Register src, Register base, int32_t offset) {
  ASSERT(src != TMP2);
  ASSERT(base != TMP2);
  if (Address::CanHoldOffset(offset)) {
    str(src, Address(base, offset));
  } else if (Address::CanHoldOffset(offset, Address::PreIndex)) {
    mov(TMP2, base);
    str(src, Address(TMP2, offset, Address::PreIndex));
  } else {
    // Since offset is 32-bits, it won't be loaded from the pool.
    AddImmediate(TMP2, base, offset, kNoRegister);
    str(src, Address(TMP2));
  }
}


// Store into object.
// Preserves object and value registers.
void Assembler::StoreIntoObjectFilterNoSmi(Register object,
                                           Register value,
                                           Label* no_update) {
  COMPILE_ASSERT((kNewObjectAlignmentOffset == kWordSize) &&
                 (kOldObjectAlignmentOffset == 0), young_alignment);

  // Write-barrier triggers if the value is in the new space (has bit set) and
  // the object is in the old space (has bit cleared).
  // To check that, we compute value & ~object and skip the write barrier
  // if the bit is not set. We can't destroy the object.
  bic(TMP, value, Operand(object));
  tsti(TMP, kNewObjectAlignmentOffset);
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
  tsti(TMP, kNewObjectAlignmentOffset);
  b(no_update, EQ);
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
  BranchLink(&StubCode::UpdateStoreBufferLabel(), PP);
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


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  ASSERT(value.IsSmi() || value.InVMHeap() ||
         (value.IsOld() && value.IsNotTemporaryScopedHandle()));
  // No store buffer update.
  LoadObject(TMP, value, PP);
  str(TMP, dest);
}


// Frame entry and exit.
void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  AddImmediate(SP, SP, -frame_space, kNoRegister);
  if (OS::ActivationFrameAlignment() > 1) {
    mov(TMP, SP);  // SP can't be register operand of andi.
    andi(TMP, TMP, ~(OS::ActivationFrameAlignment() - 1));
    mov(SP, TMP);
  }
}


void Assembler::EnterFrame(intptr_t frame_size) {
  Push(LR);
  Push(FP);
  mov(FP, SP);

  if (frame_size > 0) {
    sub(SP, SP, Operand(frame_size));
  }
}


void Assembler::LeaveFrame() {
  mov(SP, FP);
  Pop(FP);
  Pop(LR);
}


void Assembler::EnterDartFrame(intptr_t frame_size) {
  // Setup the frame.
  adr(TMP, 0);  // TMP gets PC of this instruction.
  EnterFrame(0);
  Push(TMP);  // Save PC Marker.
  PushPP();  // Save PP.

  // Load the pool pointer.
  LoadPoolPointer(PP);

  // Reserve space.
  if (frame_size > 0) {
    sub(SP, SP, Operand(frame_size));
  }
}


void Assembler::EnterDartFrameWithInfo(intptr_t frame_size, Register new_pp) {
  // Setup the frame.
  adr(TMP, 0);  // TMP gets PC of this instruction.
  EnterFrame(0);
  Push(TMP);  // Save PC Marker.
  PushPP();  // Save PP.

  // Load the pool pointer.
  if (new_pp == kNoRegister) {
    LoadPoolPointer(PP);
  } else {
    mov(PP, new_pp);
  }

  // Reserve space.
  if (frame_size > 0) {
    sub(SP, SP, Operand(frame_size));
  }
}


// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate. We must also set up the pool pointer for the function.
void Assembler::EnterOsrFrame(intptr_t extra_size, Register new_pp) {
  const intptr_t offset = CodeSize();

  Comment("EnterOsrFrame");
  adr(TMP, 0);

  AddImmediate(TMP, TMP, -offset, kNoRegister);
  StoreToOffset(TMP, FP, kPcMarkerSlotFromFp * kWordSize);

  // Setup pool pointer for this dart function.
  if (new_pp == kNoRegister) {
    LoadPoolPointer(PP);
  } else {
    mov(PP, new_pp);
  }

  if (extra_size > 0) {
    sub(SP, SP, Operand(extra_size));
  }
}


void Assembler::LeaveDartFrame() {
  // Restore and untag PP.
  LoadFromOffset(PP, FP, kSavedCallerPpSlotFromFp * kWordSize);
  sub(PP, PP, Operand(kHeapObjectTag));
  LeaveFrame();
}


void Assembler::EnterCallRuntimeFrame(intptr_t frame_size) {
  EnterFrame(0);

  // TODO(zra): also save volatile FPU registers.

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
  // TODO(zra): Also include FPU regs in this count once they are added.
  const intptr_t kPushedRegistersSize =
      kDartVolatileCpuRegCount * kWordSize;
  AddImmediate(SP, FP, -kPushedRegistersSize, PP);
  for (int i = kDartLastVolatileCpuReg; i >= kDartFirstVolatileCpuReg; i--) {
    const Register reg = static_cast<Register>(i);
    Pop(reg);
  }

  Pop(FP);
  Pop(LR);
}


void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
