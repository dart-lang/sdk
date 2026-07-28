// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryFinalTest);
  });
}

@reflectiveTest
class UnnecessaryFinalTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_final;

  test_field_final() async {
    await assertNoDiagnostics(r'''
class C {
  final int x = 3;
}
''');
  }

  test_forEachLoopVariable_final() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for ([!final!] x in []) {}
}
''');
  }

  test_forEachLoopVariable_var() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var x in []) {}
}
''');
  }

  test_listPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!final!] [a] = [1];
}
''');
  }

  test_listPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case [int x, [!final!] int y]) {}
}
''');
  }

  test_localVariable_final() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final!] x = 1;
}
''');
  }

  test_localVariable_final_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!final!] _ = '';
}
''');
  }

  test_localVariable_final_wildcard_preWildcards() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  [!final!] _ = '';
}
''');
  }

  test_localVariable_var() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = 1;
}
''');
  }

  test_mapPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!final!] {'a': a} = {'a': 1};
}
''');
  }

  test_mapPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case {'x': [!final!] x, 'y' : var y}) {}
}
''');
  }

  test_objectPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  int c;
  C(this.c);
}

f() {
  [!final!] C(:c) = C(1);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  int c;
  int d;
  C(this.c, this.d);
}

f(Object o) {
  if (o case C(c: [!final!] x, d: var y)) {}
}
''');
  }

  test_objectPattern_switch() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && [!final!] b):
  }
}
''');
  }

  test_parameter_declaring() async {
    await assertNoDiagnostics(r'''
class C(final int x);
''');
  }

  test_parameter_declaring_prePrimaryConstructors() async {
    await assertDiagnostics(
      r'''
// @dart = 3.10
class C(final int x);
''',
      [
        error(diag.experimentNotEnabled, 23, 1),
        lint(24, 5),
        error(diag.experimentNotEnabled, 36, 1),
      ],
    );
  }

  test_parameter_function_finalTyped() async {
    await assertDiagnostics(
      r'''
void f(final int x) {}
''',
      [error(diag.extraneousModifier, 7, 5)],
    );
  }

  test_parameter_function_finalTyped_prePrimaryConstructors() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
void f([!final!] int x) {}
''');
  }

  test_parameter_function_typed() async {
    await assertNoDiagnostics(r'''
void f(int x) {
}
''');
  }

  test_parameter_functionExpression_final() async {
    await assertDiagnostics(
      r'''
void f() {
  (final c) => c.length;
}
''',
      [error(diag.extraneousModifier, 14, 5)],
    );
  }

  test_parameter_functionExpression_final_prePrimaryConstructors() async {
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.10
void f() {
  ([!final!] c) => c.length;
}
''');
  }

  test_parameter_functionExpression_typed() async {
    await assertNoDiagnostics(r'''
void f() {
  (String c) => c.length;
}
''');
  }

  test_recordPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  [!final!] (a, b) = (1, 2);
}
''');
  }

  test_recordPattern_destructured_forEach() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  for ([!final!] (a, b) in [(1, 2)]) { }
}
''');
  }

  test_recordPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var (a, b) = (1, 2);
}
''');
  }

  test_recordPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case ([!final!] int x, int y)) {}
}
''');
  }

  test_recordPattern_ifCase_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case (int x, int y)) {}
}
''');
  }

  test_recordPattern_switch() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ((1, 2)) {
    case (/*[0*/final/*0]*/ a, /*[1*/final/*1]*/ b):
  }
}
''');
  }
}
