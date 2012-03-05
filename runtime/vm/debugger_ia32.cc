// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/debugger.h"

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/disassembler.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
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


void CodeBreakpoint::PatchFunctionReturn() {
  uint8_t* code = reinterpret_cast<uint8_t*>(pc_ - 5);
  ASSERT((code[0] == 0x89) && (code[1] == 0xEC));  // mov esp,ebp
  ASSERT(code[2] == 0x5D);  // pop ebp
  ASSERT(code[3] == 0xC3);  // ret
  ASSERT(code[4] == 0x90);  // nop

  // Smash code with call instruction and relative target address.
  uword stub_addr = StubCode::BreakpointReturnEntryPoint();
  code[0] = 0xE8;
  *reinterpret_cast<uword*>(&code[1]) = stub_addr - pc_;
  CPU::FlushICache(pc_, 5);
}


void CodeBreakpoint::RestoreFunctionReturn() {
  uint8_t* code = reinterpret_cast<uint8_t*>(pc_ - 5);
  ASSERT(code[0] == 0xE8);
  code[0] = 0x89;
  code[1] = 0xEC;  // mov esp,ebp
  code[2] = 0x5D;  // pop ebp
  code[3] = 0xC3;  // ret
  code[4] = 0x90;  // nop
  CPU::FlushICache(pc_, 5);
}



}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
