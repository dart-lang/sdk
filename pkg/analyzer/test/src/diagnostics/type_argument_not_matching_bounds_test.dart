// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeArgumentNotMatchingBoundsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeArgumentNotMatchingBoundsTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
mixin C {}
class G<E extends A> {}
class D = G<B> with C;
//          ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }
//                   ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_const_matching() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }
''');
  }

  test_enum_inferred() async {
    await resolveTestCodeWithDiagnostics('''
enum E<T extends int> {
  v('');
//  ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
// [diag.constConstructorParamTypeMismatch] A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.
  const E(T t);
}
''');
  }

  test_enum_superBounded() async {
    await resolveTestCodeWithDiagnostics('''
enum E<T extends E<T>> {
  v<Never>()
}
''');
  }

  test_enum_withTypeArguments() async {
    await resolveTestCodeWithDiagnostics('''
enum E<T extends int> {
  v<String>()
//  ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'int' of the type parameter 'T'.
}
''');
  }

  test_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
class C extends G<B>{}
//                ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_extends_regressionInIssue18468Fix() async {
    // https://code.google.com/p/dart/issues/detail?id=18628
    await resolveTestCodeWithDiagnostics(r'''
class X<T extends Type> {}
class Y<U> extends X<U> {}
//                   ^
// [diag.typeArgumentNotMatchingBounds] 'U' doesn't conform to the bound 'Type' of the type parameter 'T'.
''');
  }

  test_extensionOverride_hasTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T extends num> on int {
  void foo() {}
}

void f() {
  E<String>(0).foo();
//  ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_extensionOverride_hasTypeArguments_call() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E<T extends num> on int {
  void call() {}
}

void f() {
  E<String>(0)();
//  ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_extensionType_superBounded() async {
    await resolveTestCodeWithDiagnostics('''
extension type A<T extends A<T>>(int it) {}

void f(A a) {}
//     ^
// [context 1] The raw type was instantiated as 'A<A<dynamic>>', and is not regular-bounded.
// [diag.typeArgumentNotMatchingBounds][context 1] 'A<dynamic>' doesn't conform to the bound 'A<A<dynamic>>' of the type parameter 'T'.
''');
  }

  test_extensionType_withTypeArguments() async {
    await resolveTestCodeWithDiagnostics('''
extension type A<T extends num>(int it) {}

void f(A<String> a) {}
//       ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
''');
  }

  test_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  var f;
  C(G<B> this.f) {}
//  ^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//    ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
}
''');
  }

  test_functionExpressionInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  (<T extends num>() {})<String>();
//                       ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_functionExpressionInvocation_implicitCall() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call<T extends num>() {}
}

void f(C c) {
  c<String>();
//  ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_functionReference() async {
    await resolveTestCodeWithDiagnostics('''
void foo<T extends num>(T a) {}
void bar() {
  foo<String>;
//    ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_functionReference_matching() async {
    await resolveTestCodeWithDiagnostics('''
void foo<T extends num>(T a) {}
void bar() {
  foo<int>;
}
''');
  }

  test_functionReference_regularBounded() async {
    await resolveTestCodeWithDiagnostics('''
void foo<T>(T a) {}
void bar() {
  foo<String>;
}
''');
  }

  test_functionReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
G<B> f() => throw 0;
// [context 1][column 1][length 4] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_functionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
typedef G<B> f();
//      ^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//        ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_functionTypedFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> h()) {}
//^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//  ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_genericFunctionTypeArgument_invariant() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = T Function<T>(T);
typedef FB<T extends F> = S Function<S extends T>(S);
class CB<T extends F> {}
void f(CB<FB<F>> a) {}
//     ^^^^^^^^^
// [context 1] The inverted type 'CB<S Function<S extends T Function<T>(T)>(S)>' is also not regular-bounded, so the type is not well-bounded.
//        ^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'FB<F>' doesn't conform to the bound 'F' of the type parameter 'T'.
''');
  }

  test_genericFunctionTypeArgument_regularBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F1 = T Function<T>(T);
typedef F2 = S Function<S>(S);
class CB<T extends F1> {}
void f(CB<F2> a) {}
''');
  }

  test_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
class C implements G<B>{}
//                   ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_is() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
var b = 1 is G<B>;
//           ^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//             ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_metadata_matching() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {
  const A();
}

@A<int>()
void f() {}
''');
  }

  test_metadata_notMatching() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {
  const A();
}

@A<String>()
// ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
void f() {}
''');
  }

  test_metadata_notMatching_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
}

typedef B<T extends num> = A<T>;

@B<String>()
// ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
void f() {}
''');
  }

  test_methodInvocation_genericFunctionTypeArgument_match() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function<T extends num>();
void f<T extends void Function<X extends num>()>() {}
void g() {
  f<F>();
}
''');
  }

  test_methodInvocation_genericFunctionTypeArgument_mismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
typedef F = void Function<T extends A>();
void f<T extends void Function<U extends B>()>() {}
void g() {
  f<F>();
//  ^
// [diag.typeArgumentNotMatchingBounds] 'F' doesn't conform to the bound 'void Function<U extends B>()' of the type parameter 'T'.
}
''');
  }

  test_methodInvocation_localFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class Point<T extends num> {
  Point(T x, T y);
}

main() {
  Point<T> f<T extends num>(T x, T y) {
    return new Point<T>(x, y);
  }
  print(f<String>('hello', 'world'));
//        ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_methodInvocation_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class Point<T extends num> {
  Point(T x, T y);
}

class PointFactory {
  Point<T> point<T extends num>(T x, T y) {
    return new Point<T>(x, y);
  }
}

f(PointFactory factory) {
  print(factory.point<String>('hello', 'world'));
//                    ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_methodInvocation_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class Point<T extends num> {
  Point(T x, T y);
}

Point<T> f<T extends num>(T x, T y) {
  return new Point<T>(x, y);
}

main() {
  print(f<String>('hello', 'world'));
//        ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
}
''');
  }

  test_methodReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  G<B> m() => throw 0;
//^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//  ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
}
''');
  }

  test_new() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
f() { return new G<B>(); }
//                 ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_new_matching() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class G<E extends A> {}
f() { return new G<B>(); }
''');
  }

  test_new_superTypeOfUpperBound() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class C extends B {}
class G<E extends B> {}
f() { return new G<A>(); }
//                 ^
// [diag.typeArgumentNotMatchingBounds] 'A' doesn't conform to the bound 'B' of the type parameter 'E'.
''');
  }

  test_nonFunctionTypeAlias_body_typeArgument_mismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<T extends A> {}
typedef X = G<B>;
//            ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'T'.
''');
  }

  test_nonFunctionTypeAlias_body_typeArgument_regularBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class G<T extends A> {}
typedef X = G<B>;
''');
  }

  test_nonFunctionTypeAlias_body_typeArgument_superBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends A<T>> {}
typedef X = List<A>;
''');
  }

  test_nonFunctionTypeAlias_interfaceType_body_mismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<T extends A> {}
typedef X = G<B>;
//            ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'T'.
''');
  }

  test_nonFunctionTypeAlias_interfaceType_body_regularBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
typedef X<T> = A;
''');
  }

  test_nonFunctionTypeAlias_interfaceType_body_superBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends A<T>> {}
typedef X<T> = A;
//             ^
// [context 1] The raw type was instantiated as 'A<A<dynamic>>', and is not regular-bounded.
// [diag.typeArgumentNotMatchingBounds][context 1] 'A<dynamic>' doesn't conform to the bound 'A<A<dynamic>>' of the type parameter 'T'.
''');
  }

  test_nonFunctionTypeAlias_interfaceType_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef X<T extends A> = Map<int, T>;
void f(X<String> a) {}
//     ^^^^^^^^^
// [context 1] The inverted type 'X<String>' is also not regular-bounded, so the type is not well-bounded.
//       ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'A' of the type parameter 'T'.
''');
  }

  test_nonFunctionTypeAlias_interfaceType_parameter_regularBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
typedef X<T extends A> = Map<int, T>;
void f(X<B> a) {}
''');
  }

  Future<void> test_nonFunctionTypeAlias_parameter() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}
class D<T> {}
typedef Alias<T extends B> = D<T>;
main() {
  D d = Alias<A>();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
//            ^
// [diag.typeArgumentNotMatchingBounds] 'A' doesn't conform to the bound 'B' of the type parameter 'T'.
}
''');
  }

  test_not_matching_bounds() async {
    // There should be an error, because Bar's type argument T is Foo, which
    // doesn't extends Foo<T>.
    var result = await resolveTestCodeWithDiagnostics('''
class Foo<T> {}
class Bar<T extends Foo<T>> {}
class Baz extends Bar {}
//                ^^^
// [context 1] The raw type was instantiated as 'Bar<Foo<dynamic>>', and is not regular-bounded.
// [diag.typeArgumentNotMatchingBounds][context 1] 'Foo<dynamic>' doesn't conform to the bound 'Foo<Foo<dynamic>>' of the type parameter 'T'.
void main() {}
''');
    // Instantiate-to-bounds should have instantiated "Bar" to "Bar<Foo>".
    assertType(result.findElement.class_('Baz').supertype, 'Bar<Foo<dynamic>>');
  }

  test_notRegularBounded_notSuperBounded_parameter_invariant() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X Function(X);
typedef G<X extends A<X>> = void Function<Y extends X>();
foo(G g) {}
//  ^
// [context 1] The raw type was instantiated as 'G<dynamic Function(dynamic)>', and is not regular-bounded.
// [context 2] The inverted type 'G<Never Function(Never)>' is also not regular-bounded, so the type is not well-bounded.
// [diag.typeArgumentNotMatchingBounds][context 1][context 2] 'A<Never>' doesn't conform to the bound 'A<A<Never>>' of the type parameter 'X'.
''');
  }

  test_ofFunctionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
typedef F<T extends A>();
F<B> fff = (throw 42);
// [context 1][column 1][length 4] The inverted type 'F<B>' is also not regular-bounded, so the type is not well-bounded.
//^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'T'.
''');
  }

  test_ofFunctionTypeAlias_hasBound2_matching() async {
    await resolveTestCodeWithDiagnostics(r'''
class MyClass<T> {}
typedef MyFunction<T, P extends MyClass<T>>();
class A<T, P extends MyClass<T>> {
  MyFunction<T, P> f = (throw 0);
}
''');
  }

  test_ofFunctionTypeAlias_hasBound_matching() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
typedef F<T extends A>();
F<A> fa = (throw 0);
F<B> fb = (throw 0);
''');
  }

  test_ofFunctionTypeAlias_noBound_matching() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<T>();
F<int> f1 = (throw 0);
F<String> f2 = (throw 0);
''');
  }

  test_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> g) {}
//^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//  ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_redirectingConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class X<T extends A> {
  X(int x, int y) {}
  factory X.name(int x, int y) = X<B>;
//                               ^^^^
// [diag.redirectToInvalidReturnType] The return type 'X<B>' of the redirected constructor isn't a subtype of 'X<T>'.
//                                 ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'T'.
}
''');
  }

  test_regression_42196() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X,Y>>, Y extends X> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Never, Never>>, dynamic>>();
}
''');
  }

  test_regression_42196_object() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X, Y>>, Y extends Never> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Never, Never>>, Object?>>();
}
''');
  }

  test_regression_42196_void() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X, Y>>, Y extends Never> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Never, Never>>, void>>();
}
''');
  }

  test_superBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<X extends A<X>> {}

A get foo => throw 0;
''');
  }

  test_typeArgumentList() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class C<E> {}
class D<E extends A> {}
C<D<B>> c = (throw 0);
//^^^^
// [context 1] The inverted type 'D<B>' is also not regular-bounded, so the type is not well-bounded.
//  ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_typeLiteral_class() async {
    await resolveTestCodeWithDiagnostics('''
class C<T extends int> {}
var t = C<String>;
//      ^^^^^^^^^
// [context 1] The inverted type 'C<String>' is also not regular-bounded, so the type is not well-bounded.
//        ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'int' of the type parameter 'T'.
''');
  }

  test_typeLiteral_functionTypeAlias() async {
    await resolveTestCodeWithDiagnostics('''
typedef Cb<T extends int> = void Function();
var t = Cb<String>;
//      ^^^^^^^^^^
// [context 1] The inverted type 'Cb<String>' is also not regular-bounded, so the type is not well-bounded.
//         ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'int' of the type parameter 'T'.
''');
  }

  test_typeLiteral_typeAlias() async {
    await resolveTestCodeWithDiagnostics('''
class C {}
typedef D<T extends int> = C;
var t = D<String>;
//      ^^^^^^^^^
// [context 1] The inverted type 'D<String>' is also not regular-bounded, so the type is not well-bounded.
//        ^^^^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'String' doesn't conform to the bound 'int' of the type parameter 'T'.
''');
  }

  test_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D<F extends G<B>> {}
//                ^^^^
// [context 1] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//                  ^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_variableDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class G<E extends A> {}
G<B> g = (throw 0);
// [context 1][column 1][length 4] The inverted type 'G<B>' is also not regular-bounded, so the type is not well-bounded.
//^
// [diag.typeArgumentNotMatchingBounds][context 1] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }

  test_with() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
mixin G<E extends A> {}
class C extends Object with G<B>{}
//                            ^
// [diag.typeArgumentNotMatchingBounds] 'B' doesn't conform to the bound 'A' of the type parameter 'E'.
''');
  }
}
