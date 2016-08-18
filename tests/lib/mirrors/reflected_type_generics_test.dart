// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_generics_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'reflected_type_helper.dart';

class A<T> {}
class P {}
class B extends A<P> {}
class C<K, V> {}
class D<T> extends A<T> {}
class E<K> extends C<K, int> {}

main() {
  // "Happy" paths:
  expectReflectedType(reflectType(A, [P]), new A<P>().runtimeType);
  expectReflectedType(reflectType(C, [B, P]), new C<B, P>().runtimeType);
  expectReflectedType(reflectType(D, [P]), new D<P>().runtimeType);
  // expectReflectedType(reflectType(E, [P]), new E<P>().runtimeType);

  // Edge cases:
  Expect.throws(
    () => reflectType(P, []),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if reflecting not a generic class with empty list of type arguments");
  Expect.throws(
    () => reflectType(P, [B]),
    (e) => e is ArgumentError && e.invalidValue == P,
    "Should throw an ArgumentError if reflecting not a generic class with some type arguments");
  Expect.throws(
    () => reflectType(A, []),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if type argument list is empty for a generic class");
  Expect.throws(
    () => reflectType(A, [P, B]),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError if number of type arguments is not correct");
  Expect.throws(
    () => reflectType(B, [P]),
    (e) => e is ArgumentError && e.invalidValue == B,
    "Should throw an ArgumentError for non-generic class extending generic one");

  Expect.throws(
    () => reflectType(A, ["non-type"]),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError when any of type arguments is not a Type");
    Expect.throws(
      () => reflectType(A, [P, B]),
      (e) => e is ArgumentError && e.invalidValue is List,
      "Should throw an ArgumentError if number of type arguments is not correct"
      " for generic extending another generic");

  // Instantiation of a generic class preserves type information:
  ClassMirror m = reflectType(A, [P]) as ClassMirror;
  var instance = m.newInstance(const Symbol(""), []).reflectee;
  Expect.equals(new A<P>().runtimeType, instance.runtimeType);
}
