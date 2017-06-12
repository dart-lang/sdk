// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

// Expect the initializer expressions E(i) to be evaluated
// in the order 1, 2, 3, ...
// Each expression must be evaluated exactly once.

String trace = "";

int E(int i) {
  trace += "$i-";
  return i;
}

class A {
  var a1;
  A(x, y) : a1 = E(4) {
    Expect.equals(2, x);
    Expect.equals(3, y);
    Expect.equals(4, a1);
    E(6);
  }
}

class B extends A {
  var b1, b2;

  B(x)
      : b1 = E(1),
        super(E(2), E(3)),
        b2 = E(5) {
    Expect.equals(1, b1);
    Expect.equals(5, b2);
    E(7);
  }
}

main() {
  var b = new B(0);
  Expect.equals("1-2-3-4-5-6-7-", trace);
}
