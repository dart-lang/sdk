// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidReturningThisTest);
  });
}

@reflectiveTest
class AvoidReturningThisTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_returning_this';

  /// https://github.com/dart-lang/linter/issues/3853
  test_conditionalReturn() async {
    await assertNoDiagnostics(r'''
class C {
  C getInstance(C? c) {
    if (c == null) return this;
    return c;
  }
}
''');
  }

  test_conditionalReturn_expression_ternary() async {
    await assertNoDiagnostics(r'''
class C {
  C getInstance(C? c) => c == null ? this : c;
}
''');
  }

  test_conditionalReturn_ternary() async {
    await assertNoDiagnostics(r'''
class C {
  C getInstance(C? c) {
    return c == null ? this : c;
  }
}
''');
  }

  test_extensionMethodReturnsThis() async {
    await assertNoDiagnostics(r'''
class A {}
extension Ext on A {
  A m() => this;
}
''');
  }

  test_getterReturnsThis_arrow_subclassOfGeneric_definedInInterface() async {
    await assertNoDiagnostics(r'''
abstract class C<T> {
  T get g;
}
class E implements C<E> {
  @override
  E get g => this;
}
''');
  }

  test_getterReturnsThis_block_subclassOfGeneric_definedInInterface() async {
    await assertNoDiagnostics(r'''
abstract class C<T> {
  T get g;
}
class E implements C<E> {
  @override
  E get g {
    return this;
  }
}
''');
  }

  test_methodReturnsNotThis() async {
    await assertNoDiagnostics(r'''
class A {
  int x = 1;
  int goodAddOne2() {
    x++;
    return this.x;
  }
}
''');
  }

  test_methodReturnsThis() async {
    await assertDiagnostics(r'''
class A {
  A m() {
    return this;
  }
}
''', [
      lint(31, 4),
    ]);
  }

  test_methodReturnsThis_arrow_subclassOfGeneric_definedInInterface() async {
    await assertNoDiagnostics(r'''
abstract class C<T> {
  T m();
}
class E implements C<E> {
  E m() => this;
}
''');
  }

  test_methodReturnsThis_block_subclassOfGeneric_definedInInterface() async {
    await assertNoDiagnostics(r'''
abstract class C<T> {
  T m();
}
class E implements C<E> {
  E m() {
    return this;
  }
}
''');
  }

  test_methodReturnsThis_containsFunctionExpressionWithBlockBody() async {
    await assertDiagnostics(r'''
class A {
  int x = 1;
  A m() {
    final a = () {
      return 1;
    };
    x = a();
    return this;
  }
}
''', [
      lint(99, 4),
    ]);
  }

  test_methodReturnsThis_containsFunctionExpressionWithExpressionBody() async {
    await assertDiagnostics(r'''
class A {
  int x = 1;
  A m() {
    int a() => 1;
    x = a();
    return this;
  }
}
''', [
      lint(75, 4),
    ]);
  }

  test_methodReturnsThis_inEnum() async {
    await assertDiagnostics(r'''
enum A {
  a, b, c;
  A m() => this;
}
''', [
      lint(24, 1),
    ]);
  }

  test_methodReturnsThis_otherReturnType() async {
    await assertNoDiagnostics(r'''
class A {
  Object m() {
    return this;
  }
}
''');
  }

  test_methodReturnsThis_subclass_definedInInterface() async {
    await assertNoDiagnostics(r'''
abstract class A {
  A m();
}
class B extends A {
  @override
  B m() {
    return this;
  }
}
''');
  }

  test_methodReturnsThis_subclass_notDefinedInInterface() async {
    await assertDiagnostics(r'''
class A {}
class B extends A{
  B m() {
    return this;
  }
}
''', [
      lint(51, 4),
    ]);
  }

  test_operatorReturnsThis() async {
    await assertNoDiagnostics(r'''
class A {
  A operator +(int n) {
    return this;
  }
}
''');
  }
}
