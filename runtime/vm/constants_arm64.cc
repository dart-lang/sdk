// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(TARGET_ARCH_ARM64)

#include "vm/constants.h"  // NOLINT

namespace dart {

const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",  "r8",  "r9",  "r10",
    "r11", "r12", "r13", "r14", "r15", "r16", "r17", "r18", "r19", "r20", "r21",
    "nr",  "r23", "r24", "ip0", "ip1", "pp",  "ctx", "fp",  "lr",  "r31",
};

const char* fpu_reg_names[kNumberOfFpuRegisters] = {
    "v0",  "v1",  "v2",  "v3",  "v4",  "v5",  "v6",  "v7",  "v8",  "v9",  "v10",
    "v11", "v12", "v13", "v14", "v15", "v16", "v17", "v18", "v19", "v20", "v21",
    "v22", "v23", "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31",
};

const Register CallingConventions::ArgumentRegisters[] = {
    R0, R1, R2, R3, R4, R5, R6, R7,
};

const FpuRegister CallingConventions::FpuArgumentRegisters[] = {
    V0, V1, V2, V3, V4, V5, V6, V7,
};

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64)
