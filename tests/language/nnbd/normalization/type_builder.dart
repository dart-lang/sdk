// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

// This defines a set of higher order combinators for building objects
// of type Type at runtime.  A key constraint behind this design is that
// the structure of the Type objects is constructed at runtime by
// applying type constructors (e.g. `FutureOr`) to types provided via
// instantiation of generic methods.  This ensures that normalization
// is performed at runtime (or during optimization in the compiler) rather
// than as a simple static rewrite in the front end.

// A TypeBuilder is a parametric type builder that allows composing together
// different builders at runtime.  The intuition is that a
// TypeBuilder represents a latent computation of a type `T`.
// TypeBuilders can be composed together to produce computations
// which compute more complex types.  For example, we define below
// `FutureOr` combinator which given a TypeBuilder for a type `T`
// produces a TypeBuilder for the type `FutureOr<T>`.
// The type represented by a TypeBuilder can be reified into a runtime
// type object by calling the TypeBuilder with a generic function which
// uses its type parameter to produce a runtime type object as desired.
// So for example, calling the TypeBuilder representing the type `int`
// with `<T>() => T` produces the runtime Type representation of `int`.
typedef TypeBuilder = Type Function(Type Function<T>());

// Given a type `T`, produce a TypeBuilder which builds `T`
TypeBuilder $Primitive<T>() => (build) => build<T>();

// Given a TypeBuilder for a type `T`, return a TypeBuilder for `FutureOr<T>`
TypeBuilder $FutureOr(TypeBuilder of) =>
    (build) => of(<T>() => build<FutureOr<T>>());

// Given a TypeBuilder for a type `T`, return a TypeBuilder for `T?`
TypeBuilder $OrNull(TypeBuilder of) => (build) => of(<T>() => build<T?>());

// Given a TypeBuilder for a type `T`, return a TypeBuilder for `List<T>`
TypeBuilder $List(TypeBuilder of) => (build) => of(<T>() => build<List<T>>());

// Given a TypeBuilder for a type `T`, return a TypeBuilder for `Future<T>`
TypeBuilder $Future(TypeBuilder of) =>
    (build) => of(<T>() => build<Future<T>>());

// Given a TypeBuilder for a type `From` and a TypeBuilder for a type `To`,
// return a TypeBuilder for `To Function(From)`
TypeBuilder $Function1(TypeBuilder from, TypeBuilder to) =>
    (build) => from(<From>() => to(<To>() => build<To Function(From)>()));

// Given a TypeBuilder for a type `From` and a TypeBuilder for a type `To`,
// return a TypeBuilder for `To Function({From a})`
TypeBuilder $FunctionOptionalNamedA(TypeBuilder from, TypeBuilder to) =>
    (build) => from(<From>() => to(<To>() => build<To Function({From a})>()));

// Given a TypeBuilder for a type `From` and a TypeBuilder for a type `To`,
// return a TypeBuilder for `To Function({From b})`
TypeBuilder $FunctionOptionalNamedB(TypeBuilder from, TypeBuilder to) =>
    (build) => from(<From>() => to(<To>() => build<To Function({From b})>()));

// Given a TypeBuilder for a type `From` and a TypeBuilder for a type `To`,
// return a TypeBuilder for `To Function({required From a})`
TypeBuilder $FunctionRequiredNamedA(TypeBuilder from, TypeBuilder to) =>
    (build) =>
        from(<From>() => to(<To>() => build<To Function({required From a})>()));

// Define some primitive TypeBuilder objects
TypeBuilder $int = $Primitive<int>();
TypeBuilder $Object = $Primitive<Object>();
TypeBuilder $ObjectQ = $OrNull($Object);
TypeBuilder $dynamic = $Primitive<dynamic>();
TypeBuilder $void = $Primitive<void>();
TypeBuilder $Never = $Primitive<Never>();
TypeBuilder $Null = $Primitive<Null>();

// A helper class for testing equality of objects produced
// by the .runtimeType method.
class Rep<T> {}

TypeBuilder $Rep(TypeBuilder of) => (build) => of(<R>() => build<Rep<R>>());

// A helper class for testing equality of objects produced
// by implicit calls to noSuchMethod.
class NSM {
  Type noSuchMethod(i) => i.typeArguments.first;
}

// Given a TypeBuilder for `T`, reify `T` directly to a Type object
Type typeObjectOf(TypeBuilder build) => build(<T>() => T);

// Given a TypeBuilder for a type `T`, create an instance o of `Rep<T>`
// and return the result of calling o.runtimeType
Type runtimeTypeOfRepOf(TypeBuilder build) =>
    build(<T>() => Rep<T>().runtimeType);

// Given a TypeBuilder for a type `T`, cause an invocation NSM.noSuchMethod
// `T` as a runtime type object in the `typeArguments` list of the Invocation
// object passed to the handler, and return that runtime type object as the
// result.
Type noSuchMethodTypeOf(TypeBuilder build) =>
    build(<T>() => (NSM() as dynamic).method<T>());

// Check that two objects are equal to themselves
void checkReflexivity2(Object? a, Object? b) {
  Expect.equals(a, a);
  Expect.equals(b, b);
}

// Check that two objects are equal
// compared in any order.
void checkEquals2(Object? a, Object? b) {
  checkReflexivity2(a, b);
  Expect.equals(a, b);
  Expect.equals(b, a);
}

// Given a list of objects, check that each is
// equal to every element of the list.
void checkAllEquals(List<Object?> elements) {
  var count = elements.length;
  for (var element1 in elements) {
    for (var element2 in elements) {
      Expect.equals(element1, element2);
      Expect.equals(element2, element1);
    }
  }
}

// Check that two objects are unequal
// compared in any order.
void checkNotEquals2(Object? a, Object? b) {
  checkReflexivity2(a, b);
  Expect.notEquals(a, b);
  Expect.notEquals(b, a);
}

// Given two TypeBuilder objects, check that reifying the type
// represented by the two builders produces equal types, whether
// that reification happens via a direct reification; via reification
// as a generic type on a class; or via reification as a type argument to
// a noSuchMethod handler invocation.
void checkTypeEqualities(TypeBuilder a, TypeBuilder b) {
  checkAllEquals([
    typeObjectOf(a),
    typeObjectOf(b),
    noSuchMethodTypeOf(a),
    noSuchMethodTypeOf(b)
  ]);

  checkAllEquals([
    typeObjectOf($Rep(a)),
    typeObjectOf($Rep(b)),
    noSuchMethodTypeOf($Rep(a)),
    noSuchMethodTypeOf($Rep(b)),
    runtimeTypeOfRepOf(a),
    runtimeTypeOfRepOf(b)
  ]);
}

// Given two TypeBuilder objects, check that reifying the type
// represented by the two builders produces unequal types, whether
// that reification happens via a direct reification; via reification
// as a generic type on a class; or via reification as a type argument to
// a noSuchMethod handler invocation.
void checkTypeInequalities(TypeBuilder a, TypeBuilder b) {
  checkNotEquals2(typeObjectOf(a), typeObjectOf(b));
  checkNotEquals2(runtimeTypeOfRepOf(a), runtimeTypeOfRepOf(b));
  checkNotEquals2(noSuchMethodTypeOf(a), noSuchMethodTypeOf(b));
}
