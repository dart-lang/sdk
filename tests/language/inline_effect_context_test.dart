// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test inlining of simple function with control flow in an effect context.
// Optimize function foo with instance of A and inlined function bar. Call later
// with instance of B and cause deoptimization.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

class A {
  var x = 1;
}

class B {
  var x = 0;
}

int bar(o) {
  if (o.x > 0) {
    // <-- Deoptimize from inner frame.
    return 1;
  } else {
    return 0;
  }
}

int foo(o) {
  bar(o); // <-- Used in an effect context.
  return 1;
}

main() {
  var o = new A();
  int sum = 0;
  for (int i = 0; i < 20; i++) sum += foo(o);
  o = new B();
  sum += foo(o); // <-- Cause deoptimization of bar within foo.
  Expect.equals(21, sum);
}
