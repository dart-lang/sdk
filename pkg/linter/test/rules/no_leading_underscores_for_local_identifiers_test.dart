// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLeadingUnderscoresForLocalIdentifiersTest);
  });
}

@reflectiveTest
class NoLeadingUnderscoresForLocalIdentifiersTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    diag.unusedCatchStack,
    ...super.ignoredDiagnosticCodes,
  ];

  @override
  String get lintRule => LintNames.no_leading_underscores_for_local_identifiers;

  test_catchClause_error() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {}
  catch([!_error!]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {}
  catch(error, [!_stackTrace!]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for(var [!_x!] in [1,2,3]) {}
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (var [!_i!] = 0;;) {}
}
''');
  }

  test_forLoop_multipleVariables() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (var i = 0, [!_j!] = 0;;) {}
}
''');
  }

  test_listPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case [int [!_x!], int y]) {}
}
''');
  }

  test_listPattern_switch() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ([1,2]) {
    case [1 && var [!_a!], 2 && var b]:
  }
}
''');
  }

  test_listPattern_switch_leftOperand() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ([1,2]) {
    case [var [!_a!] && 1, 2 && var b]:
  }
}
''');
  }

  test_localFunction() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void m() {
    int [!_f!]() => 10;
  }
}
''');
  }

  test_localVariable() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  var [!_foo!] = 0;
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  var x = 1, [!_y!] = 2;
}
''');
  }

  test_mapPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  final {'first': [!_a!], 'second': b} = {'first': 1, 'second': 2};
}
''');
  }

  test_mapPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case {'x': var [!_x!], 'y' : var y}) {}
}
''');
  }

  test_mapPattern_switch() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ({1: 2}) {
    case {'a': var [!_a!], 'b': var b} :
  }
}
''');
  }

  test_method() async {
    await assertNoDiagnostics(r'''
class C {
  void _m() {}
}
''');
  }

  test_objectPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: [!_b!]) = A(1);
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  int c;
  int d;
  C(this.c, this.d);
}

f(Object o) {
  if (o case C(c: var [!_x!], d: var y)) {}
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
    case A(a: >0 && var [!_b!]):
  }
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f(int [!_p!]) {}
''');
  }

  test_parameter_inBody_factory() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  factory (int [!_x!]) => C._();
  C._();
}
''');
  }

  test_parameter_inBody_new() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  new (int [!_x!]);
}
''');
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
// ignore: private_named_non_field_parameter
void f({int? _n}) {}
''');
  }

  test_parameter_namedRequired() async {
    await assertNoDiagnostics(r'''
// ignore: private_named_non_field_parameter
void f({required int _n}) {}
''');
  }

  test_parameter_noUnderscore() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_parameter_primary_declaring() async {
    await assertNoDiagnostics(r'''
class C(final int _x) {
  void p() => print(_x);
}
''');
  }

  test_parameter_primary_simple() async {
    await assertDiagnosticsFromMarkup(r'''
class C(int [!_x!]) {}
''');
  }

  test_recordPattern_destructured() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  var ([!_a!], b) = ('a', 'b');
}
''');
  }

  test_recordPattern_destructured_field() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  var (a: [!_a!], :b) = (a: 1, b: 1);
}
''');
  }

  test_recordPattern_ifCase() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case (int [!_x!], int y)) {}
}
''');
  }

  test_recordPattern_ifCase_field() async {
    await assertDiagnosticsFromMarkup(r'''
f(Object o) {
  if (o case (x: int [!_x!], :int y)) {}
}
''');
  }

  test_recordPattern_switch() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  switch ((1, 2)) {
    case (var [!_a!], var b):
  }
}
''');
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
