// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseTruncatingDivisionTest);
  });
}

@reflectiveTest
class UseTruncatingDivisionTest extends LintRuleTest {
  @override
  String get lintRule => 'use_truncating_division';

  test_double_divide_truncate() async {
    await assertNoDiagnostics(r'''
void f(double x, double y) {
  (x / y).toInt();
}
''');
  }

  test_int_divide_truncate() async {
    await assertDiagnostics(r'''
void f(int x, int y) {
  (x / y).toInt();
}
''', [
      lint(25, 15),
    ]);
  }

  test_int_divide_truncate_moreParensAroundDivision() async {
    await assertDiagnostics(r'''
void f(int x, int y) {
  (((x / y))).toInt();
}
''', [
      lint(25, 19),
    ]);
  }

  test_int_divide_truncate_moreParensAroundOperands() async {
    await assertDiagnostics(r'''
void f(int x, int y) {
  ((x + 1) / (y - 1)).toInt();
}
''', [
      lint(25, 27),
    ]);
  }

  test_intExtensionType_divide_truncate() async {
    await assertNoDiagnostics(r'''
void f(ET x, int y) {
  (x / y).toInt();
}

extension type ET(int it) {
  int operator /(int other) => 7;
}
''');
  }
}
