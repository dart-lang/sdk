// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checked_mode_compile_time_error_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckedModeCompileTimeErrorCodeTest_Kernel);
  });
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest_Kernel
    extends CheckedModeCompileTimeErrorCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @failingTest
  @override
  test_fieldFormalParameterAssignableToField_fieldType_unresolved_null() async {
    // Expected 1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super
        .test_fieldFormalParameterAssignableToField_fieldType_unresolved_null();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_fieldType_unresolved() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super
        .test_fieldFormalParameterNotAssignableToField_fieldType_unresolved();
  }

  @failingTest
  @override
  test_fieldInitializerNotAssignable() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t2 = "" in let ...
    await super.test_fieldInitializerNotAssignable();
  }

  @failingTest
  @override
  test_fieldTypeMismatch_unresolved() async {
    // UnimplementedError: kernel: (AsExpression) x as{TypeError} invalid-type
    await super.test_fieldTypeMismatch_unresolved();
  }

  @failingTest
  @override
  test_fieldTypeOk_unresolved_null() async {
    // UnimplementedError: kernel: (AsExpression) x as{TypeError} invalid-type
    await super.test_fieldTypeOk_unresolved_null();
  }

  @failingTest
  @override
  test_listElementTypeNotAssignable() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, found 0;
    //          1 errors of type StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_listElementTypeNotAssignable();
  }

  @failingTest
  @override
  test_mapKeyTypeNotAssignable() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, found 0;
    //          1 errors of type StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_mapKeyTypeNotAssignable();
  }

  @failingTest
  @override
  test_mapValueTypeNotAssignable() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, found 0;
    //          1 errors of type StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_mapValueTypeNotAssignable();
  }

  @failingTest
  @override
  test_parameterAssignable_undefined_null() async {
    // Expected 1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super.test_parameterAssignable_undefined_null();
  }

  @failingTest
  @override
  test_parameterNotAssignable_undefined() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super.test_parameterNotAssignable_undefined();
  }

  @failingTest
  @override
  test_topLevelVarAssignable_undefined_null() async {
    // Expected 1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super.test_topLevelVarAssignable_undefined_null();
  }

  @failingTest
  @override
  test_topLevelVarNotAssignable_undefined() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t6 = "foo" in let ...
    await super.test_topLevelVarNotAssignable_undefined();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
