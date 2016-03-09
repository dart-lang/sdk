// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test canonicalization of simple arithmetic equivalences.
// VMOptions=--optimization-counter-threshold=20 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

main() {
  for (var i = 0; i < 50; i++) {
    Expect.isTrue(mul1double(i) is double);
    Expect.equals(i.toDouble(), mul1double(i));
    Expect.equals(0.0, mul0double(i));
    Expect.equals(i.toDouble(), add0double(i));

    Expect.equals(i, mul1int(i));
    Expect.equals(i, add0int(i));
    Expect.equals(0, mul0int(i));
    Expect.equals(0, and0(i));
    Expect.equals(i, and1(i));
    Expect.equals(i, or0(i));
    Expect.equals(i, xor0(i));
  }

  Expect.isTrue(mul0double(double.NAN).isNaN);
  Expect.isFalse(add0double(-0.0).isNegative);
}

mul1double(x) => 1.0 * x;
mul0double(x) => 0.0 * x;
add0double(x) => 0.0 + x;

mul1int(x) => 1 * x;
mul0int(x) => 0 * x;
add0int(x) => 0 + x;
and0(x) => 0 & x;
or0(x) => 0 | x;
xor0(x) => 0 ^ x;
and1(x) => (-1) & x;
