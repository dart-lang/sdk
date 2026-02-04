// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
      [error(diag.wrongNumberOfTypeArguments, 17, 5)],
    );
  }

  test_class_tooMany() async {
    await assertErrorsInCode(
      r'''
class A<E> {}
A<A, A>? a;
''',
      [error(diag.wrongNumberOfTypeArguments, 14, 8)],
    );
  }

  test_classAlias() async {
    await assertErrorsInCode(
      r'''
class A {}
mixin M {}
class B<F extends num> = A<F> with M;
''',
      [error(diag.wrongNumberOfTypeArguments, 47, 4)],
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
      [error(diag.wrongNumberOfTypeArguments, 47, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 53, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 50, 11)],
    );
  }

  test_dynamic() async {
    await assertErrorsInCode(
      r'''
dynamic<int> v;
''',
      [error(diag.wrongNumberOfTypeArguments, 0, 12)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 14, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 14, 13)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 12, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 12, 13)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 33, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 30, 10)],
    );
  }

  test_functionTypeExpression_tooFew() async {
    await assertErrorsInCode(
      '''
f(void Function<T, U>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int>;
}
''',
      [error(diag.wrongNumberOfTypeArgumentsFunction, 80, 5)],
    );
  }

  test_functionTypeExpression_tooMany() async {
    await assertErrorsInCode(
      '''
f(void Function<T>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int, String>;
}
''',
      [error(diag.disallowedTypeInstantiationExpression, 57, 20)],
    );
  }

  test_messageText_annotation() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}

@A<int>()
void f() {}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsElement,
          28,
          5,
          messageContains: [
            "The class 'A'",
            '0 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_constructorInvocationWithExplicitNew_noTypeParameters() async {
    await assertErrorsInCode(
      r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsConstructor,
          53,
          5,
          messageContains: [
            "The constructor 'Foo.bar'",
            "doesn't have type parameters",
          ],
        ),
      ],
    );
  }

  test_messageText_constructorInvocationWithImplicitNew_noTypeParameters() async {
    await assertErrorsInCode(
      r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsConstructor,
          49,
          5,
          messageContains: [
            "The constructor 'Foo.bar'",
            "doesn't have type parameters",
          ],
        ),
      ],
    );
  }

  test_messageText_constructorTearoff_noTypeParametersExpected() async {
    await assertErrorsInCode(
      '''
class A<T> {
  A.foo() {}
}

var x = A.foo<int>;
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsConstructor,
          42,
          5,
          messageContains: [
            "The constructor 'A.foo'",
            "doesn't have type parameters",
          ],
        ),
      ],
    );
  }

  test_messageText_dotShorthand() async {
    await assertErrorsInCode(
      r'''
abstract class Foo<T> {
  const factory Foo.a() = _Foo;

  const Foo();
}

class _Foo<T> extends Foo<T> {
  const _Foo();
}

Foo<int> bar<T>() => const .a<int>();
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsDotShorthandConstructor,
          154,
          5,
          messageContains: [
            "the constructor 'Foo.a'",
            "type parameters can't be applied to dot shorthand constructor "
                "invocations",
          ],
        ),
      ],
    );
  }

  test_messageText_dynamic() async {
    await assertErrorsInCode(
      r'''
dynamic<int> v;
''',
      [
        error(
          diag.wrongNumberOfTypeArguments,
          0,
          12,
          messageContains: [
            "The type 'dynamic'",
            '0 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_enum() async {
    await assertErrorsInCode(
      r'''
enum E<T, U> {
  v<int>()
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsEnum,
          18,
          5,
          messageContains: [
            'The enum',
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_extension() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  void foo() {}
}

void f() {
  E<int>(0).foo();
}
''',
      [error(diag.wrongNumberOfTypeArgumentsExtension, 54, 5)],
    );
  }

  test_messageText_functionInstantiation_duringConstEvaluation() async {
    await assertErrorsInCode(
      '''
void f<T>() {}
const dynamic x = f;
const y = (f)<int, String>;
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsFunction,
          49,
          13,
          messageContains: [
            "The type of this function is 'void Function<T>()'",
            '1 type parameters',
            '2 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_implicitCallTearoff() async {
    await assertErrorsInCode(
      '''
f(C c) {
  c<int>;
}
class C {
  void call<T, U>() {}
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsElement,
          12,
          5,
          messageContains: [
            "The method 'call'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_instantiationOfFunctionTypedExpression() async {
    await assertErrorsInCode(
      '''
f(void Function<T, U>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int>;
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsFunction,
          80,
          5,
          messageContains: [
            "The type of this function is 'void Function<T, U>()'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_localFunction() async {
    await assertErrorsInCode(
      '''
f() {
  void foo<T, U>() {}
  foo<int>;
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsElement,
          33,
          5,
          messageContains: [
            "The function 'foo'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_namedType() async {
    await assertErrorsInCode(
      r'''
class A<E, F> {}
A<A>? a;
''',
      [
        error(
          diag.wrongNumberOfTypeArguments,
          17,
          5,
          messageContains: [
            "The type 'A'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_never() async {
    await assertErrorsInCode(
      r'''
Never<int> f() => throw '';
''',
      [
        error(
          diag.wrongNumberOfTypeArguments,
          0,
          10,
          messageContains: [
            "The type 'Never'",
            '0 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_prefixedConstructorInvocation() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode(
      '''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsConstructor,
          43,
          5,
          messageContains: [
            "The constructor 'p.Foo.bar'",
            "doesn't have type parameters",
          ],
        ),
      ],
    );
  }

  test_messageText_topLevelFunctionInvocation() async {
    await assertErrorsInCode(
      '''
void f() {
  g<int>();
}
void g<T, U>() {}
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsElement,
          14,
          5,
          messageContains: [
            "The function 'g'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_topLevelFunctionTearoff_const() async {
    await assertErrorsInCode(
      r'''
void foo<T, U>(T a, U b) {}
const g = foo<int>;
''',
      [
        error(
          diag.wrongNumberOfTypeArgumentsElement,
          41,
          5,
          messageContains: [
            "The function 'foo'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_typeInstantiation() async {
    await assertErrorsInCode(
      '''
class C<T, U> {}
var t = C<int>;
''',
      [
        error(
          diag.wrongNumberOfTypeArguments,
          26,
          5,
          messageContains: [
            "The type 'C'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_typeInstantiation_typedef() async {
    await assertErrorsInCode(
      '''
typedef Fn<T, U> = void Function(T, U);
var t = Fn<int>;
''',
      [
        error(
          diag.wrongNumberOfTypeArguments,
          50,
          5,
          messageContains: [
            "The type 'Fn'",
            '2 type parameters',
            '1 type arguments',
          ],
        ),
      ],
    );
  }

  test_messageText_typeParameter() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  late T<int> f;
}
''',
      [
        error(
          diag.wrongNumberOfTypeArguments,
          20,
          6,
          messageContains: [
            "The type 'T'",
            '0 type parameters',
            '1 type arguments',
          ],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 28, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 44, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 34, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 50, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 31, 13)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 47, 13)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 19, 5)],
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
      [error(diag.wrongNumberOfTypeArgumentsElement, 19, 13)],
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
      [error(diag.wrongNumberOfTypeArguments, 31, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 37, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 34, 11)],
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
      [error(diag.wrongNumberOfTypeArguments, 79, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 73, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 38, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 35, 11)],
    );
  }

  test_typeParameter() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  late T<int> f;
}
''',
      [error(diag.wrongNumberOfTypeArguments, 20, 6)],
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
      [error(diag.wrongNumberOfTypeArguments, 49, 4)],
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
      [error(diag.wrongNumberOfTypeArguments, 46, 7)],
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
      [error(diag.wrongNumberOfTypeArguments, 36, 6)],
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@extensionType::A
  type: A
''');
  }

  test_tooFew() async {
    await assertErrorsInCode(
      r'''
extension type A<S, T>(int it) {}

void f(A<int> a) {}
''',
      [error(diag.wrongNumberOfTypeArguments, 42, 6)],
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@extensionType::A
  type: A<InvalidType, InvalidType>
''');
  }

  test_tooMany() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}

void f(A<int, String> a) {}
''',
      [error(diag.wrongNumberOfTypeArguments, 39, 14)],
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
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  element: <testLibrary>::@extensionType::A
  type: A<InvalidType>
''');
  }
}
