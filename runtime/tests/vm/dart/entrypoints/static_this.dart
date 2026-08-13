// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that 'StaticCall's against "this" go through the unchecked entry-point.

import "common.dart";
import "package:expect/expect.dart";

class C<T> {
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  @pragma("vm:entry-point")
  @NeverInline
  @AlwaysInline
  void target2(T x) {
    Expect.notEquals(x, -1);
  }

  @NeverInline
  void target1(T x) {
    target2(x);
  }
}

test(List<String> args) {
  // Make sure the precise runtime-type of C is not known below.
  C c = args.length == 0 ? C<int>() : C<String>();

  const int iterations = benchmarkMode ? 400000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    c.target1(i);
  }

  entryPoint.expectUnchecked(iterations);
}
