// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLiteralBoolComparisonsTest);
  });
}

@reflectiveTest
class NoLiteralBoolComparisonsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.no_literal_bool_comparisons;

  test_ampersand_true() async {
    await assertDiagnostics(
      r'''
void f(bool value) {
  if (value & true) {}
}
''',
      [lint(35, 4)],
    );
  }

  test_ampersandAmpersand_true() async {
    await assertDiagnostics(
      r'''
void f(bool value) {
  if (value && true) {}
}
''',
      [lint(36, 4)],
    );
  }

  test_bangeq_true_expression_nonNullableBool() async {
    await assertDiagnostics(
      r'''
void f(bool x, bool y) {
  print((x && y) != true);
}
''',
      [lint(45, 4)],
    );
  }

  test_bar_true() async {
    await assertDiagnostics(
      r'''
void f(bool value) {
  if (value | true) {}
}
''',
      [lint(35, 4)],
    );
  }

  test_barBar_true() async {
    await assertDiagnostics(
      r'''
void f(bool value) {
  if (value || true) {}
}
''',
      [lint(36, 4)],
    );
  }

  test_caret_true() async {
    await assertDiagnostics(
      r'''
void f(bool value) {
  if (value ^ true) {}
}
''',
      [lint(35, 4)],
    );
  }

  test_conditional_both_true() async {
    await assertDiagnostics(
      r'''
void f(bool value1, bool value2) {
  print(value1 ? true : true);
}
''',
      [lint(52, 11)],
    );
  }

  test_conditional_else_true() async {
    await assertDiagnostics(
      r'''
void f(bool value1, bool value2) {
  print(value1 ? value2 : true);
}
''',
      [lint(61, 4)],
    );
  }

  test_conditional_neither_booleans() async {
    await assertNoDiagnostics(r'''
void f(bool value1) {
  print(value1 ? null : null);
}
''');
  }

  test_conditional_then_null_else_false() async {
    await assertNoDiagnostics(r'''
void f(bool value1) {
  print(value1 ? null : false);
}
''');
  }

  test_conditional_then_true() async {
    await assertDiagnostics(
      r'''
void f(bool value1, bool value2) {
  print(value1 ? true : value2);
}
''',
      [lint(52, 4)],
    );
  }

  test_conditional_then_true_else_null() async {
    await assertNoDiagnostics(r'''
void f(bool value1) {
  print(value1 ? null : false);
}
''');
  }

  test_eqeq_true_field_nonNullableBool() async {
    await assertDiagnostics(
      r'''
void f(C c) {
  if (c.x == true) {}
}
abstract class C {
  bool get x;
}
''',
      [lint(27, 4)],
    );
  }

  test_eqeq_true_invocation() async {
    await assertDiagnostics(
      r'''
void f(bool Function() fn) {
  if (fn() == true) {}
}
''',
      [lint(43, 4)],
    );
  }

  test_eqeq_true_localVariable_nonNullableBool() async {
    await assertDiagnostics(
      r'''
void f(bool x) {
  if (x == true) {}
}
''',
      [lint(28, 4)],
    );
  }

  test_eqeq_true_nullableBool() async {
    await assertNoDiagnostics(r'''
void f(bool? x) {
  print(x == true);
}
''');
  }

  test_eqeq_true_propertyAccess() async {
    await assertDiagnostics(
      r'''
extension E on List {
  void m() {
    if (this.isNotEmpty == true) {}
  }
}
''',
      [lint(62, 4)],
    );
  }

  test_true_eqeq_localVariable_nonNullableBool() async {
    await assertDiagnostics(
      r'''
void f(bool x) {
  while (true == x) {}
}
''',
      [lint(26, 4)],
    );
  }
}
