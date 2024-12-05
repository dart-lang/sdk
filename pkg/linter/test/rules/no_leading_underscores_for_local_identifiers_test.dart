// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLeadingUnderscoresForLocalIdentifiersTest);
  });
}

@reflectiveTest
class NoLeadingUnderscoresForLocalIdentifiersTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_CATCH_STACK,
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
        WarningCode.UNUSED_LOCAL_VARIABLE,
      ];

  @override
  String get lintRule => LintNames.no_leading_underscores_for_local_identifiers;

  test_catchClause_error() async {
    await assertDiagnostics(r'''
void f() {
  try {}
  catch(_error) {}
}
''', [
      lint(28, 6),
    ]);
  }

  test_catchClause_error_justUnderscore() async {
    await assertNoDiagnostics(r'''
void f() {
  try {}
  catch(_) {}
}
''');
  }

  test_catchClause_stackTrace() async {
    await assertDiagnostics(r'''
void f() {
  try {}
  catch(error, _stackTrace) {}
}
''', [
      lint(35, 11),
    ]);
  }

  test_field() async {
    await assertNoDiagnostics(r'''
class C {
  var _foo = 0;
}
''');
  }

  test_fieldFormalParameter() async {
    // https://github.com/dart-lang/linter/issues/3127
    await assertNoDiagnostics(r'''
class C {
  final int _p;
  C(this._p);
}
''');
  }

  test_forEach() async {
    await assertDiagnostics(r'''
void f() {
  for(var _x in [1,2,3]) {}
}
''', [
      lint(21, 2),
    ]);
  }

  test_forEach_justUnderscore() async {
    await assertNoDiagnostics(r'''
void f() {
  for(var _ in [1,2,3]) {}
}
''');
  }

  test_forEach_noUnderscore() async {
    await assertNoDiagnostics(r'''
void f() {
  for(var x in [1,2,3]) {}
}
''');
  }

  test_forLoop_firstVariable() async {
    await assertDiagnostics(r'''
void f() {
  for (var _i = 0;;) {}
}
''', [
      lint(22, 2),
    ]);
  }

  test_forLoop_multipleVariables() async {
    await assertDiagnostics(r'''
void f() {
  for (var i = 0, _j = 0;;) {}
}
''', [
      lint(29, 2),
    ]);
  }

  test_listPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case [int _x, int y]) {}
}
''', [
      lint(32, 2),
    ]);
  }

  test_listPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ([1,2]) {
    case [1 && var _a, 2 && var b]:
  }
}
''', [
      lint(44, 2),
    ]);
  }

  test_listPattern_switch_leftOperand() async {
    await assertDiagnostics(r'''
f() {
  switch ([1,2]) {
    case [var _a && 1, 2 && var b]:
  }
}
''', [
      lint(39, 2),
    ]);
  }

  test_localFunction() async {
    await assertDiagnostics(r'''
class C {
  void m() {
    int _f() => 10;
  }
}
''', [
      lint(31, 2),
    ]);
  }

  test_localVariable() async {
    await assertDiagnostics(r'''
void f() {
  var _foo = 0;
}
''', [
      lint(17, 4),
    ]);
  }

  test_localVariable_internalUnderscore() async {
    await assertNoDiagnostics(r'''
void f() {
  var p_p = 0;
}
''');
  }

  test_localVariable_justUnderscore() async {
    await assertNoDiagnostics(r'''
void f() {
  var _ = 0;
}
''');
  }

  test_localVariable_multipleVariables() async {
    await assertDiagnostics(r'''
void f() {
  var x = 1, _y = 2;
}
''', [
      lint(24, 2),
    ]);
  }

  test_mapPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  final {'first': _a, 'second': b} = {'first': 1, 'second': 2};
}
''', [
      lint(24, 2),
    ]);
  }

  test_mapPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case {'x': var _x, 'y' : var y}) {}
}
''', [
      lint(37, 2),
    ]);
  }

  test_mapPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ({1: 2}) {
    case {'a': var _a, 'b': var b} :
  }
}
''', [
      lint(45, 2),
    ]);
  }

  test_method() async {
    await assertNoDiagnostics(r'''
class C {
  void _m() {}
}
''');
  }

  test_objectPattern_destructured() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: _b) = A(1);
}
''', [
      lint(53, 2),
    ]);
  }

  test_objectPattern_destructured_field() async {
    await assertNoDiagnostics(r'''
class A {
  int _a;
  A(this._a);
}
f() {
  var A(:_a) = A(1);
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
  if (o case C(c: var _x, d: var y)) {}
}
''', [
      lint(88, 2),
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
    case A(a: >0 && var _b):
  }
}
''', [
      lint(82, 2),
    ]);
  }

  test_objectPattern_switch_field() async {
    await assertNoDiagnostics(r'''
class A {
  var _a;
}

f(A a) {
  switch (a) {
    case A(:var _a):
  }
  switch (a) {
    case A(:var _a?):
    case A(:var _a!):
  }
}
''');
  }

  test_parameter() async {
    await assertDiagnostics(r'''
void f(int _p) {}
''', [
      lint(11, 2),
    ]);
  }

  test_parameter_internalUnderscore() async {
    await assertNoDiagnostics(r'''
void f(int p_p) {}
''');
  }

  test_parameter_justUnderscore() async {
    await assertNoDiagnostics(r'''
void f(int _) {}
''');
  }

  test_parameter_named() async {
    await assertNoDiagnostics(r'''
// ignore: private_optional_parameter
void f({int? _n}) {}
''');
  }

  test_parameter_namedRequired() async {
    await assertNoDiagnostics(r'''
// ignore: private_optional_parameter
void f({required int _n}) {}
''');
  }

  test_parameter_noUnderscore() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_recordPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  var (_a, b) = ('a', 'b');
}
''', [
      lint(13, 2),
    ]);
  }

  test_recordPattern_destructured_field() async {
    await assertDiagnostics(r'''
f() {
  var (a: _a, :b) = (a: 1, b: 1);
}
''', [
      lint(16, 2),
    ]);
  }

  test_recordPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case (int _x, int y)) {}
}
''', [
      lint(32, 2),
    ]);
  }

  test_recordPattern_ifCase_field() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case (x: int _x, :int y)) {}
}
''', [
      lint(35, 2),
    ]);
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (var _a, var b):
  }
}
''', [
      lint(40, 2),
    ]);
  }

  test_superFormalParameter() async {
    await assertNoDiagnostics(r'''
class C {
  int _i;
  C(this._i);
}
class D extends C {
  D(super._i);
}
''');
  }

  test_topLevelVariable() async {
    await assertNoDiagnostics(r'''
var _foo = 0;
''');
  }

  test_typedef() async {
    await assertNoDiagnostics(r'''
typedef _T = void Function(String);
''');
  }
}
