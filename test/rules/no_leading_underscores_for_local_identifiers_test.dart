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

  test_listPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ([1,2]) {
    case [1 && var _a, 2 && var b]: print('$_a$b');
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
    case [var _a && 1, 2 && var b]: print('$_a$b');
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
  print('$_a$b');
}
''', [
      lint(24, 2),
    ]);
  }

  test_mapPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ({1: 2}) {
    case {'a': var _a, 'b': var b} : print('$_a$b');
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
  print('$_b');
}
''', [
      lint(53, 2),
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
    case A(a: >0 && var _b): print('$_b');
  }
}
''', [
      lint(82, 2),
    ]);
  }

  test_recordPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  var (_a, b) = ('a', 'b');
  print('$_a$b');
}
''', [
      lint(13, 2),
    ]);
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (var _a, var b): print('$_a$b');
  }
}
''', [
      lint(40, 2),
    ]);
  }
}
