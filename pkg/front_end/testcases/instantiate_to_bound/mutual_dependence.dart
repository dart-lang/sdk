// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that covariant and contravariant occurrences of the same
// type variable from the set of mutually dependent type variables in the bounds
// of all of these type variables are replaced with `dynamic` and Null
// respectively.

class B<X, Y> {}

class C1<X extends X Function(Y), Y extends X Function(Y)> {}

C1 c1;

class C2<X extends X Function(Y), Y extends Y Function(X)> {}

C2 c2;

class C3<X extends X Function(X, Y), Y extends X Function(X, Y)> {}

C3 c3;

class C4<X extends X Function(X, Y), Y extends Y Function(X, Y)> {}

C4 c4;

class D1<X extends B<X, Y>, Y extends X Function(Y)> {}

D1 d1;

class D2<X extends B<X, Y>, Y extends Y Function(X)> {}

D2 d2;

class D3<X extends B<X, Y>, Y extends X Function(X, Y)> {}

D3 d3;

class D4<X extends B<X, Y>, Y extends Y Function(X, Y)> {}

D4 d4;

class E<X extends X Function(X)> {}

E e;

main() {}
