// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DivisionOptimizationTest);
  });
}

@reflectiveTest
class DivisionOptimizationTest extends DriverResolutionTest {
  test_divisionOptimization() async {
    await assertNoErrorsInCode(r'''
f(int x, int y) {
  var v = x / y.toInt();
}
''');
  }

  test_double() async {
    await assertErrorsInCode(r'''
f(double x, double y) {
  var v = (x / y).toInt();
}
''', [HintCode.DIVISION_OPTIMIZATION]);
  }

  test_dynamic() async {
    await assertNoErrorsInCode(r'''
f(x, y) {
  var v = (x / y).toInt();
}
''');
  }

  test_int() async {
    await assertErrorsInCode(r'''
f(int x, int y) {
  var v = (x / y).toInt();
}
''', [HintCode.DIVISION_OPTIMIZATION]);
  }

  test_nonNumeric() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator /(x) { return x; }
}
f(A x, A y) {
  var v = (x / y).toInt();
}
''');
  }

  test_wrappedInParentheses() async {
    await assertErrorsInCode(r'''
f(int x, int y) {
  var v = (((x / y))).toInt();
}
''', [HintCode.DIVISION_OPTIMIZATION]);
  }
}
