// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/assembler.h"
#include "vm/runtime_entry.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, print_stop_message, false, "Print stop message.");


void Assembler::InitializeMemoryWithBreakpoints(uword data, int length) {
  ASSERT(Utils::IsAligned(data, 4));
  ASSERT(Utils::IsAligned(length, 4));
  const uword end = data + length;
  while (data < end) {
    *reinterpret_cast<int32_t*>(data) = Instr::kBreakPointInstruction;
    data += 4;
  }
}


void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  int bound_pc = buffer_.Size();
  while (label->IsLinked()) {
    const int32_t position = label->Position();
    const int32_t next = buffer_.Load<int32_t>(position);
    // Relative destination from an instruction after the branch.
    const int32_t dest = bound_pc - (position + Instr::kInstrSize);
    const int32_t encoded = Assembler::EncodeBranchOffset(dest, next);
    buffer_.Store<int32_t>(position, encoded);
    label->position_ = Assembler::DecodeBranchOffset(next);
  }
  label->BindTo(bound_pc);
  delay_slot_available_ = false;
}


int32_t Assembler::EncodeBranchOffset(int32_t offset, int32_t instr) {
  ASSERT(Utils::IsAligned(offset, 4));
  ASSERT(Utils::IsInt(18, offset));

  // Properly preserve only the bits supported in the instruction.
  offset >>= 2;
  offset &= kBranchOffsetMask;
  return (instr & ~kBranchOffsetMask) | offset;
}


int Assembler::DecodeBranchOffset(int32_t instr) {
  // Sign-extend, left-shift by 2.
  return (((instr & kBranchOffsetMask) << 16) >> 14);
}


void Assembler::LoadWordFromPoolOffset(Register rd, int32_t offset) {
  ASSERT(rd != PP);
  if (Address::CanHoldOffset(offset)) {
    lw(rd, Address(PP, offset));
  } else {
    const int16_t offset_low = Utils::Low16Bits(offset);  // Signed.
    offset -= offset_low;
    const uint16_t offset_high = Utils::High16Bits(offset);  // Unsigned.
    if (offset_high != 0) {
      lui(rd, Immediate(offset_high));
      addu(rd, rd, PP);
      lw(rd, Address(rd, offset_low));
    } else {
      lw(rd, Address(PP, offset_low));
    }
  }
}


void Assembler::AdduDetectOverflow(Register rd, Register rs, Register rt,
                                   Register ro) {
  ASSERT(rd != ro);
  ASSERT(rd != TMP1);
  ASSERT(ro != TMP1);
  ASSERT(ro != rs);
  ASSERT(ro != rt);

  if ((rs == rt) && (rd == rs)) {
    ASSERT(rd != TMP2);
    ASSERT(ro != TMP2);
    ASSERT(rs != TMP2);
    ASSERT(rt != TMP2);
    mov(TMP2, rt);
    rt = TMP2;
  }

  if (rd == rs) {
    mov(TMP1, rs);  // Preserve rs.
    addu(rd, rs, rt);  // rs is overwritten.
    xor_(TMP1, rd, TMP1);  // Original rs.
    xor_(ro, rd, rt);
    and_(ro, ro, TMP1);
  } else if (rd == rt) {
    mov(TMP1, rt);  // Preserve rt.
    addu(rd, rs, rt);  // rt is overwritten.
    xor_(TMP1, rd, TMP1);  // Original rt.
    xor_(ro, rd, rs);
    and_(ro, ro, TMP1);
  } else {
    addu(rd, rs, rt);
    xor_(ro, rd, rs);
    xor_(TMP1, rd, rt);
    and_(ro, TMP1, ro);
  }
}


void Assembler::SubuDetectOverflow(Register rd, Register rs, Register rt,
                                   Register ro) {
  ASSERT(rd != ro);
  ASSERT(rd != TMP1);
  ASSERT(ro != TMP1);
  ASSERT(ro != rs);
  ASSERT(ro != rt);
  ASSERT(rs != TMP1);
  ASSERT(rt != TMP1);

  // This happens with some crankshaft code. Since Subu works fine if
  // left == right, let's not make that restriction here.
  if (rs == rt) {
    mov(rd, ZR);
    mov(ro, ZR);
    return;
  }

  if (rd == rs) {
    mov(TMP1, rs);  // Preserve left.
    subu(rd, rs, rt);  // Left is overwritten.
    xor_(ro, rd, TMP1);  // scratch is original left.
    xor_(TMP1, TMP1, rs);  // scratch is original left.
    and_(ro, TMP1, ro);
  } else if (rd == rt) {
    mov(TMP1, rt);  // Preserve right.
    subu(rd, rs, rt);  // Right is overwritten.
    xor_(ro, rd, rs);
    xor_(TMP1, rs, TMP1);  // Original right.
    and_(ro, TMP1, ro);
  } else {
    subu(rd, rs, rt);
    xor_(ro, rd, rs);
    xor_(TMP1, rs, rt);
    and_(ro, TMP1, ro);
  }
}


void Assembler::LoadObject(Register rd, const Object& object) {
  // Smi's and VM heap objects are never relocated; do not use object pool.
  if (object.IsSmi()) {
    LoadImmediate(rd, reinterpret_cast<int32_t>(object.raw()));
  } else if (object.InVMHeap()) {
    // Make sure that class CallPattern is able to decode this load immediate.
    int32_t object_raw = reinterpret_cast<int32_t>(object.raw());
    const uint16_t object_low = Utils::Low16Bits(object_raw);
    const uint16_t object_high = Utils::High16Bits(object_raw);
    lui(rd, Immediate(object_high));
    ori(rd, rd, Immediate(object_low));
  } else {
    // Make sure that class CallPattern is able to decode this load from the
    // object pool.
    const int32_t offset =
        Array::data_offset() + 4*AddObject(object) - kHeapObjectTag;
    LoadWordFromPoolOffset(rd, offset);
  }
}


int32_t Assembler::AddObject(const Object& obj) {
  ASSERT(obj.IsNotTemporaryScopedHandle());
  ASSERT(obj.IsOld());
  if (object_pool_.IsNull()) {
    // The object pool cannot be used in the vm isolate.
    ASSERT(Isolate::Current() != Dart::vm_isolate());
    object_pool_ = GrowableObjectArray::New(Heap::kOld);
  }
  for (int i = 0; i < object_pool_.Length(); i++) {
    if (object_pool_.At(i) == obj.raw()) {
      return i;
    }
  }
  object_pool_.Add(obj, Heap::kOld);
  return object_pool_.Length() - 1;
}


void Assembler::PushObject(const Object& object) {
  LoadObject(TMP1, object);
  Push(TMP1);
}


void Assembler::CompareObject(Register rd, Register rn, const Object& object) {
  ASSERT(rn != TMP1);
  LoadObject(TMP1, object);
  subu(rd, rn, TMP1);
}


void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(RawObject::kClassIdTagBit == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset = Object::tags_offset() +
      RawObject::kClassIdTagBit / kBitsPerByte;
  lhu(result, FieldAddress(object, class_id_offset));
}


void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);
  lw(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  lw(result, Address(result, table_offset_in_isolate));
  sll(TMP1, class_id, 2);
  addu(result, result, TMP1);
  lw(result, Address(result));
}


void Assembler::LoadClass(Register result, Register object) {
  ASSERT(TMP1 != result);
  LoadClassId(TMP1, object);

  lw(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  lw(result, Address(result, table_offset_in_isolate));
  sll(TMP1, TMP1, 2);
  addu(result, result, TMP1);
  lw(result, Address(result));
}


void Assembler::EnterStubFrame(bool uses_pp) {
  if (uses_pp) {
    addiu(SP, SP, Immediate(-4 * kWordSize));
    sw(ZR, Address(SP, 3 * kWordSize));  // PC marker is 0 in stubs.
    sw(RA, Address(SP, 2 * kWordSize));
    sw(PP, Address(SP, 1 * kWordSize));
    sw(FP, Address(SP, 0 * kWordSize));
    mov(FP, SP);
    // Setup pool pointer for this stub.
    Label next;
    bal(&next);
    delay_slot()->mov(T0, RA);

    const intptr_t object_pool_pc_dist =
        Instructions::HeaderSize() - Instructions::object_pool_offset() +
        CodeSize();

    Bind(&next);
    lw(PP, Address(T0, -object_pool_pc_dist));
  } else {
    addiu(SP, SP, Immediate(-3 * kWordSize));
    sw(ZR, Address(SP, 2 * kWordSize));  // PC marker is 0 in stubs.
    sw(RA, Address(SP, 1 * kWordSize));
    sw(FP, Address(SP, 0 * kWordSize));
    mov(FP, SP);
  }
}


void Assembler::LeaveStubFrame(bool uses_pp) {
  mov(SP, FP);
  if (uses_pp) {
    lw(RA, Address(SP, 2 * kWordSize));
    lw(PP, Address(SP, 1 * kWordSize));
    lw(FP, Address(SP, 0 * kWordSize));
    addiu(SP, SP, Immediate(4 * kWordSize));
  } else {
    lw(RA, Address(SP, 1 * kWordSize));
    lw(FP, Address(SP, 0 * kWordSize));
    addiu(SP, SP, Immediate(3 * kWordSize));
  }
}


void Assembler::CallRuntime(const RuntimeEntry& entry) {
  entry.Call(this);
}


void Assembler::EnterDartFrame(intptr_t frame_size) {
  const intptr_t offset = CodeSize();

  addiu(SP, SP, Immediate(-4 * kWordSize));
  sw(RA, Address(SP, 2 * kWordSize));
  sw(FP, Address(SP, 1 * kWordSize));
  sw(PP, Address(SP, 0 * kWordSize));

  Label next;
  // Branch and link to the instruction after the delay slot to get the PC.
  bal(&next);

  // RA is the address of the sw instruction below. Save it in T0.
  delay_slot()->mov(T0, RA);

  // Calculate the offset of the pool pointer from the PC.
  const intptr_t object_pool_pc_dist =
      Instructions::HeaderSize() - Instructions::object_pool_offset() +
      CodeSize();

  // This sw instruction is the return address for the bal, so T0 holds
  // the PC at this sw instruction.
  Bind(&next);

  // Save PC in frame for fast identification of corresponding code.
  if (offset == 0) {
    sw(T0, Address(SP, 3 * kWordSize));
  } else {
    // Adjust saved PC for any intrinsic code that could have been generated
    // before a frame is created.
    AddImmediate(T1, T0, -offset);
    sw(T1, Address(SP, 3 * kWordSize));
  }

  // Set FP to the saved previous FP.
  addiu(FP, SP, Immediate(kWordSize));

  // Load the pool pointer.
  lw(PP, Address(T0, -object_pool_pc_dist));

  // Reserve space for locals.
  AddImmediate(SP, -frame_size);
}


void Assembler::LeaveDartFrame() {
  addiu(SP, FP, Immediate(-kWordSize));

  lw(RA, Address(SP, 2 * kWordSize));
  lw(FP, Address(SP, 1 * kWordSize));
  lw(PP, Address(SP, 0 * kWordSize));

  // Adjust SP for PC pushed in EnterDartFrame.
  addiu(SP, SP, Immediate(4 * kWordSize));
}


void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  AddImmediate(SP, -frame_space);
  if (OS::ActivationFrameAlignment() > 0) {
    LoadImmediate(TMP1, ~(OS::ActivationFrameAlignment() - 1));
    and_(SP, SP, TMP1);
  }
}


int32_t Assembler::AddExternalLabel(const ExternalLabel* label) {
  if (object_pool_.IsNull()) {
    // The object pool cannot be used in the vm isolate.
    ASSERT(Isolate::Current() != Dart::vm_isolate());
    object_pool_ = GrowableObjectArray::New(Heap::kOld);
  }
  const word address = label->address();
  ASSERT(Utils::IsAligned(address, 4));
  // The address is stored in the object array as a RawSmi.
  const Smi& smi = Smi::Handle(Smi::New(address >> kSmiTagShift));
  // Do not reuse an existing entry, since each reference may be patched
  // independently.
  object_pool_.Add(smi, Heap::kOld);
  return object_pool_.Length() - 1;
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

