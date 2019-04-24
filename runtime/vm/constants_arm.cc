// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#define RUNTIME_VM_CONSTANTS_H_  // To work around include guard.
#include "vm/constants_arm.h"

namespace arch_arm {

const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "r0", "r1",  "r2", "r3", "r4", "r5", "r6", "r7",
    "r8", "ctx", "pp", "fp", "ip", "sp", "lr", "pc",
};

const char* fpu_reg_names[kNumberOfFpuRegisters] = {
    "q0", "q1", "q2",  "q3",  "q4",  "q5",  "q6",  "q7",
#if defined(VFPv3_D32)
    "q8", "q9", "q10", "q11", "q12", "q13", "q14", "q15",
#endif
};

const Register CallingConventions::ArgumentRegisters[] = {R0, R1, R2, R3};

// Although 'kFpuArgumentRegisters' is 0, we have to give this array at least
// one element to appease MSVC.
const FpuRegister CallingConventions::FpuArgumentRegisters[] = {Q0};

}  // namespace arch_arm
