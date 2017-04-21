// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// Test hoisted (loop-invariant) smi operations with deoptimization.

test_mul(h) {
  var x;
  for (var i = 0; i < 3; i++) {
    x = h * 100000;
  }
  return x;
}

test_neg(h) {
  var x;
  for (var i = 0; i < 3; i++) {
    x = -h;
  }
  return x;
}

main() {
  for (var i = 0; i < 20; i++) test_mul(10);
  Expect.equals(1000000, test_mul(10));
  Expect.equals(100000000000, test_mul(1000000));
  Expect.equals(100000 * 0x3fffffffffffffff, test_mul(0x3fffffffffffffff));

  for (var i = 0; i < 20; i++) test_neg(10);
  Expect.equals(-10, test_neg(10));
  Expect.equals(0x40000000, test_neg(-0x40000000));
  Expect.equals(0x4000000000000000, test_neg(-0x4000000000000000));
}
