// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/constants.h"  // NOLINT

namespace dart {

#if !defined(FFI_UNIT_TESTS)
DEFINE_FLAG(bool,
            use_compressed_instructions,
            true,
            "Use instructions from the C extension");
#endif

const char* const cpu_reg_names[kNumberOfCpuRegisters] = {
    "zero", "ra", "sp",  "gp",   "tp",   "t0",  "t1", "t2", "fp", "thr", "a0",
    "a1",   "a2", "tmp", "tmp2", "pp",   "a6",  "a7", "s2", "s3", "s4",  "s5",
    "s6",   "s7", "s8",  "s9",   "null", "wbs", "t3", "t4", "t5", "t6",
};

const char* const cpu_reg_abi_names[kNumberOfCpuRegisters] = {
    "zero", "ra", "sp", "gp", "tp",  "t0",  "t1", "t2", "s0", "s1", "a0",
    "a1",   "a2", "a3", "a4", "a5",  "a6",  "a7", "s2", "s3", "s4", "s5",
    "s6",   "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
};

const char* const fpu_reg_names[kNumberOfFpuRegisters] = {
    "ft0", "ft1", "ft2",  "ft3",  "ft4", "ft5", "ft6",  "ft7",
    "fs0", "fs1", "fa0",  "fa1",  "fa2", "fa3", "fa4",  "fa5",
    "fa6", "fa7", "fs2",  "fs3",  "fs4", "fs5", "fs6",  "fs7",
    "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11",
};

const Register CallingConventions::ArgumentRegisters[] = {
    // A3/A4/A5 are assigned to TMP/TMP2/PP. This assignment is important for
    // reducing code size. To minimize distruption to the rest of the compiler,
    // we tell the register allocator and marshaller use T3/T4/T5 for FFI calls,
    // so they can make use of general moves that assume the availability of
    // TMP/TMP2/PP, and only move them to A3/A4/A5 at the last momement in
    // FfiCallInstr and CCallInstr (and NativeEntryInstr in the opposite
    // direction).
    A0, A1, A2, T3, T4, T5, A6, A7,
};

const FpuRegister CallingConventions::FpuArgumentRegisters[] = {
    FA0, FA1, FA2, FA3, FA4, FA5, FA6, FA7,
};

}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
