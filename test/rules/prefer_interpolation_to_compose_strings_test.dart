// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/prefer_interpolation_to_compose_strings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferInterpolationToComposeStringsTest);
  });
}

@reflectiveTest
class PreferInterpolationToComposeStringsTest extends LintRuleTest {
  @override
  String get lintRule => PreferInterpolationToComposeStrings.code.name;

  test_stringLiteral_stringLiteral() async {
    await assertNoDiagnostics(r'''
final a = 'foo' + 'bar';
''');
  }

  test_stringLiteral_toStringInvocation() async {
    await assertDiagnostics(r'''
final a = A();
final b = 'foo' + a.toString();

class A {
  @override
  String toString({int? x}) => 'A';
}
''', [
      lint(25, 20),
    ]);
  }

  test_stringLiteral_toStringInvocation_withArguments() async {
    await assertNoDiagnostics(r'''
final a = A();
final b = 'foo' + a.toString(x: 0);

class A {
  @override
  String toString({int? x}) => 'A';
}
''');
  }

  test_stringLiteral_variableString() async {
    await assertDiagnostics(r'''
final a = 'foo';
final b = 'bar' + a;
''', [
      lint(27, 9),
    ]);
  }

  /// #2490
  test_stringLiteralRaw_variableString() async {
    await assertNoDiagnostics(r'''
final a = 'foo';
final b = r'bar' + a;
''');
  }

  test_toStringInvocation_stringLiteral_withArguments() async {
    await assertNoDiagnostics(r'''
final a = A();
final b = a.toString(x: 0) + 'foo';

class A {
  @override
  String toString({int? x}) => 'A';
}
''');
  }

  /// #792
  test_variableNotString() async {
    await assertNoDiagnostics(r'''
class A {
  A operator +(String other) => this;
}

void f(A a) {
  a + ' ';
}
''');
  }

  /// #813
  test_variableString_plusEqual_stringLiteral() async {
    await assertNoDiagnostics(r'''
void f() {
  var a = 'foo';
  a += 'bar';
  a;
}
''');
  }

  test_variableString_stringLiteral() async {
    await assertDiagnostics(r'''
final a = 'foo';
final b = a + 'bar';
''', [
      lint(27, 9),
    ]);
  }

  /// #2490
  test_variableString_stringLiteralRaw() async {
    await assertNoDiagnostics(r'''
final a = 'foo';
final b = a + r'bar';
''');
  }

  /// #735
  test_variableString_variableString() async {
    await assertNoDiagnostics(r'''
final a = 'foo';
final b = 'bar';
final c = a + b;
''');
  }
}
