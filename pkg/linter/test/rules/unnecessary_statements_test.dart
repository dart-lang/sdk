// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryStatementsTest);
  });
}

@reflectiveTest
class UnnecessaryStatementsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_statements;

  test_asExpression() async {
    // See https://github.com/dart-lang/linter/issues/2163.
    await assertNoDiagnostics(r'''
void f(Object o) {
  o as int;
}
''');
  }

  test_binaryExpression() async {
    await assertDiagnostics(r'''
void f() {
  1 + 1;
}
''', [
      lint(13, 5),
    ]);
  }

  test_binaryExpression_andAnd() async {
    await assertDiagnostics(r'''
void f() {
  true && 1 == 2;
}
''', [
      lint(21, 6),
    ]);
  }

  test_binaryExpression_or() async {
    await assertDiagnostics(r'''
void f() {
  false || 1 == 2;
}
''', [
      lint(22, 6),
    ]);
  }

  test_binaryExpression_or_rightSideHasEffect() async {
    await assertNoDiagnostics(r'''
void f() {
  false || 7.isEven;
}
''');
  }

  test_construcorTearoff_new() async {
    await assertDiagnostics(r'''
void f() {
  ArgumentError.new;
}
''', [
      lint(13, 17),
    ]);
  }

  test_constructorTearoff_named() async {
    await assertDiagnostics(r'''
void f() {
  DateTime.now;
}
''', [
      lint(13, 12),
    ]);
  }

  test_doStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  do {} while (1 == 2);
}
''');
  }

  test_forEachStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i in []) {}
}
''');
  }

  test_forLoopUpdaters_subsequent() async {
    await assertDiagnostics(r'''
void f() {
  for (; 1 == 2; print(7), []) {}
}
''', [
      lint(38, 2),
    ]);
  }

  test_forStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  for (; 1 == 2;) {}
}
''');
  }

  test_functionTearoff() async {
    await assertDiagnostics(r'''
void f() {
  g;
}
void g() {}
''', [
      lint(13, 1),
    ]);
  }

  test_ifNull() async {
    await assertDiagnostics(r'''
void f() {
  null ?? 7;
}
''', [
      lint(21, 1),
    ]);
  }

  test_ifNull_rightSideHasEffect() async {
    await assertNoDiagnostics(r'''
void f() {
  null ?? 7.toString();
}
''');
  }

  test_ifStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) {
  } else if (1 == 2) {
  }
}
''');
  }

  test_inDoWhile() async {
    await assertDiagnostics(r'''
void f() {
  do {
    [];
  } while (1 == 2);
}
''', [
      lint(22, 2),
    ]);
  }

  test_inForLoop() async {
    await assertDiagnostics(r'''
void f() {
  for (var i in []) {
    ~1;
  }
}
''', [
      lint(37, 2),
    ]);
  }

  test_inForLoopInitializer() async {
    await assertDiagnostics(r'''
void f() {
  for (7; 1 == 2;) {}
}
''', [
      lint(18, 1),
    ]);
  }

  test_inForLoopUpdaters() async {
    await assertDiagnostics(r'''
void f() {
  for (; 1 == 2; []) {}
}
''', [
      lint(28, 2),
    ]);
  }

  test_inIfBody() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2) {
    [];
  }
}
''', [
      lint(31, 2),
    ]);
  }

  test_instanceCreationExpression() async {
    await assertNoDiagnostics(r'''
void f() {
  List.empty();
}
''');
  }

  test_instanceField() async {
    await assertDiagnostics(r'''
void f() {
  C().g;
}

class C {
  int g = 1;
}
''', [
      lint(13, 5),
    ]);
  }

  test_instanceField2() async {
    await assertDiagnostics(r'''
void f(C c) {
  c.g;
}
class C {
  int g = 1;
}
''', [
      lint(16, 3),
    ]);
  }

  test_instanceGetter() async {
    await assertNoDiagnostics(r'''
void f() {
  List.empty().first;
}
''');
  }

  test_instanceGetter2() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.first;
}
''');
  }

  test_inSwitchStatement_case() async {
    await assertDiagnostics(r'''
void f() {
  switch (7) {
    case 6:
      [];
  }
}
''', [
      lint(44, 2),
    ]);
  }

  test_inSwitchStatement_case_break() async {
    await assertNoDiagnostics(r'''
void f() {
  switch (7) {
    case 6:
      break;
  }
}
''');
  }

  test_inSwitchStatement_default() async {
    await assertDiagnostics(r'''
void f() {
  switch (7) {
    default:
      [];
  }
}
''', [
      lint(45, 2),
    ]);
  }

  test_intLiteral() async {
    await assertDiagnostics(r'''
void f() {
  1;
}
''', [
      lint(13, 1),
    ]);
  }

  test_listLiteral() async {
    await assertDiagnostics(r'''
void f() {
  [];
}
''', [
      lint(13, 2),
    ]);
  }

  test_localVariable() async {
    await assertDiagnostics(r'''
void f() {
  var g = 1;
  g;
}
''', [
      lint(26, 1),
    ]);
  }

  test_mapLiteral() async {
    await assertDiagnostics(r'''
void f() {
  <dynamic, dynamic>{};
}
''', [
      lint(13, 20),
    ]);
  }

  test_methodInvocation() async {
    await assertNoDiagnostics(r'''
void f() {
  g();
}
void g() {}
''');
  }

  test_methodInvocation2() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.forEach((_) {});
}
''');
  }

  test_methodTearoff() async {
    await assertDiagnostics(r'''
void f() {
  List.empty().where;
}
''', [
      lint(13, 18),
    ]);
  }

  test_methodTearoff_cascaded() async {
    await assertDiagnostics(r'''
void f() {
  List.empty()..where;
}
''', [
      lint(25, 7),
    ]);
  }

  test_methodTearoff_cascaded_followOn() async {
    await assertDiagnostics(r'''
void f() {
 List.empty()
    ..forEach((_) {})
    ..where;
}
''', [
      lint(51, 7),
    ]);
  }

  test_methodTearoff_cascaded_returned_InLocalFunction() async {
    await assertDiagnostics(r'''
void f() {
  // ignore: unused_element
  g() => List.empty()..where;
}
''', [
      lint(60, 7),
    ]);
  }

  test_methodTearoff_cascaded_returned_InTopLevelFunction() async {
    await assertDiagnostics(r'''
List<int> f() => List.empty()..where;
''', [
      lint(29, 7),
    ]);
  }

  test_methodTearoff_returned_inFunctionLiteral() async {
    await assertDiagnostics(r'''
void f() {
  () => List.empty().where;
}
''', [
      lint(13, 24),
    ]);
  }

  test_methodTearoff_returned_InLocalFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_element
  g() => List.empty().where;
}
''');
  }

  test_methodTearoff_returned_InTopLevelFunction() async {
    await assertNoDiagnostics(r'''
Object f() => List.empty().where;
''');
  }

  /// https://github.com/dart-lang/linter/issues/4334
  test_patternAssignment_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var (a, b) = (0, 0);
  var result = (1, 2);
  (a, b) = (a + result.$1, b + result.$2);
}
''');
  }

  test_rethrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (_) {
    rethrow;
  }
}
''');
  }

  test_returnStatement_binaryOperation() async {
    await assertNoDiagnostics(r'''
int f() {
  return 1 + 1;
}
''');
  }

  test_returnStatement_cascadedTearoff() async {
    await assertDiagnostics(r'''
List<int> f() {
  return List.empty()..where;
}
''', [
      lint(37, 7),
    ]);
  }

  test_stringLiteral() async {
    await assertDiagnostics(r'''
void f() {
  "blah";
}
''', [
      lint(13, 6),
    ]);
  }

  test_switchStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  switch (~1) {}
}
''');
  }

  test_throwExpression() async {
    await assertNoDiagnostics(r'''
void f() {
  throw Exception();
}
''');
  }

  test_topLevelGetter() async {
    await assertNoDiagnostics(r'''
void f() {
  g;
}
int get g => 1;
''');
  }

  test_topLevelVariable() async {
    await assertDiagnostics(r'''
void f() {
  g;
}
int g = 1;
''', [
      lint(13, 1),
    ]);
  }

  test_unaryOperation() async {
    await assertDiagnostics(r'''
void f() {
  ~1;
}
''', [
      lint(13, 2),
    ]);
  }

  test_unaryOperation_postfix() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  x++;
}
''');
  }

  test_unaryOperation_prefix() async {
    await assertNoDiagnostics(r'''
void f(int x) {
  ++x;
}
''');
  }

  test_whileStatement() async {
    await assertNoDiagnostics(r'''
void f() {
  while (1 == 2) {}
}
''');
  }
}
