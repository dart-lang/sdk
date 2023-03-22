// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalLocalsTestLanguage300);
  });
}

@reflectiveTest
class PreferFinalLocalsTestLanguage300 extends LintRuleTest
    with LanguageVersion300Mixin {
  @override
  String get lintRule => 'prefer_final_locals';

  test_destructured_listPattern_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [a, b, ...rest] = [1, 2, 3, 4, 5, 6, 7];
  print('${++a}$b$rest');
}
''');
  }

  test_destructured_listPattern_ok() async {
    await assertDiagnostics(r'''
f() {
  var [a, b, ...rest] = [1, 2, 3, 4, 5, 6, 7];
  print('$a$b$rest');
}
''', [
      lint(12, 15),
    ]);
  }

  test_destructured_mapPattern() async {
    await assertDiagnostics(r'''
f() {
  var {'first': a, 'second': b} = {'first': 1, 'second': 2};
  print('$a$b');
}
''', [
      lint(12, 25),
    ]);
  }

  test_destructured_mapPattern_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var {'first': a, 'second': b} = {'first': 1, 'second': 2};
  print('${++a}$b');
}
''');
  }

  test_destructured_mapPattern_ok() async {
    await assertNoDiagnostics(r'''
f() {
  final {'first': a, 'second': b} = {'first': 1, 'second': 2};
  print('$a$b');
}
''');
  }

  test_destructured_objectPattern() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  var A(a: b) = A(1);
  print('$b');
}
''', [
      lint(56, 4),
    ]);
  }

  test_destructured_objectPattern_mutated_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  var A(a: b) = A(1);
  print('${++b}');
}
''');
  }

  test_destructured_objectPattern_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: b) = A(1);
  print('$b');
}
''');
  }

  test_destructured_recordPattern() async {
    await assertDiagnostics(r'''
f() {
  var (a, b) = ('a', 'b');
  print('$a$b');
}
''', [
      lint(21, 10),
    ]);
  }

  test_destructured_recordPattern_list() async {
    await assertDiagnostics(r'''
f() {
  var [a, b] = ['a', 'b'];
  print('$a$b');
}
''', [
      lint(12, 6),
    ]);
  }

  test_destructured_recordPattern_list_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [a, b] = [1, 2];
  print('${++a}$b');
}
''');
  }

  test_destructured_recordPattern_list_ok() async {
    await assertNoDiagnostics(r'''
f() {
  final [a, b] = [1, 2];
  print('$a$b');
}
''');
  }

  test_destructured_recordPattern_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var (a, b) = (1, 'b');
  print('${++a}$b');
}
''');
  }

  test_destructured_recordPattern_ok() async {
    await assertNoDiagnostics(r'''
f() {
  final (a, b) = ('a', 'b');
  print('$a$b');
}
''');
  }

  test_ifPatternList() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case [int x, final int y]) print('$x$y'); 
}
''', [
      lint(28, 5),
    ]);
  }

  test_ifPatternList_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case [final int x, final int y]) print('$x$y'); 
}
''');
  }

  test_ifPatternMap() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case {'x': var x}) print('$x');
}
''', [
      lint(37, 1),
    ]);
  }

  test_ifPatternMap_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case {'x': final x}) print('$x');
}
''');
  }

  test_ifPatternRecord() async {
    await assertDiagnostics(r'''
f(Object o) {
  if (o case (int x, int y)) print('$x$y');
}
''', [
      lint(32, 1),
      lint(39, 1),
    ]);
  }

  test_ifPatternRecord_ok() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  if (o case (final int x, final int y)) print('$x$y');
}
''');
  }

  test_switch_objectPattern() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var b): print('$b');
  }
}
''', [
      lint(83, 1),
    ]);
  }

  test_switch_objectPattern_mutated_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var b): print('${++b}');
  }
}
''');
  }

  test_switch_objectPattern_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && final b): print('$b');
  }
}
''');
  }

  test_switch_recordPattern() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (var a, int b): print('$a$b');
  }
}
''', [
      lint(40, 1),
      lint(47, 1),
    ]);
  }

  test_switch_recordPattern_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (var a, final int b): {
      print('${++a}$b');
    }
  }
}
''');
  }

  test_switch_recordPattern_ok() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (final a, final int b): print('$a$b');
  }
}
''');
  }
}
