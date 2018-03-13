// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the instantiate-to-bound algorithm implementation works
// well in cases where there are multiple distinct strongly connected components
// of the type variable dependency graph in one declaration.

class A<X> {}

class B<X, Y> {}

class C<X, Y> {}

// Two loops.
class D<X extends A<X>, Y extends A<Y>> {}

D d;

class E<W extends B<W, X>, X extends C<W, X>, Y extends B<Y, Z>,
    Z extends C<Y, Z>> {}

E e;

class F<V extends num, W extends B<W, X>, X extends C<W, X>, Y extends B<W, X>,
    Z extends C<Y, Z>> {}

F f;

class G<V extends num, W extends B<V, X>, X extends C<W, V>, Y extends B<W, X>,
    Z extends C<Y, Z>> {}

G g;

class H<S extends A<S>, T extends B<T, U>, U extends C<T, U>, V extends A<V>,
    W extends S, X extends T, Y extends U, Z extends V> {}

H h;

// A square and a triangle.
class I<T extends U, U extends Y, V extends Function(W), W extends Function(X),
    X extends Function(V), Y extends Z, Z extends T> {}

I i;

// A triangle and a "bowtie."
class J<
    S extends T Function(U),
    T extends U Function(S),
    U extends S Function(T),
    V extends W,
    W extends X,
    X extends Y Function(V),
    Y extends Z,
    Z extends X> {}

J j;

main() {}
