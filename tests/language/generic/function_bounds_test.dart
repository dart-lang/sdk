// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--lazy-dispatchers
// VMOptions=--no-lazy-dispatchers

import 'dart:math';
import 'package:expect/expect.dart';

Type getType<T>() => T;

void testInstantiateToBounds() {
  f<T extends num, U extends T>() => [T, U];
  g<T extends List<U>, U extends int>() => [T, U];
  h<T extends U, U extends num>(T x, U y) => [T, U];

  // Check that instantiate to bounds creates the correct type arguments
  // during dynamic calls.
  Expect.listEquals([num, num], (f as dynamic)());
  Expect.listEquals([getType<List<int>>(), int], (g as dynamic)());
  Expect.listEquals([num, num], (h as dynamic)(-1, -1));

  // Check that when instantiate to bounds creates a super-bounded type argument
  // during a dynamic call, an error is thrown.
  i<T extends Iterable<T>>() => null;
  j<T extends Iterable<S>, S extends T>() => null;
  Expect.throwsTypeError(() => (i as dynamic)(), "Super bounded type argument");
  Expect.throwsTypeError(() => (j as dynamic)(), "Super bounded type argument");
}

void testChecksBound() {
  f<T extends num>(T x) => x;
  g<T extends U, U extends num>(T x, U y) => x;

  // Check that arguments are checked against the correct types when instantiate
  // to bounds produces a type argument during a dynamic call.
  Expect.equals((f as dynamic)(42), 42);
  Expect.equals((g as dynamic)(42.0, 100), 42.0);
  Expect.throwsTypeError(() => (f as dynamic)('42'), "Argument check");
  Expect.throwsTypeError(() => (g as dynamic)('hi', 100), "Argument check");

  // Check that an actual type argument is checked against the bound during a
  // dynamic call.
  Expect.equals((f as dynamic)<int>(42), 42);
  Expect.equals((g as dynamic)<double, num>(42.0, 100), 42.0);
  Expect.throwsTypeError(() => (g as dynamic)<double, int>(42.0, 100),
      "Type argument bounds check");
  Expect.throwsTypeError(
      () => (f as dynamic)<Object>(42), "Type argument bounds check");
  Expect.throwsTypeError(() => (g as dynamic)<double, int>(42.0, 100),
      "Type argument bounds check");
  Expect.throwsTypeError(() => (g as dynamic)<num, Object>(42.0, 100),
      "Type argument bounds check");
}

typedef G<U> = num Function<T extends U>(T x);

typedef F<U> = Object Function<T extends U>(T x);

void testSubtype() {
  num f<T extends num>(T x) => x + 2;
  dynamic d = f;

  // Check that casting to an equal generic function type works
  Expect.equals((f as G<num>)(40), 42);
  Expect.equals((d as G<num>)(40), 42);

  // Check that casting to a more general generic function type works
  Expect.equals((f as F<num>)(40), 42);
  Expect.equals((d as F<num>)(40), 42);

  // Check that casting to a generic function with more specific bounds fails
  Expect.throwsTypeError(
      () => (f as G<int>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (d as G<int>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (f as G<double>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (d as G<double>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (f as G<Null>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (d as G<Null>), "Generic functions are invariant");

  // Check that casting to a generic function with a more general bound fails
  Expect.throwsTypeError(
      () => (f as G<Object>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (d as G<Object>), "Generic functions are invariant");

  // Check that casting to a generic function with an unrelated bound fails
  Expect.throwsTypeError(
      () => (f as G<String>), "Generic functions are invariant");
  Expect.throwsTypeError(
      () => (d as G<String>), "Generic functions are invariant");
}

void testToString() {
  num f<T extends num, U extends T>(T x, U y) => min(x, y);
  num g<T, U>(T x, U y) => max(x as num, y as num);
  String h<T, U>(T x, U y) => h.runtimeType.toString();

  // Check that generic method types are printed in a reasonable way
  Expect.isTrue(
      new RegExp(r'<(\w+) extends num, (\w+) extends \1>\(\1, \2\) => num')
          .hasMatch(f.runtimeType.toString()));
  Expect.isTrue(new RegExp(r'<(\w+), (\w+)>\(\1, \2\) => num')
      .hasMatch(g.runtimeType.toString()));
  Expect.isTrue(
      new RegExp(r'<(\w+), (\w+)>\(\1, \2\) => String').hasMatch(h(42, 123.0)));
}

main() {
  testInstantiateToBounds(); //# 01: ok
  testToString(); //# 02: ok
  testChecksBound(); //# 03: ok
  testSubtype(); //# 04: ok
}
