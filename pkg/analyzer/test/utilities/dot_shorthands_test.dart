// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/dot_shorthands.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HasDependentDotShorthandTest);
  });
}

@reflectiveTest
class HasDependentDotShorthandTest extends PubPackageResolutionTest {
  void assertHasDependentDotShorthand() async {
    var initializer = findNode.singleVariableDeclaration.initializer;
    expect(hasDependentDotShorthand(initializer!), isTrue);
  }

  void assertHasNoDependentDotShorthand() async {
    var initializer = findNode.singleVariableDeclaration.initializer;
    expect(hasDependentDotShorthand(initializer!), isFalse);
  }

  test_constructorInvocation() async {
    await assertNoErrorsInCode(r'''
class A<X> {
  A(X x);
  A.named(X x);
}

A<A> a = A(.named(null));
''');
    assertHasDependentDotShorthand();
  }

  test_constructorInvocation_explicitTypeArgument() async {
    await assertNoErrorsInCode(r'''
class A<X> {
  A(X x);
  A.named(X x);
}

A<A> a = A<A>(.named(null));
''');
    assertHasNoDependentDotShorthand();
  }

  test_constructorInvocation_nested() async {
    await assertNoErrorsInCode(r'''
class A<X> {
  A(X x);
  A.named(X x);
}

X id<X>(X x) => x;

A<A> a = A(id(.named(null)));
''');
    assertHasDependentDotShorthand();
  }

  test_constructorInvocation_noTypeParametersInParameter() async {
    await assertNoErrorsInCode(r'''
class A<X> {
  A(int x);
}

A<String> a = A(.parse('0'));
''');
    assertHasNoDependentDotShorthand();
  }

  test_functionExpression() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

E Function() e = () => .a;
''');
    assertHasDependentDotShorthand();
  }

  test_functionExpression_list() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

List<E> Function() e = () => [.a];
''');
    assertHasDependentDotShorthand();
  }

  test_list() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

List<E> e = [.b];
''');
    assertHasDependentDotShorthand();
  }

  test_map() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

Map<String, E> e = {'test': .b};
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }
T f<T>(T t) => t;

E e = f(.a);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_filterTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named();
}

X id<X>(X x) => x;

bar<T extends A>(T t) {
  Map<T, S> baz<S>(T t, S s) => {t: s};
  Map<T, A> m = baz(id(id(id(id(id(id(t)))))), .named());
  print(m);
}
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_functionType_parameter_blockBody() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S f<S>(S Function() s) => s();

T t<T>(T t) => t;

E e = f(() { return t(.a); });
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_functionType_parameter_blockBody_independent() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S f<S>(S Function() s) => s();

E eFn(E e) => e;

E e = f(() { return eFn(.a); });
''');
    assertHasNoDependentDotShorthand();
  }

  test_methodInvocation_functionType_parameter_expressionBody() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S f<S>(S Function() s) => s();

E e = f(() => .a);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_functionType_parameter_expressionBody2() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S f<S>(S Function(S) s, S input) => s(input);

E e = f((E _) => .a, E.b);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_functionType_returnType() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S Function(T) f<T, S>(T t, S s) => (T t) => s;

E Function(E) e = f(E.a, .b);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_functionType_returnType2() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S Function(T) f<T, S>(T t, S s) => (T t) => s;

E Function(E) e = f(.a, E.b);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_list() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

S f<S>(List<S> s) => s[0];

E e = f([.a, .b]);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_multipleTypeParameter() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

E d(E e) => e;

S f<T, S>(T t, S s) => s;

T g<T>(T t) => t;

E e = f(d(.a), g(.b));
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_multipleTypeParameters() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

E d(E e) => e;

S f<T, S>(T t, S s) => s;

T g<T>(T t) => t;

E e = f(d(.a), E.b);
''');
    assertHasNoDependentDotShorthand();
  }

  test_methodInvocation_noTypeParameters() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c; }

T id<T>(T t) => t;

E idE(E e) => e;

E e = idE(id(.b));
''');
    assertHasNoDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(.a, .b);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter_explicitTypeArguments() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f<E>(.a, .b);
''');
    assertHasNoDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter_functionType() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T? Function() d<T>(T t) => () { return t;};

E? Function() e = d(.a);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter_functionType_nested() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T? Function() d<T>(T t) => () { return t;};
T f<T>(T t, E e) => t;

E? Function() e = d(f(.a, .b));
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter_independent() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(E.a, .b);
''');
    assertHasNoDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter_nested() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(f(.a, .b), .c);
''');
    assertHasDependentDotShorthand();
  }

  test_methodInvocation_singleTypeParameter_nested_independent() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(E.a, f(.b, .c));
''');
    assertHasNoDependentDotShorthand();
  }

  test_set() async {
    await assertNoErrorsInCode(r'''
enum E { a, b, c }

Set<E> e = {.b};
''');
    assertHasDependentDotShorthand();
  }
}
