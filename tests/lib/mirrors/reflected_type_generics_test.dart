// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors' show reflectType, ClassMirror;

import 'package:expect/expect.dart';

import 'reflected_type_helper.dart';

class A<T> {}

class P {}

class B extends A<P> {}

class C<K, V> {}

class D<T> extends A<T> {}

class E<K> extends C<K, int> {}

class F<G> {}

typedef bool Predicate<T>(T arg);

class FBounded<S extends FBounded<S>> {}

class Helper<T> {
  Type get param => T;
}

mixin Mixin<T extends P> {}

class Composite<K extends P, V> extends Object with Mixin<K> {}

void main() {
  // "Happy" paths:
  expectReflectedType(reflectType(A, [P]), new A<P>().runtimeType);
  expectReflectedType(reflectType(C, [B, P]), new C<B, P>().runtimeType);
  expectReflectedType(reflectType(D, [P]), new D<P>().runtimeType);
  expectReflectedType(reflectType(E, [P]), new E<P>().runtimeType);
  expectReflectedType(
    reflectType(FBounded, [new FBounded<Never>().runtimeType]),
    new FBounded<FBounded<Never>>().runtimeType,
  );

  var predicateHelper = new Helper<Predicate>();
  expectReflectedType(reflectType(Predicate), predicateHelper.param);
  var composite = new Composite<P, int>();
  expectReflectedType(reflectType(Composite, [P, int]), composite.runtimeType);

  // Edge cases:
  Expect.throws(
    () => reflectType(P, []),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if reflecting not a generic class with "
    "empty list of type arguments",
  );
  Expect.throwsArgumentError(
    () => reflectType(P, [B]),
    "Should throw an ArgumentError if reflecting not a generic class with "
    "some type arguments",
  );
  Expect.throws(
    () => reflectType(A, []),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if type argument list is empty for a "
    "generic class",
  );
  Expect.throws(
    () => reflectType(A, [P, B]),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if number of type arguments is not "
    "correct",
  );
  Expect.throws(
    () => reflectType(B, [P]),
    (e) => e is ArgumentError,
    "Should throw an ArgumentError for non-generic class extending "
    "generic one",
  );
  Expect.throws(
    () => reflectType(A, [P, B]),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if number of type arguments is not correct "
    "for generic extending another generic",
  );
  Expect.throwsUnsupportedError(
    () => reflectType(reflectType(F).typeVariables[0].reflectedType, [int]),
    "Type variables types cannot be reflected with type arguments",
  );

  // Instantiation of a generic class preserves type information:
  ClassMirror m = reflectType(A, [P]) as ClassMirror;
  var instance = m.newInstance(Symbol.empty, []).reflectee;
  Expect.equals(new A<P>().runtimeType, instance.runtimeType);
}
