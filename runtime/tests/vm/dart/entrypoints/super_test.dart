// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=5 -Denable_inlining=true
// VMOptions=--enable-testing-pragmas --no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=5

// Test that 'StaticCall's against "super" go through the unchecked entrypoint.

import "common.dart";
import "package:expect/expect.dart";

class C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validate)
  void target1(T x) {
    Expect.notEquals(x, -1);
  }
}

class D<T> extends C<T> {
  @NeverInline
  void target1(T x) {
    super.target1(x);
  }
}

class E<T> extends C<T> {
  @NeverInline
  void target1(T x) {
    super.target1(x);
  }
}

int j = 0;

C getC() {
  if (j % 2 == 0) {
    ++j;
    return new D<int>();
  } else if (j % 2 == 1) {
    ++j;
    return new E<int>();
  } else {
    return new C<int>();
  }
}

// This works around issues with OSR not totally respecting the optimization
// counter threshold.
void testOneC(C x, int i) => x.target1(i);

main(List<String> args) {
  expectedEntryPoint = -1;
  for (int i = 0; i < 100; ++i) {
    testOneC(getC(), i);
  }

  expectedEntryPoint = 1;
  const int iterations = benchmarkMode ? 200000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    testOneC(getC(), i);
  }

  Expect.isTrue(validateRan);
}
