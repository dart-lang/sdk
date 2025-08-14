// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest_ExtensionType);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends PubPackageResolutionTest {
  test_class_tooFew() async {
    await assertErrorsInCode(
      r'''
class A<E, F> {}
A<A>? a;
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 17, 5)],
    );
  }

  test_class_tooMany() async {
    await assertErrorsInCode(
      r'''
class A<E> {}
A<A, A>? a;
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 14, 8)],
    );
  }

  test_classAlias() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin M {}
class B<F extends num> = A<F> with M;
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 47, 4)],
    );
  }

  test_const_nonGeneric() async {
    await assertErrorsInCode(
      '''
class C {
  const C();
}

f() {
  return const C<int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 47, 6)],
    );
  }

  test_const_tooFew() async {
    await assertErrorsInCode(
      '''
class C<K, V> {
  const C();
}

f() {
  return const C<int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 53, 6)],
    );
  }

  test_const_tooMany() async {
    await assertErrorsInCode(
      '''
class C<E> {
  const C();
}

f() {
  return const C<int, int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 50, 11)],
    );
  }

  test_dynamic() async {
    await assertErrorsInCode(
      r'''
dynamic<int> v;
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 0, 12)],
    );
  }

  test_functionInvocation_tooFew() async {
    await assertErrorsInCode(
      '''
void f() {
  g<int>();
}
void g<T, U>() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 14, 5)],
    );
  }

  test_functionInvocation_tooMany() async {
    await assertErrorsInCode(
      '''
void f() {
  g<int, String>();
}
void g<T>() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 14, 13)],
    );
  }

  test_functionReference_implicitCallTearoff_tooFew() async {
    await assertErrorsInCode(
      '''
f(C c) {
  c<int>;
}
class C {
  void call<T, U>() {}
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction, 12, 5)],
    );
  }

  test_functionReference_implicitCallTearoff_tooMany() async {
    await assertErrorsInCode(
      '''
f(C c) {
  c<int, String>;
}
class C {
  void call<T>() {}
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction, 12, 13)],
    );
  }

  test_functionReference_tooFew() async {
    await assertErrorsInCode(
      '''
f() {
  void foo<T, U>() {}
  foo<int>;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction, 33, 5)],
    );
  }

  test_functionReference_tooMany() async {
    await assertErrorsInCode(
      '''
f() {
  void foo<T>() {}
  foo<int, int>;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction, 30, 10)],
    );
  }

  test_functionTypeExpression_tooFew() async {
    await assertErrorsInCode(
      '''
f(void Function<T, U>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int>;
}
''',
      [
        error(
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsAnonymousFunction,
          80,
          5,
        ),
      ],
    );
  }

  test_functionTypeExpression_tooMany() async {
    await assertErrorsInCode(
      '''
f(void Function<T>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int, String>;
}
''',
      [
        error(
          CompileTimeErrorCode.disallowedTypeInstantiationExpression,
          57,
          20,
        ),
      ],
    );
  }

  test_metadata_1of0() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}

@A<int>()
void f() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 28, 5)],
    );
  }

  test_metadata_1of0_viaTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}

typedef B = A;

@B<int>()
void f() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 44, 5)],
    );
  }

  test_metadata_1of2() async {
    await assertErrorsInCode(
      r'''
class A<T, U> {
  const A();
}

@A<int>()
void f() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 34, 5)],
    );
  }

  test_metadata_1of2_viaTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}

typedef B<T, U> = A;

@B<int>()
void f() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 50, 5)],
    );
  }

  test_metadata_2of1() async {
    await assertErrorsInCode(
      r'''
class A<T> {
  const A();
}

@A<int, String>()
void f() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 31, 13)],
    );
  }

  test_metadata_2of1_viaTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}

typedef B<T> = A;

@B<int, String>()
void f() {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 47, 13)],
    );
  }

  test_methodInvocation_tooFew() async {
    await assertErrorsInCode(
      '''
void f(C c) {
  c.g<int>();
}
class C {
  void g<T, U>() {}
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 19, 5)],
    );
  }

  test_methodInvocation_tooMany() async {
    await assertErrorsInCode(
      '''
void f(C c) {
  c.g<int, String>();
}
class C {
  void g<T>() {}
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod, 19, 13)],
    );
  }

  test_new_nonGeneric() async {
    await assertErrorsInCode(
      '''
class C {}

f() {
  return new C<int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 31, 6)],
    );
  }

  test_new_tooFew() async {
    await assertErrorsInCode(
      '''
class C<K, V> {}

f() {
  return new C<int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 37, 6)],
    );
  }

  test_new_tooMany() async {
    await assertErrorsInCode(
      '''
class C<E> {}

f() {
  return new C<int, int>();
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 34, 11)],
    );
  }

  test_objectPattern_tooFew() async {
    await assertErrorsInCode(
      r'''
abstract class A<T, U> {
  int get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: 0):
      break;
  }
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 79, 6)],
    );
  }

  test_objectPattern_tooMany() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: 0):
      break;
  }
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 73, 6)],
    );
  }

  test_type_tooFew() async {
    await assertErrorsInCode(
      r'''
class A<K, V> {
  late K element;
}
f(A<int> a) {
  a.element.anyGetterExistsInDynamic;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 38, 6)],
    );
  }

  test_type_tooMany() async {
    await assertErrorsInCode(
      r'''
class A<E> {
  late E element;
}
f(A<int, int> a) {
  a.element.anyGetterExistsInDynamic;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 35, 11)],
    );
  }

  test_typeParameter() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  late T<int> f;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 20, 6)],
    );
  }

  test_typeTest_tooFew() async {
    await assertErrorsInCode(
      r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 49, 4)],
    );
  }

  test_typeTest_tooMany() async {
    await assertErrorsInCode(
      r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 46, 7)],
    );
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest_ExtensionType
    extends PubPackageResolutionTest {
  test_notGeneric() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

void f(A<int> a) {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 36, 6)],
    );

    var node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@extensionType::A
  type: A
''');
  }

  test_tooFew() async {
    await assertErrorsInCode(
      r'''
extension type A<S, T>(int it) {}

void f(A<int> a) {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 42, 6)],
    );

    var node = findNode.namedType('A<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@extensionType::A
  type: A<InvalidType, InvalidType>
''');
  }

  test_tooMany() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}

void f(A<int, String> a) {}
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArguments, 39, 14)],
    );

    var node = findNode.namedType('A<int, String>');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  element2: <testLibrary>::@extensionType::A
  type: A<InvalidType>
''');
  }
}
