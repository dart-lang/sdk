// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDoubleAndIntChecksTest);
  });
}

@reflectiveTest
class AvoidDoubleAndIntChecksTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_double_and_int_checks;

  test_checkingForDouble() async {
    await assertNoDiagnostics(r'''
void f(m) {
  if (m is double) {}
}
''');
  }

  test_checkingForDoubleAfterInt() async {
    await assertNoDiagnostics(r'''
void f(m) {
  if (m is int) {}
  else if (m is double) {}
}
''');
  }

  test_checkingForIntAfterDouble() async {
    await assertDiagnostics(r'''
void f(m) {
  if (m is double) {}
  else if (m is int) {}
}
''', [
      lint(45, 8),
    ]);
  }

  test_checkingForIntAfterDouble_getter() async {
    await assertNoDiagnostics(r'''
get g => null;
void f() {
  if (g is double) {}
  else if (g is int) {}
}
''');
  }

  test_checkingForIntAfterDouble_localVariable() async {
    await assertDiagnostics(r'''
void f() {
  var m;
  if (m is double) {}
  else if (m is int) {}
}
''', [
      lint(53, 8),
    ]);
  }
}
