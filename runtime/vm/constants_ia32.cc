// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(TARGET_ARCH_IA32)

#include "vm/constants_ia32.h"

namespace dart {

// Although 'kArgumentRegisters' and 'kXmmArgumentRegisters' are both 0, we have
// to give these arrays at least one element to appease MSVC.

const Register CallingConventions::ArgumentRegisters[] = {
    static_cast<Register>(0)};
const XmmRegister CallingConventions::XmmArgumentRegisters[] = {
    static_cast<XmmRegister>(0)};

}  // namespace dart

#endif
