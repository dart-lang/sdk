// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryFinalTestLanguage300);
  });
}

@reflectiveTest
class UnnecessaryFinalTestLanguage300 extends LintRuleTest
    with LanguageVersion300Mixin {
  @override
  String get lintRule => 'unnecessary_final';

  test_listPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  final [a] = [1];
  print('$a');
}
''', [
      lint(8, 5),
    ]);
  }

  test_listPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case [int x, final int y]) print('$x$y'); 
}
''', [
      lint(35, 5),
    ]);
  }

  test_mapPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  final {'a': a} = {'a': 1};
  print('$a');
}
''', [
      lint(8, 5),
    ]);
  }

  test_mapPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case {'x': final x, 'y' : var y}) print('$x$y');
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
  print(c);
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
  print(c);
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
  if (o case C(c: final x, d: var y)) print('$x$y');
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
    case A(a: >0 && final b): print('$b');
  }
}
''', [
      lint(79, 5),
    ]);
  }

  test_recordPattern_ifCase() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case (final int x, int y)) print('$x$y');
}
''', [
      lint(28, 5),
    ]);
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (final a, final b): print('$a$b');
  }
}
''', [
      lint(36, 5),
      lint(45, 5),
    ]);
  }
}
