// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUseFromSamePackageTest);
  });
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackageTest extends LintRuleTest {
  @override
  String get lintRule => 'deprecated_member_use_from_same_package';

  @override
  Future<void> assertDiagnostics(
      String code, List<ExpectedDiagnostic> expectedDiagnostics) async {
    addTestFile(code);
    await resolveTestFile();
    var filteredErrors = errors
        .whereNot((e) =>
            e.errorCode == HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE ||
            e.errorCode ==
                HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE)
        .toList();
    await assertDiagnosticsIn(filteredErrors, expectedDiagnostics);
  }

  test_deprecatedCallMethod() async {
    await assertDiagnostics(r'''
class C {
  @deprecated
  void call() {}
}

void f(C c) => c();
''', [
      lint(59, 3),
    ]);
  }

  test_deprecatedClass() async {
    await assertDiagnostics(r'''
@deprecated
class C {}

void f(C c) {}
''', [
      lint(31, 1),
    ]);
  }

  test_deprecatedClass_usedInClassTypeAlias() async {
    await assertDiagnostics(r'''
@deprecated
mixin class C {}

class D = Object with C;
''', [
      lint(52, 1),
    ]);
  }

  test_deprecatedClass_usedInDeprecatedClassTypeAlias() async {
    await assertNoDiagnostics(r'''
@deprecated
mixin class C {}

@deprecated
class D = Object with C;
''');
  }

  test_deprecatedClass_usedInDeprecatedDefaultParameter() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

void f({@deprecated C? c = null}) {}
''');
  }

  test_deprecatedClass_usedInDeprecatedEnum() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
enum E {
  one, two;

  void f(C c) {}
}
''');
  }

  test_deprecatedClass_usedInDeprecatedExtension() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
extension E on C {}
''');
  }

  test_deprecatedClass_usedInDeprecatedExtensionTypeRepresentation() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
extension type E(C c) { }
''');
  }

  test_deprecatedClass_usedInDeprecatedField_initializer() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

class D {
  @deprecated
  Object f = C;
}
''');
  }

  test_deprecatedClass_usedInDeprecatedField_typeAnnotation() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

class D {
  @deprecated
  C? f;
}
''');
  }

  test_deprecatedClass_usedInDeprecatedFieldFormalParameter() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

class D {
  Object c;
  D({@deprecated required C this.c});
}
''');
  }

  test_deprecatedClass_usedInDeprecatedFunctionTypeAlias() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
typedef void Callback(C c);
''');
  }

  test_deprecatedClass_usedInDeprecatedFunctionTypedParameter() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

void f({@deprecated required void p(C c)}) {}
''');
  }

  test_deprecatedClass_usedInDeprecatedLibrary() async {
    await assertNoDiagnostics(r'''
@deprecated
library a;

@deprecated
class C {}

C? x;
''');
  }

  test_deprecatedClass_usedInDeprecatedMixin() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
mixin M {
  C? x;
}
''');
  }

  test_deprecatedClass_usedInDeprecatedSimpleParameter() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

void f({@deprecated C? c}) {}
''');
  }

  test_deprecatedClass_usedInDeprecatedTopLevelVariable() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
C? x;
''');
  }

  test_deprecatedClass_usedInExtensionTypeRepresentation() async {
    await assertDiagnostics(r'''
@deprecated
class C {}

extension type E(C c) { }
''', [
      lint(41, 1),
    ]);
  }

  test_deprecatedClass_usedInFieldFormalParameter() async {
    await assertDiagnostics(r'''
@deprecated
class C {}

class D {
  Object c;
  D({required C this.c});
}
''', [
      lint(60, 1),
    ]);
  }

  test_deprecatedClass_usedInFunctionTypeAlias() async {
    await assertDiagnostics(r'''
@deprecated
class C {}

typedef void Callback(C c);
''', [
      lint(46, 1),
    ]);
  }

  test_deprecatedClass_usedInFunctionTypedParameter() async {
    await assertDiagnostics(r'''
@deprecated
class C {}

void f({void p(C c)?}) {}
''', [
      lint(39, 1),
    ]);
  }

  test_deprecatedClass_usedInGenericFunctionTypeAlias() async {
    await assertNoDiagnostics(r'''
@deprecated
class C {}

@deprecated
typedef Callback = void Function(C);
''');
  }

  test_deprecatedClass_usedInGenericTypeAlias() async {
    await assertDiagnostics(r'''
@deprecated
class C {}

typedef Callback = void Function(C);
''', [
      lint(57, 1),
    ]);
  }

  test_deprecatedClass_usedInHideCombinator() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
class C {}
''');
    await assertDiagnostics(r'''
import 'lib.dart' hide C;
''', [
      // No lint.
      error(WarningCode.UNUSED_IMPORT, 7, 10),
    ]);
  }

  test_deprecatedClass_usedInShowCombinator() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
class C {}
''');
    await assertDiagnostics(r'''
import 'lib.dart' show C;
''', [
      error(WarningCode.UNUSED_IMPORT, 7, 10),
      lint(23, 1),
    ]);
  }

  test_deprecatedConstructor_usedInSuperConstructorCall() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  A();
}
class B extends A {
  B() : super();
}
''', [
      lint(61, 7),
    ]);
  }

  test_deprecatedDefaultParameterOfFunction() async {
    await assertDiagnostics(r'''
void f({@deprecated int p = 1}) {}

void g() => f(p: 1);
''', [
      lint(50, 1),
    ]);
  }

  test_deprecatedEnum() async {
    await assertDiagnostics(r'''
@deprecated
enum E {
  one, two;
}
late E e;
''', [
      lint(40, 1),
    ]);
  }

  test_deprecatedEnumValue() async {
    await assertDiagnostics(r'''
enum E {
  one, @deprecated two;
}
late E e = E.two;
''', [
      lint(48, 3),
    ]);
  }

  test_deprecatedExtension_usedInExtensionOverride_getter() async {
    await assertDiagnostics(r'''
@deprecated
extension E on int {
  int get foo => 1;
}

var x = E(0).foo;
''', [
      lint(64, 1),
    ]);
  }

  test_deprecatedExtension_usedInExtensionOverride_methodInvocation() async {
    await assertDiagnostics(r'''
@deprecated
extension E on int {
  void f() {}
}

var x = E(0).f();
''', [
      lint(58, 1),
    ]);
  }

  test_deprecatedExtensionType_usedInExtensionTypeImplements() async {
    await assertDiagnostics(r'''
@deprecated
extension type E(int i) { }

extension type F(int i) implements E { }
''', [
      lint(76, 1),
    ]);
  }

  test_deprecatedExtensionType_usedInExtensionTypeRepresentation() async {
    await assertDiagnostics(r'''
@deprecated
extension type E(int i) { }

extension type F(E c) { }
''', [
      lint(58, 1),
    ]);
  }

  test_deprecatedExtensionType_usedInField() async {
    await assertDiagnostics(r'''
@deprecated
extension type E(int i) { }

class C {
  E? e;
}
''', [
      lint(53, 1),
    ]);
  }

  test_deprecatedExtensionType_usedInFunctionParam() async {
    await assertDiagnostics(r'''
@deprecated
extension type E(int i) { }

void f(E e) { }
''', [
      lint(48, 1),
    ]);
  }

  test_deprecatedField_usedAsGetter() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  a.f;
}
''', [
      lint(58, 1),
    ]);
  }

  test_deprecatedField_usedAsSetter() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  a.f = 1;
}
''', [
      lint(58, 1),
    ]);
  }

  test_deprecatedField_usedInDeprecatedClass() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

@deprecated
class B {
  void f(A a) {
    a.f;
    a.f = 1;
  }
}
''');
  }

  test_deprecatedField_usedInDeprecatedFunction() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

@deprecated
void f(A a) {
  a.f;
  a.f = 1;
}
''');
  }

  test_deprecatedField_usedInPostfix() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  a.f++;
}
''', [
      lint(56, 3),
    ]);
  }

  test_deprecatedField_usedInPrefix() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  ++a.f;
}
''', [
      lint(58, 3),
    ]);
  }

  test_deprecatedField_usedInSuper() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  int f = 0;
}

class B extends A {
  int get g => super.f;
}
''', [
      lint(81, 1),
    ]);
  }

  test_deprecatedGetter_usedInAssignment() async {
    await assertNoDiagnostics(r'''
@deprecated
int get x => 1;

set x(int value) {}

void f() {
  x = 1;
}
''');
  }

  test_deprecatedGetter_usedInCompoundAssignment() async {
    await assertDiagnostics(r'''
@deprecated
int get x => 1;

set x(int value) {}

void f() {
  x += 1;
}
''', [
      lint(63, 1),
    ]);
  }

  test_deprecatedIndexOperator() async {
    await assertDiagnostics(r'''
class C {
  @deprecated
  int operator[](int p) => 1;
}

void f(C c) {
  c[1];
}
''', [
      lint(73, 4),
    ]);
  }

  test_deprecatedLibrary_export() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
library a;
''');
    await assertDiagnostics(r'''
export 'lib.dart';
''', [
      lint(0, 18),
    ]);
  }

  test_deprecatedLibrary_import() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
library a;
''');
    await assertDiagnostics(r'''
import 'lib.dart';
''', [
      lint(0, 18),
      error(WarningCode.UNUSED_IMPORT, 7, 10),
    ]);
  }

  test_deprecatedMethod() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  void m() {}

  void m2() {
    m();
  }
}
''', [
      lint(57, 1),
    ]);
  }

  test_deprecatedMethod_usedInDeprecatedConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  void m() {}

  @deprecated
  A() {
    m();
  }
}
''');
  }

  test_deprecatedMethod_usedInDeprecatedSubclassConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  @deprecated
  void m() {}
}
class B extends A {
  @deprecated
  B() {
    m();
  }
}
''');
  }

  test_deprecatedMethod_withMessage() async {
    await assertDiagnostics(r'''
class A {
  @Deprecated('Message')
  void m() {}

  void m2() {
    m();
  }
}
''', [
      lint(68, 1),
    ]);
  }

  test_deprecatedNamedConstructor() async {
    await assertDiagnostics(r'''
class C {
  @deprecated
  C.named();
}

var x = C.named();
''', [
      lint(48, 7),
    ]);
  }

  test_deprecatedNamedConstructor_usedInSuperConstructorCall() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  A.named();
}
class B extends A {
  B() : super.named();
}
''', [
      lint(67, 13),
    ]);
  }

  test_deprecatedNamedParameterOfFunction() async {
    await assertDiagnostics(r'''
void f({@deprecated int? p}) {}

void g() => f(p: 1);
''', [
      lint(47, 1),
    ]);
  }

  test_deprecatedNamedParameterOfFunction_usedInDeclaringFunction() async {
    await assertNoDiagnostics(r'''
int? f({@deprecated int? p}) => p;
''');
  }

  test_deprecatedNamedParameterOfMethod() async {
    await assertDiagnostics(r'''
class C {
  void f({@deprecated int? p}) {}

  void g() => f(p: 1);
}
''', [
      lint(61, 1),
    ]);
  }

  test_deprecatedOperator() async {
    await assertDiagnostics(r'''
class C {
  @deprecated
  C operator+(int other) => C();
}
void f(C c) {
  c + 1;
}
''', [
      lint(75, 5),
    ]);
  }

  test_deprecatedOperator_usedInCompoundAssignment() async {
    await assertDiagnostics(r'''
class C {
  @deprecated
  C operator+(int other) => C();
}
void f(C c) {
  c += 1;
}
''', [
      lint(75, 6),
    ]);
  }

  test_deprecatedParameterOfConstructor_usedInDeclaringConstructorBody() async {
    await assertNoDiagnostics(r'''
class C {
  C({@deprecated int? p}) {
    p;
  }
}
''');
  }

  test_deprecatedParameterOfConstructor_usedInDeclaringConstructorInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  C({@deprecated int? p}) : assert(p == null || p > 0);
}
''');
  }

  test_deprecatedParameterOfConstructor_usedInRedirectingConstructor() async {
    await assertDiagnostics(r'''
class C {
  C({@deprecated int? p});
  C.two() : this(p: 0);
}
''', [
      lint(54, 1),
    ]);
  }

  test_deprecatedPositionalParameterOfFunction() async {
    await assertDiagnostics(r'''
void f([@deprecated int? p]) {}

void g() => f(1);
''', [
      lint(47, 1),
    ]);
  }

  test_deprecatedSetter() async {
    await assertDiagnostics(r'''
@deprecated set f(int value) {}

void g() => f = 1;
''', [
      lint(45, 1),
    ]);
  }

  test_deprecatedSetter_usedInCompoundAssignment() async {
    await assertDiagnostics(r'''
int get x => 1;

@deprecated
set x(int value) {}

void f() {
  x += 1;
}
''', [
      lint(63, 1),
    ]);
  }

  test_deprecatedStaticField() async {
    await assertDiagnostics(r'''
class A {
  @deprecated
  static int f = 0;
}

var a = A.f;
''', [
      lint(57, 1),
    ]);
  }

  test_deprecatedTopLevelVariable_usedInAssignment() async {
    await assertDiagnostics(r'''
@deprecated
int x = 1;

void f() {
  x = 1;
}
''', [
      lint(37, 1),
    ]);
  }

  test_deprecatedUnnamedConstructor() async {
    await assertDiagnostics(r'''
class C {
  @deprecated
  C();
}

var x = C();
''', [
      lint(42, 1),
    ]);
  }
}
