// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// No type checks are removed here, but we can skip the argument count check.
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10 -Denable_inlining=true

import "package:expect/expect.dart";
import "common.dart";

class C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validateTearoff)
  @pragma("vm:entry-point")
  void samir1(T x) {
    if (x == -1) {
      throw "oh no";
    }
  }
}

main(List<String> args) {
  var c = new C<int>();
  var f = c.samir1;

  // Warmup.
  expectedEntryPoint = -1;
  expectedTearoffEntryPoint = -1;
  for (int i = 0; i < 100; ++i) {
    f(i);
  }

  expectedEntryPoint = 0;
  expectedTearoffEntryPoint = 1;
  int iterations = benchmarkMode ? 100000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    f(i);
  }

  Expect.isTrue(validateRan);
}
