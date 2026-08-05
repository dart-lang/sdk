// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferPatternTypeLiteralEqualityTest);
  });
}

@reflectiveTest
class PreferPatternTypeLiteralEqualityTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.type_literal_in_constant_pattern;

  test_constNotType_matchObjectNullable() async {
    await assertNoDiagnostics(r'''
void f(Object? x) {
  if (x case 0) {}
}
''');
  }

  test_constNotType_matchType() async {
    await assertDiagnostics(
      r'''
void f(Type x) {
  if (x case 0) {}
}
''',
      [error(diag.constantPatternNeverMatchesValueType, 30, 1)],
    );
  }

  test_constType_matchDynamic() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic x) {
  if (x case [!int!]) {}
}
''');
  }

  test_constType_matchObject() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object x) {
  if (x case [!int!]) {}
}
''');
  }

  test_constType_matchObjectNullable() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object? x) {
  if (x case [!int!]) {}
}
''');
  }

  test_constType_matchType() async {
    await assertNoDiagnostics(r'''
void f(Type x) {
  if (x case int) {}
}
''');
  }

  test_constType_matchType_explicitConst() async {
    await assertNoDiagnostics(r'''
void f(Type x) {
  if (x case const (int)) {}
}
''');
  }

  test_constType_matchType_nested() async {
    await assertNoDiagnostics(r'''
void f(A x) {
  if (x case A(type: int)) {}
}

class A {
  final Type type;
  A(this.type);
}
''');
  }

  test_constType_matchTypeParameter_boundObjectNullable() async {
    await assertDiagnosticsFromMarkup(r'''
void f<T extends Object?>(T x) {
  if (x case [!int!]) {}
}
''');
  }

  /// Nobody will write such code, but just in case.
  test_constType_matchTypeParameter_boundType() async {
    await assertNoDiagnostics(r'''
void f<T extends Type>(T x) {
  if (x case int) {}
}
''');
  }

  test_constType_matchTypeParameter_variable() async {
    await assertNoDiagnostics(r'''
void f<T>() {
  if (T case int) {}
}
''');
  }
}
