// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnreachableFromMainTest);
  });
}

@reflectiveTest
class UnreachableFromMainTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'unreachable_from_main';

  test_class_instanceField_reachable_overrides_local() async {
    await assertDiagnostics(r'''
void main() {
  B();
}

class A {
  int? f;
}

class B extends A {
  int? f;
}
''', [
      lint(41, 1),
    ]);
  }

  test_class_instanceField_reachable_read() async {
    await assertNoDiagnostics(r'''
void main() {
  C().f;
}

class C {
  int? f;
}
''');
  }

  test_class_instanceField_reachable_write() async {
    await assertNoDiagnostics(r'''
void main() {
  C().f = 0;
}

class C {
  int? f;
}
''');
  }

  test_class_instanceField_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C();
}

class C {
  int? f;
}
''', [
      lint(41, 1),
    ]);
  }

  test_class_instanceGetter_reachable_invoked() async {
    await assertNoDiagnostics(r'''
void main() {
  C().foo;
}

class C {
  int get foo => 0;
}
''');
  }

  test_class_instanceGetter_reachable_overrides() async {
    await assertDiagnostics(r'''
void main() {
  B();
}

class A {
  int get foo => 0;
}

class B extends A {
  int get foo => 0;
}
''', [
      lint(44, 3),
    ]);
  }

  test_class_instanceGetter_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C();
}

class C {
  int get foo => 0;
}
''', [
      lint(44, 3),
    ]);
  }

  test_class_instanceMethod_reachable_invoked() async {
    await assertNoDiagnostics(r'''
void main() {
  C().foo();
}

class C {
  void foo() {}
}
''');
  }

  test_class_instanceMethod_reachable_invoked_generic() async {
    await assertNoDiagnostics(r'''
void main() {
  C<int>().foo(null);
}

class C<T> {
  void foo(T? _) {}
}
''');
  }

  test_class_instanceMethod_reachable_overrides_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo() {}
}
''');

    await assertNoDiagnostics(r'''
import 'a.dart';

void main() {
  B();
}

class B extends A {
  void foo() {}
}
''');
  }

  test_class_instanceMethod_reachable_overrides_local() async {
    await assertDiagnostics(r'''
void main() {
  B();
}

class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''', [
      lint(41, 3),
    ]);
  }

  test_class_instanceMethod_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C();
}

class C {
  void foo() {}
}
''', [
      lint(41, 3),
    ]);
  }

  test_class_instanceSetter_reachable_invoked() async {
    await assertNoDiagnostics(r'''
void main() {
  C().foo = 0;
}

class C {
  set foo(int _) {}
}
''');
  }

  test_class_instanceSetter_reachable_overrides() async {
    await assertDiagnostics(r'''
void main() {
  B();
}

class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}
}
''', [
      lint(40, 3),
    ]);
  }

  test_class_instanceSetter_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C();
}

class C {
  set foo(int _) {}
}
''', [
      lint(40, 3),
    ]);
  }

  test_class_reachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';

void main() => A()
''');
    await assertNoDiagnostics(r'''
part 'part.dart';

class A {}
''');
  }

  test_class_reachable_referencedDeepInTypeAnnotation_externalMethodDeclaration() async {
    await assertNoDiagnostics(r'''
void main() {
  D().f;
}

class C {}

class D {
  external C Function() f();
}
''');
  }

  test_class_reachable_referencedDeepInTypeArgument() async {
    await assertNoDiagnostics(r'''
void main() {
  C<D Function()>();
}

class C<T> {}

class D {}
''');
  }

  test_class_reachable_referencedInTypeAnnotation_externalFieldDeclaration() async {
    await assertNoDiagnostics(r'''
void main() {
  D().c;
}

class C {}

class D {
  external C? c;
}
''');
  }

  test_class_reachable_referencedInTypeAnnotation_externalMethodDeclaration() async {
    await assertNoDiagnostics(r'''
void main() {
  D().f;
}

class C {}

class D {
  external C f();
}
''');
  }

  test_class_reachable_referencedInTypeArgument() async {
    await assertNoDiagnostics(r'''
void main() {
  C<D>();
}

class C<T> {}

class D {}
''');
  }

  test_class_reachableViaAnnotation() async {
    await assertNoDiagnostics(r'''
void main() {
  f();
}

class C {
  const C();
}

@C()
void f() {}
''');
  }

  test_class_reachableViaComment() async {
    await assertNoDiagnostics(r'''
/// See [C].
void main() {}

class C {}
''');
  }

  test_class_reachableViaDefaultValueType() async {
    await assertNoDiagnostics(r'''
void main() {
  f();
}

class C {
  const C();
}

void f([Object? p = const C()]) {}
''');
  }

  test_class_referencedInObjectPattern() async {
    await assertDiagnostics(r'''
class C {}

void main() {
  f();
}

void f([Object? c]) {
  if (c case C()) {}
}
''', [
      lint(6, 1),
    ]);
  }

  test_class_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

class C {}
''', [
      lint(22, 1),
    ]);
  }

  test_class_unreachable_foundInAsExpression() async {
    await assertDiagnostics(r'''
class A {}

void main() {
  f();
}

void f([Object? o]) {
  o as A;
}
''', [
      lint(6, 1),
    ]);
  }

  test_class_unreachable_foundInAsPattern() async {
    await assertDiagnostics(r'''
class A {}

void main() {
  f();
}

void f([(Object, )? l]) {
  var (_ as A, ) = l!;
}
''', [
      lint(6, 1),
    ]);
  }

  test_class_unreachable_foundInIsExpression() async {
    await assertDiagnostics(r'''
class A {}

void main() {
  f();
}

void f([Object? o]) {
  o is A;
}
''', [
      lint(6, 1),
    ]);
  }

  test_class_unreachable_hasNamedConstructors() async {
    await assertDiagnostics(r'''
void main() {}

class C {
  C();
  C.named();
}
''', [
      lint(22, 1),
      // TODO(srawlins): See if we can skip reporting a declaration if its
      // enclosing declaration is being reported.
      lint(28, 1),
      lint(37, 5),
    ]);
  }

  test_class_unreachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';

void main() {}
''');
    await assertDiagnostics(r'''
part 'part.dart';

class A {}
''', [
      lint(25, 1),
    ]);
  }

  test_class_unreachable_referencedInParameter_externalMethodDeclaration() async {
    await assertDiagnostics(r'''
void main() {
  D().f;
}

class C {}

class D {
  external f(C c);
}
''', [
      lint(32, 1),
    ]);
  }

  test_class_unreachable_referencedInTypeAnnotation_fieldDeclaration() async {
    await assertDiagnostics(r'''
void main() {
  D().c;
}

class C {}

class D {
  C? c;
}
''', [
      lint(32, 1),
    ]);
  }

  test_class_unreachable_referencedInTypeAnnotation_parameter() async {
    await assertDiagnostics(r'''
void main() {
  f();
}

void f([C? c]) {}

class C {}
''', [
      lint(49, 1),
    ]);
  }

  test_class_unreachable_referencedInTypeAnnotation_topLevelVariable() async {
    await assertDiagnostics(r'''
void main() {
  print(c);
}

C? c;

class C {}
''', [
      lint(42, 1),
    ]);
  }

  test_class_unreachable_referencedInTypeAnnotation_variableDeclaration() async {
    await assertDiagnostics(r'''
void main() {
  C? c;
}

class C {}
''', [
      lint(31, 1),
    ]);
  }

  test_class_unreachable_typedefBound() async {
    await assertDiagnostics(r'''
void main() {
  f();
}

class C {}

void f<T extends C>() {}
''', [
      lint(30, 1),
    ]);
  }

  test_classInPart_reachable() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';

class A {}
''');
    await assertNoDiagnostics(r'''
part 'part.dart';

void main() => A();
''');
  }

  test_classInPart_reachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';

class A {}

void main() => A()
''');
    await assertNoDiagnostics(r'''
part 'part.dart';
''');
  }

  test_classInPart_unreachable() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';

class A {}
''');
    await assertDiagnostics(r'''
part 'part.dart';

void main() {}
''', [
      lint(28, 1),
    ]);
  }

  test_classInPart_unreachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';

class A {}

void main() {}
''');
    await assertDiagnostics(r'''
part 'part.dart';
''', [
      lint(28, 1),
    ]);
  }

  test_constructor_named_onEnum() async {
    await assertDiagnostics(r'''
void main() {
  E.one;
  E.two;
}

enum E {
  one(), two();

  const E();
  const E.named();
}
''', [
      // No lint.
      error(WarningCode.UNUSED_ELEMENT, 84, 5),
    ]);
  }

  test_constructor_named_reachableViaDirectCall() async {
    await assertNoDiagnostics(r'''
void main() {
  C.named();
}

class C {
  C.named();
}
''');
  }

  test_constructor_named_reachableViaExplicitSuperCall() async {
    await assertNoDiagnostics(r'''
void main() {
  D();
}

class C {
  C.named();
}

class D extends C {
  D() : super.named();
}
''');
  }

  test_constructor_named_reachableViaRedirectedConstructor() async {
    await assertNoDiagnostics(r'''
void main() {
  C.two();
}

class C {
  C.named();
  factory C.two() = C.named;
}
''');
  }

  test_constructor_named_reachableViaRedirection() async {
    await assertNoDiagnostics(r'''
void main() {
  C.two();
}

class C {
  C.named();

  C.two() : this.named();
}
''');
  }

  test_constructor_named_reachableViaTearoff() async {
    await assertNoDiagnostics(r'''
void main() {
  C.named;
}

class C {
  C.named();
}
''');
  }

  test_constructor_named_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C;
}

class C {
  C.named();
}
''', [
      lint(36, 5),
    ]);
  }

  test_constructor_named_unreachable_inExtensionType() async {
    await assertDiagnostics(r'''
void main() {
  E(7);
}

extension type E(int it) {
  E.named(this.it);
}
''', [
      lint(56, 5),
    ]);
  }

  test_constructor_named_unreachable_otherHasRedirectedConstructor() async {
    await assertDiagnostics(r'''
void main() {
  C.two();
}

class C {
  C.named();
  C.one();
  factory C.two() = C.one;
}
''', [
      lint(42, 5),
    ]);
  }

  test_constructor_reachableViaTestReflectiveLoader() async {
    var testReflectiveLoaderPath = '$workspaceRootPath/test_reflective_loader';
    var packageConfigBuilder = PackageConfigFileBuilder();
    packageConfigBuilder.add(
      name: 'test_reflective_loader',
      rootPath: testReflectiveLoaderPath,
    );
    writeTestPackageConfig(packageConfigBuilder);
    newFile('$testReflectiveLoaderPath/lib/test_reflective_loader.dart', r'''
library test_reflective_loader;

const Object reflectiveTest = _ReflectiveTest();
class _ReflectiveTest {
  const _ReflectiveTest();
}
''');
    await assertNoDiagnostics(r'''
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  // Usually some reference via `defineReflectiveTests`.
  A;
}

@reflectiveTest
class A {
  A() {}
}
''');
  }

  test_constructor_unnamed_reachableViaDefaultImplicitSuperCall() async {
    await assertNoDiagnostics(r'''
void main() {
  D();
}

class C {
  C();
}

class D extends C {
  // Just a default constructor.
}
''');
  }

  test_constructor_unnamed_reachableViaDirectCall() async {
    await assertNoDiagnostics(r'''
void main() {
  C();
}

class C {
  C();
}
''');
  }

  test_constructor_unnamed_reachableViaExplicitSuperCall() async {
    await assertNoDiagnostics(r'''
void main() {
  D();
}

class C {
  C();
}

class D extends C {
  D() : super();
}
''');
  }

  test_constructor_unnamed_reachableViaImplicitSuperCall() async {
    await assertNoDiagnostics(r'''
void main() {
  D();
}

class C {
  C();
}

class D extends C {
  D();
}
''');
  }

  test_constructor_unnamed_reachableViaImplicitSuperCall_indirectly() async {
    await assertNoDiagnostics(r'''
void main() {
  E();
}

class C {
  C();
}

class D extends C {
  // Just a default constructor.
}

class E extends D {
  E();
}
''');
  }

  test_constructor_unnamed_reachableViaImplicitSuperCall_superParameters() async {
    await assertNoDiagnostics(r'''
void main() {
  D(1);
}

class C {
  C(int p);
}

class D extends C {
  D(super.p);
}
''');
  }

  test_constructor_unnamed_reachableViaRedirectedConstructor() async {
    await assertNoDiagnostics(r'''
void main() {
  C.two();
}

class C {
  C();
  factory C.two() = C;
}
''');
  }

  test_constructor_unnamed_reachableViaRedirection() async {
    await assertNoDiagnostics(r'''
void main() {
  C.two();
}

class C {
  C();

  C.two() : this();
}
''');
  }

  test_constructor_unnamed_reachableViaTearoff() async {
    await assertNoDiagnostics(r'''
void main() {
  C.new;
}

class C {
  C();
}
''');
  }

  test_constructor_unnamed_referencedInConstantPattern() async {
    await assertDiagnostics(r'''
class C {
  const C();
}

void main() {
  f();
}

void f([C? c]) {
  if (c case const C()) {}
}
''', [
      lint(6, 1),
      lint(18, 1),
    ]);
  }

  test_constructor_unnamed_referencedInConstantPattern_generic() async {
    await assertDiagnostics(r'''
class C<T> {
  const C();
}

void main() {
  f();
}

void f([C? c]) {
  if (c case const C<int>()) {}
}
''', [
      lint(6, 1),
      lint(21, 1),
    ]);
  }

  test_constructor_unnamed_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C;
}

class C {
  C();
}
''', [
      lint(34, 1),
    ]);
  }

  test_constructor_unnamed_unreachable_otherHasRedirection() async {
    await assertDiagnostics(r'''
void main() {
  C.two();
}

class C {
  C();
  C.one();
  C.two() : this.one();
}
''', [
      lint(40, 1),
    ]);
  }

  test_enum_reachableViaValue() async {
    await assertNoDiagnostics(r'''
void main() {
  E.one;
}

enum E { one, two }
''');
  }

  test_enum_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

enum E { one, two }
''', [
      lint(21, 1),
    ]);
  }

  test_extension_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

extension IntExtension on int {}
''', [
      lint(26, 12),
    ]);
  }

  test_extensionType_reachable_referencedInTypeAnnotation_asExpression() async {
    await assertNoDiagnostics(r'''
void main() {
  1 as E;
}

extension type E(int it) {}
''');
  }

  test_extensionType_reachable_referencedInTypeAnnotation_castPattern() async {
    await assertNoDiagnostics(r'''
void main() {
  var r = (1, );
  var (s as E, ) = r;
}

extension type E(int it) {}
''');
  }

  test_mixin_reachable_implemented() async {
    await assertNoDiagnostics(r'''
void main() {
  A();
}

mixin M {}

class A implements M {}
''');
  }

  test_mixin_reachable_mixed() async {
    await assertNoDiagnostics(r'''
void main() {
  A();
}

mixin M {}

class A with M {}
''');
  }

  test_mixin_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

mixin M {}
''', [
      lint(22, 1),
    ]);
  }

  test_staticField_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C;
}

class C {
  static int f = 1;
}
''', [
      lint(45, 1),
    ]);
  }

  test_staticFieldOnClass_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  C.f;
}

class C {
  static int f = 1;
}
''');
  }

  test_staticFieldOnEnum_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E.f;
}

enum E {
  one, two, three;
  static int f = 1;
}
''');
  }

  test_staticFieldOnExtension_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E.f;
}

extension E on int {
  static int f = 1;
}
''');
  }

  test_staticFieldOnExtension_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  E(1).m();
}

extension E on int {
  static int f = 1;
  void m() {}
}
''', [
      lint(63, 1),
    ]);
  }

  test_staticFieldOnMixin_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  M.f;
}

mixin M {
  static int f = 1;
}
''');
  }

  test_staticGetter_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  C.g;
}

class C {
  static int get g => 7;
}
''');
  }

  test_staticGetter_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C;
}

class C {
  static int get g => 7;
}
''', [
      lint(49, 1),
    ]);
  }

  test_staticMethod_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C;
}

class C {
  static void f() {}
}
''', [
      lint(46, 1),
    ]);
  }

  test_staticMethodOnClass_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  C.f();
}

class C {
  static void f() {}
}
''');
  }

  test_staticMethodOnEnum_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E.f();
}

enum E {
  one, two, three;
  static void f() {}
}
''');
  }

  test_staticMethodOnExtension_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E.f();
}

extension E on int {
  static void f() {}
}
''');
  }

  test_staticMethodOnMixin_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  M.f();
}

mixin M {
  static void f() {}
}
''');
  }

  test_staticSetter_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  C.s = 1;
}

class C {
  static set s(int value) {}
}
''');
  }

  test_staticSetter_unreachable() async {
    await assertDiagnostics(r'''
void main() {
  C;
}

class C {
  static set s(int value) {}
}
''', [
      lint(45, 1),
    ]);
  }

  test_topLevelFunction_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  f1();
}

void f1() {
  f2();
}

void f2() {}
''');
  }

  test_topLevelFunction_reachable_private() async {
    await assertNoDiagnostics(r'''
void main() {
  _f();
}

void _f() {}
''');
  }

  test_topLevelFunction_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

void f() {}
''', [
      lint(21, 1),
    ]);
  }

  test_topLevelFunction_unreachable_unrelatedPragma() async {
    await assertDiagnostics(r'''
void main() {}

@pragma('other')
void f() {}
''', [
      lint(38, 1),
    ]);
  }

  test_topLevelFunction_unreachable_visibleForTesting() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void main() {}

@visibleForTesting
void f() {}
''');
  }

  test_topLevelFunction_vmEntryPoint() async {
    await assertNoDiagnostics(r'''
@pragma('vm:entry-point')
void f6() {}
''');
  }

  test_topLevelFunction_vmEntryPoint_const() async {
    await assertNoDiagnostics(r'''
const entryPoint = pragma('vm:entry-point');
@entryPoint
void f6() {}
''');
  }

  test_topLevelGetter_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  g;
}

int get g => 7;
''');
  }

  test_topLevelGetter_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

int get g => 7;
''', [
      lint(24, 1),
    ]);
  }

  test_topLevelSetter_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  s = 7;
}

set s(int value) {}
''');
  }

  test_topLevelSetter_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

set s(int value) {}
''', [
      lint(20, 1),
    ]);
  }

  test_topLevelVariable_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  _f();
}

void _f() {
  x;
}

int x = 1;
''');
  }

  test_topLevelVariable_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

int x = 1;
''', [
      lint(20, 1),
    ]);
  }

  test_typedef_reachable_referencedInObjectPattern() async {
    await assertNoDiagnostics(r'''
typedef T = int;

void main() {
  f();
}

void f([Object? c]) {
  if (c case T()) {}
}
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_asExpression() async {
    await assertNoDiagnostics(r'''
void main() {
  1.5 as T;
}

typedef T = int;
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_castPattern() async {
    await assertNoDiagnostics(r'''
void main() {
  var r = (1.5, );
  var (s as T, ) = r;
}

typedef T = int;
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_genericFunctionType() async {
    await assertNoDiagnostics(r'''
void main() {
  t = () => 7;
}

T? Function()? t;

typedef T = int;
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_isExpression() async {
    await assertNoDiagnostics(r'''
void main() {
  1.5 is T;
}

typedef T = int;
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_parameter() async {
    await assertNoDiagnostics(r'''
void main() {
  f(() {});
}

void f([Cb? c]) {}

typedef Cb = void Function();
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_recordType() async {
    await assertNoDiagnostics(r'''
void main() {
  t = (1, );
}

(T, )? t;

typedef T = int;
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_topLevelVariable() async {
    await assertNoDiagnostics(r'''
void main() {
  c = () {};
}

Cb? c;

typedef Cb = void Function();
''');
  }

  test_typedef_reachable_referencedInTypeAnnotation_variableDeclaration() async {
    await assertNoDiagnostics(r'''
void main() {
  Cb c = () {};
}

typedef Cb = void Function();
''');
  }

  test_typedef_unreachable() async {
    await assertDiagnostics(r'''
void main() {}

typedef T = String;
''', [
      lint(24, 1),
    ]);
  }
}
