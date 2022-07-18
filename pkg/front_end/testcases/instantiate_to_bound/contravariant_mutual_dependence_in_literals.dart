// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that contravariant occurrences of mutually dependent type
// variables in the bounds of all of these type variables are replaced with
// Null, in the case when the raw type is used as a type argument of a list or
// map literal.

class D<X extends void Function(X, Y), Y extends void Function(X, Y)> {}

var ld = <D>[];
var md = <D, D>{};

class E<X extends void Function(X)> {}

var le = <E>[];
var me = <E, E>{};

main() {}
