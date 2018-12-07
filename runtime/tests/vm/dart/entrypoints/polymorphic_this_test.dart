// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10 -Denable_inlining=true
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10

// Test that 'PolymorphicInstanceCall's against "this" go through the unchecked
// entrypoint.

import "common.dart";
import "package:expect/expect.dart";

abstract class C<T> {
  @NeverInline
  void target1(T x) {
    target2(x);
  }

  void target2(T x);
}

class D<T> extends C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  void target2(T x) {
    Expect.notEquals(x, -1);
  }
}

class E<T> extends C<T> {
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  @NeverInline
  void target2(T x) {
    Expect.notEquals(x, -1);
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
  // Warmup.
  expectedEntryPoint = -1;
  for (int i = 0; i < 100; ++i) {
    getC().target1(0);
  }

  expectedEntryPoint = 1;
  const int iterations = benchmarkMode ? 200000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    getC().target1(i);
  }

  // Once for D and once for E.
  expectedEntryPoint = 0;
  dynamic x = getC();
  x.target2(0);
  x = getC();
  x.target2(0);

  Expect.isTrue(validateRan);
}
