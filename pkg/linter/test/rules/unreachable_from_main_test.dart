// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnreachableFromMainTest);
  });
}

@reflectiveTest
class UnreachableFromMainTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  bool get addMetaPackageDep => true;

  @override
  bool get addTestReflectiveLoaderPackageDep => true;

  @override
  String get lintRule => LintNames.unreachable_from_main;

  test_class_instanceField_reachable_matchedInPattern() async {
    await assertNoDiagnostics(r'''
void main() {
  var x = switch (C(1)) {
    C(:final f) => f.round(),
  };
  print(x);
}

class C {
  final int f;
  C(this.f);
}
''');
  }

  test_class_instanceField_reachable_overrides_local() async {
    await assertDiagnostics(
      r'''
void main() {
  B();
}

class A {
  int? f;
}

class B extends A {
  int? f;
}
''',
      [lint(41, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  C();
}

class C {
  int? f;
}
''',
      [lint(41, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  B();
}

class A {
  int get foo => 0;
}

class B extends A {
  int get foo => 0;
}
''',
      [lint(44, 3)],
    );
  }

  test_class_instanceGetter_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  C();
}

class C {
  int get foo => 0;
}
''',
      [lint(44, 3)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  B();
}

class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''',
      [lint(41, 3)],
    );
  }

  test_class_instanceMethod_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  C();
}

class C {
  void foo() {}
}
''',
      [lint(41, 3)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  B();
}

class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}
}
''',
      [lint(40, 3)],
    );
  }

  test_class_instanceSetter_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  C();
}

class C {
  set foo(int _) {}
}
''',
      [lint(40, 3)],
    );
  }

  test_class_reachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'lib.dart';

void main() => A();
''');
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';

class A {}
''');
    await assertDiagnosticsInUnits([
      ('$testPackageLibPath/lib.dart', []),
      ('$testPackageLibPath/part.dart', []),
    ]);
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

  test_class_reachable_referencedInTypeArgument_genericGenericType() async {
    await assertNoDiagnostics(r'''
class A {}

void main() {
  f();
}

void f([List<List<A>>? l]) {}
''');
  }

  test_class_reachable_typeLiteral() async {
    await assertNoDiagnostics(r'''
void main() {
  C;
}

class C {}
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
    await assertDiagnostics(
      r'''
class C {}

void main() {
  f();
}

void f([Object? c]) {
  if (c case C()) {}
}
''',
      [lint(6, 1)],
    );
  }

  test_class_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {}

class C {}
''',
      [lint(22, 1)],
    );
  }

  test_class_unreachable_foundInAsExpression() async {
    await assertDiagnostics(
      r'''
class A {}

void main() {
  f();
}

void f([Object? o]) {
  o as A;
}
''',
      [lint(6, 1)],
    );
  }

  test_class_unreachable_foundInAsPattern() async {
    await assertDiagnostics(
      r'''
class A {}

void main() {
  f();
}

void f([(Object, )? l]) {
  var (_ as A, ) = l!;
}
''',
      [lint(6, 1)],
    );
  }

  test_class_unreachable_foundInIsExpression() async {
    await assertDiagnostics(
      r'''
class A {}

void main() {
  f();
}

void f([Object? o]) {
  o is A;
}
''',
      [lint(6, 1)],
    );
  }

  test_class_unreachable_hasNamedConstructors() async {
    await assertDiagnostics(
      r'''
void main() {}

class C {
  C();
  C.named();
}
''',
      [
        lint(22, 1),
        // TODO(srawlins): See if we can skip reporting a declaration if its
        // enclosing declaration is being reported.
        lint(28, 1),
        lint(37, 5),
      ],
    );
  }

  test_class_unreachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'lib.dart';

void main() {}
''');
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';

class A {}
''');
    await assertDiagnosticsInUnits([
      ('$testPackageLibPath/lib.dart', [lint(25, 1)]),
      ('$testPackageLibPath/part.dart', []),
    ]);
  }

  test_class_unreachable_referencedInParameter_externalMethodDeclaration() async {
    await assertDiagnostics(
      r'''
void main() {
  D().f;
}

class C {}

class D {
  external f(C c);
}
''',
      [lint(32, 1)],
    );
  }

  test_class_unreachable_referencedInTypeAnnotation_fieldDeclaration() async {
    await assertDiagnostics(
      r'''
void main() {
  D().c;
}

class C {}

class D {
  C? c;
}
''',
      [lint(32, 1)],
    );
  }

  test_class_unreachable_referencedInTypeAnnotation_parameter() async {
    await assertDiagnostics(
      r'''
void main() {
  f();
}

void f([C? c]) {}

class C {}
''',
      [lint(49, 1)],
    );
  }

  test_class_unreachable_referencedInTypeAnnotation_topLevelVariable() async {
    await assertDiagnostics(
      r'''
void main() {
  print(c);
}

C? c;

class C {}
''',
      [lint(42, 1)],
    );
  }

  test_class_unreachable_referencedInTypeAnnotation_variableDeclaration() async {
    await assertDiagnostics(
      r'''
void main() {
  C? c;
}

class C {}
''',
      [lint(31, 1)],
    );
  }

  test_class_unreachable_typeArgumentBound() async {
    await assertDiagnostics(
      r'''
void main() {
  f();
}

class C {}

void f<T extends C>() {}
''',
      [lint(30, 1)],
    );
  }

  test_classInPart_reachable() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'lib.dart';

class A {}
''');
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';

void main() => A();
''');
    await assertDiagnosticsInUnits([
      ('$testPackageLibPath/lib.dart', []),
      ('$testPackageLibPath/part.dart', []),
    ]);
  }

  test_classInPart_reachable_mainInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'lib.dart';

class A {}

void main() => A();
''');
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';
''');
    await assertDiagnosticsInUnits([
      ('$testPackageLibPath/lib.dart', []),
      ('$testPackageLibPath/part.dart', []),
    ]);
  }

  test_classInPart_unreachable() async {
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';

void main() {}
''');
    newFile('$testPackageLibPath/part.dart', r'''
part of 'lib.dart';

class A {}
''');
    await assertDiagnosticsInUnits([
      ('$testPackageLibPath/lib.dart', []),
      ('$testPackageLibPath/part.dart', [lint(27, 1)]),
    ]);
  }

  test_classInPart_unreachable_mainInPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
part 'part.dart';
''');
    newFile('$testPackageLibPath/part.dart', r'''
part of 'lib.dart';

class A {}

void main() {}
''');
    await assertDiagnosticsInUnits([
      ('$testPackageLibPath/lib.dart', []),
      ('$testPackageLibPath/part.dart', [lint(27, 1)]),
    ]);
  }

  test_constructor_named_onEnum() async {
    await assertNoDiagnostics(r'''
void main() {
  E.one;
  E.two;
}

enum E {
  one(), two();

  const E();
  const E.named();
}
''');
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
    await assertDiagnostics(
      r'''
void main() {
  C;
}

class C {
  C.named();
}
''',
      [lint(36, 5)],
    );
  }

  test_constructor_reachableViaTestReflectiveLoader() async {
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
    await assertDiagnostics(
      r'''
class C {
  const C();
}

void main() {
  f();
}

void f([C? c]) {
  if (c case const C()) {}
}
''',
      [lint(6, 1), lint(18, 1)],
    );
  }

  test_constructor_unnamed_referencedInConstantPattern_generic() async {
    await assertDiagnostics(
      r'''
class C<T> {
  const C();
}

void main() {
  f();
}

void f([C? c]) {
  if (c case const C<int>()) {}
}
''',
      [lint(6, 1), lint(21, 1)],
    );
  }

  test_constructor_unnamed_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  C;
}

class C {
  C();
}
''',
      [lint(34, 1)],
    );
  }

  test_constructor_unnamed_unreachable_otherHasRedirection() async {
    await assertDiagnostics(
      r'''
void main() {
  C.two();
}

class C {
  C();
  C.one();
  C.two() : this.one();
}
''',
      [lint(40, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {}

enum E { one, two }
''',
      [lint(21, 1)],
    );
  }

  test_extension_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {}

extension IntExtension on int {}
''',
      [lint(26, 12)],
    );
  }

  test_extensionType_constructor_named_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  E(7);
}

extension type E(int it) {
  E.named(this.it);
}
''',
      [lint(56, 5)],
    );
  }

  test_extensionType_instanceMethod_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E(1).m();
}

extension type E(int i) {
  void m() {}
}
''');
  }

  test_extensionType_instanceMethod_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  E(1);
}

extension type E(int i) {
  void m() {}
}
''',
      [lint(58, 1)],
    );
  }

  test_extensionType_member_redeclare_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  var c = C();
  c.m();
  E(c);
}

class C {
  void m() {}
}

extension type E(C c) implements C {
  void m() {}
}
''',
      [lint(120, 1)],
    );
  }

  test_extensionType_primaryConstructorBody_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E(1);
  print(E(1).i);
}

extension type E(int i) {
  this {
    print(i);
  }
}
''');
  }

  test_extensionType_reachable_referencedInTypeAnnotation_asExpression() async {
    await assertNoDiagnostics(r'''
void main() {
  1 as E;
}

extension type E(int it) {}
''');
  }

  test_extensionType_representation_private_unreachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E(1);
}

extension type E(int _i) {}
''');
  }

  test_extensionType_representation_reachable() async {
    await assertNoDiagnostics(r'''
void main() {
  E(1).i;
}

extension type E(int i) {}
''');
  }

  test_extensionType_representation_unreachable() async {
    // We do not worry about the representation field, and whether or not it is
    // used or reachable.
    await assertNoDiagnostics(r'''
void main() {
  E(1);
}

extension type E(int i) {}
''');
  }

  test_extensionType_staticMethod_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  E(1);
}

extension type E(int i) {
  static void f() {}
}
''',
      [lint(65, 1)],
    );
  }

  test_extensionType_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {}

extension type E(int i) {}
''',
      [lint(31, 1)],
    );
  }

  test_instanceFieldOnExtension_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  E.f;
}

extension E on int {
  static int f = 1;
  void m() {}
}
''',
      [lint(72, 1)],
    );
  }

  test_instanceMethod_reachable_toJson() async {
    await assertNoDiagnostics(r'''
import 'dart:convert';

void main() async {
  jsonEncode([C()]);
}

class C {
  List<Object> toJson() => ['c'];
}
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
    await assertDiagnostics(
      r'''
void main() {}

mixin M {}
''',
      [lint(22, 1)],
    );
  }

  test_setUpClass_class_static_member_reachable() async {
    await assertNoDiagnostics('''
void main() {
  A();
}

final class A {
  static setUpClass() {}
}
''');
  }

  test_setUpClass_top_level_unreachable() async {
    await assertDiagnostics(
      '''
void main() {}

setUpClass() {}
''',
      [lint(16, 10)],
    );
  }

  test_staticField_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  C;
}

class C {
  static int f = 1;
}
''',
      [lint(45, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  E(1).m();
}

extension E on int {
  static int f = 1;
  void m() {}
}
''',
      [lint(63, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  C;
}

class C {
  static int get g => 7;
}
''',
      [lint(49, 1)],
    );
  }

  test_staticMethod_unreachable() async {
    await assertDiagnostics(
      r'''
void main() {
  C;
}

class C {
  static void f() {}
}
''',
      [lint(46, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {
  C;
}

class C {
  static set s(int value) {}
}
''',
      [lint(45, 1)],
    );
  }

  test_tearDownClass_class_static_member_reachable() async {
    await assertNoDiagnostics('''
void main() {
  A();
}

final class A {
  static tearDownClass() {}
}
''');
  }

  test_tearDownClass_top_level_unreachable() async {
    await assertDiagnostics(
      '''
void main() {}

tearDownClass() {}
''',
      [lint(16, 13)],
    );
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
    await assertDiagnostics(
      r'''
void main() {}

void f() {}
''',
      [lint(21, 1)],
    );
  }

  test_topLevelFunction_unreachable_unrelatedPragma() async {
    await assertDiagnostics(
      r'''
void main() {}

@pragma('other')
void f() {}
''',
      [lint(38, 1)],
    );
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
void main() {}

@pragma('vm:entry-point')
void f6() {}
''');
  }

  test_topLevelFunction_vmEntryPoint_const() async {
    await assertNoDiagnostics(r'''
void main() {}

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
    await assertDiagnostics(
      r'''
void main() {}

int get g => 7;
''',
      [lint(24, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {}

set s(int value) {}
''',
      [lint(20, 1)],
    );
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
    await assertDiagnostics(
      r'''
void main() {}

int x = 1;
''',
      [lint(20, 1)],
    );
  }

  test_typedef_reachable_referencedAsInstanceCreation_named() async {
    await assertNoDiagnostics(r'''
void main() {
  T.named();
}

class C {
  C.named();
}

typedef T = C;
''');
  }

  test_typedef_reachable_referencedAsInstanceCreation_unnamed() async {
    await assertNoDiagnostics(r'''
void main() {
  T();
}

class C {}

typedef T = C;
''');
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
    await assertDiagnostics(
      r'''
void main() {}

typedef T = String;
''',
      [lint(24, 1)],
    );
  }

  test_widgetPreview_classInstanceMethod() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

void main() {}

class B {
  // Widget previews can't be defined with instance methods.
  // ignore: invalid_widget_preview_application
  @Preview()
  Widget foo() => Text('');
}
''',
      [lint(109, 1), lint(244, 3)],
    );
  }

  test_widgetPreview_classStaticMethod() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

void main() {}

class B {
  @Preview()
  static Widget foo() => Text('');
}
''',
      [lint(109, 1)],
    );
  }

  test_widgetPreview_constructor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widget_previews.dart';

void main() {}

class B {
  @Preview()
  const B();
}
''',
      [lint(70, 1), error(diag.invalidWidgetPreviewApplication, 77, 7)],
    );
  }

  test_widgetPreview_factoryConstructor() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widget_previews.dart';

void main() {}

class B {
  // ignore: invalid_widget_preview_application
  @Preview()
  factory B.foo() => B();

  const B();
}
''',
      [lint(70, 1), lint(170, 1)],
    );
  }

  test_widgetPreview_privatePreview() async {
    await assertDiagnostics(
      r'''
// Widget previews can't be defined with private functions.
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
void main() {}

class B {
  @Preview()
  factory B._foo() => B._();

  @Preview()
  B._();

  @Preview()
  static Widget _bar() => Text('');
}

@Preview()
void _f6() {}
''',
      [
        lint(168, 1),
        error(diag.invalidWidgetPreviewApplication, 175, 7),
        error(diag.invalidWidgetPreviewApplication, 218, 7),
        error(diag.invalidWidgetPreviewApplication, 241, 7),
        error(diag.invalidWidgetPreviewApplication, 291, 7),
      ],
    );
  }

  test_widgetPreview_topLevelFunction() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widget_previews.dart';

void main() {}

// ignore: invalid_widget_preview_application
@Preview()
void f6() {}
''');
  }

  test_widgetPreview_topLevelFunction_const() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widget_previews.dart';
void main() {}

const preview = Preview();
@preview
void f6() {}
''');
  }

  test_widgetPreview_topLevelFunction_customPreviewClass() async {
    await assertDiagnostics(
      r'''
void main() {}

class Preview {
  const Preview();
}

// This isn't from package:flutter/widget_previews.dart and shouldn't be exempt.
@Preview()
void f6() {}
''',
      [lint(22, 7), lint(40, 7), lint(151, 2)],
    );
  }
}
