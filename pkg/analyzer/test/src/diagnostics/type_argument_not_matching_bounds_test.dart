// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeArgumentNotMatchingBoundsTest);
    defineReflectiveTests(
      TypeArgumentNotMatchingBoundsWithNullSafetyTest,
    );
  });
}

@reflectiveTest
class TypeArgumentNotMatchingBoundsTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D = G<B> with C;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 69, 1),
    ]);
  }

  test_const() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 81, 1),
    ]);
  }

  test_const_matching() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }
''');
  }

  test_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
class C extends G<B>{}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 64, 1),
    ]);
  }

  test_extends_regressionInIssue18468Fix() async {
    // https://code.google.com/p/dart/issues/detail?id=18628
    await assertErrorsInCode(r'''
class X<T extends Type> {}
class Y<U> extends X<U> {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 48, 1),
    ]);
  }

  test_extensionOverride_hasTypeArguments() async {
    await assertErrorsInCode(r'''
extension E<T extends num> on int {
  void foo() {}
}

void f() {
  E<String>(0).foo();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 70, 6),
    ]);
  }

  test_extensionOverride_hasTypeArguments_call() async {
    await assertErrorsInCode(r'''
extension E<T extends num> on int {
  void call() {}
}

void f() {
  E<String>(0)();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 71, 6),
    ]);
  }

  test_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  var f;
  C(G<B> this.f) {}
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 71, 1),
    ]);
  }

  test_functionReturnType() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
G<B> f() => throw 0;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 48, 1),
    ]);
  }

  test_functionTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
typedef G<B> f();
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 56, 1),
    ]);
  }

  test_functionTypedFormalParameter() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> h()) {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 50, 1),
    ]);
  }

  test_implements() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
class C implements G<B>{}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 67, 1),
    ]);
  }

  test_is() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
var b = 1 is G<B>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 61, 1),
    ]);
  }

  test_methodInvocation_localFunction() async {
    await assertErrorsInCode(r'''
class Point<T extends num> {
  Point(T x, T y);
}

main() {
  Point<T> f<T extends num>(T x, T y) {
    return new Point<T>(x, y);
  }
  print(f<String>('hello', 'world'));
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 145, 6),
    ]);
  }

  test_methodInvocation_method() async {
    await assertErrorsInCode(r'''
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
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 202, 6),
    ]);
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode(r'''
class Point<T extends num> {
  Point(T x, T y);
}

Point<T> f<T extends num>(T x, T y) {
  return new Point<T>(x, y);
}

main() {
  print(f<String>('hello', 'world'));
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 140, 6),
    ]);
  }

  test_methodReturnType() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  G<B> m() => throw 0;
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 60, 1),
    ]);
  }

  test_new() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
f() { return new G<B>(); }
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 65, 1),
    ]);
  }

  test_new_matching() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class G<E extends A> {}
f() { return new G<B>(); }
''');
  }

  test_new_superTypeOfUpperBound() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends B {}
class G<E extends B> {}
f() { return new G<A>(); }
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 96, 1),
    ]);
  }

  test_not_matching_bounds() async {
    // There should be an error, because Bar's type argument T is Foo, which
    // doesn't extends Foo<T>.
    await assertErrorsInCode('''
class Foo<T> {}
class Bar<T extends Foo<T>> {}
class Baz extends Bar {}
void main() {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 65, 3),
    ]);
    // Instantiate-to-bounds should have instantiated "Bar" to "Bar<Foo>".
    assertType(result.unit.declaredElement.getType('Baz').supertype,
        'Bar<Foo<dynamic>>');
  }

  test_ofFunctionTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
typedef F<T extends A>();
F<B> fff = (throw 42);
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 50, 1),
    ]);
  }

  test_ofFunctionTypeAlias_hasBound2_matching() async {
    await assertNoErrorsInCode(r'''
class MyClass<T> {}
typedef MyFunction<T, P extends MyClass<T>>();
class A<T, P extends MyClass<T>> {
  MyFunction<T, P> f = (throw 0);
}
''');
  }

  test_ofFunctionTypeAlias_hasBound_matching() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
typedef F<T extends A>();
F<A> fa = (throw 0);
F<B> fb = (throw 0);
''');
  }

  test_ofFunctionTypeAlias_noBound_matching() async {
    await assertNoErrorsInCode(r'''
typedef F<T>();
F<int> f1 = (throw 0);
F<String> f2 = (throw 0);
''');
  }

  test_parameter() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> g) {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 50, 1),
    ]);
  }

  test_redirectingConstructor() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class X<T extends A> {
  X(int x, int y) {}
  factory X.name(int x, int y) = X<B>;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_INVALID_RETURN_TYPE, 99, 4),
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 101, 1),
    ]);
  }

  test_regression_42196_Null() async {
    await assertNoErrorsInCode(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X,Y>>, Y extends X> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Null, Null>>, dynamic>>();
}
''');
  }

  test_typeArgumentList() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C<E> {}
class D<E extends A> {}
C<D<B>> c = (throw 0);
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 64, 1),
    ]);
  }

  test_typeParameter() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D<F extends G<B>> {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 77, 1),
    ]);
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
G<B> g = (throw 0);
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 48, 1),
    ]);
  }

  test_with() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {}
class C extends Object with G<B>{}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 76, 1),
    ]);
  }
}

@reflectiveTest
class TypeArgumentNotMatchingBoundsWithNullSafetyTest
    extends TypeArgumentNotMatchingBoundsTest with WithNullSafetyMixin {
  test_extends_optIn_fromOptOut_Null() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<X extends int> {}
''');

    await assertNoErrorsInCode(r'''
// @dart=2.6
import 'a.dart';

class A1<T extends Null> extends A<T> {}
''');
  }

  test_extends_optIn_fromOptOut_otherTypeParameter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void foo<T extends U, U>() {
}
''');

    await assertNoErrorsInCode(r'''
// @dart=2.6
import 'a.dart';

class A {}
class B extends A {}

main() {
  foo<B, A>();
}
''');
  }

  test_regression_42196() async {
    await assertNoErrorsInCode(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X,Y>>, Y extends X> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Never, Never>>, dynamic>>();
}
''');
  }

  @override
  test_regression_42196_Null() async {
    await assertErrorsInCode(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X,Y>>, Y extends X> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Null, Null>>, dynamic>>();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 120, 16),
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 124, 4),
    ]);
  }

  test_regression_42196_object() async {
    await assertNoErrorsInCode(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X, Y>>, Y extends Never> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Never, Never>>, Object?>>();
}
''');
  }

  test_regression_42196_void() async {
    await assertNoErrorsInCode(r'''
typedef G<X> = Function(X);
class A<X extends G<A<X, Y>>, Y extends Never> {}

test<X>() { print("OK"); }

main() {
  test<A<G<A<Never, Never>>, void>>();
}
''');
  }

  test_superBounded() async {
    await assertNoErrorsInCode(r'''
class A<X extends A<X>> {}

A get foo => throw 0;
''');
  }
}
