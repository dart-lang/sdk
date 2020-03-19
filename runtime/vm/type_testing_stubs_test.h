// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TYPE_TESTING_STUBS_TEST_H_
#define RUNTIME_VM_TYPE_TESTING_STUBS_TEST_H_

#if defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_ARM) ||                  \
    defined(TARGET_ARCH_X64)

#include "include/dart_api.h"

namespace dart {

namespace compiler {
class Assembler;
}

void GenerateInvokeTTSStub(compiler::Assembler* assembler);

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM64) ||  defined(TARGET_ARCH_ARM) ||          \
        // defined(TARGET_ARCH_X64)

#endif  // RUNTIME_VM_TYPE_TESTING_STUBS_TEST_H_
