// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSingleCascadeInExpressionStatementsTest);
  });
}

@reflectiveTest
class AvoidSingleCascadeInExpressionStatementsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_single_cascade_in_expression_statements';

  test_multipleCascades() async {
    await assertNoDiagnostics(r'''
void f(int p) {
  p..toString()..toString();
}
''');
  }

  test_singleCascade() async {
    await assertDiagnostics(r'''
void f(int p) {
  p..toString();
}
''', [
      lint(18, 13),
    ]);
  }

  test_singleCascade_asArgument() async {
    await assertNoDiagnostics(r'''
void f(int p) {
  g(p..toString());
}

void g(int p) {}
''');
  }

  test_singleCascade_inIfCondition() async {
    await assertNoDiagnostics(r'''
void f(bool p) {
  if (p..hashCode) {}
}
''');
  }

  test_singleCascade_thrown() async {
    await assertNoDiagnostics(r'''
void f(int p) {
  throw p..toString();
}
''');
  }
}
