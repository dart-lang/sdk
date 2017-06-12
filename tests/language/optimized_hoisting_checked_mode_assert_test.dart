// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test checked mode assertions inside loops.

int foo(x, n) {
  double z = 0.0;
  for (var i = 0; i < n; i++) {
    double z = x;
  }
  return 0;
}

main() {
  for (var i = 0; i < 20; i++) foo(1.0, 10);
  Expect.equals(0, foo(1.0, 10));
  Expect.equals(0, foo(2, 0)); // Must not throw in checked mode.
}
