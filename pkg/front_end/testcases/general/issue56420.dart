// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X1 extends B, X2 extends B> {}

class B {}

A<Y1, Y2> Function<Y1 extends B, Y2 extends B>() f1 =
    <Y1 extends B, Y2 extends B>() => new A<Y1, Y2>();
A<Z2, Z1> Function<Z1 extends B, Z2 extends B>() f2 =
    <Z1 extends B, Z2 extends B>() => new A<Z2, Z1>();
test(bool b) {
  var x = b ? f1 : f2;
}

main() {}
