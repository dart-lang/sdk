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
