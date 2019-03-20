// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(TARGET_ARCH_X64)

#include "vm/constants_x64.h"

namespace dart {

#if defined(_WIN64)
const Register CallingConventions::ArgumentRegisters[] = {
    CallingConventions::kArg1Reg, CallingConventions::kArg2Reg,
    CallingConventions::kArg3Reg, CallingConventions::kArg4Reg};

const XmmRegister CallingConventions::XmmArgumentRegisters[] = {
    XmmRegister::XMM0, XmmRegister::XMM1, XmmRegister::XMM2, XmmRegister::XMM3};
#else
const Register CallingConventions::ArgumentRegisters[] = {
    CallingConventions::kArg1Reg, CallingConventions::kArg2Reg,
    CallingConventions::kArg3Reg, CallingConventions::kArg4Reg,
    CallingConventions::kArg5Reg, CallingConventions::kArg6Reg};

const XmmRegister CallingConventions::XmmArgumentRegisters[] = {
    XmmRegister::XMM0, XmmRegister::XMM1, XmmRegister::XMM2, XmmRegister::XMM3,
    XmmRegister::XMM4, XmmRegister::XMM5, XmmRegister::XMM6, XmmRegister::XMM7};
#endif

}  // namespace dart

#endif
