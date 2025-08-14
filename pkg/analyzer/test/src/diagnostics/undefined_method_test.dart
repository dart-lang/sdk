// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedMethodTest);
  });
}

@reflectiveTest
class UndefinedMethodTest extends PubPackageResolutionTest {
  test_conditional_expression_condition_context() async {
    await assertErrorsInCode(
      '''
T castObject<T>(Object value) => value as T;

main() {
  (castObject(true)..whatever()) ? 1 : 2;
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          76,
          8,
          messageContains: ["type 'bool'"],
        ),
      ],
    );
  }

  test_constructor_defined() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(
      r'''
import 'lib.dart';

f(B b) {
  b.a();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 33, 1)],
    );
  }

  test_definedInUnnamedExtension() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension on C {
  void a() {}
}
''');
    await assertErrorsInCode(
      r'''
import 'lib.dart';

f(C c) {
  c.a();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 33, 1)],
    );
  }

  test_extensionMethodHiddenByStaticSetter() async {
    await assertErrorsInCode(
      '''
class C {
  void f() {
    foo();
  }
  static set foo(int x) {}
}

extension E on C {
  int foo() => 1;
}

''',
      [error(CompileTimeErrorCode.undefinedMethod, 27, 3)],
    );
  }

  test_extensionMethodShadowingTopLevelSetter() async {
    await assertErrorsInCode(
      '''
class C {
  void f() {
    foo();
  }
}

extension E on C {
  int foo() => 1;
}

set foo(int x) {}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 27, 3)],
    );
  }

  test_functionAlias_notInstantiated() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo();
}

extension E on Type {
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.undefinedMethodOnFunctionType, 58, 3)],
    );
  }

  test_functionAlias_typeInstantiated_parenthesized() async {
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode(r'''
main() {
  (() => null).call();
}
''');
  }

  test_functionExpression_directCall_defined() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null)();
}
''');
  }

  test_ignoreTypePropagation() async {
    await assertErrorsInCode(
      r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
  }
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 85, 1)],
    );
  }

  test_localSetterShadowingExtensionMethod() async {
    await assertErrorsInCode(
      '''
class C {}

extension E1 on C {
  int foo(int x) => 1;
}

extension E2 on C {
  static set foo(int x) {}

  void f() {
    foo();
  }
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 123, 3)],
    );
  }

  test_method_undefined() async {
    await assertErrorsInCode(
      r'''
class C {
  f() {
    abs();
  }
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 22, 3)],
    );
  }

  test_method_undefined_cascade() async {
    await assertErrorsInCode(
      r'''
class C {}
f(C c) {
  c..abs();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 25, 3)],
    );
  }

  test_method_undefined_enum() async {
    await assertErrorsInCode(
      r'''
enum E { A }
f() => E.abs();
''',
      [error(CompileTimeErrorCode.undefinedMethod, 22, 3)],
    );
  }

  test_method_undefined_mixin() async {
    await assertErrorsInCode(
      r'''
mixin M {}
f(M m) {
  m.abs();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 24, 3)],
    );
  }

  test_method_undefined_mixin_cascade() async {
    await assertErrorsInCode(
      r'''
mixin M {}
f(M m) {
  m..abs();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 25, 3)],
    );
  }

  test_static_conditionalAccess_defined() async {
    await assertErrorsInCode(
      '''
class A {
  static void m() {}
}
f() { A?.m(); }
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 40, 2)],
    );
  }

  test_static_extension_instanceAccess() async {
    await assertErrorsInCode(
      '''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 68, 1)],
    );
  }

  test_static_mixinApplication_superConstructorIsFactory() async {
    await assertErrorsInCode(
      r'''
mixin M {}

class A {
  A();
  factory A.named() = A;
}

class B = A with M;

void main() {
  B.named();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 96, 5)],
    );
  }

  test_typeAlias_functionType() async {
    await assertErrorsInCode(
      r'''
typedef A = void Function();

void f() {
  A.foo();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 45, 3)],
    );
  }

  test_typeAlias_interfaceType() async {
    await assertErrorsInCode(
      r'''
typedef A = List<int>;

void f() {
  A.foo();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 39, 3)],
    );
  }

  test_withExtension() async {
    await assertErrorsInCode(
      r'''
class C {}

extension E on C {
  void a() {}
}

f(C c) {
  c.c();
}
''',
      [error(CompileTimeErrorCode.undefinedMethod, 61, 1)],
    );
  }
}
