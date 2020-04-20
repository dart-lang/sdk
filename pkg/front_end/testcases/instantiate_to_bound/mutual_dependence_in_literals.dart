// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that covariant and contravariant occurrences of the same
// type variable from the set of mutually dependent type variables in the bounds
// of all of these type variables are replaced with `dynamic` and Null
// respectively, in case when the raw type is used as a type argument of a list
// or a map literal.

class B<X, Y> {}

class C1<X extends X Function(Y), Y extends X Function(Y)> {}

var lc1 = <C1>[];
var mc1 = <C1, C1>{};

class C2<X extends X Function(Y), Y extends Y Function(X)> {}

var lc2 = <C2>[];
var mc2 = <C2, C2>{};

class C3<X extends X Function(X, Y), Y extends X Function(X, Y)> {}

var lc3 = <C3>[];
var mc3 = <C3, C3>{};

class C4<X extends X Function(X, Y), Y extends Y Function(X, Y)> {}

var lc4 = <C4>[];
var mc4 = <C4, C4>{};

class D1<X extends B<X, Y>, Y extends X Function(Y)> {}

var ld1 = <D1>[];
var md1 = <D1, D1>{};

class D2<X extends B<X, Y>, Y extends Y Function(X)> {}

var ld2 = <D2>[];
var md2 = <D2, D2>{};

class D3<X extends B<X, Y>, Y extends X Function(X, Y)> {}

var ld3 = <D3>[];
var md3 = <D3, D3>{};

class D4<X extends B<X, Y>, Y extends Y Function(X, Y)> {}

var ld4 = <D4>[];
var md4 = <D4, D4>{};

class E<X extends X Function(X)> {}

var le = <E>[];
var me = <E, E>{};

main() {}
