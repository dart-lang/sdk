// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/type_literal_in_constant_pattern.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferPatternTypeLiteralEqualityTest);
  });
}

@reflectiveTest
class PreferPatternTypeLiteralEqualityTest extends LintRuleTest {
  @override
  String get lintRule => TypeLiteralInConstantPattern.lintName;

  test_constNotType_matchObjectNullable() async {
    await assertNoDiagnostics(r'''
void f(Object? x) {
  if (x case 0) {}
}
''');
  }

  test_constNotType_matchType() async {
    await assertDiagnostics(r'''
void f(Type x) {
  if (x case 0) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 1),
    ]);
  }

  test_constType_matchDynamic() async {
    await assertDiagnostics(r'''
void f(dynamic x) {
  if (x case int) {}
}
''', [
      lint(33, 3),
    ]);
  }

  test_constType_matchObject() async {
    await assertDiagnostics(r'''
void f(Object x) {
  if (x case int) {}
}
''', [
      lint(32, 3),
    ]);
  }

  test_constType_matchObjectNullable() async {
    await assertDiagnostics(r'''
void f(Object? x) {
  if (x case int) {}
}
''', [
      lint(33, 3),
    ]);
  }

  test_constType_matchType() async {
    await assertDiagnostics(r'''
void f(Type x) {
  if (x case int) {}
}
''', [
      lint(30, 3),
    ]);
  }

  test_constType_matchType_explicitConst() async {
    await assertNoDiagnostics(r'''
void f(Type x) {
  if (x case const (int)) {}
}
''');
  }

  test_constType_matchType_nested() async {
    await assertDiagnostics(r'''
void f(A x) {
  if (x case A(type: int)) {}
}

class A {
  final Type type;
  A(this.type);
}
''', [
      lint(35, 3),
    ]);
  }

  test_constType_matchTypeParameter_boundObjectNullable() async {
    await assertDiagnostics(r'''
void f<T extends Object?>(T x) {
  if (x case int) {}
}
''', [
      lint(46, 3),
    ]);
  }

  /// Nobody will write such code, but just in case.
  test_constType_matchTypeParameter_boundType() async {
    await assertDiagnostics(r'''
void f<T extends Type>(T x) {
  if (x case int) {}
}
''', [
      lint(43, 3),
    ]);
  }
}
