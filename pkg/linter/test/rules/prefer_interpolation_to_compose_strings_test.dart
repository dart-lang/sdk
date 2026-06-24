// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferInterpolationToComposeStringsTest);
  });
}

@reflectiveTest
class PreferInterpolationToComposeStringsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_interpolation_to_compose_strings;

  test_stringLiteral_stringLiteral() async {
    await assertNoDiagnostics(r'''
final a = 'foo' + 'bar';
''');
  }

  test_stringLiteral_stringLiteral_stringLiteral() async {
    await assertNoDiagnostics(r'''
final a = 'foo' + 'bar' + 'baz';
''');
  }

  test_stringLiteral_toStringInvocation() async {
    await assertDiagnosticsFromMarkup(r'''
final b = [!'foo' + 7.toString()!];
''');
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
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = [!'bar' + a!];
''');
  }

  test_stringLiteral_variableString_insideInterpolation() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = /*[0*/'${/*[1*/'bar' + a/*1]*/}' + a/*0]*/;
''');
  }

  test_stringLiteral_variableString_stringLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = [!'bar' + a!] + 'baz';
''');
  }

  test_stringLiteral_variableString_variableString() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = [!'bar' + a!] + a;
''');
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
}
''');
  }

  test_variableString_stringLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = [!a + 'bar'!];
''');
  }

  test_variableString_stringLiteral_stringLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = [!a + 'bar'!] + 'baz';
''');
  }

  test_variableString_stringLiteral_stringLiteral_variableString() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = /*[0*/a + 'bar'/*0]*/ + /*[1*/'baz' + a/*1]*/;
''');
  }

  test_variableString_stringLiteral_variableString() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final b = [!a + 'bar'!] + a;
''');
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
final c = a + a;
''');
  }

  test_variableString_variableString_stringLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
final a = 'foo';
final c = a + [!a + 'bar'!];
''');
  }

  test_variableString_variableString_variableString() async {
    await assertNoDiagnostics(r'''
final a = 'foo';
final c = a + a + a;
''');
  }
}
