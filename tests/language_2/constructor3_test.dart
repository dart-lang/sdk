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
  A(x, y) : a1 = E(3) {
    Expect.equals(1, x);
    Expect.equals(2, y);
    E(5);
  }
}

class B extends A {
  var b1;
  B(x)
      : b1 = E(4),
        super(E(1), E(2)) {
    // Implicit super call to A's body happens here.
    Expect.equals(4, b1);
    E(6);
  }
}

main() {
  var b = new B(0);
  Expect.equals("4-1-2-3-5-6-", trace);
}
