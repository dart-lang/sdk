// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest_ExtensionType);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends PubPackageResolutionTest {
  test_class_tooFew() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E, F> {}
A<A>? a;
// [diag.wrongNumberOfTypeArguments][column 1][length 5] The type 'A' is declared with 2 type parameters, but 1 type arguments were given.
''');
  }

  test_class_tooMany() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {}
A<A, A>? a;
// [diag.wrongNumberOfTypeArguments][column 1][length 8] The type 'A' is declared with 1 type parameters, but 2 type arguments were given.
''');
  }

  test_classAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M {}
class B<F extends num> = A<F> with M;
//                       ^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 0 type parameters, but 1 type arguments were given.
''');
  }

  test_const_nonGeneric() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  const C();
}

f() {
  return const C<int>();
//             ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 0 type parameters, but 1 type arguments were given.
}
''');
  }

  test_const_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
class C<K, V> {
  const C();
}

f() {
  return const C<int>();
//             ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_const_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
class C<E> {
  const C();
}

f() {
  return const C<int, int>();
//             ^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 1 type parameters, but 2 type arguments were given.
}
''');
  }

  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic<int> v;
// [diag.wrongNumberOfTypeArguments][column 1][length 12] The type 'dynamic' is declared with 0 type parameters, but 1 type arguments were given.
''');
  }

  test_functionInvocation_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  g<int>();
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'g' is declared with 2 type parameters, but 1 type arguments are given.
}
void g<T, U>() {}
''');
  }

  test_functionInvocation_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  g<int, String>();
// ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'g' is declared with 1 type parameters, but 2 type arguments are given.
}
void g<T>() {}
''');
  }

  test_functionReference_implicitCallTearoff_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
f(C c) {
  c<int>;
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'call' is declared with 2 type parameters, but 1 type arguments are given.
}
class C {
  void call<T, U>() {}
}
''');
  }

  test_functionReference_implicitCallTearoff_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
f(C c) {
  c<int, String>;
// ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'call' is declared with 1 type parameters, but 2 type arguments are given.
}
class C {
  void call<T>() {}
}
''');
  }

  test_functionReference_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  void foo<T, U>() {}
  foo<int>;
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 2 type parameters, but 1 type arguments are given.
}
''');
  }

  test_functionReference_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  void foo<T>() {}
  foo<int, int>;
//   ^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 1 type parameters, but 2 type arguments are given.
}
''');
  }

  test_functionTypeExpression_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
f(void Function<T, U>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int>;
//                    ^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function<T, U>()', which has 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_functionTypeExpression_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
f(void Function<T>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int, String>;
//^^^^^^^^^^^^^^^^^^^^
// [diag.disallowedTypeInstantiationExpression] Only a generic type, generic function, generic instance method, or generic constructor can have type arguments.
}
''');
  }

  test_messageText_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

@A<int>()
//^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 0 type parameters, but 1 type arguments are given.
void f() {}
''');
  }

  test_messageText_constructorInvocationWithExplicitNew_noTypeParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'Foo.bar' doesn't have type parameters.
}
''');
  }

  test_messageText_constructorInvocationWithImplicitNew_noTypeParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
//       ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'Foo.bar' doesn't have type parameters.
}
''');
  }

  test_messageText_constructorTearoff_noTypeParametersExpected() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo() {}
}

var x = A.foo<int>;
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'A.foo' doesn't have type parameters.
''');
  }

  test_messageText_dotShorthand() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class Foo<T> {
  const factory Foo.a() = _Foo;

  const Foo();
}

class _Foo<T> extends Foo<T> {
  const _Foo();
}

Foo<int> bar<T>() => const .a<int>();
//                           ^^^^^
// [diag.wrongNumberOfTypeArgumentsDotShorthandConstructor] The dot shorthand resolves to the constructor 'Foo.a', and type parameters can't be applied to dot shorthand constructor invocations.
''');
  }

  test_messageText_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic<int> v;
// [diag.wrongNumberOfTypeArguments][column 1][length 12] The type 'dynamic' is declared with 0 type parameters, but 1 type arguments were given.
''');
  }

  test_messageText_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E<T, U> {
  v<int>()
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsEnum] The enum is declared with 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_messageText_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

void f() {
  E<int>(0).foo();
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsExtension] The extension 'E' is declared with 0 type parameters, but 1 type arguments were given.
}
''');
  }

  test_messageText_functionInstantiation_duringConstEvaluation() async {
    await resolveTestCodeWithDiagnostics('''
void f<T>() {}
const dynamic x = f;
const y = (f)<int, String>;
//           ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function<T>()', which has 1 type parameters, but 2 type arguments were given.
''');
  }

  test_messageText_implicitCallTearoff() async {
    await resolveTestCodeWithDiagnostics('''
f(C c) {
  c<int>;
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'call' is declared with 2 type parameters, but 1 type arguments are given.
}
class C {
  void call<T, U>() {}
}
''');
  }

  test_messageText_instantiationOfFunctionTypedExpression() async {
    await resolveTestCodeWithDiagnostics('''
f(void Function<T, U>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int>;
//                    ^^^^^
// [diag.wrongNumberOfTypeArgumentsFunction] The type of this function is 'void Function<T, U>()', which has 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_messageText_localFunction() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  void foo<T, U>() {}
  foo<int>;
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 2 type parameters, but 1 type arguments are given.
}
''');
  }

  test_messageText_namedType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E, F> {}
A<A>? a;
// [diag.wrongNumberOfTypeArguments][column 1][length 5] The type 'A' is declared with 2 type parameters, but 1 type arguments were given.
''');
  }

  test_messageText_never() async {
    await resolveTestCodeWithDiagnostics(r'''
Never<int> f() => throw '';
// [diag.wrongNumberOfTypeArguments][column 1][length 10] The type 'Never' is declared with 0 type parameters, but 1 type arguments were given.
''');
  }

  test_messageText_prefixedConstructorInvocation() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
//         ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'p.Foo.bar' doesn't have type parameters.
}
''');
  }

  test_messageText_topLevelFunctionInvocation() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  g<int>();
// ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'g' is declared with 2 type parameters, but 1 type arguments are given.
}
void g<T, U>() {}
''');
  }

  test_messageText_topLevelFunctionTearoff_const() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo<T, U>(T a, U b) {}
const g = foo<int>;
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 2 type parameters, but 1 type arguments are given.
''');
  }

  test_messageText_typeInstantiation() async {
    await resolveTestCodeWithDiagnostics('''
class C<T, U> {}
var t = C<int>;
//       ^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 2 type parameters, but 1 type arguments were given.
''');
  }

  test_messageText_typeInstantiation_typedef() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T, U> = void Function(T, U);
var t = Fn<int>;
//        ^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'Fn' is declared with 2 type parameters, but 1 type arguments were given.
''');
  }

  test_messageText_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  late T<int> f;
//     ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'T' is declared with 0 type parameters, but 1 type arguments were given.
}
''');
  }

  test_metadata_1of0() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

@A<int>()
//^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 0 type parameters, but 1 type arguments are given.
void f() {}
''');
  }

  test_metadata_1of0_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

typedef B = A;

@B<int>()
//^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 0 type parameters, but 1 type arguments are given.
void f() {}
''');
  }

  test_metadata_1of2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {
  const A();
}

@A<int>()
//^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 2 type parameters, but 1 type arguments are given.
void f() {}
''');
  }

  test_metadata_1of2_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

typedef B<T, U> = A;

@B<int>()
//^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 2 type parameters, but 1 type arguments are given.
void f() {}
''');
  }

  test_metadata_2of1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
}

@A<int, String>()
//^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 1 type parameters, but 2 type arguments are given.
void f() {}
''');
  }

  test_metadata_2of1_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

typedef B<T> = A;

@B<int, String>()
//^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The class 'A' is declared with 1 type parameters, but 2 type arguments are given.
void f() {}
''');
  }

  test_methodInvocation_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
void f(C c) {
  c.g<int>();
//   ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'g' is declared with 2 type parameters, but 1 type arguments are given.
}
class C {
  void g<T, U>() {}
}
''');
  }

  test_methodInvocation_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
void f(C c) {
  c.g<int, String>();
//   ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'g' is declared with 1 type parameters, but 2 type arguments are given.
}
class C {
  void g<T>() {}
}
''');
  }

  test_new_nonGeneric() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f() {
  return new C<int>();
//           ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 0 type parameters, but 1 type arguments were given.
}
''');
  }

  test_new_tooFew() async {
    await resolveTestCodeWithDiagnostics('''
class C<K, V> {}

f() {
  return new C<int>();
//           ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_new_tooMany() async {
    await resolveTestCodeWithDiagnostics('''
class C<E> {}

f() {
  return new C<int, int>();
//           ^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 1 type parameters, but 2 type arguments were given.
}
''');
  }

  test_objectPattern_tooFew() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A<T, U> {
  int get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: 0):
//       ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 2 type parameters, but 1 type arguments were given.
      break;
  }
}
''');
  }

  test_objectPattern_tooMany() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: 0):
//       ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 0 type parameters, but 1 type arguments were given.
      break;
  }
}
''');
  }

  test_type_tooFew() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V> {
  late K element;
}
f(A<int> a) {
//^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 2 type parameters, but 1 type arguments were given.
  a.element.anyGetterExistsInDynamic;
}
''');
  }

  test_type_tooMany() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  late E element;
}
f(A<int, int> a) {
//^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 1 type parameters, but 2 type arguments were given.
  a.element.anyGetterExistsInDynamic;
}
''');
  }

  test_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  late T<int> f;
//     ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'T' is declared with 0 type parameters, but 1 type arguments were given.
}
''');
  }

  test_typeTest_tooFew() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
//            ^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 2 type parameters, but 1 type arguments were given.
}
''');
  }

  test_typeTest_tooMany() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
//            ^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'C' is declared with 1 type parameters, but 2 type arguments were given.
}
''');
  }
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest_ExtensionType
    extends PubPackageResolutionTest {
  test_notGeneric() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f(A<int> a) {}
//     ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 0 type parameters, but 1 type arguments were given.
''');

    var node = result.findNode.namedType('A<int>');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<S, T>(int it) {}

void f(A<int> a) {}
//     ^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 2 type parameters, but 1 type arguments were given.
''');

    var node = result.findNode.namedType('A<int>');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}

void f(A<int, String> a) {}
//     ^^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'A' is declared with 1 type parameters, but 2 type arguments were given.
''');

    var node = result.findNode.namedType('A<int, String>');
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
