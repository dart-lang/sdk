// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidMultipleDeclarationsPerLineTest);
  });
}

@reflectiveTest
class AvoidMultipleDeclarationsPerLineTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_multiple_declarations_per_line';

  test_extensionField_multiple() async {
    await assertDiagnostics(r'''
extension E on Object {
  static String? a, b, c;
}
''', [
      lint(44, 1),
    ]);
  }

  test_extensionField_single() async {
    await assertNoDiagnostics(r'''
extension E on Object {
  static String? a;
}
''');
  }

  test_field_multiple() async {
    await assertDiagnostics(r'''
class C {
  String? a, b, c;
}
''', [
      lint(23, 1),
    ]);
  }

  test_field_single() async {
    await assertNoDiagnostics(r'''
class C {
  String? a;
}
''');
  }

  test_forLoop_multiple() async {
    await assertNoDiagnostics(r'''
// See https://github.com/dart-lang/linter/issues/2543.
void f() {
  for (var i = 0, j = 0; i < 2 && j < 2; ++i, ++j) {}
}
''');
  }

  test_functionVariable_multiple() async {
    await assertDiagnostics(r'''
void f() {
  String? a, b, c;
}
''', [
      lint(24, 1),
    ]);
  }

  test_functionVariable_single() async {
    await assertNoDiagnostics(r'''
void f() {
  String? a;
}
''');
  }

  test_topLevel_multiple() async {
    await assertDiagnostics(r'''
String? a, b, c;
''', [
      lint(11, 1),
    ]);
  }

  test_topLevel_single() async {
    await assertNoDiagnostics(r'''
String? a;
''');
  }
}
