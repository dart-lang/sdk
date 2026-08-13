// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=100

// Verifies that class of a constant participates in CHA decisions.
// Regression test for https://github.com/dart-lang/sdk/issues/44342.

import 'package:expect/expect.dart';

class A {
  const A();

  int foo() => 3;

  @pragma("vm:never-inline")
  int bar() => foo();
}

class B extends A {}

class C extends A {
  const C();

  int foo() => 4;
}

A x = B();
A y = const C();

main() {
  for (int i = 0; i < 200; ++i) {
    // Optimize A.bar() with inlined A.foo().
    int result = x.bar();
    Expect.equals(3, result);
  }
  int result = y.bar();
  Expect.equals(4, result);
}
