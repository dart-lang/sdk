// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DivisionOptimizationTest);
  });
}

@reflectiveTest
class DivisionOptimizationTest extends PubPackageResolutionTest {
  test_divisionOptimization() async {
    await assertNoErrorsInCode(r'''
void f(int x, int y) {
  x / y.toInt();
}
''');
  }

  test_double() async {
    await assertNoErrorsInCode(r'''
void f(double x, double y) {
  (x / y).toInt();
}
''');
  }

  test_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x, y) {
  (x / y).toInt();
}
''');
  }

  test_int() async {
    await assertErrorsInCode(r'''
void f(int x, int y) {
  (x / y).toInt();
}
''', [
      error(HintCode.DIVISION_OPTIMIZATION, 25, 15),
    ]);
  }

  test_nonNumeric() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator /(A x) { return x; }

  void toInt() {}
}
void f(A x, A y) {
  (x / y).toInt();
}
''');
  }

  test_wrappedInParentheses() async {
    await assertErrorsInCode(r'''
void f(int x, int y) {
  (((x / y))).toInt();
}
''', [
      error(HintCode.DIVISION_OPTIMIZATION, 25, 19),
    ]);
  }
}
