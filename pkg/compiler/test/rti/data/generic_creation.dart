// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*class: A:needsArgs*/

class A<X, Y, Z> {
  shift() => A<Z, X, Y>();

  swap() => A<Z, Y, X>();

  first() => A<X, X, X>();

  last() => A<Z, Z, Z>();

  wrap() => A<A<X, X, X>, A<Y, Y, Y>, A<Z, Z, Z>>();
}

class B extends A<U, V, W> {}

/*class: C:needsArgs*/

class C<T> extends A<U, T, W> {}

/*class: D:needsArgs*/

class D<X, Y, Z> extends A<Y, Z, X> {}

class U {}

class V {}

class W {}

sameType(a, b) => makeLive(a.runtimeType == b.runtimeType);

main() {
  A a = A<U, V, W>();
  sameType(new A<W, U, V>(), a.shift());
  sameType(new A<W, V, U>(), a.swap());
  sameType(new A<U, U, U>(), a.first());
  sameType(new A<W, W, W>(), a.last());
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), a.wrap());
  B b = B();
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), b.wrap());
  C c = C<V>();
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), c.wrap());
  D d = D<U, V, W>();
  sameType(new A<A<V, V, V>, A<W, W, W>, A<U, U, U>>(), d.wrap());
}
