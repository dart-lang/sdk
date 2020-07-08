// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct comparison (equality and relational) when mixing double and
// Smi arguments. We convert Smi to doubles and to the operation. This is
// not correct in 64-bit mode where not every Smi can be converted to a
// double without loss of precision.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

equalityFunc(a, b) => a == b;

lessThanFunc(a, b) => a < b;

main() {
  for (int i = 0; i < 20; i++) {
    Expect.isFalse(equalityFunc(1.0, 4));
    Expect.isTrue(lessThanFunc(1.0, 4));
  }
  Expect.isFalse(equalityFunc(3459045988797251776, 3459045988797251777));
  Expect.isTrue(lessThanFunc(3459045988797251776, 3459045988797251777));
}
