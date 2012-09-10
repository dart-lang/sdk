// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization caused by running code that did not collect type
// feedback before.

sum(a, b) {
  int sum = 0;
  for (int j = 1; j < 10; j++) {
    for (int i = a; i < b; i++) {
      sum++;
    }
  }
  return sum;
}

main() {
  for (var i = 0; i < 2000; i++) Expect.equals(9, sum(1, 2));
  Expect.equals(9, sum(1.0, 2.0));  // Passing double causes deoptimization.
}