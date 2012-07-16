// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/debugger.h"

#include "vm/cpu.h"
#include "vm/stub_code.h"

namespace dart {

// TODO(hausner): Implement this. For now just return null instead
// of hitting UNIMPLEMENTED.
RawInstance* ActivationFrame::GetLocalVarValue(intptr_t slot_index) {
  return Instance::null();
}


RawInstance* ActivationFrame::GetInstanceCallReceiver(
                 intptr_t num_actual_args) {
  ASSERT(num_actual_args > 0);  // At minimum we have a receiver on the stack.
  // Stack pointer points to last argument that was pushed on the stack.
  uword receiver_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawInstance*>(
             *reinterpret_cast<uword*>(receiver_addr));
}


void CodeBreakpoint::PatchFunctionReturn() {
  uint8_t* code = reinterpret_cast<uint8_t*>(pc_ - 13);
  // movq %rbp,%rsp
  ASSERT((code[0] == 0x48) && (code[1] == 0x89) && (code[2] == 0xec));
  ASSERT(code[3] == 0x5d);  // popq %rbp
  ASSERT(code[4] == 0xc3);  // ret
  // Next 8 bytes are nop instructions
  ASSERT((code[5] == 0x90) && (code[6] == 0x90) &&
         (code[7] == 0x90) && (code[8] == 0x90) &&
         (code[9] == 0x90) && (code[10] == 0x90) &&
         (code[11] == 0x90) && (code[12] == 0x90));
         // Smash code with call instruction and relative target address.
  uword stub_addr = StubCode::BreakpointReturnEntryPoint();
  code[0] = 0x49;
  code[1] = 0xbb;
  *reinterpret_cast<uword*>(&code[2]) = stub_addr;
  code[10] = 0x41;
  code[11] = 0xff;
  code[12] = 0xd3;
  CPU::FlushICache(pc_, 5);
}


void CodeBreakpoint::RestoreFunctionReturn() {
  uint8_t* code = reinterpret_cast<uint8_t*>(pc_ - 13);
  ASSERT((code[0] == 0x49) && (code[1] == 0xbb));
  code[0] = 0x48;  // movq %rbp,%rsp
  code[1] = 0x89;
  code[2] = 0xec;
  code[3] = 0x5d;  // popq %rbp
  code[4] = 0xc3;  // ret
  code[5] = 0x90;  // nop
  code[6] = 0x90;  // nop
  code[7] = 0x90;  // nop
  code[8] = 0x90;  // nop
  code[9] = 0x90;  // nop
  code[10] = 0x90;  // nop
  code[11] = 0x90;  // nop
  code[12] = 0x90;  // nop
  CPU::FlushICache(pc_, 5);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
