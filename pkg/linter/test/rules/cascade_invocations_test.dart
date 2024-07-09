// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CascadeInvocationsTest);
  });
}

@reflectiveTest
class CascadeInvocationsTest extends LintRuleTest {
  @override
  String get lintRule => 'cascade_invocations';

  test_assignmentDependsOnTarget() async {
    await assertNoDiagnostics(r'''
class C {
  Object d = D();
}
class D {
  D d = D();
}
void f(C c) {
  var d = c.d as D;
  d.d = d;
}
''');
  }

  test_assignmentThenMethodCall() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list = [];
  list.clear();
}
''', [
      lint(40, 13),
    ]);
  }

  test_consecutiveMethodCalls_thenDifferentTarget() async {
    await assertDiagnostics(r'''
class C {
  late C parent;
  late C c;

  void bar() {
    c.bar();
    c.bar();
    parent.c.bar();
  }
}
''', [
      lint(72, 8),
    ]);
  }

  test_methodCallDependsOnTarget() async {
    await assertNoDiagnostics(r'''
class C {
  Object d = D();
}
class D {
  void foo(D d) {}
}
void f(C c) {
  var d = c.d as D;
  d.foo(d);
}
''');
  }

  test_methodCallThenNullAwareAccess() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c.m();
  c?.m(); // ignore: invalid_null_aware_operator
}
class C {
  void m() {}
}
''');
  }

  test_multipleConsecutiveMethodCalls() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.clear();
  list.clear();
}
''', [
      lint(43, 13),
    ]);
  }

  test_multipleConsecutiveMethodCalls_cascaded() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.clear();
  list.clear();
  list..clear();
}
''', [
      lint(43, 13),
      lint(59, 14),
    ]);
  }

  test_nonConsecutiveReferences() async {
    await assertNoDiagnostics(r'''
void f(Foo a, Foo, b) {
  a.foo();
  b.foo();
  a.bar;
  b.bar;
}
class Foo {
  int get bar => 5;
  void foo() {}
}
''');
  }

  test_nullAwareAccessThenConsecutiveAccess() async {
    await assertDiagnostics(r'''
void f(C c) {
  c?.m(); // ignore: invalid_null_aware_operator
  c.m();
  c.m();
}
class C {
  void m() {}
}
''', [
      lint(74, 6),
    ]);
  }

  test_nullAwareAccessThenMethodCall() async {
    await assertNoDiagnostics(r'''
void f(C c) {
  c?.m(); // ignore: invalid_null_aware_operator
  c.m();
}
class C {
  void m() {}
}
''');
  }

  test_nullAwareAssignment() async {
    await assertDiagnostics(r'''
void f(C? c) {
  c ??= C();
  c.foo = 1;
  c.bar = 2;
}
class C {
  int foo = 0;
  int bar = 0;
}
''', [
      lint(43, 10),
    ]);
  }

  test_oneCallIsAwaited() async {
    await assertNoDiagnostics(r'''
void f() async {
  var list = await Future.value([]);
  list.forEach(print);
}
''');
  }

  test_prefixedTopLevelFunctionCall() async {
    await assertNoDiagnostics(r'''
import 'dart:math' as math;
void f() {
  math.sin(0);
  math.cos(0);
}
''');
  }

  test_selfReferenceInsidePropertyAssignment() async {
    // https://github.com/dart-lang/linter/issues/339
    await assertNoDiagnostics(r'''
void f() {
  var c = C();
  c.a = [
    A()
      ..x = ''
      ..y = 'x_${c.hashCode}'
  ];
}
class A {
  String x = '';
  String y = '';
}
class C {
  List<A> a = [A()];
}
''');
  }

  test_staticMethods() async {
    await assertNoDiagnostics(r'''
void f() {
  C.m();
  C.n();
}
class C {
  static int m() => 0;
  static int n() => 0;
}
''');
  }

  test_staticSetters() async {
    // https://github.com/dart-lang/linter/issues/694
    await assertNoDiagnostics(r'''
void f() {
  C.bar = 2;
  C.foo = 3;
}
class C {
  static int foo = 0;
  static int bar = 1;
}
''');
  }

  test_twoConsecutiveMethodCalls() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.clear();
  list.clear();
}
''', [
      lint(43, 13),
    ]);
  }
}
