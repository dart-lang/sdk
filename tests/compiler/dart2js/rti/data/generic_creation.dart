// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/*class: A:needsArgs*/
/*element: A.:needsSignature*/
class A<X, Y, Z> {
  /*element: A.shift:needsSignature*/
  shift() => new A<Z, X, Y>();
  /*element: A.swap:needsSignature*/
  swap() => new A<Z, Y, X>();
  /*element: A.first:needsSignature*/
  first() => new A<X, X, X>();
  /*element: A.last:needsSignature*/
  last() => new A<Z, Z, Z>();
  /*element: A.wrap:needsSignature*/
  wrap() => new A<A<X, X, X>, A<Y, Y, Y>, A<Z, Z, Z>>();
}

/*element: B.:needsSignature*/
class B extends A<U, V, W> {}

/*class: C:needsArgs*/
/*element: C.:needsSignature*/
class C<T> extends A<U, T, W> {}

/*class: D:needsArgs*/
/*element: D.:needsSignature*/
class D<X, Y, Z> extends A<Y, Z, X> {}

class U {}

class V {}

class W {}

/*element: sameType:needsSignature*/
sameType(a, b) => Expect.equals(a.runtimeType, b.runtimeType);

/*element: main:needsSignature*/
main() {
  A a = new A<U, V, W>();
  sameType(new A<W, U, V>(), a.shift());
  sameType(new A<W, V, U>(), a.swap());
  sameType(new A<U, U, U>(), a.first());
  sameType(new A<W, W, W>(), a.last());
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), a.wrap());
  B b = new B();
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), b.wrap());
  C c = new C<V>();
  sameType(new A<A<U, U, U>, A<V, V, V>, A<W, W, W>>(), c.wrap());
  D d = new D<U, V, W>();
  sameType(new A<A<V, V, V>, A<W, W, W>, A<U, U, U>>(), d.wrap());
}
