// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that 'StaticCall's against "super" go through the unchecked entrypoint.

import "common.dart";
import "package:expect/expect.dart";

class C<T> {
  @AlwaysInline
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

test(List<String> args) {
  // Make sure the check on target1.x is not completely eliminated.
  if (args.length > 0) {
    (C<int>() as C<num>).target1(1.0);
  }

  const int iterations = benchmarkMode ? 200000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    getC().target1(i);
  }

  entryPoint.expectUnchecked(iterations);
}
