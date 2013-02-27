// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/assembler_macros.h"

#include "vm/assembler.h"

namespace dart {

#define __ assembler->


void AssemblerMacros::TryAllocate(Assembler* assembler,
                                  const Class& cls,
                                  Label* failure,
                                  bool near_jump,
                                  Register instance_reg) {
  UNIMPLEMENTED();
}


void AssemblerMacros::EnterDartFrame(Assembler* assembler,
                                     intptr_t frame_size) {
  const intptr_t offset = assembler->CodeSize();
  // Save PC in frame for fast identification of corresponding code.
  // Note that callee-saved registers can be added to the register list.
  __ EnterFrame((1 << PP) | (1 << FP) | (1 << LR) | (1 << PC), 0);

  if (offset != 0) {
    // Adjust saved PC for any intrinsic code that could have been generated
    // before a frame is created. Use PP as temp register.
    __ ldr(PP, Address(FP, 2 * kWordSize));
    __ AddImmediate(PP, PP, -offset);
    __ str(PP, Address(FP, 2 * kWordSize));
  }

  // Setup pool pointer for this dart function.
  const intptr_t object_pool_pc_dist =
      Instr::kPCReadOffset - assembler->CodeSize() -
      Instructions::HeaderSize() + Instructions::object_pool_offset();
  __ ldr(PP, Address(PC, object_pool_pc_dist));

  // Reserve space for locals.
  __ AddImmediate(SP, -frame_size);
}


void AssemblerMacros::LeaveDartFrame(Assembler* assembler) {
  __ LeaveFrame((1 << PP) | (1 << FP) | (1 << LR));
  // Adjust SP for PC pushed in EnterDartFrame.
  __ AddImmediate(SP, kWordSize);
}


void AssemblerMacros::EnterStubFrame(Assembler* assembler) {
  // Push 0 as saved PC for stub frames.
  __ mov(IP, ShifterOperand(LR));
  __ mov(LR, ShifterOperand(0));
  __ EnterFrame((1 << FP) | (1 << IP) | (1 << LR), 0);
}


void AssemblerMacros::LeaveStubFrame(Assembler* assembler) {
  __ LeaveFrame((1 << FP) | (1 << LR));
  // Adjust SP for null PC pushed in EnterStubFrame.
  __ AddImmediate(SP, kWordSize);
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM

