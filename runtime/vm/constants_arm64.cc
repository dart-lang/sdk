// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(TARGET_ARCH_ARM64)

#include "vm/constants_arm64.h"

namespace dart {

const Register CallingConventions::ArgumentRegisters[] = {
    R0, R1, R2, R3, R4, R5, R6, R7,
};

const FpuRegister CallingConventions::FpuArgumentRegisters[] = {
    V0, V1, V2, V3, V4, V5, V6, V7,
};

}  // namespace dart

#endif
