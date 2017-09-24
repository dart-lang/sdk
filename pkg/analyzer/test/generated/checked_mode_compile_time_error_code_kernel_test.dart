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
  @failingTest
  test_fieldFormalParameterNotAssignableToField_fieldType_unresolved() async {
    return super
        .test_fieldFormalParameterNotAssignableToField_fieldType_unresolved();
  }

  @override
  @failingTest
  test_fieldFormalParameterNotAssignableToField_optional() async {
    return super.test_fieldFormalParameterNotAssignableToField_optional();
  }

  @override
  @failingTest
  test_fieldTypeMismatch_unresolved() async {
    return super.test_fieldTypeMismatch_unresolved();
  }

  @override
  @failingTest
  test_parameterNotAssignable_undefined() async {
    return super.test_parameterNotAssignable_undefined();
  }

  @override
  @failingTest
  test_redirectingConstructor_paramTypeMismatch() async {
    return super.test_redirectingConstructor_paramTypeMismatch();
  }

  @override
  @failingTest
  test_topLevelVarNotAssignable_undefined() async {
    return super.test_topLevelVarNotAssignable_undefined();
  }
}
