// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#define RUNTIME_VM_CONSTANTS_H_  // To work around include guard.
#include "vm/constants_ia32.h"

namespace arch_ia32 {

// Although 'kArgumentRegisters' and 'kFpuArgumentRegisters' are both 0, we have
// to give these arrays at least one element to appease MSVC.

const Register CallingConventions::ArgumentRegisters[] = {
    static_cast<Register>(0)};
const FpuRegister CallingConventions::FpuArgumentRegisters[] = {
    static_cast<FpuRegister>(0)};

}  // namespace arch_ia32
