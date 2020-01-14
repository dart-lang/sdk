// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

// Super initializer and super constructor body are executed in with the same
// bindings.

String trace = "";

int E(int i) {
  trace = "$trace$i-";
  return i;
}

class A {
  A({arg1: 100, arg2: 200})
      : a1 = E(arg1++),
        a2 = E(arg2++) {
    // b2 should be initialized between the above initializers and the following
    // statements.
    E(arg1); // 101
    E(arg2); // 51
  }
  var a1;
  var a2;
}

class B extends A {
  // Initializers in order: b1, super, b2.
  B(x, y)
      : b1 = E(x++),
        b2 = E(y++),
        super(arg2: 50) {
    // Implicit super call to A's body happens here.
    E(x); // 11
    E(y); // 21
  }
  var b1;
  var b2;
}

class C extends B {
  C() : super(10, 20);
}

main() {
  var c = new C();
  Expect.equals(100, c.a1);
  Expect.equals(50, c.a2);
  Expect.equals(10, c.b1);
  Expect.equals(20, c.b2);

  Expect.equals("10-20-100-50-101-51-11-21-", trace);
}
