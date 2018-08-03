// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that covariant occurrences of mutually dependent type
// variables in the bounds of all of these type variables are replaced with
// `dynamic`, in case when the raw type is used as a type argument of a list or
// a map literal.

class B<X, Y> {}

class C<X, Y> {}

class D<X extends B<X, Y>, Y extends C<X, Y>> {}

var ld = <D>[];
var md = <D, D>{};

class E<X extends B<X, Y>, Y extends X Function()> {}

var le = <E>[];
var me = <E, E>{};

class F<X extends X Function()> {}

var lf = <F>[];
var mf = <F, F>{};

main() {}
