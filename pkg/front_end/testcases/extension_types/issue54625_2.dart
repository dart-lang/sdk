// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

X Function<X extends E>() foo() => throw 0;

class A<Supertype, Subtype extends Supertype> {}

A<X, Null> Function<X extends E>() // Error.
  test1() => throw 0;

A<Object, X> Function<X extends E>() // Ok.
  test2() => throw 0;

extension type E(num it) implements num {}

Null returnsNull<Y extends E>() => null;

test3() {
  var f = foo();
  f = returnsNull; // Error.
}
