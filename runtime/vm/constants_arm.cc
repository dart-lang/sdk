// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#define RUNTIME_VM_CONSTANTS_H_  // To work around include guard.
#include "vm/constants_arm.h"

namespace arch_arm {

const Register CallingConventions::ArgumentRegisters[] = {R0, R1, R2, R3};

// Although 'kFpuArgumentRegisters' is 0, we have to give this array at least
// one element to appease MSVC.
const FpuRegister CallingConventions::FpuArgumentRegisters[] = {Q0};

}  // namespace arch_arm
