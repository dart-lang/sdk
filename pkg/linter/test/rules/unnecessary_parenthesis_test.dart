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
g({required (int,) i}) { }

''', [
      lint(18, 6),
    ]);
  }

  test_record_param() async {
    await assertDiagnostics(r'''
void f() {
  g(((3,)));
}
g((int,) i) { }

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
f() {
  g(i: (3));
}

g({required (int,) i}) { }
''', [
      error(
          CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
          13,
          3),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4876
  test_singleElementRecordWithNoTrailingComma_param() async {
    await assertDiagnostics(r'''
f() {    
  g((3));
}

g((int,) i) { }
''', [
      error(
          CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
          14,
          3),
    ]);
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
}
