// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// Test optimization of redundant array loads.

var A = [0, 2, 3];

test1(a) {
  int x = a[0];
  int y = a[1];
  ++a[0];
  return a[0] + y + a[2];
}

int test2(a) {
  return a[2] + a[2];
}

main() {
  for (int i = 0; i < 20; i++) {
    test1(A);
    test2(A);
  }
  Expect.equals(26, test1(A));
  Expect.equals(6, test2(A));
}
