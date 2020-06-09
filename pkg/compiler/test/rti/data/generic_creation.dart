// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

/*class: A:needsArgs*/

/*spec:nnbd-off.member: A.:*/
/*prod:nnbd-off.member: A.:*/
class A<X, Y, Z> {
  /*spec:nnbd-off.member: A.shift:*/
  /*prod:nnbd-off.member: A.shift:*/
  shift() => new A<Z, X, Y>();

  /*spec:nnbd-off.member: A.swap:*/
  /*prod:nnbd-off.member: A.swap:*/
  swap() => new A<Z, Y, X>();

  /*spec:nnbd-off.member: A.first:*/
  /*prod:nnbd-off.member: A.first:*/
  first() => new A<X, X, X>();

  /*spec:nnbd-off.member: A.last:*/
  /*prod:nnbd-off.member: A.last:*/
  last() => new A<Z, Z, Z>();

  /*spec:nnbd-off.member: A.wrap:*/
  /*prod:nnbd-off.member: A.wrap:*/
  wrap() => new A<A<X, X, X>, A<Y, Y, Y>, A<Z, Z, Z>>();
}

/*spec:nnbd-off.member: B.:*/
/*prod:nnbd-off.member: B.:*/
class B extends A<U, V, W> {}

/*class: C:needsArgs*/

/*spec:nnbd-off.member: C.:*/
/*prod:nnbd-off.member: C.:*/
class C<T> extends A<U, T, W> {}

/*class: D:needsArgs*/

/*spec:nnbd-off.member: D.:*/
/*prod:nnbd-off.member: D.:*/
class D<X, Y, Z> extends A<Y, Z, X> {}

class U {}

class V {}

class W {}

/*spec:nnbd-off.member: sameType:*/
/*prod:nnbd-off.member: sameType:*/
sameType(a, b) => Expect.equals(a.runtimeType, b.runtimeType);

/*spec:nnbd-off.member: main:*/
/*prod:nnbd-off.member: main:*/
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
