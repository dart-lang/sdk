// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParameterAssignmentsTest);
  });
}

@reflectiveTest
class ParameterAssignmentsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.parameter_assignments;

  test_anonymousFunction_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
void main() {
  (int i) {
    [!i = 42!];
  }(0);
}
''');
  }

  test_anonymousFunction_assignment_arrowBody() async {
    await assertDiagnosticsFromMarkup(r'''
void main() {
  (int i) => [!i = 42!];
}
''');
  }

  test_anonymousFunction_assignment_notInvoked() async {
    await assertDiagnosticsFromMarkup(r'''
void main() {
  (int i) {
    [!i = 42!];
  };
}
''');
  }

  test_assignment_followedByNotOperator() async {
    await assertDiagnosticsFromMarkup(r'''
void f(bool p) {
  [!p = true!];
  if (!p || p) {}
}
''');
  }

  test_assignment_inIfElseBranches() async {
    await assertDiagnosticsFromMarkup(r'''
void foo({String? value}) {
  if (1 == 1) {
    /*[0*/value = ' $value'/*0]*/;
  } else {
    /*[1*/value = ' $value'/*1]*/;
  }
}
''');
  }

  test_assignment_nullableParameter() async {
    await assertDiagnosticsFromMarkup(r'''
void f([int? p]) {
  p ??= 8;
  [!p = 42!];
}
''');
  }

  test_assignment_nullableParameter_named() async {
    await assertDiagnosticsFromMarkup(r'''
void f({int? p}) {
  p ??= 8;
  [!p = 42!];
}
''');
  }

  test_assignment_wildcard() async {
    await assertDiagnostics(
      r'''
void f([int? _]) {
  _ = 8;
}
''',
      [
        // No lint.
        error(diag.undefinedIdentifier, 21, 1),
      ],
    );
  }

  test_closure_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  (int p) {
    [!p = 2!];
  }(2);
}
''');
  }

  test_compoundAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!p += 3!];
}
''');
  }

  test_constructor_inBody_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C(int x) {
    [!x = 4!];
  }
}
''');
  }

  test_constructor_primary_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
class C(int x) {
  this {
    [!x = 4!];
  }
}
''');
  }

  test_function_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!p = 4!];
}
''');
  }

  test_function_incrementAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!p += 4!];
}
''');
  }

  test_function_named_default() async {
    await assertDiagnosticsFromMarkup(r'''
void f({int p = 5}) {
  print([!p++!]);
}
''');
  }

  test_function_named_optional_ok() async {
    await assertNoDiagnostics(r'''
void f({int? optional}) {
  optional ??= 8;
}
''');
  }

  test_function_ok_noAssignment() async {
    await assertNoDiagnostics(r'''
void f(String p) {
  print(p);
}
''');
  }

  test_function_ok_shadow() async {
    await assertNoDiagnostics(r'''
void f(String? p) {
  if (p == null) {
    int p = 2;
    p = 3;
  }
}
''');
  }

  test_function_positional_optional_assignedTwice() async {
    await assertDiagnostics(
      r'''
void f([int? optional]) {
  optional ??= 8;
  optional ??= 16;
}
''',
      [
        error(diag.deadNullAwareExpression, 59, 2),
        lint(46, 15),
        error(diag.deadCode, 59, 3),
      ],
    );
  }

  test_function_positional_optional_ok() async {
    await assertNoDiagnostics(r'''
void f([int? optional]) {
  optional ??= 8;
}
''');
  }

  test_function_positional_optional_re_incremented() async {
    await assertDiagnosticsFromMarkup(r'''
void f([int? optional]) {
  optional ??= 8;
  [!optional += 16!];
}
''');
  }

  test_function_positional_optional_reassigned() async {
    await assertDiagnosticsFromMarkup(r'''
void f([int? optional]) {
  optional ??= 8;
  [!optional = 16!];
}
''');
  }

  test_function_postfix() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!p++!];
}
''');
  }

  test_function_prefix() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!++p!];
}
''');
  }

  test_instanceMethod_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m(int p) {
    [!p = 4!];
  }
}
''');
  }

  test_instanceMethod_nonAssignment() async {
    await assertNoDiagnostics(r'''
class A {
  void m(String p) {
    print(p);
  }
}
''');
  }

  test_instanceSetter_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  set x(int value) {
    [!value = 5!];
  }
}
''');
  }

  // If and switch cases don't need verification since params aren't valid
  // constant pattern expressions.

  test_listAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
f(int b) {
  [![b]!] = [1];
}
''');
  }

  test_localFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  void g() {
    [!p = 3!];
  }
  g();
}
''');
  }

  test_mapAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
f(int a) {
  [!{'a': a}!] = {'a': 1};
}
''');
  }

  test_member_setter() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  set x(int v) {
    [!v = 5!];
  }
}
''');
  }

  test_nullAwareAssignment_nonNullableParameter() async {
    await assertDiagnostics(
      r'''
void f([int p = 42]) {
  // ignore: dead_null_aware_expression
  p ??= 8;
}
''',
      [lint(65, 7), error(diag.deadCode, 71, 2)],
    );
  }

  test_nullAwareAssignment_nonNullableParameter_named() async {
    await assertDiagnostics(
      r'''
void f({int p = 42}) {
  // ignore: dead_null_aware_expression
  p ??= 8;
}
''',
      [lint(65, 7), error(diag.deadCode, 71, 2)],
    );
  }

  test_nullAwareAssignment_nullableParameter() async {
    await assertNoDiagnostics(r'''
void f([int? p]) {
  p ??= 8;
}
''');
  }

  test_nullAwareAssignment_nullableParameter_named() async {
    await assertNoDiagnostics(r'''
void f({int? p}) {
  p ??= 8;
}
''');
  }

  test_nullAwareAssignment_nullableParameter_promotedToNonNullable() async {
    await assertDiagnostics(
      r'''
void f([int? p]) {
  p ??= 8;
  // ignore: dead_null_aware_expression
  p ??= 16;
}
''',
      [lint(72, 8), error(diag.deadCode, 78, 3)],
    );
  }

  test_objectAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}

f(int b) {
  [!A(a: b)!] = A(1);
}
''');
  }

  test_postfixOperation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!p++!];
}
''');
  }

  test_postfixOperation_named() async {
    await assertDiagnosticsFromMarkup(r'''
void f({int p = 5}) {
  [!p++!];
}
''');
  }

  test_recordAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int a) {
  var b = 0;
  [!(a, b)!] = (1, 2);
}
''');
  }

  test_topLevelFunction_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int p) {
  [!p = 4!];
}
''');
  }

  test_topLevelFunction_nonAssignment() async {
    await assertNoDiagnostics(r'''
void f(String p) {
  print(p);
}
''');
  }

  test_topLevelMethod_nullableParameter_assignment() async {
    await assertNoDiagnostics(r'''
void f(String? p) {
  if (p == null) {
    int p = 2;
    p = 3;
  }
}
''');
  }
}
