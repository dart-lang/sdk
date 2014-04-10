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

DEFINE_FLAG(bool, print_stop_message, true, "Print stop message.");
DECLARE_FLAG(bool, inline_alloc);


void Assembler::InitializeMemoryWithBreakpoints(uword data, intptr_t length) {
  ASSERT(Utils::IsAligned(data, 4));
  ASSERT(Utils::IsAligned(length, 4));
  const uword end = data + length;
  while (data < end) {
    *reinterpret_cast<int32_t*>(data) = Instr::kBreakPointInstruction;
    data += 4;
  }
}


void Assembler::Stop(const char* message) {
  UNIMPLEMENTED();
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

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
