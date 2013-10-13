// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

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
  uword* code = reinterpret_cast<uword*>(pc_ - 3 * Instr::kInstrSize);
  ASSERT(code[0] == 0xe8bd4c00);  // ldmia sp!, {pp, fp, lr}
  ASSERT(code[1] == 0xe28dd004);  // add sp, sp, #4
  ASSERT(code[2] == 0xe12fff1e);  // bx lr

  // Smash code with call instruction and target address.
  uword stub_addr = StubCode::BreakpointReturnEntryPoint();
  uint16_t target_lo = stub_addr & 0xffff;
  uint16_t target_hi = stub_addr >> 16;
  uword movw = 0xe300c000 | ((target_lo >> 12) << 16) | (target_lo & 0xfff);
  uword movt = 0xe340c000 | ((target_hi >> 12) << 16) | (target_hi & 0xfff);
  uword blx =  0xe12fff3c;
  code[0] = movw;  // movw ip, #target_lo
  code[1] = movt;  // movt ip, #target_hi
  code[2] = blx;    // blx ip
  CPU::FlushICache(pc_ - 3 * Instr::kInstrSize, 3 * Instr::kInstrSize);
}


void CodeBreakpoint::RestoreFunctionReturn() {
  uword* code = reinterpret_cast<uword*>(pc_ - 3 * Instr::kInstrSize);
  ASSERT((code[0] & 0xfff0f000) == 0xe300c000);
  code[0] = 0xe8bd4c00;  // ldmia sp!, {pp, fp, lr}
  code[1] = 0xe28dd004;  // add sp, sp, #4
  code[2] = 0xe12fff1e;  // bx lr
  CPU::FlushICache(pc_ - 3 * Instr::kInstrSize, 3 * Instr::kInstrSize);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
