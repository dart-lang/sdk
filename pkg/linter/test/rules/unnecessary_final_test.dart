// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryFinalTest);
  });
}

@reflectiveTest
class UnnecessaryFinalTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_final';

  test_field_final() async {
    await assertNoDiagnostics(r'''
class C {
  final int x = 3;
}
''');
  }

  test_forEachLoopVariable_final() async {
    await assertDiagnostics(r'''
void f() {
  for (final x in []) {}
}
''', [
      lint(18, 5),
    ]);
  }

  test_forEachLoopVariable_var() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var x in []) {}
}
''');
  }

  test_listPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  final [a] = [1];
}
''', [
      lint(8, 5),
    ]);
  }

  test_listPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case [int x, final int y]) {}
}
''', [
      lint(35, 5),
    ]);
  }

  test_localVariable_final() async {
    await assertDiagnostics(r'''
void f() {
  final x = 1;
}
''', [
      lint(13, 5),
    ]);
  }

  test_localVariable_var() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = 1;
}
''');
  }

  test_mapPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  final {'a': a} = {'a': 1};
}
''', [
      lint(8, 5),
    ]);
  }

  test_mapPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case {'x': final x, 'y' : var y}) {}
}
''', [
      lint(33, 5),
    ]);
  }

  test_objectPattern_destructured() async {
    await assertDiagnostics(r'''
class C {
  int c;
  C(this.c);
}

f() {
  final C(:c) = C(1);
}
''', [
      lint(43, 5),
    ]);
  }

  test_objectPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
class C {
  int c;
  C(this.c);
}

f() {
  var C(:c) = C(1);
}
''');
  }

  test_objectPattern_ifCase() async {
    await assertDiagnostics(r'''
class C {
  int c;
  int d;
  C(this.c, this.d);
}

f(Object o) {
  if (o case C(c: final x, d: var y)) {}
}
''', [
      lint(84, 5),
    ]);
  }

  test_objectPattern_switch() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && final b):
  }
}
''', [
      lint(79, 5),
    ]);
  }

  test_parameter_function_finalTyped() async {
    await assertDiagnostics(r'''
void f(final int x) {}
''', [
      lint(7, 5),
    ]);
  }

  test_parameter_function_typed() async {
    await assertNoDiagnostics(r'''
void f(int x) {
}
''');
  }

  test_parameter_functionExpression_final() async {
    await assertDiagnostics(r'''
void f() {
  (final c) => c.length;
}
''', [
      lint(14, 5),
    ]);
  }

  test_parameter_functionExpression_typed() async {
    await assertNoDiagnostics(r'''
void f() {
  (String c) => c.length;
}
''');
  }

  test_recordPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  final (a, b) = (1, 2);
}
''', [
      lint(8, 5),
    ]);
  }

  test_recordPattern_destructured_forEach() async {
    await assertDiagnostics(r'''
f() {
  for (final (a, b) in [(1, 2)]) { }
}
''', [
      lint(13, 5),
    ]);
  }

  test_recordPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var (a, b) = (1, 2);
}
''');
  }

  test_recordPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case (final int x, int y)) {}
}
''', [
      lint(28, 5),
    ]);
  }

  test_recordPattern_ifCase_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case (int x, int y)) {}
}
''');
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (final a, final b):
  }
}
''', [
      lint(36, 5),
      lint(45, 5),
    ]);
  }
}
