// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10 -Denable_inlining=true
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10

// Test that TFA infers skip check in a basic case with covariance.

import "../common.dart";
import "package:expect/expect.dart";

class C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  void target1(T x) => x;
}

main() {
  C c = new C<int>();

  expectedEntryPoint = 1;
  const int iterations = benchmarkMode ? 200000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    c.target1(i);
  }

  if (!benchmarkMode) {
    Expect.isTrue(validateRan);
  }
}
