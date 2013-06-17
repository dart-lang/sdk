// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

// TODO(hausner): Handle captured variables.
RawInstance* ActivationFrame::GetLocalVarValue(intptr_t slot_index) {
  uword var_address = fp() + slot_index * kWordSize;
  return reinterpret_cast<RawInstance*>(
             *reinterpret_cast<uword*>(var_address));
}


RawInstance* ActivationFrame::GetInstanceCallReceiver(
                 intptr_t num_actual_args) {
  ASSERT(num_actual_args > 0);  // At minimum we have a receiver on the stack.
  // Stack pointer points to last argument that was pushed on the stack.
  uword receiver_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawInstance*>(
             *reinterpret_cast<uword*>(receiver_addr));
}


RawObject* ActivationFrame::GetClosureObject(intptr_t num_actual_args) {
  // At a minimum we have the closure object on the stack.
  ASSERT(num_actual_args > 0);
  // Stack pointer points to last argument that was pushed on the stack.
  uword closure_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawObject*>(
             *reinterpret_cast<uword*>(closure_addr));
}


void CodeBreakpoint::PatchFunctionReturn() {
  Instr* instr1 = Instr::At(pc_ - 5 * Instr::kInstrSize);
  Instr* instr2 = Instr::At(pc_ - 4 * Instr::kInstrSize);
  Instr* instr3 = Instr::At(pc_ - 3 * Instr::kInstrSize);
  Instr* instr4 = Instr::At(pc_ - 2 * Instr::kInstrSize);
  Instr* instr5 = Instr::At(pc_ - 1 * Instr::kInstrSize);

#if defined(DEBUG)
  instr1->AssertIsImmInstr(LW, SP, RA, 2 * kWordSize);
  instr2->AssertIsImmInstr(LW, SP, FP, 1 * kWordSize);
  instr3->AssertIsImmInstr(LW, SP, PP, 0 * kWordSize);
  instr4->AssertIsSpecialInstr(JR, RA, ZR, ZR);
  instr5->AssertIsImmInstr(ADDIU, SP, SP, 4 * kWordSize);
#endif  // defined(DEBUG)

  // Smash code with call instruction and target address.
  uword stub_addr = StubCode::BreakpointReturnEntryPoint();
  uint16_t target_lo = stub_addr & 0xffff;
  uint16_t target_hi = stub_addr >> 16;

  // Unlike other architectures, the sequence we are patching in is shorter
  // than the sequence we are replacing. We pad at the top with nops so that
  // the end of the new sequence is lined up with the code descriptor.
  instr1->SetInstructionBits(Instr::kNopInstruction);
  instr2->SetImmInstrBits(LUI, ZR, TMP1, target_hi);
  instr3->SetImmInstrBits(ORI, TMP1, TMP1, target_lo);
  instr4->SetSpecialInstrBits(JALR, TMP1, ZR, RA);
  instr5->SetInstructionBits(Instr::kNopInstruction);

  CPU::FlushICache(pc_ - 5 * Instr::kInstrSize, 5 * Instr::kInstrSize);
}


void CodeBreakpoint::RestoreFunctionReturn() {
  Instr* instr1 = Instr::At(pc_ - 5 * Instr::kInstrSize);
  Instr* instr2 = Instr::At(pc_ - 4 * Instr::kInstrSize);
  Instr* instr3 = Instr::At(pc_ - 3 * Instr::kInstrSize);
  Instr* instr4 = Instr::At(pc_ - 2 * Instr::kInstrSize);
  Instr* instr5 = Instr::At(pc_ - 1 * Instr::kInstrSize);

  ASSERT(instr2->OpcodeField() == LUI && instr2->RtField() == TMP1);

  instr1->SetImmInstrBits(LW, SP, RA, 2 * kWordSize);
  instr2->SetImmInstrBits(LW, SP, FP, 1 * kWordSize);
  instr3->SetImmInstrBits(LW, SP, PP, 0 * kWordSize);
  instr4->SetSpecialInstrBits(JR, RA, ZR, ZR);
  instr5->SetImmInstrBits(ADDIU, SP, SP, 4 * kWordSize);

  CPU::FlushICache(pc_ - 5 * Instr::kInstrSize, 5 * Instr::kInstrSize);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
