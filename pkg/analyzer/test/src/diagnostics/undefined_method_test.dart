// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedMethodTest extends PubPackageResolutionTest {
  test_conditional_expression_condition_context() async {
    await resolveTestCodeWithDiagnostics('''
T castObject<T>(Object value) => value as T;

main() {
  (castObject(true)..whatever()) ? 1 : 2;
//                   ^^^^^^^^
// [diag.undefinedMethod] The method 'whatever' isn't defined for the type 'bool'.
}
''');
  }

  test_constructor_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.m();
}
C c = C.m();
''');
  }

  test_definedInPrivateExtension() async {
    newFile('$testPackageLibPath/lib.dart', '''
class B {}

extension _ on B {
  void a() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart';

f(B b) {
  b.a();
//  ^
// [diag.undefinedMethod] The method 'a' isn't defined for the type 'B'.
}
''');
  }

  test_definedInUnnamedExtension() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension on C {
  void a() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart';

f(C c) {
  c.a();
//  ^
// [diag.undefinedMethod] The method 'a' isn't defined for the type 'C'.
}
''');
  }

  test_extensionMethodHiddenByStaticSetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
  static set foo(int x) {}
}

extension E on C {
  int foo() => 1;
}

''');
  }

  test_extensionMethodShadowingTopLevelSetter() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
}

extension E on C {
  int foo() => 1;
}

set foo(int x) {}
''');
  }

  test_functionAlias_notInstantiated() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn.foo();
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionAlias_typeInstantiated() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo();
//        ^^^
// [diag.undefinedMethodOnFunctionType] The method 'foo' isn't defined for the 'Fn' function type.
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionAlias_typeInstantiated_parenthesized() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionExpression_callMethod_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (() => null).call();
}
''');
  }

  test_functionExpression_directCall_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (() => null)();
}
''');
  }

  test_ignoreTypePropagation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
//    ^
// [diag.undefinedMethod] The method 'm' isn't defined for the type 'A'.
  }
}
''');
  }

  test_localSetterShadowingExtensionMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

extension E1 on C {
  int foo(int x) => 1;
}

extension E2 on C {
  static set foo(int x) {}

  void f() {
    foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'C'.
  }
}
''');
  }

  test_method_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  f() {
    abs();
//  ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'C'.
  }
}
''');
  }

  test_method_undefined_cascade() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
f(C c) {
  c..abs();
//   ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'C'.
}
''');
  }

  test_method_undefined_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { A }
f() => E.abs();
//       ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'E'.
''');
  }

  test_method_undefined_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  m.abs();
//  ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'M'.
}
''');
  }

  test_method_undefined_mixin_cascade() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
f(M m) {
  m..abs();
//   ^^^
// [diag.undefinedMethod] The method 'abs' isn't defined for the type 'M'.
}
''');
  }

  test_static_conditionalAccess_defined() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void m() {}
}
f() { A?.m(); }
//     ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
''');
  }

  test_static_extension_instanceAccess() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
//  ^
// [diag.undefinedMethod] The method 'a' isn't defined for the type 'C'.
}
''');
  }

  test_static_mixinApplication_superConstructorIsFactory() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class A {
  A();
  factory A.named() = A;
}

class B = A with M;

void main() {
  B.named();
//  ^^^^^
// [diag.undefinedMethod] The method 'named' isn't defined for the type 'B'.
}
''');
  }

  test_typeAlias_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function();

void f() {
  A.foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'Type'.
}
''');
  }

  test_typeAlias_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = List<int>;

void f() {
  A.foo();
//  ^^^
// [diag.undefinedMethod] The method 'foo' isn't defined for the type 'List'.
}
''');
  }

  test_withExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {
  void a() {}
}

f(C c) {
  c.c();
//  ^
// [diag.undefinedMethod] The method 'c' isn't defined for the type 'C'.
}
''');
  }
}
