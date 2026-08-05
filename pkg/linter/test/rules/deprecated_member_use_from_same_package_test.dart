// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUseFromSamePackageTest);
  });
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackageTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [diag.unusedLocalVariable];

  @override
  String get lintRule => LintNames.deprecated_member_use_from_same_package;

  test_deprecatedCallMethod() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  void call() {}
}

void f(C c) => [!c()!];
''');
  }

  test_deprecatedClass() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class C {}

void f([!C!] c) {}
''');
  }

  test_deprecatedClass_usedInClassTypeAlias() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
mixin class C {}

class D = Object with [!C!];
''');
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
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class C {}

extension type E([!C!] c) { }
''');
  }

  test_deprecatedClass_usedInFieldFormalParameter() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class C {}

class D {
  Object c;
  D({required [!C!] this.c});
}
''');
  }

  test_deprecatedClass_usedInFunctionTypeAlias() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class C {}

typedef void Callback([!C!] c);
''');
  }

  test_deprecatedClass_usedInFunctionTypedParameter() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class C {}

void f({void p([!C!] c)?}) {}
''');
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
    await assertDiagnosticsFromMarkup(r'''
@deprecated
class C {}

typedef Callback = void Function([!C!]);
''');
  }

  test_deprecatedClass_usedInHideCombinator() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
class C {}
''');
    await assertDiagnostics(
      r'''
import 'lib.dart' hide C;
''',
      [
        // No lint.
        error(diag.unusedImport, 7, 10),
      ],
    );
  }

  test_deprecatedClass_usedInShowCombinator() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
class C {}
''');
    await assertDiagnostics(
      r'''
import 'lib.dart' show C;
''',
      [error(diag.unusedImport, 7, 10), lint(23, 1)],
    );
  }

  test_deprecatedConstructor_usedInRedirectingConstructorInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  A();
  A.two() : [!this()!];
}
''');
  }

  test_deprecatedConstructor_usedInSuperConstructorCall() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  A();
}
class B extends A {
  B() : [!super()!];
}
''');
  }

  test_deprecatedConstructor_usedInSuperConstructorCall_implicit() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  A();
}
class B extends A {
  [!B();!]
}
''');
  }

  test_deprecatedDefaultParameterOfFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f({@deprecated int p = 1}) {}

void g() => f([!p!]: 1);
''');
  }

  test_deprecatedEnum() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
enum E {
  one, two;
}
late [!E!] e;
''');
  }

  test_deprecatedEnumValue() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  one, @deprecated two;
}
late E e = E.[!two!];
''');
  }

  test_deprecatedExtension_usedInExtensionOverride_getter() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension E on int {
  int get foo => 1;
}

var x = [!E!](0).foo;
''');
  }

  test_deprecatedExtension_usedInExtensionOverride_methodInvocation() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension E on int {
  void f() {}
}

var x = [!E!](0).f();
''');
  }

  test_deprecatedExtensionType_usedInExtensionTypeImplements() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension type E(int i) { }

extension type F(int i) implements [!E!] { }
''');
  }

  test_deprecatedExtensionType_usedInExtensionTypeRepresentation() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension type E(int i) { }

extension type F([!E!] c) { }
''');
  }

  test_deprecatedExtensionType_usedInField() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension type E(int i) { }

class C {
  [!E!]? e;
}
''');
  }

  test_deprecatedExtensionType_usedInFunctionParam() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
extension type E(int i) { }

void f([!E!] e) { }
''');
  }

  test_deprecatedField_inObjectPattern_explicitName() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @Deprecated('')
  final int foo = 0;
}

int f(Object x) =>
  switch (x) {
    A([!foo!]: var bar) => bar,
    _ => 0,
  };
''');
  }

  test_deprecatedField_inObjectPattern_inferredName() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @Deprecated('')
  final int foo = 0;
}

int f(Object x) =>
  switch (x) {
    A(:var [!foo!]) => foo,
    _ => 0,
  };
''');
  }

  test_deprecatedField_usedAsGetter() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  a.[!f!];
}
''');
  }

  test_deprecatedField_usedAsSetter() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  a.[!f!] = 1;
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  [!a.f!]++;
}
''');
  }

  test_deprecatedField_usedInPrefix() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  int f = 0;
}

void f(A a) {
  ++[!a.f!];
}
''');
  }

  test_deprecatedField_usedInSuper() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  int f = 0;
}

class B extends A {
  int get g => super.[!f!];
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
@deprecated
int get x => 1;

set x(int value) {}

void f() {
  [!x!] += 1;
}
''');
  }

  test_deprecatedIndexOperator() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  int operator[](int p) => 1;
}

void f(C c) {
  [!c[1]!];
}
''');
  }

  test_deprecatedLibrary_export() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
library a;
''');
    await assertDiagnosticsFromMarkup(r'''
[!export 'lib.dart';!]
''');
  }

  test_deprecatedLibrary_import() async {
    newFile('$testPackageLibPath/lib.dart', r'''
@deprecated
library a;
''');
    await assertDiagnostics(
      r'''
import 'lib.dart';
''',
      [lint(0, 18), error(diag.unusedImport, 7, 10)],
    );
  }

  test_deprecatedMethod() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  void m() {}

  void m2() {
    [!m!]();
  }
}
''');
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

  test_deprecatedMethod_usedInPrimaryConstructorBody() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
void deprecatedMethod() {}

class B(var int x) {
  this {
    [!deprecatedMethod!]();
  }
}
''');
  }

  test_deprecatedMethod_withMessage() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @Deprecated('Message')
  void m() {}

  void m2() {
    [!m!]();
  }
}
''');
  }

  test_deprecatedNamedConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  C.named();
}

var x = [!C.named!]();
''');
  }

  test_deprecatedNamedConstructor_usedInSuperConstructorCall() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  A.named();
}
class B extends A {
  B() : [!super.named()!];
}
''');
  }

  test_deprecatedNamedParameterOfFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f({@deprecated int? p}) {}

void g() => f([!p!]: 1);
''');
  }

  test_deprecatedNamedParameterOfFunction_usedInDeclaringFunction() async {
    await assertNoDiagnostics(r'''
int? f({@deprecated int? p}) => p;
''');
  }

  test_deprecatedNamedParameterOfMethod() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  void f({@deprecated int? p}) {}

  void g() => f([!p!]: 1);
}
''');
  }

  test_deprecatedOperator() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  C operator+(int other) => C();
}
void f(C c) {
  [!c + 1!];
}
''');
  }

  test_deprecatedOperator_usedInCompoundAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  C operator+(int other) => C();
}
void f(C c) {
  [!c += 1!];
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class C {
  C({@deprecated int? p});
  C.two() : this([!p!]: 0);
}
''');
  }

  test_deprecatedParameterOfPrimaryConstructor_usedInDeclaringConstructorBody() async {
    await assertNoDiagnostics(r'''
class C({@deprecated int? p}) {
  this : q = p;
  int? q;
}
''');
  }

  test_deprecatedPositionalParameterOfFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f([@deprecated int? p]) {}

void g() => f([!1!]);
''');
  }

  test_deprecatedPrimaryConstructor_bodyPart() async {
    await assertDiagnosticsFromMarkup(r'''
class A(var int x) {
  @deprecated
  this;
}

void f() {
  var a = [!A!](1);
}
''');
  }

  test_deprecatedSetter() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated set f(int value) {}

void g() => [!f!] = 1;
''');
  }

  test_deprecatedSetter_usedInCompoundAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
int get x => 1;

@deprecated
set x(int value) {}

void f() {
  [!x!] += 1;
}
''');
  }

  test_deprecatedStaticField() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  @deprecated
  static int f = 0;
}

var a = A.[!f!];
''');
  }

  test_deprecatedTopLevelVariable_usedInAssignment() async {
    await assertDiagnosticsFromMarkup(r'''
@deprecated
int x = 1;

void f() {
  [!x!] = 1;
}
''');
  }

  test_deprecatedUnnamedConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  C();
}

var x = [!C!]();
''');
  }

  test_deprecatedUnnamedConstructor_newSyntax() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  @deprecated
  new();
}

var x = [!C!]();
''');
  }
}
