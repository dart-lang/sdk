// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'error_suppression_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(scheglov): Restore similar test coverage when the front-end API
    // allows it.  See https://github.com/dart-lang/sdk/issues/32258.
    // defineReflectiveTests(ErrorSuppressionTest_Kernel);
  });
}

@reflectiveTest
class ErrorSuppressionTest_Kernel extends ErrorSuppressionTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  @failingTest
  test_error_code_mismatch() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVALID_ASSIGNMENT, found 0;
    //          1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_error_code_mismatch();
  }

  @override
  @failingTest
  test_ignore_first() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_ignore_first();
  }

  @override
  @failingTest
  test_ignore_first_trailing() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_ignore_first_trailing();
  }

  @override
  @failingTest
  test_ignore_for_file() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_ignore_for_file();
  }

  @override
  @failingTest
  test_invalid_error_code() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVALID_ASSIGNMENT, found 0;
    //          1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_invalid_error_code();
  }

  @override
  @failingTest
  test_missing_error_codes() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t1 = #lib1::x in let ...
    await super.test_missing_error_codes();
  }

  @override
  @failingTest
  test_multiple_ignores() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t2 = #lib2::x in let ...
    await super.test_multiple_ignores();
  }

  @override
  @failingTest
  test_multiple_ignores_traling() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t3 = #lib3::x in let ...
    await super.test_multiple_ignores_traling();
  }

  @override
  @failingTest
  test_multiple_ignores_whitespace_variant_1() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t4 = #lib4::x in let ...
    await super.test_multiple_ignores_whitespace_variant_1();
  }

  @override
  @failingTest
  test_multiple_ignores_whitespace_variant_2() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t5 = #lib5::x in let ...
    await super.test_multiple_ignores_whitespace_variant_2();
  }

  @override
  @failingTest
  test_multiple_ignores_whitespace_variant_3() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t6 = #lib6::x in let ...
    await super.test_multiple_ignores_whitespace_variant_3();
  }

  @override
  @failingTest
  test_no_ignores() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVALID_ASSIGNMENT, found 0;
    //          1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_no_ignores();
  }
}
