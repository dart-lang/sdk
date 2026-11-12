// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies function types and type parameters of generic function types
// in various contexts (nested generic function types, function types inside
// generic functions, closures inside generic functions, tear-offs).

import 'package:expect/expect.dart';

typedef G1 = U Function<U>(U);
typedef Nested = void Function<U>(void Function<V>(U, V));

class C<T> {
  R m<R>(T t, R Function(T) f) => f(t);

  Type typeOfM<R>() => (R Function(T) f) {}.runtimeType;
}

Type typeOf<X>() => X;

Object outer<T>() {
  T id(T x) => x;
  return id;
}

Object outerGeneric<T>() {
  S g<S>(T t, S s) => s;
  return g;
}

Object outerNested<T>() {
  void h<U>(void Function<V>(T, U, V) f) {}
  return h;
}

Object typeInsideGeneric<T>() => typeOf<int Function()>();

Object genericTypeInsideGeneric<T>() => typeOf<S Function<S>(T, S)>();

bool isCheck<T>(Object o) => o is T Function(T);

bool isGenericCheck<T>(Object o) => o is S Function<S>(T, S);

T Function(T) castCheck<T>(Object o) => o as T Function(T);

Object instantiateTearOff<T>() {
  S g<S>(T t, S s) => s;
  final String Function(T, String) f = g;
  return f;
}

int foo<A, B>(A a, B b) => 0;

void main() {
  G1 f1 = <U>(U u) => u;
  Expect.equals(typeOf<G1>(), f1.runtimeType);
  Expect.equals(
    typeOf<Nested>(),
    typeOf<void Function<A>(void Function<B>(A, B))>(),
  );
  Expect.notEquals(
    typeOf<Nested>(),
    typeOf<void Function<A>(void Function<B>(B, A))>(),
  );

  final o1 = outer<int>();
  Expect.isTrue(o1 is int Function(int));
  Expect.isFalse(o1 is String Function(String));
  Expect.equals(typeOf<int Function(int)>(), o1.runtimeType);

  final o2 = outerGeneric<int>();
  Expect.isTrue(o2 is S Function<S>(int, S));
  Expect.isFalse(o2 is S Function<S>(String, S));
  Expect.equals(typeOf<S Function<S>(int, S)>(), o2.runtimeType);

  final o3 = outerNested<String>();
  Expect.equals(
    typeOf<void Function<U>(void Function<V>(String, U, V))>(),
    o3.runtimeType,
  );
  Expect.notEquals(
    typeOf<void Function<U>(void Function<V>(String, V, U))>(),
    o3.runtimeType,
  );

  Expect.equals(typeOf<int Function()>(), typeInsideGeneric<String>());
  Expect.equals(
    typeOf<S Function<S>(double, S)>(),
    genericTypeInsideGeneric<double>(),
  );

  Expect.isTrue(isCheck<int>(o1));
  Expect.isFalse(isCheck<String>(o1));
  Expect.isTrue(isGenericCheck<int>(o2));
  Expect.isFalse(isGenericCheck<String>(o2));
  Expect.equals(42, castCheck<int>(o1)(42));
  Expect.throwsTypeError(() => castCheck<String>(o1));

  Expect.equals(
    typeOf<String Function(int, String)>(),
    instantiateTearOff<int>().runtimeType,
  );

  final c = C<int>();
  Expect.equals('v1', c.m<String>(1, (int x) => 'v$x'));
  Expect.equals(
    typeOf<Null Function(String Function(int))>(),
    c.typeOfM<String>(),
  );
  final tearOff = c.m;
  Expect.equals(
    typeOf<R Function<R>(Object?, R Function(int))>(),
    tearOff.runtimeType,
  );
  final instTearOff = c.m<double>;
  Expect.equals(
    typeOf<double Function(Object?, double Function(int))>(),
    instTearOff.runtimeType,
  );

  Expect.equals(typeOf<int Function<A, B>(A, B)>(), (foo).runtimeType);
  Expect.equals(
    typeOf<int Function(int, String)>(),
    (foo<int, String>).runtimeType,
  );

  final ctor = C.new;
  Expect.equals(typeOf<C<T> Function<T>()>(), ctor.runtimeType);

  dynamic d = <T extends num>(T x) => x;
  Expect.equals(3, d<int>(3));
  Expect.throwsTypeError(() => d<String>('a'));
}
