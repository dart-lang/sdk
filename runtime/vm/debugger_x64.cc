// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/debugger.h"

#include "vm/assembler.h"
#include "vm/cpu.h"
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
  uint8_t* code = reinterpret_cast<uint8_t*>(pc_ - 13);
  ASSERT((code[0] == 0x4c) && (code[1] == 0x8b) && (code[2] == 0x7d) &&
         (code[3] == 0xf0));  // movq r15,[rbp-0x10]
  ASSERT((code[4] == 0x48) && (code[5] == 0x89) &&
         (code[6] == 0xec));  // mov rsp, rbp
  ASSERT(code[7] == 0x5d);  // pop rbp
  ASSERT(code[8] == 0xc3);  // ret
  ASSERT((code[9] == 0x0F) && (code[10] == 0x1F) && (code[11] == 0x40) &&
         (code[12] == 0x00));  // nops
  // Smash code with call instruction and relative target address.
  uword stub_addr = StubCode::BreakpointReturnEntryPoint();
  code[0] = 0x49;
  code[1] = 0xbb;
  *reinterpret_cast<uword*>(&code[2]) = stub_addr;
  code[10] = 0x41;
  code[11] = 0xff;
  code[12] = 0xd3;
  CPU::FlushICache(pc_ - 13, 13);
}


void CodeBreakpoint::RestoreFunctionReturn() {
  uint8_t* code = reinterpret_cast<uint8_t*>(pc_ - 13);
  ASSERT((code[0] == 0x49) && (code[1] == 0xbb));

  MemoryRegion code_region(reinterpret_cast<void*>(pc_ - 13), 13);
  Assembler assembler;

  assembler.ReturnPatchable();
  assembler.FinalizeInstructions(code_region);

  CPU::FlushICache(pc_ - 13, 13);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
