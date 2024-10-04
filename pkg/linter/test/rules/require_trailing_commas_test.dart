// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireTrailingCommasTest);
  });
}

@reflectiveTest
class RequireTrailingCommasTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.require_trailing_commas;

  test_function_parameters_multiLine() async {
    await assertDiagnostics(r'''
void method4(int one,
    int two) {}
''', [
      lint(33, 1),
    ]);
  }

  test_function_parameters_multiLine_withComma() async {
    await assertNoDiagnostics(r'''
void f(
  int one,
  int two,
) {}
''');
  }

  test_function_parameters_withNamed_mulitLine_withComma() async {
    await assertNoDiagnostics(r'''
void f(
  int one, {
  int? two,
}) {}
''');
  }

  test_function_parameters_withNamed_multiLine() async {
    await assertDiagnostics(r'''
void f(int one,
    {int two = 2}) {}
''', [
      lint(32, 1),
    ]);
  }

  test_function_parameters_withNamed_singleLine() async {
    await assertNoDiagnostics(r'''
  void method1(Object p1, Object p2, {Object? param3, Object? param4}) {}
''');
  }

  test_functionLiteral_parameters_multiLine() async {
    await assertDiagnostics(r'''
void f() {
  (int one,
      int two)
      {};
}
''', [
      lint(36, 1),
    ]);
  }

  test_functionLiteral_parameters_singleLine() async {
    await assertNoDiagnostics(r'''
void f() {
  (a, b) {};
}
''');
  }
}
