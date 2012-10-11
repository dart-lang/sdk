// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X, Y, Z> {
  shift() => new A<Z, X, Y>();
  swap() => new A<Z, Y, X>();
  first() => new A<X, X, X>();
  last() => new A<Z, Z, Z>();
  wrap() => new A<A<X, X, X>, A<Y, Y, Y>, A<Z, Z, Z>>();
}

class U {}
class V {}
class W {}

sameType(a, b) => Expect.identical(a.runtimeType, b.runtimeType);

main() {
  A a = new A<U, V, W>();
  sameType(new A<W, U, V>(), a.shift());
  sameType(new A<W, V, U>(), a.swap());
  sameType(new A<U, U, U>(), a.first());
  sameType(new A<W, W, W>(), a.last());
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), a.wrap());
}
