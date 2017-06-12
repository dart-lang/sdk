// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimziation caused by lazy finalization.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

main() {
  Expect.equals(20000, part1());
  // Trigger lazy finalization of class B, which should invalidate
  // optimized code for A.loop.
  Expect.equals(-20000, part2());
}

part1() {
  var a = new A();
  a.loop();
  // Second invocation calls optimized code.
  return a.loop();
}

part2() {
  var b = new B();
  b.loop();
  // Second invocation calls optimized code.
  return b.loop();
}

class A {
  foo() => 2;

  loop() {
    var sum = 0;
    for (int i = 0; i < 10000; i++) {
      sum += foo();
    }
    return sum;
  }
}

class Aa extends A {}

class B extends Aa {
  foo() => -2;
}
