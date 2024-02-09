// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_TEST_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_TEST_H_

#include "vm/compiler/runtime_api.h"
#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler_base.h"

namespace dart {

namespace compiler {

void EnterTestFrame(Assembler* assembler);

void LeaveTestFrame(Assembler* assembler);

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_TEST_H_
