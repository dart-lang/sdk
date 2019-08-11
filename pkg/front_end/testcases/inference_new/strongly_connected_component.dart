// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

bool f() => null;

// Even though x, y, and z form a strongly connected component (each depends on
// all the others), the circularity is calculated based on the first problematic
// dependency of each field.  So x's first problematic dependency is y, and y's
// first problematic dependency is x; therefore x and y are considered to have a
// circularity, and for error recovery their type is set to `dynamic`.
// Thereafter, z infers without problems.

var x = /*@ returnType=() ->* invalid-type */ () => f() ? y : z;
var y = /*@ returnType=invalid-type */ () => x;
var z = /*@ returnType=invalid-type */ () => x;

main() {}
