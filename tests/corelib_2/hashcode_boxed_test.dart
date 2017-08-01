// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

double fib(double n) {
  return n <= 1.0 ? 1.0 : fib(n - 1) + fib(n - 2);
}

main() {
  // Compute the same value in a way that won't be optimized away so the results
  // are different objects in memory.
  var a = fib(5.0) + 1.0;
  var b = fib(4.0) + 4.0;

  Expect.isTrue(identical(a, b));
  Expect.equals(identityHashCode(a), identityHashCode(b));
  Expect.equals(a, b);
  Expect.equals(a.hashCode, b.hashCode);
}
