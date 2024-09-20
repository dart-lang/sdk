// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryParenthesisTest);
  });
}

@reflectiveTest
class UnnecessaryParenthesisTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_parenthesis';

  test_asExpressionInside_targetOfIndexAssignmentExpression() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  (o as List)[7] = 7;
}
''');
  }

  test_asExpressionInside_targetOfIndexExpression() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  (o as List)[7];
}
''');
  }

  test_asExpressionInside_targetOfMethodInvocation() async {
    await assertNoDiagnostics(r'''
void f() {
  (2 as num).toString();
}
''');
  }

  test_asExpressionInside_targetOfPrefixExpression() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  !(o as bool);
}
''');
  }

  test_assignmentInside_await() async {
    await assertNoDiagnostics(r'''
void f(Future<void> f, Future<void>? g) async {
  await (g ??= f);
}
''');
  }

  test_binaryExpressionInside_namedArgument() async {
    await assertDiagnostics(r'''
void f({required int p}) {
  f(p: (1 + 3));
}
''', [
      lint(34, 7),
    ]);
  }

  test_binaryExpressionInside_positionalArgument() async {
    await assertDiagnostics(r'''
void f(int p) {
  f((1 + 3));
}
''', [
      lint(20, 7),
    ]);
  }

  test_binaryExpressionInside_prefixExpression() async {
    await assertNoDiagnostics(r'''
var x = ~(1 | 2);
''');
  }

  test_binaryExpressionInside_returnExpression() async {
    await assertDiagnostics(r'''
bool f() {
  return (1 > 1);
}
''', [
      lint(20, 7),
    ]);
  }

  test_conditionalExpressionInside_argument() async {
    await assertDiagnostics(r'''
void f(int p) {
  print((1 == 1 ? 2 : 3));
}
''', [
      lint(24, 16),
    ]);
  }

  test_conditionalExpressionInside_listLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  [(1 == 1 ? 2 : 3)];
}
''');
  }

  test_conditionalExpressionInside_stringInterpolation() async {
    await assertDiagnostics(r'''
void f() {
  '${(1 == 1 ? 2 : 3)}';
}
''', [
      lint(16, 16),
    ]);
  }

  test_conditionalInside_expressionBody() async {
    await assertNoDiagnostics(r'''
int f() => (1 == 1 ? 2 : 3);
''');
  }

  /// https://github.com/dart-lang/linter/issues/4060
  test_constantPattern() async {
    await assertNoDiagnostics(r'''
const a = 1;
const b = 2;

void f(int i) {
  switch (i) {
    case const (a + b):
  }
}
''');
  }

  test_constructorFieldInitializer_binaryInside() async {
    await assertDiagnostics(r'''
class C {
  bool f;
  C() : f = (true && false);
}
''', [
      lint(32, 15),
    ]);
  }

  test_constructorFieldInitializer_equalityInside() async {
    await assertNoDiagnostics(r'''
class C {
  bool f;
  C() : f = (1 == 2);
}
''');
  }

  test_constructorFieldInitializer_functionExpressionInAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  final bool Function() e;

  C(bool Function()? e) : e = e ??= (() => true);
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/1395
  test_constructorFieldInitializer_functionExpressionInCascade() async {
    await assertNoDiagnostics(r'''
class C {
  Object f;

  C() : f = (C()..f = () => 42);
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/1395
  test_constructorFieldInitializer_functionExpressionInCascade2() async {
    await assertNoDiagnostics(r'''
class C {
  dynamic f;

  C()
      : f = (C()..f = (C()..f = () => 42));
}
''');
  }

  test_constructorFieldInitializer_functionExpressionInNullAware() async {
    await assertNoDiagnostics(r'''
class C {
  final bool Function() e;

  C(bool Function()? e) : e = e ?? (() => true);
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/1473
  test_constructorFieldInitializer_functionExpressionInNullAware2() async {
    await assertNoDiagnostics(r'''
class C {
  final bool Function() e;

  C(bool Function()? e) : e = (e ?? () => true);
}
''');
  }

  test_equalityInside_expressionBody() async {
    await assertDiagnostics(r'''
bool f() => (1 == 1);
''', [
      lint(12, 8),
    ]);
  }

  test_inListLiteral() async {
    await assertDiagnostics(r'''
final items = [1, (DateTime.now())];
''', [
      lint(18, 16),
    ]);
  }

  test_isExpressionInside_targetOfMethodInvocation() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  (o is num).toString();
}
''');
  }

  test_notEqualInside_returnExpression() async {
    await assertNoDiagnostics(r'''
bool f() {
  return (1 != 1);
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4041
  test_nullAware_cascadeAssignment() async {
    await assertNoDiagnostics(r'''
class A {
  var b = false;
  void m() {}
  set setter(int i) {}
}

void f(A? a) {
  (a?..b = true)?.m();
  (a?..b = true)?.setter = 1;
}

void g(List<int>? list) {
  (list?..[0] = 1)?.length;
}
''');
  }

  test_positionalArgument() async {
    await assertDiagnostics(r'''
void f() {
  print((1 + 2));
}
''', [
      lint(19, 7),
    ]);
  }

  test_postfixExpressionInside_targetOfMethodInvocation() async {
    await assertNoDiagnostics(r'''
void f(int i) {
  (i++).toString();
}
''');
  }

  test_prefixExpressionInside_targetOfMethodInvocation() async {
    await assertNoDiagnostics(r'''
void f(bool b) {
  (!b).toString();
}
''');
  }

  test_record_assignment() async {
    await assertDiagnostics(r'''
void f() {
  (int,) r = ((3,));
}
''', [
      lint(24, 6),
    ]);
  }

  test_record_namedParam() async {
    await assertDiagnostics(r'''
void f() {
  g(i: ((3,)));
}

void g({required (int,) i}) {}
''', [
      lint(18, 6),
    ]);
  }

  test_record_param() async {
    await assertDiagnostics(r'''
void f() {
  g(((3,)));
}

void g((int,) i) {}
''', [
      lint(15, 6),
    ]);
  }

  test_singleElementRecordWithNoTrailingComma_assignment() async {
    await assertDiagnostics(r'''
void f() {
  (int,) r = (3);
}
''', [
      error(
          CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
          24,
          3),
    ]);
  }

  test_singleElementRecordWithNoTrailingComma_namedParam() async {
    await assertDiagnostics(r'''
void f() {
  g(i: (3));
}

void g({required (int,) i}) {}
''', [
      error(
        CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
        18,
        3,
      ),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4876
  test_singleElementRecordWithNoTrailingComma_param() async {
    await assertDiagnostics(r'''
void f() {
  g((3));
}

void g((int,) i) {}
''', [
      error(
        CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
        15,
        3,
      ),
    ]);
  }

  test_spread() async {
    await assertNoDiagnostics(r'''
void f(Object p) {
  [...(p as List)];
}
''');
  }

  test_spread_nullAware() async {
    await assertNoDiagnostics(r'''
void f(Object? p) {
  [...?(p as List?)];
}
''');
  }

  test_switchExpression_expressionStatement() async {
    await assertNoDiagnostics(r'''
void f(Object? x) {
  (switch (x) { _ => 0 });
}
''');
  }

  test_switchExpression_invocationArgument() async {
    await assertDiagnostics(r'''
void f(Object? x) {
  print((switch (x) { _ => 0 }));
}
''', [
      lint(28, 23),
    ]);
  }

  test_switchExpression_variableDeclaration() async {
    await assertDiagnostics(r'''
void f(Object? x) {
  final v = (switch (x) { _ => 0 });
}
''', [
      lint(32, 23),
    ]);
  }

  test_targetOfGetterInNullableExtension() async {
    await assertNoDiagnostics(r'''
void f(C? c) {
  (c?.s).g;
}

class C {
  String? get s => 'yay';
}

extension on String? {
  bool get g => false;
}
''');
  }

  test_targetOfMethodInNullableExtension() async {
    await assertNoDiagnostics(r'''
void f(C? c) {
  (c?.s).g();
}

class C {
  String? get s => 'yay';
}

extension on String? {
  bool g() => false;
}
''');
  }

  test_typeLiteralInside() async {
    await assertNoDiagnostics(r'''
void f() {
  (List<int>).toString();
}
''');
  }

  test_unaryExpressionInside_targetOfMethodInvocation() async {
    await assertNoDiagnostics(r'''
void f(int p) {
  (p++).toString();
}
''');
  }

  test_unaryExpressionInside_targetOfPropertyAccess() async {
    await assertNoDiagnostics(r'''
void f(int p) {
  (p++).hashCode;
}
''');
  }
}
