// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-testing-pragmas --no-background-compilation --optimization-counter-threshold=10 -Denable_inlining=true --compilation-counter-threshold=1
// VMOptions=--enable-testing-pragmas --no-background-compilation --optimization-counter-threshold=10 --compilation-counter-threshold=1
// VMOptions=--enable-testing-pragmas --no-background-compilation --optimization-counter-threshold=-1 --compilation-counter-threshold=1

// Test that 'PolymorphicInstanceCall's against "this" go through the unchecked
// entrypoint. The use of optional arguments here encourages prologue sharing
// between the entrypoints.

import "../common.dart";
import "package:expect/expect.dart";

abstract class C<T> {
  @NeverInline
  void samir1(T x) {
    samir2(x, y: "hi");
  }

  void samir2(T x, {required String y});
}

class D<T> extends C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  @pragma("vm:entry-point")
  void samir2(T x, {required String y}) {
    Expect.notEquals(x, -1);
    Expect.equals(y, "hi");
  }
}

class E<T> extends C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  @pragma("vm:entry-point")
  void samir2(T x, {required String y}) {
    Expect.notEquals(x, -1);
    Expect.equals(y, "hi");
  }
}

int j = 0;

C getC() {
  if (j % 2 == 0) {
    ++j;
    return new D<int>();
  } else {
    ++j;
    return new E<int>();
  }
}

main(List<String> args) {
  const int iterations = benchmarkMode ? 100000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    getC().samir1(i);
  }

  entryPoint.expectUnchecked(iterations);
}
