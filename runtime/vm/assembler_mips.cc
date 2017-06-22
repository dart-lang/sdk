// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/longjump.h"
#include "vm/runtime_entry.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, inline_alloc);
#if defined(USING_SIMULATOR)
DECLARE_FLAG(int, trace_sim_after);
#endif

void Assembler::InitializeMemoryWithBreakpoints(uword data, intptr_t length) {
  ASSERT(Utils::IsAligned(data, 4));
  ASSERT(Utils::IsAligned(length, 4));
  const uword end = data + length;
  while (data < end) {
    *reinterpret_cast<int32_t*>(data) = Instr::kBreakPointInstruction;
    data += 4;
  }
}


void Assembler::GetNextPC(Register dest, Register temp) {
  if (temp != kNoRegister) {
    mov(temp, RA);
  }
  EmitRegImmType(REGIMM, R0, BGEZAL, 1);
  mov(dest, RA);
  if (temp != kNoRegister) {
    mov(RA, temp);
  }
}


static bool CanEncodeBranchOffset(int32_t offset) {
  ASSERT(Utils::IsAligned(offset, 4));
  return Utils::IsInt(18, offset);
}


int32_t Assembler::EncodeBranchOffset(int32_t offset, int32_t instr) {
  if (!CanEncodeBranchOffset(offset)) {
    ASSERT(!use_far_branches());
    Thread::Current()->long_jump_base()->Jump(1, Object::branch_offset_error());
  }

  // Properly preserve only the bits supported in the instruction.
  offset >>= 2;
  offset &= kBranchOffsetMask;
  return (instr & ~kBranchOffsetMask) | offset;
}


static intptr_t DecodeBranchOffset(int32_t instr) {
  // Sign-extend, left-shift by 2.
  return (((instr & kBranchOffsetMask) << 16) >> 14);
}


static int32_t DecodeLoadImmediate(int32_t ori_instr, int32_t lui_instr) {
  return (((lui_instr & kBranchOffsetMask) << 16) |
          (ori_instr & kBranchOffsetMask));
}


static int32_t EncodeLoadImmediate(int32_t dest, int32_t instr) {
  return ((instr & ~kBranchOffsetMask) | (dest & kBranchOffsetMask));
}


class PatchFarJump : public AssemblerFixup {
 public:
  PatchFarJump() {}

  void Process(const MemoryRegion& region, intptr_t position) {
    const int32_t high = region.Load<int32_t>(position);
    const int32_t low = region.Load<int32_t>(position + Instr::kInstrSize);
    const int32_t offset = DecodeLoadImmediate(low, high);
    const int32_t dest = region.start() + offset;

    if ((Instr::At(reinterpret_cast<uword>(&high))->OpcodeField() == LUI) &&
        (Instr::At(reinterpret_cast<uword>(&low))->OpcodeField() == ORI)) {
      // Change the offset to the absolute value.
      const int32_t encoded_low =
          EncodeLoadImmediate(dest & kBranchOffsetMask, low);
      const int32_t encoded_high = EncodeLoadImmediate(dest >> 16, high);

      region.Store<int32_t>(position, encoded_high);
      region.Store<int32_t>(position + Instr::kInstrSize, encoded_low);
      return;
    }
    // If the offset loading instructions aren't there, we must have replaced
    // the far branch with a near one, and so these instructions should be NOPs.
    ASSERT((high == Instr::kNopInstruction) && (low == Instr::kNopInstruction));
  }

  virtual bool IsPointerOffset() const { return false; }
};


void Assembler::EmitFarJump(int32_t offset, bool link) {
  ASSERT(!in_delay_slot_);
  ASSERT(use_far_branches());
  const uint16_t low = Utils::Low16Bits(offset);
  const uint16_t high = Utils::High16Bits(offset);
  buffer_.EmitFixup(new PatchFarJump());
  lui(T9, Immediate(high));
  ori(T9, T9, Immediate(low));
  if (link) {
    EmitRType(SPECIAL, T9, R0, RA, 0, JALR);
  } else {
    EmitRType(SPECIAL, T9, R0, R0, 0, JR);
  }
}


static Opcode OppositeBranchOpcode(Opcode b) {
  switch (b) {
    case BEQ:
      return BNE;
    case BNE:
      return BEQ;
    case BGTZ:
      return BLEZ;
    case BLEZ:
      return BGTZ;
    case BEQL:
      return BNEL;
    case BNEL:
      return BEQL;
    case BGTZL:
      return BLEZL;
    case BLEZL:
      return BGTZL;
    default:
      UNREACHABLE();
      break;
  }
  return BNE;
}


void Assembler::EmitFarBranch(Opcode b,
                              Register rs,
                              Register rt,
                              int32_t offset) {
  ASSERT(!in_delay_slot_);
  EmitIType(b, rs, rt, 4);
  nop();
  EmitFarJump(offset, false);
}


static RtRegImm OppositeBranchNoLink(RtRegImm b) {
  switch (b) {
    case BLTZ:
      return BGEZ;
    case BGEZ:
      return BLTZ;
    case BLTZAL:
      return BGEZ;
    case BGEZAL:
      return BLTZ;
    default:
      UNREACHABLE();
      break;
  }
  return BLTZ;
}


void Assembler::EmitFarRegImmBranch(RtRegImm b, Register rs, int32_t offset) {
  ASSERT(!in_delay_slot_);
  EmitRegImmType(REGIMM, rs, b, 4);
  nop();
  EmitFarJump(offset, (b == BLTZAL) || (b == BGEZAL));
}


void Assembler::EmitFarFpuBranch(bool kind, int32_t offset) {
  ASSERT(!in_delay_slot_);
  const uint32_t b16 = kind ? (1 << 16) : 0;
  Emit(COP1 << kOpcodeShift | COP1_BC << kCop1SubShift | b16 | 4);
  nop();
  EmitFarJump(offset, false);
}


void Assembler::EmitBranch(Opcode b, Register rs, Register rt, Label* label) {
  ASSERT(!in_delay_slot_);
  if (label->IsBound()) {
    // Relative destination from an instruction after the branch.
    const int32_t dest =
        label->Position() - (buffer_.Size() + Instr::kInstrSize);
    if (use_far_branches() && !CanEncodeBranchOffset(dest)) {
      EmitFarBranch(OppositeBranchOpcode(b), rs, rt, label->Position());
    } else {
      const uint16_t dest_off = EncodeBranchOffset(dest, 0);
      EmitIType(b, rs, rt, dest_off);
    }
  } else {
    const intptr_t position = buffer_.Size();
    if (use_far_branches()) {
      const uint32_t dest_off = label->position_;
      EmitFarBranch(b, rs, rt, dest_off);
    } else {
      const uint16_t dest_off = EncodeBranchOffset(label->position_, 0);
      EmitIType(b, rs, rt, dest_off);
    }
    label->LinkTo(position);
  }
}


void Assembler::EmitRegImmBranch(RtRegImm b, Register rs, Label* label) {
  ASSERT(!in_delay_slot_);
  if (label->IsBound()) {
    // Relative destination from an instruction after the branch.
    const int32_t dest =
        label->Position() - (buffer_.Size() + Instr::kInstrSize);
    if (use_far_branches() && !CanEncodeBranchOffset(dest)) {
      EmitFarRegImmBranch(OppositeBranchNoLink(b), rs, label->Position());
    } else {
      const uint16_t dest_off = EncodeBranchOffset(dest, 0);
      EmitRegImmType(REGIMM, rs, b, dest_off);
    }
  } else {
    const intptr_t position = buffer_.Size();
    if (use_far_branches()) {
      const uint32_t dest_off = label->position_;
      EmitFarRegImmBranch(b, rs, dest_off);
    } else {
      const uint16_t dest_off = EncodeBranchOffset(label->position_, 0);
      EmitRegImmType(REGIMM, rs, b, dest_off);
    }
    label->LinkTo(position);
  }
}


void Assembler::EmitFpuBranch(bool kind, Label* label) {
  ASSERT(!in_delay_slot_);
  const int32_t b16 = kind ? (1 << 16) : 0;  // Bit 16 set for branch on true.
  if (label->IsBound()) {
    // Relative destination from an instruction after the branch.
    const int32_t dest =
        label->Position() - (buffer_.Size() + Instr::kInstrSize);
    if (use_far_branches() && !CanEncodeBranchOffset(dest)) {
      EmitFarFpuBranch(kind, label->Position());
    } else {
      const uint16_t dest_off = EncodeBranchOffset(dest, 0);
      Emit(COP1 << kOpcodeShift | COP1_BC << kCop1SubShift | b16 | dest_off);
    }
  } else {
    const intptr_t position = buffer_.Size();
    if (use_far_branches()) {
      const uint32_t dest_off = label->position_;
      EmitFarFpuBranch(kind, dest_off);
    } else {
      const uint16_t dest_off = EncodeBranchOffset(label->position_, 0);
      Emit(COP1 << kOpcodeShift | COP1_BC << kCop1SubShift | b16 | dest_off);
    }
    label->LinkTo(position);
  }
}


static int32_t FlipBranchInstruction(int32_t instr) {
  Instr* i = Instr::At(reinterpret_cast<uword>(&instr));
  if (i->OpcodeField() == REGIMM) {
    RtRegImm b = OppositeBranchNoLink(i->RegImmFnField());
    i->SetRegImmFnField(b);
    return i->InstructionBits();
  } else if (i->OpcodeField() == COP1) {
    return instr ^ (1 << 16);
  }
  Opcode b = OppositeBranchOpcode(i->OpcodeField());
  i->SetOpcodeField(b);
  return i->InstructionBits();
}


void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  intptr_t bound_pc = buffer_.Size();

  while (label->IsLinked()) {
    int32_t position = label->Position();
    int32_t dest = bound_pc - (position + Instr::kInstrSize);

    if (use_far_branches() && !CanEncodeBranchOffset(dest)) {
      // Far branches are enabled and we can't encode the branch offset.

      // Grab the branch instruction. We'll need to flip it later.
      const int32_t branch = buffer_.Load<int32_t>(position);

      // Grab instructions that load the offset.
      const int32_t high =
          buffer_.Load<int32_t>(position + 2 * Instr::kInstrSize);
      const int32_t low =
          buffer_.Load<int32_t>(position + 3 * Instr::kInstrSize);

      // Change from relative to the branch to relative to the assembler buffer.
      dest = buffer_.Size();
      const int32_t encoded_low =
          EncodeLoadImmediate(dest & kBranchOffsetMask, low);
      const int32_t encoded_high = EncodeLoadImmediate(dest >> 16, high);

      // Skip the unconditional far jump if the test fails by flipping the
      // sense of the branch instruction.
      buffer_.Store<int32_t>(position, FlipBranchInstruction(branch));
      buffer_.Store<int32_t>(position + 2 * Instr::kInstrSize, encoded_high);
      buffer_.Store<int32_t>(position + 3 * Instr::kInstrSize, encoded_low);
      label->position_ = DecodeLoadImmediate(low, high);
    } else if (use_far_branches() && CanEncodeBranchOffset(dest)) {
      // We assembled a far branch, but we don't need it. Replace with a near
      // branch.

      // Grab the link to the next branch.
      const int32_t high =
          buffer_.Load<int32_t>(position + 2 * Instr::kInstrSize);
      const int32_t low =
          buffer_.Load<int32_t>(position + 3 * Instr::kInstrSize);

      // Grab the original branch instruction.
      int32_t branch = buffer_.Load<int32_t>(position);

      // Clear out the old (far) branch.
      for (int i = 0; i < 5; i++) {
        buffer_.Store<int32_t>(position + i * Instr::kInstrSize,
                               Instr::kNopInstruction);
      }

      // Calculate the new offset.
      dest = dest - 4 * Instr::kInstrSize;
      const int32_t encoded = EncodeBranchOffset(dest, branch);
      buffer_.Store<int32_t>(position + 4 * Instr::kInstrSize, encoded);
      label->position_ = DecodeLoadImmediate(low, high);
    } else {
      const int32_t next = buffer_.Load<int32_t>(position);
      const int32_t encoded = EncodeBranchOffset(dest, next);
      buffer_.Store<int32_t>(position, encoded);
      label->position_ = DecodeBranchOffset(next);
    }
  }
  label->BindTo(bound_pc);
  delay_slot_available_ = false;
}


void Assembler::LoadWordFromPoolOffset(Register rd,
                                       int32_t offset,
                                       Register pp) {
  ASSERT((pp != PP) || constant_pool_allowed());
  ASSERT(!in_delay_slot_);
  ASSERT(rd != pp);
  if (Address::CanHoldOffset(offset)) {
    lw(rd, Address(pp, offset));
  } else {
    const int16_t offset_low = Utils::Low16Bits(offset);  // Signed.
    offset -= offset_low;
    const uint16_t offset_high = Utils::High16Bits(offset);  // Unsigned.
    if (offset_high != 0) {
      lui(rd, Immediate(offset_high));
      addu(rd, rd, pp);
      lw(rd, Address(rd, offset_low));
    } else {
      lw(rd, Address(pp, offset_low));
    }
  }
}


void Assembler::AdduDetectOverflow(Register rd,
                                   Register rs,
                                   Register rt,
                                   Register ro,
                                   Register scratch) {
  ASSERT(!in_delay_slot_);
  ASSERT(rd != ro);
  ASSERT(rd != TMP);
  ASSERT(ro != TMP);
  ASSERT(ro != rs);
  ASSERT(ro != rt);

  if ((rs == rt) && (rd == rs)) {
    ASSERT(scratch != kNoRegister);
    ASSERT(scratch != TMP);
    ASSERT(rd != scratch);
    ASSERT(ro != scratch);
    ASSERT(rs != scratch);
    ASSERT(rt != scratch);
    mov(scratch, rt);
    rt = scratch;
  }

  if (rd == rs) {
    mov(TMP, rs);        // Preserve rs.
    addu(rd, rs, rt);    // rs is overwritten.
    xor_(TMP, rd, TMP);  // Original rs.
    xor_(ro, rd, rt);
    and_(ro, ro, TMP);
  } else if (rd == rt) {
    mov(TMP, rt);        // Preserve rt.
    addu(rd, rs, rt);    // rt is overwritten.
    xor_(TMP, rd, TMP);  // Original rt.
    xor_(ro, rd, rs);
    and_(ro, ro, TMP);
  } else {
    addu(rd, rs, rt);
    xor_(ro, rd, rs);
    xor_(TMP, rd, rt);
    and_(ro, TMP, ro);
  }
}


void Assembler::SubuDetectOverflow(Register rd,
                                   Register rs,
                                   Register rt,
                                   Register ro) {
  ASSERT(!in_delay_slot_);
  ASSERT(rd != ro);
  ASSERT(rd != TMP);
  ASSERT(ro != TMP);
  ASSERT(ro != rs);
  ASSERT(ro != rt);
  ASSERT(rs != TMP);
  ASSERT(rt != TMP);

  // This happens with some crankshaft code. Since Subu works fine if
  // left == right, let's not make that restriction here.
  if (rs == rt) {
    mov(rd, ZR);
    mov(ro, ZR);
    return;
  }

  if (rd == rs) {
    mov(TMP, rs);        // Preserve left.
    subu(rd, rs, rt);    // Left is overwritten.
    xor_(ro, rd, TMP);   // scratch is original left.
    xor_(TMP, TMP, rs);  // scratch is original left.
    and_(ro, TMP, ro);
  } else if (rd == rt) {
    mov(TMP, rt);      // Preserve right.
    subu(rd, rs, rt);  // Right is overwritten.
    xor_(ro, rd, rs);
    xor_(TMP, rs, TMP);  // Original right.
    and_(ro, TMP, ro);
  } else {
    subu(rd, rs, rt);
    xor_(ro, rd, rs);
    xor_(TMP, rs, rt);
    and_(ro, TMP, ro);
  }
}


void Assembler::CheckCodePointer() {
#ifdef DEBUG
  if (!FLAG_check_code_pointer) {
    return;
  }
  Comment("CheckCodePointer");
  Label cid_ok, instructions_ok;
  Push(CMPRES1);
  Push(CMPRES2);
  LoadClassId(CMPRES1, CODE_REG);
  BranchEqual(CMPRES1, Immediate(kCodeCid), &cid_ok);
  break_(0);
  Bind(&cid_ok);
  GetNextPC(CMPRES1, TMP);
  const intptr_t entry_offset = CodeSize() - Instr::kInstrSize +
                                Instructions::HeaderSize() - kHeapObjectTag;
  AddImmediate(CMPRES1, CMPRES1, -entry_offset);
  lw(CMPRES2, FieldAddress(CODE_REG, Code::saved_instructions_offset()));
  BranchEqual(CMPRES1, CMPRES2, &instructions_ok);
  break_(1);
  Bind(&instructions_ok);
  Pop(CMPRES2);
  Pop(CMPRES1);
#endif
}


void Assembler::RestoreCodePointer() {
  lw(CODE_REG, Address(FP, kPcMarkerSlotFromFp * kWordSize));
  CheckCodePointer();
}


void Assembler::Branch(const StubEntry& stub_entry, Register pp) {
  ASSERT(!in_delay_slot_);
  const Code& target_code = Code::ZoneHandle(stub_entry.code());
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.AddObject(target_code, kPatchable));
  LoadWordFromPoolOffset(CODE_REG, offset - kHeapObjectTag, pp);
  lw(TMP, FieldAddress(CODE_REG, Code::entry_point_offset()));
  jr(TMP);
}


void Assembler::BranchLink(const ExternalLabel* label) {
  ASSERT(!in_delay_slot_);
  LoadImmediate(T9, label->address());
  jalr(T9);
}


void Assembler::BranchLink(const Code& target, Patchability patchable) {
  ASSERT(!in_delay_slot_);
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindObject(target, patchable));
  LoadWordFromPoolOffset(CODE_REG, offset - kHeapObjectTag);
  lw(T9, FieldAddress(CODE_REG, Code::entry_point_offset()));
  jalr(T9);
  if (patchable == kPatchable) {
    delay_slot_available_ = false;  // CodePatcher expects a nop.
  }
}


void Assembler::BranchLink(const StubEntry& stub_entry,
                           Patchability patchable) {
  BranchLink(Code::ZoneHandle(stub_entry.code()), patchable);
}


void Assembler::BranchLinkPatchable(const StubEntry& stub_entry) {
  BranchLink(Code::ZoneHandle(stub_entry.code()), kPatchable);
}


void Assembler::BranchLinkToRuntime() {
  lw(T9, Address(THR, Thread::call_to_runtime_entry_point_offset()));
  jalr(T9);
  delay_slot()->lw(CODE_REG,
                   Address(THR, Thread::call_to_runtime_stub_offset()));
}


void Assembler::BranchLinkWithEquivalence(const StubEntry& stub_entry,
                                          const Object& equivalence) {
  const Code& target = Code::ZoneHandle(stub_entry.code());
  ASSERT(!in_delay_slot_);
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindObject(target, equivalence));
  LoadWordFromPoolOffset(CODE_REG, offset - kHeapObjectTag);
  lw(T9, FieldAddress(CODE_REG, Code::entry_point_offset()));
  jalr(T9);
  delay_slot_available_ = false;  // CodePatcher expects a nop.
}


bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(!object.IsICData() || ICData::Cast(object).IsOriginal());
  ASSERT(!object.IsField() || Field::Cast(object).IsOriginal());
  ASSERT(!Thread::CanLoadFromThread(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  ASSERT(object.IsNotTemporaryScopedHandle());
  ASSERT(object.IsOld());
  return true;
}


void Assembler::LoadObjectHelper(Register rd,
                                 const Object& object,
                                 bool is_unique) {
  ASSERT(!object.IsICData() || ICData::Cast(object).IsOriginal());
  ASSERT(!object.IsField() || Field::Cast(object).IsOriginal());
  ASSERT(!in_delay_slot_);
  if (Thread::CanLoadFromThread(object)) {
    // Load common VM constants from the thread. This works also in places where
    // no constant pool is set up (e.g. intrinsic code).
    lw(rd, Address(THR, Thread::OffsetFromThread(object)));
  } else if (object.IsSmi()) {
    // Relocation doesn't apply to Smis.
    LoadImmediate(rd, reinterpret_cast<int32_t>(object.raw()));
  } else if (CanLoadFromObjectPool(object)) {
    // Make sure that class CallPattern is able to decode this load from the
    // object pool.
    const int32_t offset = ObjectPool::element_offset(
        is_unique ? object_pool_wrapper_.AddObject(object)
                  : object_pool_wrapper_.FindObject(object));
    LoadWordFromPoolOffset(rd, offset - kHeapObjectTag);
  } else {
    UNREACHABLE();
  }
}


void Assembler::LoadObject(Register rd, const Object& object) {
  LoadObjectHelper(rd, object, false);
}


void Assembler::LoadUniqueObject(Register rd, const Object& object) {
  LoadObjectHelper(rd, object, true);
}


void Assembler::LoadFunctionFromCalleePool(Register dst,
                                           const Function& function,
                                           Register new_pp) {
  const int32_t offset =
      ObjectPool::element_offset(object_pool_wrapper_.FindObject(function));
  LoadWordFromPoolOffset(dst, offset - kHeapObjectTag, new_pp);
}


void Assembler::LoadNativeEntry(Register rd,
                                const ExternalLabel* label,
                                Patchability patchable) {
  const int32_t offset = ObjectPool::element_offset(
      object_pool_wrapper_.FindNativeEntry(label, patchable));
  LoadWordFromPoolOffset(rd, offset - kHeapObjectTag);
}


void Assembler::PushObject(const Object& object) {
  ASSERT(!object.IsICData() || ICData::Cast(object).IsOriginal());
  ASSERT(!object.IsField() || Field::Cast(object).IsOriginal());
  ASSERT(!in_delay_slot_);
  LoadObject(TMP, object);
  Push(TMP);
}


// Preserves object and value registers.
void Assembler::StoreIntoObjectFilterNoSmi(Register object,
                                           Register value,
                                           Label* no_update) {
  ASSERT(!in_delay_slot_);
  COMPILE_ASSERT((kNewObjectAlignmentOffset == kWordSize) &&
                 (kOldObjectAlignmentOffset == 0));

  // Write-barrier triggers if the value is in the new space (has bit set) and
  // the object is in the old space (has bit cleared).
  // To check that, we compute value & ~object and skip the write barrier
  // if the bit is not set. We can't destroy the object.
  nor(TMP, ZR, object);
  and_(TMP, value, TMP);
  andi(CMPRES1, TMP, Immediate(kNewObjectAlignmentOffset));
  beq(CMPRES1, ZR, no_update);
}


// Preserves object and value registers.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* no_update) {
  ASSERT(!in_delay_slot_);
  // For the value we are only interested in the new/old bit and the tag bit.
  // And the new bit with the tag bit. The resulting bit will be 0 for a Smi.
  sll(TMP, value, kObjectAlignmentLog2 - 1);
  and_(TMP, value, TMP);
  // And the result with the negated space bit of the object.
  nor(CMPRES1, ZR, object);
  and_(TMP, TMP, CMPRES1);
  andi(CMPRES1, TMP, Immediate(kNewObjectAlignmentOffset));
  beq(CMPRES1, ZR, no_update);
}


void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                bool can_value_be_smi) {
  ASSERT(!in_delay_slot_);
  ASSERT(object != value);
  sw(value, dest);
  Label done;
  if (can_value_be_smi) {
    StoreIntoObjectFilter(object, value, &done);
  } else {
    StoreIntoObjectFilterNoSmi(object, value, &done);
  }
  // A store buffer update is required.
  if (value != T0) {
    // Preserve T0.
    addiu(SP, SP, Immediate(-2 * kWordSize));
    sw(T0, Address(SP, 1 * kWordSize));
  } else {
    addiu(SP, SP, Immediate(-1 * kWordSize));
  }
  sw(RA, Address(SP, 0 * kWordSize));
  if (object != T0) {
    mov(T0, object);
  }
  lw(T9, Address(THR, Thread::update_store_buffer_entry_point_offset()));
  jalr(T9);
  delay_slot()->lw(CODE_REG,
                   Address(THR, Thread::update_store_buffer_code_offset()));
  lw(RA, Address(SP, 0 * kWordSize));
  if (value != T0) {
    // Restore T0.
    lw(T0, Address(SP, 1 * kWordSize));
    addiu(SP, SP, Immediate(2 * kWordSize));
  } else {
    addiu(SP, SP, Immediate(1 * kWordSize));
  }
  Bind(&done);
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


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  ASSERT(!in_delay_slot_);
  sw(value, dest);
#if defined(DEBUG)
  Label done;
  StoreIntoObjectFilter(object, value, &done);
  Stop("Store buffer update is required");
  Bind(&done);
#endif  // defined(DEBUG)
  // No store buffer update.
}


void Assembler::StoreIntoObjectNoBarrierOffset(Register object,
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
  ASSERT(!in_delay_slot_);
  ASSERT(value.IsSmi() || value.InVMHeap() ||
         (value.IsOld() && value.IsNotTemporaryScopedHandle()));
  // No store buffer update.
  LoadObject(TMP, value);
  sw(TMP, dest);
}


void Assembler::StoreIntoObjectNoBarrierOffset(Register object,
                                               int32_t offset,
                                               const Object& value) {
  if (Address::CanHoldOffset(offset - kHeapObjectTag)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(TMP), value);
  }
}


void Assembler::LoadIsolate(Register result) {
  lw(result, Address(THR, Thread::isolate_offset()));
}


void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(RawObject::kClassIdTagPos == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset =
      Object::tags_offset() + RawObject::kClassIdTagPos / kBitsPerByte;
  lhu(result, FieldAddress(object, class_id_offset));
}


void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(!in_delay_slot_);
  ASSERT(result != class_id);
  LoadIsolate(result);
  const intptr_t offset =
      Isolate::class_table_offset() + ClassTable::table_offset();
  lw(result, Address(result, offset));
  sll(TMP, class_id, 2);
  addu(result, result, TMP);
  lw(result, Address(result));
}


void Assembler::LoadClass(Register result, Register object) {
  ASSERT(!in_delay_slot_);
  ASSERT(TMP != result);
  LoadClassId(TMP, object);
  LoadClassById(result, TMP);
}


void Assembler::LoadClassIdMayBeSmi(Register result, Register object) {
  Label heap_object, done;
  andi(CMPRES1, object, Immediate(kSmiTagMask));
  bne(CMPRES1, ZR, &heap_object);
  LoadImmediate(result, kSmiCid);
  b(&done);
  Bind(&heap_object);
  LoadClassId(result, object);
  Bind(&done);
}


void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  LoadClassIdMayBeSmi(result, object);
  SmiTag(result);
}


void Assembler::EnterFrame() {
  ASSERT(!in_delay_slot_);
  addiu(SP, SP, Immediate(-2 * kWordSize));
  sw(RA, Address(SP, 1 * kWordSize));
  sw(FP, Address(SP, 0 * kWordSize));
  mov(FP, SP);
}


void Assembler::LeaveFrameAndReturn() {
  ASSERT(!in_delay_slot_);
  mov(SP, FP);
  lw(RA, Address(SP, 1 * kWordSize));
  lw(FP, Address(SP, 0 * kWordSize));
  Ret();
  delay_slot()->addiu(SP, SP, Immediate(2 * kWordSize));
}


void Assembler::EnterStubFrame(intptr_t frame_size) {
  EnterDartFrame(frame_size);
}


void Assembler::LeaveStubFrame() {
  LeaveDartFrame();
}


void Assembler::LeaveStubFrameAndReturn(Register ra) {
  LeaveDartFrameAndReturn(ra);
}


// T0 receiver, S5 guarded cid as Smi
void Assembler::MonomorphicCheckedEntry() {
  ASSERT(has_single_entry_point_);
  has_single_entry_point_ = false;
  bool saved_use_far_branches = use_far_branches();
  set_use_far_branches(false);

  Label have_cid, miss;
  Bind(&miss);
  lw(T9, Address(THR, Thread::monomorphic_miss_entry_offset()));
  jr(T9);

  Comment("MonomorphicCheckedEntry");
  ASSERT(CodeSize() == Instructions::kCheckedEntryOffset);
  SmiUntag(S5);
  LoadClassIdMayBeSmi(S4, T0);
  bne(S4, S5, &miss);

  // Fall through to unchecked entry.
  ASSERT(CodeSize() == Instructions::kUncheckedEntryOffset);

  set_use_far_branches(saved_use_far_branches);
}


#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Register temp_reg,
                                     Label* trace) {
  ASSERT(cid > 0);
  ASSERT(!in_delay_slot_);
  ASSERT(temp_reg != kNoRegister);
  ASSERT(temp_reg != TMP);
  intptr_t state_offset = ClassTable::StateOffsetFor(cid);
  LoadIsolate(temp_reg);
  intptr_t table_offset =
      Isolate::class_table_offset() + ClassTable::TableOffsetFor(cid);
  lw(temp_reg, Address(temp_reg, table_offset));
  AddImmediate(temp_reg, state_offset);
  lw(temp_reg, Address(temp_reg, 0));
  andi(CMPRES1, temp_reg, Immediate(ClassHeapStats::TraceAllocationMask()));
  bne(CMPRES1, ZR, trace);
}


void Assembler::UpdateAllocationStats(intptr_t cid,
                                      Register temp_reg,
                                      Heap::Space space) {
  ASSERT(!in_delay_slot_);
  ASSERT(temp_reg != kNoRegister);
  ASSERT(temp_reg != TMP);
  ASSERT(cid > 0);
  intptr_t counter_offset =
      ClassTable::CounterOffsetFor(cid, space == Heap::kNew);
  LoadIsolate(temp_reg);
  intptr_t table_offset =
      Isolate::class_table_offset() + ClassTable::TableOffsetFor(cid);
  lw(temp_reg, Address(temp_reg, table_offset));
  AddImmediate(temp_reg, counter_offset);
  lw(TMP, Address(temp_reg, 0));
  AddImmediate(TMP, 1);
  sw(TMP, Address(temp_reg, 0));
}


void Assembler::UpdateAllocationStatsWithSize(intptr_t cid,
                                              Register size_reg,
                                              Register temp_reg,
                                              Heap::Space space) {
  ASSERT(!in_delay_slot_);
  ASSERT(temp_reg != kNoRegister);
  ASSERT(cid > 0);
  ASSERT(temp_reg != TMP);
  const uword class_offset = ClassTable::ClassOffsetFor(cid);
  const uword count_field_offset =
      (space == Heap::kNew)
          ? ClassHeapStats::allocated_since_gc_new_space_offset()
          : ClassHeapStats::allocated_since_gc_old_space_offset();
  const uword size_field_offset =
      (space == Heap::kNew)
          ? ClassHeapStats::allocated_size_since_gc_new_space_offset()
          : ClassHeapStats::allocated_size_since_gc_old_space_offset();
  LoadIsolate(temp_reg);
  intptr_t table_offset =
      Isolate::class_table_offset() + ClassTable::TableOffsetFor(cid);
  lw(temp_reg, Address(temp_reg, table_offset));
  AddImmediate(temp_reg, class_offset);
  lw(TMP, Address(temp_reg, count_field_offset));
  AddImmediate(TMP, 1);
  sw(TMP, Address(temp_reg, count_field_offset));
  lw(TMP, Address(temp_reg, size_field_offset));
  addu(TMP, TMP, size_reg);
  sw(TMP, Address(temp_reg, size_field_offset));
}
#endif  // !PRODUCT


void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            Register instance_reg,
                            Register temp_reg) {
  ASSERT(!in_delay_slot_);
  ASSERT(failure != NULL);
  if (FLAG_inline_alloc) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cls.id(), temp_reg, failure));
    const intptr_t instance_size = cls.instance_size();
    Heap::Space space = Heap::kNew;
    lw(temp_reg, Address(THR, Thread::heap_offset()));
    lw(instance_reg, Address(temp_reg, Heap::TopOffset(space)));
    // TODO(koda): Protect against unsigned overflow here.
    AddImmediate(instance_reg, instance_size);

    // instance_reg: potential next object start.
    lw(TMP, Address(temp_reg, Heap::EndOffset(space)));
    // Fail if heap end unsigned less than or equal to instance_reg.
    BranchUnsignedLessEqual(TMP, instance_reg, failure);

    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    sw(instance_reg, Address(temp_reg, Heap::TopOffset(space)));

    ASSERT(instance_size >= kHeapObjectTag);
    AddImmediate(instance_reg, -instance_size + kHeapObjectTag);
    NOT_IN_PRODUCT(UpdateAllocationStats(cls.id(), temp_reg, space));
    uint32_t tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    LoadImmediate(TMP, tags);
    sw(TMP, FieldAddress(instance_reg, Object::tags_offset()));
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
  if (FLAG_inline_alloc) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, temp1, failure));
    Isolate* isolate = Isolate::Current();
    Heap* heap = isolate->heap();
    Heap::Space space = Heap::kNew;
    lw(temp1, Address(THR, Thread::heap_offset()));
    // Potential new object start.
    lw(instance, Address(temp1, heap->TopOffset(space)));
    // Potential next object start.
    AddImmediate(end_address, instance, instance_size);
    // Branch on unsigned overflow.
    BranchUnsignedLess(end_address, instance, failure);

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start, /* inline_isolate = */ false.
    // end_address: potential next object start.
    lw(temp2, Address(temp1, Heap::EndOffset(space)));
    BranchUnsignedGreaterEqual(end_address, temp2, failure);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    sw(end_address, Address(temp1, Heap::TopOffset(space)));
    addiu(instance, instance, Immediate(kHeapObjectTag));
    LoadImmediate(temp1, instance_size);
    NOT_IN_PRODUCT(UpdateAllocationStatsWithSize(cid, temp1, temp2, space));

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    uint32_t tags = 0;
    tags = RawObject::ClassIdTag::update(cid, tags);
    tags = RawObject::SizeTag::update(instance_size, tags);
    LoadImmediate(temp1, tags);
    sw(temp1, FieldAddress(instance, Array::tags_offset()));  // Store tags.
  } else {
    b(failure);
  }
}


void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}


void Assembler::EnterDartFrame(intptr_t frame_size) {
  ASSERT(!in_delay_slot_);

  SetPrologueOffset();

  addiu(SP, SP, Immediate(-4 * kWordSize));
  sw(RA, Address(SP, 3 * kWordSize));
  sw(FP, Address(SP, 2 * kWordSize));
  sw(CODE_REG, Address(SP, 1 * kWordSize));
  sw(PP, Address(SP, 0 * kWordSize));

  // Set FP to the saved previous FP.
  addiu(FP, SP, Immediate(2 * kWordSize));

  LoadPoolPointer();

  // Reserve space for locals.
  AddImmediate(SP, -frame_size);
}


// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate. We must also set up the pool pointer for the function.
void Assembler::EnterOsrFrame(intptr_t extra_size) {
  ASSERT(!in_delay_slot_);
  Comment("EnterOsrFrame");

  // Restore return address.
  lw(RA, Address(FP, 1 * kWordSize));

  // Load the pool pointer. offset has already been subtracted from temp.
  RestoreCodePointer();
  LoadPoolPointer();

  // Reserve space for locals.
  AddImmediate(SP, -extra_size);
}


void Assembler::LeaveDartFrame(RestorePP restore_pp) {
  ASSERT(!in_delay_slot_);
  addiu(SP, FP, Immediate(-2 * kWordSize));

  lw(RA, Address(SP, 3 * kWordSize));
  lw(FP, Address(SP, 2 * kWordSize));
  if (restore_pp == kRestoreCallerPP) {
    lw(PP, Address(SP, 0 * kWordSize));
  }

  // Adjust SP for PC, RA, FP, PP pushed in EnterDartFrame.
  addiu(SP, SP, Immediate(4 * kWordSize));
}


void Assembler::LeaveDartFrameAndReturn(Register ra) {
  ASSERT(!in_delay_slot_);
  addiu(SP, FP, Immediate(-2 * kWordSize));

  lw(RA, Address(SP, 3 * kWordSize));
  lw(FP, Address(SP, 2 * kWordSize));
  lw(PP, Address(SP, 0 * kWordSize));

  // Adjust SP for PC, RA, FP, PP pushed in EnterDartFrame, and return.
  jr(ra);
  delay_slot()->addiu(SP, SP, Immediate(4 * kWordSize));
}


void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  ASSERT(!in_delay_slot_);
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  AddImmediate(SP, -frame_space);
  if (OS::ActivationFrameAlignment() > 1) {
    LoadImmediate(TMP, ~(OS::ActivationFrameAlignment() - 1));
    and_(SP, SP, TMP);
  }
}


void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  ASSERT(!in_delay_slot_);
  const intptr_t kPushedRegistersSize = kDartVolatileCpuRegCount * kWordSize +
                                        3 * kWordSize +  // PP, FP and RA.
                                        kDartVolatileFpuRegCount * kWordSize;

  SetPrologueOffset();

  Comment("EnterCallRuntimeFrame");

  // Save volatile CPU and FPU registers on the stack:
  // -------------
  // FPU Registers
  // CPU Registers
  // RA
  // FP
  // -------------
  // TODO(zra): It may be a problem for walking the stack that FP is below
  //            the saved registers. If it turns out to be a problem in the
  //            future, try pushing RA and FP before the volatile registers.
  addiu(SP, SP, Immediate(-kPushedRegistersSize));
  for (int i = kDartFirstVolatileFpuReg; i <= kDartLastVolatileFpuReg; i++) {
    // These go above the volatile CPU registers.
    const int slot =
        (i - kDartFirstVolatileFpuReg) + kDartVolatileCpuRegCount + 3;
    FRegister reg = static_cast<FRegister>(i);
    swc1(reg, Address(SP, slot * kWordSize));
  }
  for (int i = kDartFirstVolatileCpuReg; i <= kDartLastVolatileCpuReg; i++) {
    // + 2 because FP goes in slot 0.
    const int slot = (i - kDartFirstVolatileCpuReg) + 3;
    Register reg = static_cast<Register>(i);
    sw(reg, Address(SP, slot * kWordSize));
  }
  sw(RA, Address(SP, 2 * kWordSize));
  sw(FP, Address(SP, 1 * kWordSize));
  sw(PP, Address(SP, 0 * kWordSize));
  LoadPoolPointer();

  mov(FP, SP);

  ReserveAlignedFrameSpace(frame_space);
}


void Assembler::LeaveCallRuntimeFrame() {
  ASSERT(!in_delay_slot_);
  const intptr_t kPushedRegistersSize = kDartVolatileCpuRegCount * kWordSize +
                                        3 * kWordSize +  // FP and RA.
                                        kDartVolatileFpuRegCount * kWordSize;

  Comment("LeaveCallRuntimeFrame");

  // SP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  mov(SP, FP);

  // Restore volatile CPU and FPU registers from the stack.
  lw(PP, Address(SP, 0 * kWordSize));
  lw(FP, Address(SP, 1 * kWordSize));
  lw(RA, Address(SP, 2 * kWordSize));
  for (int i = kDartFirstVolatileCpuReg; i <= kDartLastVolatileCpuReg; i++) {
    // + 2 because FP goes in slot 0.
    const int slot = (i - kDartFirstVolatileCpuReg) + 3;
    Register reg = static_cast<Register>(i);
    lw(reg, Address(SP, slot * kWordSize));
  }
  for (int i = kDartFirstVolatileFpuReg; i <= kDartLastVolatileFpuReg; i++) {
    // These go above the volatile CPU registers.
    const int slot =
        (i - kDartFirstVolatileFpuReg) + kDartVolatileCpuRegCount + 3;
    FRegister reg = static_cast<FRegister>(i);
    lwc1(reg, Address(SP, slot * kWordSize));
  }
  addiu(SP, SP, Immediate(kPushedRegistersSize));
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
  ASSERT(Address::CanHoldOffset(offset));
  return Address(array, static_cast<int32_t>(offset));
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
  if (shift < 0) {
    ASSERT(shift == -1);
    sra(TMP, index, 1);
    addu(base, array, TMP);
  } else if (shift == 0) {
    addu(base, array, index);
  } else {
    sll(TMP, index, shift);
    addu(base, array, TMP);
  }
  ASSERT(Address::CanHoldOffset(offset));
  return Address(base, offset);
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
  if (shift < 0) {
    ASSERT(shift == -1);
    sra(address, index, 1);
    addu(address, array, address);
  } else if (shift == 0) {
    addu(address, array, index);
  } else {
    sll(address, index, shift);
    addu(address, array, address);
  }
  if (offset != 0) {
    AddImmediate(address, offset);
  }
}


void Assembler::LoadHalfWordUnaligned(Register dst,
                                      Register addr,
                                      Register tmp) {
  ASSERT(dst != addr);
  lbu(dst, Address(addr, 0));
  lb(tmp, Address(addr, 1));
  sll(tmp, tmp, 8);
  or_(dst, dst, tmp);
}


void Assembler::LoadHalfWordUnsignedUnaligned(Register dst,
                                              Register addr,
                                              Register tmp) {
  ASSERT(dst != addr);
  lbu(dst, Address(addr, 0));
  lbu(tmp, Address(addr, 1));
  sll(tmp, tmp, 8);
  or_(dst, dst, tmp);
}


void Assembler::StoreHalfWordUnaligned(Register src,
                                       Register addr,
                                       Register tmp) {
  sb(src, Address(addr, 0));
  srl(tmp, src, 8);
  sb(tmp, Address(addr, 1));
}


void Assembler::LoadWordUnaligned(Register dst, Register addr, Register tmp) {
  // TODO(rmacnak): LWL + LWR
  ASSERT(dst != addr);
  lbu(dst, Address(addr, 0));
  lbu(tmp, Address(addr, 1));
  sll(tmp, tmp, 8);
  or_(dst, dst, tmp);
  lbu(tmp, Address(addr, 2));
  sll(tmp, tmp, 16);
  or_(dst, dst, tmp);
  lbu(tmp, Address(addr, 3));
  sll(tmp, tmp, 24);
  or_(dst, dst, tmp);
}


void Assembler::StoreWordUnaligned(Register src, Register addr, Register tmp) {
  // TODO(rmacnak): SWL + SWR
  sb(src, Address(addr, 0));
  srl(tmp, src, 8);
  sb(tmp, Address(addr, 1));
  srl(tmp, src, 16);
  sb(tmp, Address(addr, 2));
  srl(tmp, src, 24);
  sb(tmp, Address(addr, 3));
}


static const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "zr", "tmp", "v0", "v1", "a0", "a1", "a2", "a3", "t0", "t1", "t2",
    "t3", "t4",  "t5", "t6", "t7", "s0", "s1", "s2", "s3", "s4", "s5",
    "s6", "s7",  "t8", "t9", "k0", "k1", "gp", "sp", "fp", "ra",
};


const char* Assembler::RegisterName(Register reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
  return cpu_reg_names[reg];
}


static const char* fpu_reg_names[kNumberOfFpuRegisters] = {
    "d0", "d1", "d2",  "d3",  "d4",  "d5",  "d6",  "d7",
    "d8", "d9", "d10", "d11", "d12", "d13", "d14", "d15",
};


const char* Assembler::FpuRegisterName(FpuRegister reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfFpuRegisters));
  return fpu_reg_names[reg];
}


void Assembler::Stop(const char* message) {
  if (FLAG_print_stop_message) {
    UNIMPLEMENTED();
  }
  Label stop;
  b(&stop);
  Emit(reinterpret_cast<int32_t>(message));
  Bind(&stop);
  break_(Instr::kStopMessageCode);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
