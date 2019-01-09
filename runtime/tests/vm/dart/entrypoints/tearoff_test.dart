// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10 -Denable_inlining=true

// Test that typed calls against tearoffs go into the unchecked entrypoint.

import "package:expect/expect.dart";
import "common.dart";

class C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validateTearoff)
  @pragma("vm:entry-point")
  void target1(T x, String y) {
    Expect.notEquals(x, -1);
    Expect.equals(y, "foo");
  }
}

main(List<String> args) {
  var f = (new C<int>()).target1;

  // Warmup.
  expectedEntryPoint = -1;
  expectedTearoffEntryPoint = -1;
  for (int i = 0; i < 100; ++i) {
    f(i, "foo");
  }

  expectedEntryPoint = 0;
  expectedTearoffEntryPoint = 1;
  const int iterations = benchmarkMode ? 100000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    f(i, "foo");
  }

  Expect.isTrue(validateRan);
}
