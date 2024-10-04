// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLiteralBoolComparisonsTest);
  });
}

@reflectiveTest
class NoLiteralBoolComparisonsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.no_literal_bool_comparisons;

  test_true_eqeq_x_localVariable_nonNullableBool() async {
    await assertDiagnostics(r'''
void f(bool x) {
  while (true == x) {}
}
''', [
      lint(26, 4),
    ]);
  }

  test_x_bangeq_true_expression_nonNullableBool() async {
    await assertDiagnostics(r'''
void f(bool x, bool y) {
  print((x && y) != true);
}
''', [
      lint(45, 4),
    ]);
  }

  test_x_eqeq_true_field_nonNullableBool() async {
    await assertDiagnostics(r'''
void f(C c) {
  if (c.x == true) {}
}
abstract class C {
  bool get x;
}
''', [
      lint(27, 4),
    ]);
  }

  test_x_eqeq_true_localVariable_nonNullableBool() async {
    await assertDiagnostics(r'''
void f(bool x) {
  if (x == true) {}
}
''', [
      lint(28, 4),
    ]);
  }

  test_x_eqeq_true_nullableBool() async {
    await assertNoDiagnostics(r'''
void f(bool? x) {
  print(x == true);
}
''');
  }
}
