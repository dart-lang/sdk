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

main() {
  expectReflectedType(reflectType(A, [P]), new A<P>().runtimeType);
  Expect.throws(
    () => reflectType(P, []),
    (e) => e is ArgumentError && e.invalidValue == P,
    "Should throw an ArgumentError");
  Expect.throws(
    () => reflectType(P, [int]),
    (e) => e is ArgumentError && e.invalidValue == P,
    "Should throw an ArgumentError");
  Expect.throws(
    () => reflectType(A, []),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError");
  Expect.throws(
    () => reflectType(A, [P, int]),
    (e) => e is ArgumentError && e.invalidValue is List,
    "Should throw an ArgumentError");
  Expect.throws(
    () => reflectType(B, [P]),
    (e) => e is ArgumentError && e.invalidValue == B,
    "Should throw an ArgumentError");
  // Fails currently:
  // Expect.throws(
  //   () => reflectType(A, ["non-type"]),
  //   (e) => e is ArgumentError && e.invalidValue == B,
  //   "Should throw an ArgumentError");
}
