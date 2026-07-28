// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferForeachTest);
  });
}

@reflectiveTest
class PreferForeachTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_foreach;

  test_blockBody_multipleStatements() async {
    await assertNoDiagnostics(r'''
void f(List<int> list, void Function(int) fn) {
  for (final a in list) {
    fn(a);
    fn(a);
  }
}
''');
  }

  test_blockBody_singleStatement_functionCall() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> list, void Function(int) fn) {
  [!for (final a in list) {
    fn(a);
  }!]
}
''');
  }

  test_blockBody_singleStatement_functionTypedExpressionCall() async {
    await assertDiagnosticsFromMarkup(r'''
void Function(int) fn() => (int a) {};

void f(List<int> list) {
  [!for (final a in list) {
    fn()(a);
  }!]
}
''');
  }

  test_blockBody_singleStatement_methodCall() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f(int o) {}

  void foo(List<int> list) {
    [!for (final a in list) {
      f(a);
    }!]
  }
}
''');
  }

  test_blockBody_singleStatement_methodCall_explicitTarget() async {
    await assertDiagnosticsFromMarkup(r'''
void f(D d, List<int> list) {
  [!for (final a in list) {
    d.f(a);
  }!]
}
class D {
  void f(int a) {}
}
''');
  }

  test_blockBody_singleStatement_methodCall_forVariableIsInTarget() async {
    await assertNoDiagnostics(r'''
void f(List<D> list) {
  for (final d in list) {
    list[list.indexOf(d)].f(d);
  }
}
class D {
  void f(D d) {}
}
''');
  }

  test_blockBody_singleStatement_methodCall_forVariableIsTarget() async {
    await assertNoDiagnostics(r'''
void f(List<D> list) {
  for (final d in list) {
    d.f(d);
  }
}
class D {
  void f(D d) {}
}
''');
  }

  test_blockBody_singleStatement_parenthesizedFunctionCall() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> list, void Function(int) fn) {
  [!for (final a in list) {
    (fn(a));
  }!]
}
''');
  }

  test_blockBody_singleStatement_staticMethodCall() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> list) {
  [!for (final a in list) {
    C.f(a);
  }!]
}
class C {
  static void f(int a) {}
}
''');
  }

  test_nonBlockBody_singleStatement() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> list, void Function(int) fn) {
  [!for (final a in list) fn(a);!]
}
''');
  }
}
