// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Add tests with non-block-bodies for the for loop. Add
    // tests with multiple statements in the body.
    defineReflectiveTests(PreferForeachTest);
  });
}

@reflectiveTest
class PreferForeachTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_foreach';

  test_blockBody_singleStatement_functionCall() async {
    await assertDiagnostics(r'''
void f(List<int> list, void Function(int) fn) {
  for (final a in list) {
    fn(a);
  }
}
''', [
      lint(50, 38),
    ]);
  }

  test_blockBody_singleStatement_functionTypedExpressionCall() async {
    await assertDiagnostics(r'''
void Function(int) fn() => (int a) {};

void f(List<int> list) {
  for (final a in list) {
    fn()(a);
  }
}
''', [
      lint(67, 40),
    ]);
  }

  test_blockBody_singleStatement_methodCall() async {
    await assertDiagnostics(r'''
class C {
  void f(int o) {}

  void foo(List<int> list) {
    for (final a in list) {
      f(a);
    }
  }
}
''', [
      lint(63, 41),
    ]);
  }

  test_blockBody_singleStatement_methodCall_explicitTarget() async {
    await assertDiagnostics(r'''
void f(D d, List<int> list) {
  for (final a in list) {
    d.f(a);
  }
}
class D {
  void f(int a) {}
}
''', [
      lint(32, 39),
    ]);
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
    await assertDiagnostics(r'''
void f(List<int> list, void Function(int) fn) {
  for (final a in list) {
    (fn(a));
  }
}
''', [
      lint(50, 40),
    ]);
  }

  test_blockBody_singleStatement_staticMethodCall() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  for (final a in list) {
    C.f(a);
  }
}
class C {
  static void f(int a) {}
}
''', [
      lint(27, 39),
    ]);
  }
}
