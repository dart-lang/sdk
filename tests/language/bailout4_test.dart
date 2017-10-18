// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that dart2s computes the right bailout environment in presence
// of nested loops.

class A {
  operator [](index) => 42;
}

var a = new A();
var b = new List(4);
int count = 0;

main() {
  // Make the method recursive to make sure it gets an optimized
  // version.
  if (b[0] != null) main();

  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 2; j++) {
      for (int k = 0; k < 2; k++) {
        Expect.equals(42, a[i + j + k]);
        count++;
      }
    }
  }
  Expect.equals(8, count);
}
