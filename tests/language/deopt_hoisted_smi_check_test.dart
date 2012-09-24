// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization on an optimistically hoisted smi check.

sum(a, b) {
  var sum = 0;
  for (var j = 1; j < 10; j++) {
    for (var i = a; i < b; i++) {
      sum++;
    }
  }
  return sum;
}

main() {
  for (var i = 0; i < 2000; i++) Expect.equals(9, sum(1, 2));
  Expect.equals(9, sum(1.0, 2.0));  // Passing double causes deoptimization.
}