// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  String get lintRule => 'no_leading_underscores_for_local_identifiers';

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
}
