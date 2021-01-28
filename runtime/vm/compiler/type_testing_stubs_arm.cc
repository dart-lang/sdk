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
    compiler::UnresolvedPcRelativeCalls* unresolved_calls,
    const Code& slow_type_test_stub,
    HierarchyInfo* hi,
    const Type& type,
    const Class& type_class) {
  BuildOptimizedTypeTestStubFastCases(assembler, hi, type, type_class);
  if (!compiler::IsSameObject(
          compiler::NullObject(),
          compiler::CastHandle<Object>(slow_type_test_stub))) {
    __ GenerateUnRelocatedPcRelativeTailCall();
    unresolved_calls->Add(new compiler::UnresolvedPcRelativeCall(
        __ CodeSize(), slow_type_test_stub, /*is_tail_call=*/true));
  } else {
    __ Branch(compiler::Address(
        THR, compiler::target::Thread::slow_type_test_entry_point_offset()));
  }
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM) && !defined(DART_PRECOMPILED_RUNTIME)
