// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(TARGET_ARCH_X64)

#include "vm/constants.h"  // NOLINT

namespace dart {

const char* cpu_reg_names[kNumberOfCpuRegisters] = {
    "rax", "rcx", "rdx", "rbx", "rsp", "rbp", "rsi", "rdi",
    "r8",  "r9",  "r10", "r11", "r12", "r13", "thr", "pp"};

const char* fpu_reg_names[kNumberOfXmmRegisters] = {
    "xmm0", "xmm1", "xmm2",  "xmm3",  "xmm4",  "xmm5",  "xmm6",  "xmm7",
    "xmm8", "xmm9", "xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15"};

#if defined(TARGET_OS_WINDOWS)
const Register CallingConventions::ArgumentRegisters[] = {
    CallingConventions::kArg1Reg, CallingConventions::kArg2Reg,
    CallingConventions::kArg3Reg, CallingConventions::kArg4Reg};

const XmmRegister CallingConventions::FpuArgumentRegisters[] = {
    XmmRegister::XMM0, XmmRegister::XMM1, XmmRegister::XMM2, XmmRegister::XMM3};
#else
const Register CallingConventions::ArgumentRegisters[] = {
    CallingConventions::kArg1Reg, CallingConventions::kArg2Reg,
    CallingConventions::kArg3Reg, CallingConventions::kArg4Reg,
    CallingConventions::kArg5Reg, CallingConventions::kArg6Reg};

const XmmRegister CallingConventions::FpuArgumentRegisters[] = {
    XmmRegister::XMM0, XmmRegister::XMM1, XmmRegister::XMM2, XmmRegister::XMM3,
    XmmRegister::XMM4, XmmRegister::XMM5, XmmRegister::XMM6, XmmRegister::XMM7};
#endif

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
