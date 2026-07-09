// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for dart2js that used to miscompile [A.foo].

var global = 54;

class A {
  int a = 0;
  int b = 42;
  final int c = global;
  foo() {
    int start = a - 1;
    a = 54;
    if (b == 42) {
      b = 32;
    } else {
      b = 42;
    }
    Expect.equals(-1, start);
  }

  bar() {
    int start = a - c - 1;
    a = 42;
    if (b == 42) {
      b = 32;
    } else {
      b = 42;
    }
    Expect.equals(-55, start);
  }
}

main() {
  new A().foo();
  new A().bar();
}
