// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various optimizations and deoptimizations of optimizing compiler..
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

// Test correct throwing of ArgumentError in optimized code.

test() {
  try {
    var r = new List<int>(-1);
    Expect.isTrue(false); // Unreachable.
  } on RangeError {
    return true;
  }
  Expect.isTrue(false); // Unreachable.
}

main() {
  for (var i = 0; i < 20; i++) {
    Expect.isTrue(test());
  }
}
