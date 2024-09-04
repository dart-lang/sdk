// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferAssertsInInitializerListsTest);
  });
}

@reflectiveTest
class PreferAssertsInInitializerListsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_asserts_in_initializer_lists';

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
    await assertDiagnostics(r'''
class C {
  int? f;
  C({this.f}) {
    assert(f != null);
  }
}
''', [
      lint(40, 6),
    ]);
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
    await assertDiagnostics(r'''
class C {
  C(int? p) {
    assert(p != null);
  }
}
''', [
      lint(28, 6),
    ]);
  }

  test_assertContainsParameter_consecutive() async {
    await assertDiagnostics(r'''
class C {
  C(int? p) {
    assert(p != null);
    assert(p != null);
  }
}
''', [
      lint(28, 6),
      lint(51, 6),
    ]);
  }

  test_assertContainsParameter_usedInInitializer() async {
    await assertDiagnostics(r'''
class C {
  int? f;
  C({int? f}) : f = f ?? 7 {
    assert(f != null);
  }
}
''', [
      lint(53, 6),
    ]);
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
    await assertDiagnostics(r'''
class C {
  static int? m() => null;
  C() {
    assert(m() != null);
  }
}
''', [
      lint(49, 6),
    ]);
  }

  test_assertContainsStaticProperty() async {
    await assertDiagnostics(r'''
class C {
  static int? get f => null;
  C() {
    assert(f != null);
  }
}
''', [
      lint(51, 6),
    ]);
  }

  test_assertContainsTopLevelMethod() async {
    await assertDiagnostics(r'''
int? m() => null;

class C {
  C() {
    assert(m() != null);
  }
}
''', [
      lint(41, 6),
    ]);
  }

  test_assertContainsTopLevelProperty() async {
    await assertDiagnostics(r'''
int? get f => null;

class C {
  C() {
    assert(f != null);
  }
}
''', [
      lint(43, 6),
    ]);
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
    await assertDiagnostics(r'''
extension type E(int? i) {
  E.e(this.i) {
    assert(i != null);
  }
}
''', [
      lint(47, 6),
    ]);
  }

  test_extensionType_initializer() async {
    await assertNoDiagnostics(r'''
extension type E(int? i) {
  E.e(this.i) : assert(i != null);
}
''');
  }

  test_firstStatement() async {
    await assertDiagnostics(r'''
class A {
  A.named(a) {
    assert(a != null);
  }
}

''', [
      lint(29, 6),
    ]);
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
    await assertDiagnostics(r'''
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
''', [
      // No lint
      error(CompileTimeErrorCode.NON_BOOL_EXPRESSION, 40, 50),
    ]);
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}

class B extends A {
  B(super.a) {
    assert(a != 0);
  }
}
''', [
      lint(80, 6),
    ]);
  }
}
