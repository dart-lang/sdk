// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIfNullOperatorsTest);
  });
}

@reflectiveTest
class PreferIfNullOperatorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_if_null_operators;

  test_null_eqEq_nullable() async {
    await assertDiagnostics(r'''
void f(int? p) {
  null == p ? 1 : p;
}
''', [
      lint(19, 17),
    ]);
  }

  test_null_notEq_nullable() async {
    await assertDiagnostics(r'''
void f(int? p) {
  null != p ? p : 2;
}
''', [
      lint(19, 17),
    ]);
  }

  test_nullable_eqEq_null() async {
    await assertDiagnostics(r'''
void f(int? p) {
  p == null ? 1 : p;
}
''', [
      lint(19, 17),
    ]);
  }

  test_nullable_notEq_null() async {
    await assertDiagnostics(r'''
void f(int? p) {
  p != null ? p : 2;
}
''', [
      lint(19, 17),
    ]);
  }

  test_nullablePrefixedIdentifier_notEq_null() async {
    await assertDiagnostics(r'''
void f(C c) {
  c.d != null ? c.d : 7;
}
class C {
  int? get d => 7;
}
''', [
      lint(16, 21),
    ]);
  }
}
