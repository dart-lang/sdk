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

  @failingTest
  @override
  test_assertion_throws() async {
    // Not yet generating errors in kernel mode.
    await super.test_assertion_throws();
  }

  @failingTest
  @override
  test_fieldFormalParameterAssignableToField_fieldType_unresolved_null() async {
    // Expected 1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super
        .test_fieldFormalParameterAssignableToField_fieldType_unresolved_null();
  }

  @failingTest
  @override
  test_fieldFormalParameterAssignableToField_typedef() async {
    // Expected 1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_fieldFormalParameterAssignableToField_typedef();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_fieldFormalParameterNotAssignableToField();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_extends() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0
    await super.test_fieldFormalParameterNotAssignableToField_extends();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_fieldType() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_fieldFormalParameterNotAssignableToField_fieldType();
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
  test_fieldFormalParameterNotAssignableToField_implements() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0
    await super.test_fieldFormalParameterNotAssignableToField_implements();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_list() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0
    await super.test_fieldFormalParameterNotAssignableToField_list();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_map_keyMismatch() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0
    await super.test_fieldFormalParameterNotAssignableToField_map_keyMismatch();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_map_valueMismatch() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0
    await super
        .test_fieldFormalParameterNotAssignableToField_map_valueMismatch();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_optional() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t1 = "foo" in let ...
    await super.test_fieldFormalParameterNotAssignableToField_optional();
  }

  @failingTest
  @override
  test_fieldFormalParameterNotAssignableToField_typedef() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_fieldFormalParameterNotAssignableToField_typedef();
  }

  @failingTest
  @override
  test_fieldInitializerNotAssignable() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t2 = "" in let ...
    await super.test_fieldInitializerNotAssignable();
  }

  @failingTest
  @override
  test_fieldTypeMismatch() async {
    // UnimplementedError: kernel: (AsExpression) x as{TypeError} dart.core::int
    await super.test_fieldTypeMismatch();
  }

  @failingTest
  @override
  test_fieldTypeMismatch_generic() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t3 = #lib1::y in let ...
    await super.test_fieldTypeMismatch_generic();
  }

  @failingTest
  @override
  test_fieldTypeMismatch_unresolved() async {
    // UnimplementedError: kernel: (AsExpression) x as{TypeError} invalid-type
    await super.test_fieldTypeMismatch_unresolved();
  }

  @failingTest
  @override
  test_fieldTypeOk_generic() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t4 = #lib2::y in let ...
    await super.test_fieldTypeOk_generic();
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
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31936')
  @override
  test_listLiteral_inferredElementType() async =>
      super.test_listLiteral_inferredElementType();

  @failingTest
  @override
  test_mapKeyTypeNotAssignable() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, found 0;
    //          1 errors of type StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_mapKeyTypeNotAssignable();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31936')
  @override
  test_mapLiteral_inferredKeyType() async =>
      super.test_mapLiteral_inferredKeyType();

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31936')
  @override
  test_mapLiteral_inferredValueType() async =>
      super.test_mapLiteral_inferredValueType();

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
  test_parameterNotAssignable() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_parameterNotAssignable();
  }

  @failingTest
  @override
  test_parameterNotAssignable_typeSubstitution() async {
    // Expected 1 errors of type CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, found 0;
    //          1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_parameterNotAssignable_typeSubstitution();
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
  test_redirectingConstructor_paramTypeMismatch() async {
    // Bad state: Expected element reference for analyzer offset 33; got one for kernel offset 36
    await super.test_redirectingConstructor_paramTypeMismatch();
  }

  @failingTest
  @override
  test_superConstructor_paramTypeMismatch() async {
    // UnimplementedError: kernel: (AsExpression) d as{TypeError} dart.core::double
    await super.test_superConstructor_paramTypeMismatch();
  }

  @failingTest
  @override
  test_topLevelVarAssignable_undefined_null() async {
    // Expected 1 errors of type StaticWarningCode.UNDEFINED_CLASS, found 0
    await super.test_topLevelVarAssignable_undefined_null();
  }

  @failingTest
  @override
  test_topLevelVarNotAssignable() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t5 = "foo" in let ...
    await super.test_topLevelVarNotAssignable();
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
