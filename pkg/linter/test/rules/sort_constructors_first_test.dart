// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortConstructorsFirstTest);
  });
}

@reflectiveTest
class SortConstructorsFirstTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.sort_constructors_first;

  test_constructor_afterPrimaryConstructorBody() async {
    await assertNoDiagnostics(r'''
class C() {
  this;
  C.named() : this();
}
''');
  }

  test_constructorBeforeMethod() async {
    await assertNoDiagnostics(r'''
abstract class A {
  const A();
  void f();
}
''');
  }

  test_enum_afterPrimaryConstructorBody() async {
    await assertNoDiagnostics(r'''
enum E(int x) {
  v(1);
  this;
  const E.named() : this(2);
}
''');
  }

  test_enum_primaryConstructorBody_afterMethod() async {
    await assertDiagnostics(
      r'''
enum E(int x) {
  v(1);
  void f() {}
  this;
}
''',
      [lint(40, 4)],
    );
  }

  test_extensionType_primaryConstructorBody_afterMethod() async {
    await assertDiagnostics(
      r'''
extension type E(int x) {
  void f() {}
  this;
}
''',
      [lint(42, 4)],
    );
  }

  test_fieldBeforeConstructor() async {
    await assertDiagnostics(
      r'''
abstract class A {
  final a = 0;
  A();
}
''',
      [lint(36, 1)],
    );
  }

  test_fieldBeforeConstructor_newHead_named() async {
    await assertDiagnostics(
      r'''
abstract class A {
  final a = 0;
  new named();
}
''',
      [lint(36, 9)],
    );
  }

  test_fieldBeforeConstructor_newHead_unnamed() async {
    await assertDiagnostics(
      r'''
abstract class A {
  final a = 0;
  new();
}
''',
      [lint(36, 3)],
    );
  }

  test_method_betweenConstructors_withPrimaryConstructorBody() async {
    await assertDiagnostics(
      r'''
class C() {
  this;
  void f() {}
  C.named() : this();
}
''',
      [lint(36, 7)],
    );
  }

  test_methodBeforeConstructor() async {
    await assertDiagnostics(
      r'''
abstract class A {
  void f();
  const A();
}
''',
      [lint(39, 1)],
    );
  }

  test_methodBeforeConstructor_extensionType() async {
    // Since the check logic is shared w/ classes and enums, one test should
    // provide sufficient coverage for extension types.
    await assertDiagnostics(
      r'''
extension type E(Object o) {
  void f() {}
  E.e(this.o);
}
''',
      [lint(45, 3)],
    );
  }

  test_methodBeforeConstructors() async {
    await assertDiagnostics(
      r'''
abstract class A {
  void f();
  A();
  A.named();
}
''',
      [lint(33, 1), lint(40, 7)],
    );
  }

  test_ok() async {
    await assertNoDiagnostics(r'''
enum A {
  a,b,c;
  const A();
  int f() => 0;
}
''');
  }

  test_primaryConstructorBody_afterMethod() async {
    await assertDiagnostics(
      r'''
class C() {
  void f() {}
  this;
}
''',
      [lint(28, 4)],
    );
  }

  test_primaryConstructorBody_amongConstructors() async {
    await assertNoDiagnostics(r'''
class C() {
  C.named() : this();
  this;
}
''');
  }

  test_primaryConstructorBody_beforeMethod() async {
    await assertNoDiagnostics(r'''
class C() {
  this;
  void f() {}
}
''');
  }

  test_staticFieldBeforeConstructor() async {
    await assertDiagnostics(
      r'''
abstract class A {
  static final a = 0;
  A();
}
''',
      [lint(43, 1)],
    );
  }

  test_unsorted() async {
    await assertDiagnostics(
      r'''
enum A {
  a,b,c;
  int f() => 0;
  const A();
}
''',
      [lint(42, 1)],
    );
  }
}
