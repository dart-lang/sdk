// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullChecksTest);
  });
}

@reflectiveTest
class UnnecessaryNullChecksTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_this';

  test_closureInMethod() async {
    await assertDiagnostics(r'''
class A {
  void m1(List<int> list) {
    list.forEach((e) {
      this.m2(e);
    });
  }
  void m2(int x) {}
}
''', [
      lint(67, 10),
    ]);
  }

  test_constructorBody_assignment() async {
    await assertDiagnostics(r'''
class A {
  num x = 0;
  A.named(num a) {
    this.x = a;
  }
}
''', [
      lint(46, 6),
    ]);
  }

  test_constructorBody_methodCall() async {
    await assertDiagnostics(r'''
class A {
  A.named() {
    this.m();
  }

  void m() {}
}
''', [
      lint(28, 8),
    ]);
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
    await assertDiagnostics(r'''
class A {
  num x = 0;
  A.c1(num x)
      : this.x = x;
}
''', [
      lint(45, 4),
    ]);
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
    await assertDiagnostics(r'''
extension type E(int i) {
  E.e(int i) : this.i = i.hashCode;
}
''', [
      lint(41, 4),
    ]);
  }

  test_extensionType_inMethod() async {
    await assertDiagnostics(r'''
extension type E(Object o) {
  String m()=> this.toString();
}
''', [
      lint(44, 15),
    ]);
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
    await assertDiagnostics(r'''
class A {
  void m1() {
    if (true) {
      // ignore: unused_element
      void m2() {}
    }
    this.m2();
  }
  void m2() {}
}
''', [
      lint(101, 9),
    ]);
  }

  test_shadowInObjectPattern() async {
    await assertNoDiagnostics(r'''
class C {
  Object? value;
  bool equals(Object other) =>
      switch (other) { C(:var value) => this.value == value, _ => false };
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4457
  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/4457')
  test_shadowSwitchPatternCase() async {
    await assertNoDiagnostics(r'''
class C {
  String? name;

  void m(bool b) {
    switch (b) {
      case true:
        var name = this.name!;
        print(name);
      case false:
        break;
    }
  }
}
''');
  }

  test_subclass_noShadowing() async {
    await assertDiagnostics(r'''
class C {
  int x = 0;
}
class D extends C {
  void f(int a) {
    this.x = a;
  }
}
''', [
      lint(67, 6),
    ]);
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
