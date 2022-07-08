// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that covariant and contravariant occurrences of the same
// type variable in the bounds of the other type variables from the same
// declaration that are not being transitively depended on by that variable are
// replaced with the bound of that variable and Null respectively, in case when
// the raw type is used as a type argument of a list or a map literal.

class A<X> {}

class C<X, Y extends X Function(X)> {}

var lc = <C>[];
var mc = <C, C>{};

class D<X extends num, Y extends X Function(X)> {}

var ld = <D>[];
var md = <D, D>{};

main() {}
