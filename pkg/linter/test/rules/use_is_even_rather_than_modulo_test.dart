// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseIsEvenRatherThanModuloTest);
  });
}

@reflectiveTest
class UseIsEvenRatherThanModuloTest extends LintRuleTest {
  @override
  String get lintRule => 'use_is_even_rather_than_modulo';

  test_isEven() async {
    await assertNoDiagnostics(r'''
var a = 1.isEven;
''');
  }

  test_isOdd() async {
    await assertNoDiagnostics(r'''
var a = 2.isOdd;
''');
  }

  test_moduloThree_intTypedExpression() async {
    await assertNoDiagnostics(r'''
var a = 3;
var b = a % 3 == 1;
''');
  }

  test_moduloTwoEqualEqualOne_intTypedExpression() async {
    await assertDiagnostics(r'''
var a = 3;
var b = a % 2 == 0;
''', [
      lint(19, 10),
    ]);
  }

  test_moduloTwoEqualEqualOne_literalInt() async {
    await assertDiagnostics(r'''
var a = 13 % 2 == 1;
''', [
      lint(8, 11),
    ]);
  }

  test_moduloTwoEqualEqualThree() async {
    await assertNoDiagnostics(r'''
var a = 1 % 2 == 3 - 3;
''');
  }

  test_moduloTwoEqualEqualZero_literalInt() async {
    await assertDiagnostics(r'''
var a = 1 % 2 == 0;
''', [
      lint(8, 10),
    ]);
  }

  test_moduloTwoGreaterOrEqualZero_literalInt() async {
    await assertNoDiagnostics(r'''
  bool a = 1 % 2 >= 0;
''');
  }

  test_moduloTwoNotEqualZero_intTypedExpression() async {
    await assertNoDiagnostics(r'''
  int number = 3;
  bool d = number % 2 != 0;
''');
  }

  test_plus_intTypedExpression() async {
    await assertNoDiagnostics(r'''
var a = 3;
var b = a + 2 == 0;
''');
  }

  test_undefinedClass() async {
    await assertDiagnostics(r'''
Class tmp;
bool a = tmp % 2 == 0;
''', [
      // No lint
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 5),
    ]);
  }
}
