// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for correct optimizations related to types fo allocated lists.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

main() {
  // Trigger optimization of 'test' method.
  for (int i = 0; i < 20; i++) {
    test(2);
  }
}

test(n) {
  var a = new List(); //    Growable list.
  var b = new List(10); // Fixed size list.
  var c = const [1, 2, 3, 4]; // Constant aray.
  // In optimized mode the class checks will be eliminated since the
  // constructors above provide information about exact types.
  a.add(4);
  b[0] = 5;
  Expect.equals(4, a[0]);
  Expect.equals(5, b[0]);
  // Test bound check elimination.
  Expect.equals(2, c[1]);
  // Test elimination of array length computation.
  var v = c[n];
  Expect.equals(v, c[n]);
}
