// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/*class: A:needsArgs*/
/*kernel.element: A.:needsSignature*/
/*!kernel.element: A.:*/
class A<X, Y, Z> {
  /*kernel.element: A.shift:needsSignature*/
  /*!kernel.element: A.shift:*/
  shift() => new A<Z, X, Y>();

  /*kernel.element: A.swap:needsSignature*/
  /*!kernel.element: A.swap:*/
  swap() => new A<Z, Y, X>();

  /*kernel.element: A.first:needsSignature*/
  /*!kernel.element: A.first:*/
  first() => new A<X, X, X>();

  /*kernel.element: A.last:needsSignature*/
  /*!kernel.element: A.last:*/
  last() => new A<Z, Z, Z>();

  /*kernel.element: A.wrap:needsSignature*/
  /*!kernel.element: A.wrap:*/
  wrap() => new A<A<X, X, X>, A<Y, Y, Y>, A<Z, Z, Z>>();
}

/*kernel.element: B.:needsSignature*/
/*!kernel.element: B.:*/
class B extends A<U, V, W> {}

/*class: C:needsArgs*/
/*kernel.element: C.:needsSignature*/
/*!kernel.element: C.:*/
class C<T> extends A<U, T, W> {}

/*class: D:needsArgs*/
/*kernel.element: D.:needsSignature*/
/*!kernel.element: D.:*/
class D<X, Y, Z> extends A<Y, Z, X> {}

class U {}

class V {}

class W {}

/*kernel.element: sameType:needsSignature*/
/*!kernel.element: sameType:*/
sameType(a, b) => Expect.equals(a.runtimeType, b.runtimeType);

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
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
