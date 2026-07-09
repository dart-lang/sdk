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
  void assertHasDependentDotShorthand(TestResolvedUnitResult result) async {
    var initializer = result.findNode.singleVariableDeclaration.initializer;
    expect(hasDependentDotShorthand(initializer!), isTrue);
  }

  void assertHasNoDependentDotShorthand(TestResolvedUnitResult result) async {
    var initializer = result.findNode.singleVariableDeclaration.initializer;
    expect(hasDependentDotShorthand(initializer!), isFalse);
  }

  test_constructorInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<X> {
  A(X x);
  A.named(X x);
}

A<A> a = A(.named(null));
''');
    assertHasDependentDotShorthand(result);
  }

  test_constructorInvocation_explicitTypeArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<X> {
  A(X x);
  A.named(X x);
}

A<A> a = A<A>(.named(null));
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_constructorInvocation_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<X> {
  A(X x);
  A.named(X x);
}

X id<X>(X x) => x;

A<A> a = A(id(.named(null)));
''');
    assertHasDependentDotShorthand(result);
  }

  test_constructorInvocation_noTypeParametersInParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<X> {
  A(int x);
}

A<String> a = A(.parse('0'));
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_functionExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

E Function() e = () => .a;
''');
    assertHasDependentDotShorthand(result);
  }

  test_functionExpression_list() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

List<E> Function() e = () => [.a];
''');
    assertHasDependentDotShorthand(result);
  }

  test_list() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

List<E> e = [.b];
''');
    assertHasDependentDotShorthand(result);
  }

  test_map() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

Map<String, E> e = {'test': .b};
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }
T f<T>(T t) => t;

E e = f(.a);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_filterTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_functionType_parameter_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S f<S>(S Function() s) => s();

T t<T>(T t) => t;

E e = f(() { return t(.a); });
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_functionType_parameter_blockBody_independent() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S f<S>(S Function() s) => s();

E eFn(E e) => e;

E e = f(() { return eFn(.a); });
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_methodInvocation_functionType_parameter_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S f<S>(S Function() s) => s();

E e = f(() => .a);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_functionType_parameter_expressionBody2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S f<S>(S Function(S) s, S input) => s(input);

E e = f((E _) => .a, E.b);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_functionType_returnType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S Function(T) f<T, S>(T t, S s) => (T t) => s;

E Function(E) e = f(E.a, .b);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_functionType_returnType2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S Function(T) f<T, S>(T t, S s) => (T t) => s;

E Function(E) e = f(.a, E.b);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_list() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

S f<S>(List<S> s) => s[0];

E e = f([.a, .b]);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_multipleTypeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

E d(E e) => e;

S f<T, S>(T t, S s) => s;

T g<T>(T t) => t;

E e = f(d(.a), g(.b));
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_multipleTypeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

E d(E e) => e;

S f<T, S>(T t, S s) => s;

T g<T>(T t) => t;

E e = f(d(.a), E.b);
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_methodInvocation_noTypeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c; }

T id<T>(T t) => t;

E idE(E e) => e;

E e = idE(id(.b));
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(.a, .b);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter_explicitTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f<E>(.a, .b);
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T? Function() d<T>(T t) => () { return t;};

E? Function() e = d(.a);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter_functionType_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T? Function() d<T>(T t) => () { return t;};
T f<T>(T t, E e) => t;

E? Function() e = d(f(.a, .b));
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter_independent() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(E.a, .b);
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(f(.a, .b), .c);
''');
    assertHasDependentDotShorthand(result);
  }

  test_methodInvocation_singleTypeParameter_nested_independent() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

T f<T>(T t, E e) => t;

E e = f(E.a, f(.b, .c));
''');
    assertHasNoDependentDotShorthand(result);
  }

  test_set() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { a, b, c }

Set<E> e = {.b};
''');
    assertHasDependentDotShorthand(result);
  }
}
