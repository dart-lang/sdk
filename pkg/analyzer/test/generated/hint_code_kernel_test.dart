// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'hint_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HintCodeTest_Kernel);
  });
}

@reflectiveTest
class HintCodeTest_Kernel extends HintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_deprecatedAnnotationUse_named() async {
    return super.test_deprecatedAnnotationUse_named();
  }

  @override
  @failingTest
  test_deprecatedAnnotationUse_positional() async {
    return super.test_deprecatedAnnotationUse_positional();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_named_parameter_with_default() async {
    return super.test_invalidRequiredParam_on_named_parameter_with_default();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_positional_parameter() async {
    return super.test_invalidRequiredParam_on_positional_parameter();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_positional_parameter_with_default() async {
    return super
        .test_invalidRequiredParam_on_positional_parameter_with_default();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_required_parameter() async {
    return super.test_invalidRequiredParam_on_required_parameter();
  }

  @override
  @failingTest
  test_invalidRequiredParam_valid() async {
    return super.test_invalidRequiredParam_valid();
  }

  @override
  @failingTest
  test_required_constructor_param() async {
    return super.test_required_constructor_param();
  }

  @override
  @failingTest
  test_required_constructor_param_no_reason() async {
    return super.test_required_constructor_param_no_reason();
  }

  @override
  @failingTest
  test_required_constructor_param_null_reason() async {
    return super.test_required_constructor_param_null_reason();
  }

  @override
  @failingTest
  test_required_constructor_param_OK() async {
    return super.test_required_constructor_param_OK();
  }

  @override
  @failingTest
  test_required_constructor_param_redirecting_cons_call() async {
    return super.test_required_constructor_param_redirecting_cons_call();
  }

  @override
  @failingTest
  test_required_constructor_param_super_call() async {
    return super.test_required_constructor_param_super_call();
  }

  @override
  @failingTest
  test_required_function_param() async {
    return super.test_required_function_param();
  }

  @override
  @failingTest
  test_required_method_param() async {
    return super.test_required_method_param();
  }

  @override
  @failingTest
  test_required_method_param_in_other_lib() async {
    return super.test_required_method_param_in_other_lib();
  }

  @override
  @failingTest
  test_required_typedef_function_param() async {
    return super.test_required_typedef_function_param();
  }
}
