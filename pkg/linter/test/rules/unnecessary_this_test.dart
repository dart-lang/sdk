// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullChecksTest);
  });
}

@reflectiveTest
class UnnecessaryNullChecksTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_this;

  test_closureInMethod() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m1(List<int> list) {
    list.forEach((e) {
      [!this!].m2(e);
    });
  }
  void m2(int x) {}
}
''');
  }

  test_constructorBody_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  num x = 0;
  A.named(num a) {
    [!this!].x = a;
  }
}
''');
  }

  test_constructorBody_methodCall() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A.named() {
    [!this!].m();
  }

  void m() {}
}
''');
  }

  test_constructorBody_primary_assignment() async {
    await assertDiagnosticsFromMarkup(r'''
class A.named(num a) {
  num x = 0;
  this {
    [!this!].x = a;
  }
}
''');
  }

  test_constructorBody_primary_shadowedParameters() async {
    await assertNoDiagnostics(r'''
class A(num x) {
  num x = 0;
  this {
    this.x = x;
  }
}
''');
  }

  test_constructorBody_shadowedParameters() async {
    await assertNoDiagnostics(r'''
class A {
  num x = 0;
  A(num x) {
    this.x = x;
  }
}
''');
  }

  test_constructorInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  num x = 0;
  A.c1(num x)
      : [!this!].x = x;
}
''');
  }

  test_constructorInitializer_primary() async {
    await assertDiagnosticsFromMarkup(r'''
class A(num x) {
  num x;
  this : [!this!].x = x;
}
''');
  }

  test_extension_getter() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  int? get h => this?.hashCode;
}
''');
  }

  test_extension_method() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  String? f() => this?.toString();
}
''');
  }

  test_extensionType_inConstructorInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(int i) {
  E.e(int i) : [!this!].i = i.hashCode;
}
''');
  }

  test_extensionType_inMethod() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(Object o) {
  String m()=> [!this!].toString();
}
''');
  }

  test_initializingFormalParameter() async {
    await assertNoDiagnostics(r'''
class A {
  num x = 0, y = 0;
  A.bar(this.x, this.y);
}
''');
  }

  test_localFunctionPresent() async {
    await assertNoDiagnostics(r'''
class A {
  void m1() {
    if (true) {
      // ignore: unused_element
      void m2() {}
      this.m2();
    }
  }
  void m2() {}
}
''');
  }

  test_localFunctionPresent_outOfScope() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m1() {
    if (true) {
      // ignore: unused_element
      void m2() {}
    }
    [!this!].m2();
  }
  void m2() {}
}
''');
  }

  test_method_ofGenericClass_noShadow_fromSelf() async {
    await assertDiagnosticsFromMarkup(r'''
class A<T> {
  T foo() => throw 0;

  void bar() {
    [!this!].foo();
  }
}
''');
  }

  test_method_ofGenericClass_noShadow_fromSuper() async {
    await assertDiagnosticsFromMarkup(r'''
class A<T> {
  T foo() => throw 0;
}

class B extends A<int> {
  void bar() {
    [!this!].foo();
  }
}
''');
  }

  test_shadowInIfCaseClause() async {
    await assertNoDiagnostics(r'''
class A {
  int? value;

  void m(A a) {
    if (a case A(:var value) when value != this.value) {}
  }
}
''');
  }

  test_shadowInMethodBody() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 0;

  void m(bool b) {
    var x = this.x;
    print(x);
  }
}
''');
  }

  test_shadowInObjectPattern() async {
    await assertNoDiagnostics(r'''
class C {
  Object? value;
  bool equals(Object other) => switch (other) {
        C(:var value) => this.value == value,
        _ => false,
      };
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4457
  test_shadowInSwitchPatternCase() async {
    await assertNoDiagnostics(r'''
class C {
  int x = 0;

  int m(bool b) {
    switch (b) {
      case true:
        var x = this.x;
        return x;
      case false:
        return 7;
    }
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4457
  test_shadowInSwitchPatternCase2() async {
    await assertNoDiagnostics(r'''
class C {
  bool isEven = false;

  bool m(int p) {
    switch (p) {
      case int(:var isEven) when isEven:
        isEven = this.isEven;
        return isEven;
      default:
        return false;
    }
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4457
  test_shadowInSwitchPatternCase3() async {
    await assertNoDiagnostics(r'''
class C {
  bool isEven = false;

  bool m(int p) {
    switch (p) {
      case int(:var isEven) when this.isEven:
        isEven = this.isEven;
        return isEven;
      default:
        return false;
    }
  }
}
''');
  }

  test_subclass_noShadowing() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  int x = 0;
}
class D extends C {
  void f(int a) {
    [!this!].x = a;
  }
}
''');
  }

  test_subclass_shadowedTopLevelVariable() async {
    await assertNoDiagnostics(r'''
int x = 0;
class C {
  int x = 0;
}
class D extends C {
  void m(int a) {
    this.x = a;
  }
}
''');
  }

  test_subclass_topLevelFunctionPresent() async {
    await assertNoDiagnostics(r'''
void m1() {}
class C {
  void m1() {}
}
class D extends C {
  void m2() {
    this.m1();
  }
}
''');
  }
}
