// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferAssertsInInitializerListsTest);
  });
}

@reflectiveTest
class PreferAssertsInInitializerListsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_asserts_in_initializer_lists;

  test_afterFirstStatement() async {
    await assertNoDiagnostics(r'''
class A {
  A.named(a) {
    print('');
    assert(a != null);
  }
}

''');
  }

  test_assertContainsFieldFormalParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  int? f;
  C({this.f}) {
    [!assert!](f != null);
  }
}
''');
  }

  test_assertContainsInstanceMethod() async {
    await assertNoDiagnostics(r'''
class C {
  C() {
    assert(m());
  }
  bool m() => true;
}
''');
  }

  test_assertContainsInstanceMethod_explicitThis_inSubexpression() async {
    await assertNoDiagnostics(r'''
class C {
  int? m() => null;
  C() {
    assert(this.m() != null);
  }
}
''');
  }

  test_assertContainsInstanceMethod_inSubexpression() async {
    await assertNoDiagnostics(r'''
class C {
  int? m() => null;
  C() {
    assert(m() != null);
  }
}
''');
  }

  test_assertContainsInstanceProperty() async {
    await assertNoDiagnostics(r'''
class C {
  int? get f => null;
  C() {
    assert(f != null);
  }
}
''');
  }

  test_assertContainsInstanceProperty_explicitThis() async {
    await assertNoDiagnostics(r'''
class C {
  int? get f => null;
  C() {
    assert(this.f != null);
  }
}
''');
  }

  test_assertContainsInstancePropertyOfMixin() async {
    await assertNoDiagnostics(r'''
mixin M {
  var a;
}

class C with M {
  C() {
    assert(a != null);
  }
}
''');
  }

  test_assertContainsInstancePropertyOfSuperClass() async {
    await assertNoDiagnostics(r'''
class C {
  bool get foo => true;
}

class D extends C {
  D() {
    assert(foo);
  }
}
''');
  }

  test_assertContainsInstancePropertyOfSuperClass_inSubexpression() async {
    await assertNoDiagnostics(r'''
class C {
  int? get f => null;
}

class D extends C {
  D() {
    assert(f != null);
  }
}
''');
  }

  test_assertContainsParameter() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C(int? p) {
    [!assert!](p != null);
  }
}
''');
  }

  test_assertContainsParameter_consecutive() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  C(int? p) {
    /*[0*/assert/*0]*/(p != null);
    /*[1*/assert/*1]*/(p != null);
  }
}
''');
  }

  test_assertContainsParameter_usedInInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  int? f;
  C({int? f}) : f = f ?? 7 {
    [!assert!](f != null);
  }
}
''');
  }

  test_assertContainsSimpleParameter() async {
    await assertNoDiagnostics(r'''
class C {
  int? f;
  factory C({int? f}) {
    assert(f != null);
    return C.named();
  }
  C.named();
}
''');
  }

  test_assertContainsStaticMethod() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static int? m() => null;
  C() {
    [!assert!](m() != null);
  }
}
''');
  }

  test_assertContainsStaticProperty() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static int? get f => null;
  C() {
    [!assert!](f != null);
  }
}
''');
  }

  test_assertContainsTopLevelMethod() async {
    await assertDiagnosticsFromMarkup(r'''
int? m() => null;

class C {
  C() {
    [!assert!](m() != null);
  }
}
''');
  }

  test_assertContainsTopLevelProperty() async {
    await assertDiagnosticsFromMarkup(r'''
int? get f => null;

class C {
  C() {
    [!assert!](f != null);
  }
}
''');
  }

  test_assertFollowsStatement() async {
    await assertNoDiagnostics(r'''
class C {
  C(int? p) {
    print('');
    assert(p != null);
  }
}
''');
  }

  test_extensionType() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(int? i) {
  E.e(this.i) {
    [!assert!](i != null);
  }
}
''');
  }

  test_extensionType_initializer() async {
    await assertNoDiagnostics(r'''
extension type E(int? i) {
  E.e(this.i) : assert(i != null);
}
''');
  }

  test_extensionType_primaryConstructorBody() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(int? i) {
  this {
    [!assert!](i != null);
  }
}
''');
  }

  test_firstStatement() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A.named(a) {
    [!assert!](a != null);
  }
}

''');
  }

  test_initializer() async {
    await assertNoDiagnostics(r'''
class A {
  A.named(a) : assert(a != null);
}

''');
  }

  test_noAsserts() async {
    await assertNoDiagnostics(r'''
class C {
  C(int p) {}
}
''');
  }

  test_nonBoolExpression() async {
    await assertDiagnostics(
      r'''
class A {
  bool? f;
  A() {
    assert(()
    {
      f = true;
      return false;
    });
  }
}
''',
      [
        // No lint
        error(diag.nonBoolExpression, 40, 50),
      ],
    );
  }

  test_primaryConstructorBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C(int? x) {
  this {
    [!assert!](x != null);
  }
}
''');
  }

  test_primaryConstructorBody_dependsOnInstanceProperty() async {
    await assertNoDiagnostics(r'''
class C(var int x) {
  int get y => x;
  this {
    assert(y > 0);
  }
}
''');
  }

  test_super() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  final int a;
  A(this.a);
}

class B extends A {
  B(super.a) {
    [!assert!](a != 0);
  }
}
''');
  }
}
