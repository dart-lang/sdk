// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Two function types that are identical except the argument type of the
// nested function is a type variable from the outer function.
typedef Fn = void Function<S>(S val) Function<T>(T val);
typedef Gn = void Function<S>(T val) Function<T>(T val);

void Function<S>(S) fn<T>(T val) => <R>(R val) {};
void Function<S>(T) gn<T>(T val) => <R>(T val) {};

// The same pattern here except with bounds on the type arguments.
typedef Xn = void Function<S extends num>(S val) Function<T extends num>(T val);
typedef Yn = void Function<S extends num>(T val) Function<T extends num>(T val);

void Function<S extends num>(S) xn<T extends num>(T val) =>
    <R extends num>(R val) {};
void Function<S extends num>(T) yn<T extends num>(T val) =>
    <R extends num>(T val) {};

// The nested function here uses concrete type in the argument position so it
// should satisfy either of the previous typedefs.
void Function<S extends num>(num) zn<T extends num>(T val) =>
    <R extends num>(num val) {};

void main() {
  Expect.isTrue(fn is Fn);
  Expect.isFalse(fn is Gn);

  Expect.isTrue(gn is Gn);
  Expect.isFalse(gn is Fn);

  Expect.isTrue(xn is Xn);
  Expect.isFalse(xn is Yn);

  Expect.isTrue(yn is Yn);
  Expect.isFalse(yn is Xn);

  Expect.isTrue(zn is Xn);
  Expect.isTrue(zn is Yn);
}
