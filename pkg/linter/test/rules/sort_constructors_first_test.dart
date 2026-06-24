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
    await assertDiagnosticsFromMarkup(r'''
enum E(int x) {
  v(1);
  void f() {}
  [!this!];
}
''');
  }

  test_extensionType_primaryConstructorBody_afterMethod() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(int x) {
  void f() {}
  [!this!];
}
''');
  }

  test_fieldBeforeConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class A {
  final a = 0;
  [!A!]();
}
''');
  }

  test_fieldBeforeConstructor_newHead_named() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class A {
  final a = 0;
  [!new named!]();
}
''');
  }

  test_fieldBeforeConstructor_newHead_unnamed() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class A {
  final a = 0;
  [!new!]();
}
''');
  }

  test_method_betweenConstructors_withPrimaryConstructorBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C() {
  this;
  void f() {}
  [!C.named!]() : this();
}
''');
  }

  test_methodBeforeConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class A {
  void f();
  const [!A!]();
}
''');
  }

  test_methodBeforeConstructor_extensionType() async {
    // Since the check logic is shared w/ classes and enums, one test should
    // provide sufficient coverage for extension types.
    await assertDiagnosticsFromMarkup(r'''
extension type E(Object o) {
  void f() {}
  [!E.e!](this.o);
}
''');
  }

  test_methodBeforeConstructors() async {
    await assertDiagnosticsFromMarkup(r'''
abstract class A {
  void f();
  /*[0*/A/*0]*/();
  /*[1*/A.named/*1]*/();
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C() {
  void f() {}
  [!this!];
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
abstract class A {
  static final a = 0;
  [!A!]();
}
''');
  }

  test_unsorted() async {
    await assertDiagnosticsFromMarkup(r'''
enum A {
  a,b,c;
  int f() => 0;
  const [!A!]();
}
''');
  }
}
