// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_ARM) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/type_testing_stubs.h"

#define __ assembler->

namespace dart {

void TypeTestingStubGenerator::BuildOptimizedTypeTestStub(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const Type& type,
    const Class& type_class) {
  BuildOptimizedTypeTestStubFastCases(assembler, hi, type, type_class);

  __ ldr(CODE_REG,
         compiler::Address(
             THR, compiler::target::Thread::slow_type_test_stub_offset()));
  __ Branch(compiler::FieldAddress(
      CODE_REG, compiler::target::Code::entry_point_offset()));
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM) && !defined(DART_PRECOMPILED_RUNTIME)
