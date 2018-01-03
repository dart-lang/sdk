// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest_Kernel);
  });
}

@reflectiveTest
class StrictModeTest_Kernel extends StrictModeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get previewDart2 => true;

  @override
  @failingTest
  test_assert_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_assert_is();
  }

  @override
  @failingTest
  test_conditional_isNot() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_conditional_isNot();
  }

  @override
  @failingTest
  test_conditional_or_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_conditional_or_is();
  }

  @override
  @failingTest
  test_forEach() async {
    // 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart': Failed assertion: line 441 pos 16: 'identical(combiner.arguments.positional[0], rhs)': is not true.
    await super.test_forEach();
  }

  @override
  @failingTest
  test_if_isNot() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_if_isNot();
  }

  @override
  @failingTest
  test_if_isNot_abrupt() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_if_isNot_abrupt();
  }

  @override
  @failingTest
  test_if_or_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_if_or_is();
  }

  @override
  @failingTest
  test_localVar() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_localVar();
  }
}
