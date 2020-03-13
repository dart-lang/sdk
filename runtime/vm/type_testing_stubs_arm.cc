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
  const Register kInstanceReg = R0;
  const Register kClassIdReg = R9;

  BuildOptimizedTypeTestStubFastCases(assembler, hi, type, type_class,
                                      kInstanceReg, kClassIdReg);

  __ ldr(CODE_REG,
         compiler::Address(
             THR, compiler::target::Thread::slow_type_test_stub_offset()));
  __ Branch(compiler::FieldAddress(
      CODE_REG, compiler::target::Code::entry_point_offset()));
}

void TypeTestingStubGenerator::
    BuildOptimizedSubclassRangeCheckWithTypeArguments(
        compiler::Assembler* assembler,
        HierarchyInfo* hi,
        const Type& type,
        const Class& type_class,
        const TypeArguments& tp,
        const TypeArguments& ta) {
  const Register kInstanceReg = R0;
  const Register kInstanceTypeArguments = R4;
  const Register kClassIdReg = R9;

  BuildOptimizedSubclassRangeCheckWithTypeArguments(
      assembler, hi, type, type_class, tp, ta, kClassIdReg, kInstanceReg,
      kInstanceTypeArguments);
}

void TypeTestingStubGenerator::BuildOptimizedTypeArgumentValueCheck(
    compiler::Assembler* assembler,
    HierarchyInfo* hi,
    const AbstractType& type_arg,
    intptr_t type_param_value_offset_i,
    compiler::Label* check_failed) {
  const Register kInstanceTypeArguments = R4;
  const Register kClassIdReg = R9;
  const Register kOwnTypeArgumentValue = TMP;

  BuildOptimizedTypeArgumentValueCheck(
      assembler, hi, type_arg, type_param_value_offset_i, kClassIdReg,
      kInstanceTypeArguments, kInstantiatorTypeArgumentsReg,
      kFunctionTypeArgumentsReg, kOwnTypeArgumentValue, check_failed);
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_ARM) && !defined(DART_PRECOMPILED_RUNTIME)
