// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_generics_test;

@MirrorsUsed(targets: "test.reflected_type_generics_test")
import 'dart:mirrors';

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

class Mixin<T extends P> {}

class Composite<K extends P, V> extends Object with Mixin<K> {}

main() {
  // "Happy" paths:
  expectReflectedType(reflectType(A, [P]), new A<P>().runtimeType);
  expectReflectedType(reflectType(C, [B, P]), new C<B, P>().runtimeType);
  expectReflectedType(reflectType(D, [P]), new D<P>().runtimeType);
  expectReflectedType(reflectType(E, [P]), new E<P>().runtimeType);
  expectReflectedType(
      reflectType(FBounded, [new FBounded<Null>().runtimeType]), new FBounded<FBounded<Null>>().runtimeType);

  var predicateHelper = new Helper<Predicate<P>>();
  expectReflectedType(reflectType(Predicate, [P]), predicateHelper.param); //# 01: ok
  var composite = new Composite<P, int>();
  expectReflectedType(reflectType(Composite, [P, int]), composite.runtimeType);

  // Edge cases:
  Expect.throws(
      () => reflectType(P, []),
      (e) => e is ArgumentError && e.invalidValue is List,
      "Should throw an ArgumentError if reflecting not a generic class with "
      "empty list of type arguments");
  Expect.throws( //                                                             //# 03: ok
      () => reflectType(P, [B]), //                                             //# 03: continued
      (e) => e is Error, //                                                     //# 03: continued
      "Should throw an ArgumentError if reflecting not a generic class with " //# 03: continued
      "some type arguments"); //                                                //# 03: continued
  Expect.throws(
      () => reflectType(A, []),
      (e) => e is ArgumentError && e.invalidValue is List,
      "Should throw an ArgumentError if type argument list is empty for a "
      "generic class");
  Expect.throws( //                                                             //# 04: ok
      () => reflectType(A, [P, B]), //                                          //# 04: continued
      (e) => e is ArgumentError && e.invalidValue is List, //                   //# 04: continued
      "Should throw an ArgumentError if number of type arguments is not " //    //# 04: continued
      "correct"); //                                                            //# 04: continued
  Expect.throws(() => reflectType(B, [P]), (e) => e is Error, //            //# 05: ok
      "Should throw an ArgumentError for non-generic class extending " //   //# 05: continued
      "generic one"); //                                                    //# 05: continued
/*  Expect.throws(
      () => reflectType(A, ["non-type"]),
      (e) => e is ArgumentError && e.invalidValue is List,
      "Should throw an ArgumentError when any of type arguments is not a
      Type");*/
  Expect.throws( //                                                                //# 06: ok
      () => reflectType(A, [P, B]), //                                              //# 06: continued
      (e) => e is ArgumentError && e.invalidValue is List, //                       //# 06: continued
      "Should throw an ArgumentError if number of type arguments is not correct " //# 06: continued
      "for generic extending another generic"); //                                  //# 06: continued
  Expect.throws(
      () => reflectType(reflectType(F).typeVariables[0].reflectedType, [int]));
  Expect.throws(() => reflectType(FBounded, [int])); //# 02: ok
  var boundedType =
      reflectType(FBounded).typeVariables[0].upperBound.reflectedType;
  Expect.throws(() => reflectType(boundedType, [int])); //# 02: ok
  Expect.throws(() => reflectType(Composite, [int, int])); //# 02: ok

  // Instantiation of a generic class preserves type information:
  ClassMirror m = reflectType(A, [P]) as ClassMirror;
  var instance = m.newInstance(const Symbol(""), []).reflectee;
  Expect.equals(new A<P>().runtimeType, instance.runtimeType);
}
