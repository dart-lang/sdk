// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryConstPatternsTest);
    defineReflectiveTests(UnnecessaryConstRecordsTest);
  });
}

@reflectiveTest
class UnnecessaryConstPatternsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_const';

  test_case_constConstructor_ok() async {
    await assertNoDiagnostics(r'''
class C {
  const C();
}
f(C c) {
  switch (c) {
    case const C():
  }
}
''');
  }

  test_case_listLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case const [1, 2]:
  }
}
''');
  }

  test_case_mapLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
   case const {'k': 'v'}:
  }
}
''');
  }

  test_case_setLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case const {1}:
  }
}
''');
  }

  test_constConstructor() async {
    await assertDiagnostics(r'''
class C {
  const C();
}
const c = const C();
''', [
      lint(35, 9),
    ]);
  }

  test_listLiteral() async {
    await assertDiagnostics(r'''
const l = const [];
''', [
      lint(10, 8),
    ]);
  }

  test_mapLiteral() async {
    await assertDiagnostics(r'''
const m = const {1: 1};
''', [
      lint(10, 12),
    ]);
  }

  test_setLiteral() async {
    await assertDiagnostics(r'''
const s = const {1};
''', [
      lint(10, 9),
    ]);
  }
}

@reflectiveTest
class UnnecessaryConstRecordsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_const';

  test_recordLiteral() async {
    await assertDiagnostics(r'''
const r = const (a: 1);
''', [
      lint(10, 12),
    ]);
  }

  test_recordLiteral_ok() async {
    await assertNoDiagnostics(r'''
const r = (a: 1);
''');
  }
}
