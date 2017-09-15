// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program checking that optimizations are not too aggressive and
// incorrect:
// - (a * (1.0 / b))
//
// VMOptions=--optimization-counter-threshold=8 --no-use-osr

import "package:expect/expect.dart";

var xx = 23.0;

main() {
  xx = 1e-6;
  scaleIt(1e-310);
  Expect.isTrue(xx.isInfinite);
  for (int i = 0; i < 10; i++) {
    xx = 24.0;
    scaleIt(6.0);
    Expect.equals(4.0, xx);
  }
  xx = 1e-6;
  scaleIt(1e-310);
  Expect.isTrue(xx.isInfinite);
}

scaleIt(double b) {
  scale(1.0 / b);
}

scale(a) {
  xx *= a;
}
