// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This test triggered an NPE in dart2js.
// The bug needed:
// - double usage of the same variable in one expression ("b != b").
// - replacement of "b" with "typechecked b".
// - ...
// The example below is minimal (as far as I was able to do).

num foo(num a, num b) {
  if (a > b) return b;
  if (b is double) {
    if (true) {
      if (true) {
        return (a + b) * a * b;
      }
    }
    // Check for NaN and b == -0.0.
    if (a == 0 && b == 0 || b != b) return b;
  }
}

main() {
  Expect.equals(1, foo(2, 1));
}
