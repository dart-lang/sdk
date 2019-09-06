// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that 'StaticCall's against "this" go through the unchecked entry-point.

import "common.dart";
import "package:expect/expect.dart";

class C<T> {
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  @NeverInline
  @AlwaysInline
  void target2(T x) {
    Expect.notEquals(x, -1);
  }

  @NeverInline
  void target1(T x) {
    // Make sure this method gets optimized before main.
    // Otherwise it might get inlined into warm-up loop, and subsequent
    // loop will call an unoptimized version (which is not guaranteed to
    // dispatch to unchecked entry point).
    bumpUsageCounter();
    bumpUsageCounter();
    bumpUsageCounter();

    target2(x);
  }
}

test(List<String> args) {
  // Make sure the precise runtime-type of C is not known below.
  C c = args.length == 0 ? C<int>() : C<String>();

  // Warmup.
  expectedEntryPoint = -1;
  for (int i = 0; i < 100; ++i) {
    c.target1(i);
  }

  expectedEntryPoint = 1;
  const int iterations = benchmarkMode ? 400000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    c.target1(i);
  }

  expectedEntryPoint = 0;
  dynamic x = c;
  x.target2(0);

  Expect.isTrue(validateRan);
}
