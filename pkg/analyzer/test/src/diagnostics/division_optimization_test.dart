// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DivisionOptimizationTest);
    defineReflectiveTests(DivisionOptimizationTest_Driver);
  });
}

@reflectiveTest
class DivisionOptimizationTest extends ResolverTestCase {
  test_divisionOptimization() async {
    assertNoErrorsInCode(r'''
f(int x, int y) {
  var v = x / y.toInt();
}
''');
  }

  test_double() async {
    assertErrorsInCode(r'''
f(double x, double y) {
  var v = (x / y).toInt();
}
''', [HintCode.DIVISION_OPTIMIZATION]);
  }

  test_dynamic() async {
    assertNoErrorsInCode(r'''
f(x, y) {
  var v = (x / y).toInt();
}
''');
  }

  test_int() async {
    assertErrorsInCode(r'''
f(int x, int y) {
  var v = (x / y).toInt();
}
''', [HintCode.DIVISION_OPTIMIZATION]);
  }

  test_nonNumeric() async {
    assertNoErrorsInCode(r'''
class A {
  num operator /(x) { return x; }
}
f(A x, A y) {
  var v = (x / y).toInt();
}
''');
  }

  test_wrappedInParentheses() async {
    assertErrorsInCode(r'''
f(int x, int y) {
  var v = (((x / y))).toInt();
}
''', [HintCode.DIVISION_OPTIMIZATION]);
  }
}

@reflectiveTest
class DivisionOptimizationTest_Driver extends DivisionOptimizationTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
