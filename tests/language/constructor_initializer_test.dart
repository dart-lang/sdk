// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var _x, _y;
  A(x, [y = 10])
      : _x = x++,
        _y = y++ {
    // Check that value of modified constructor parameters
    // is remembered in the constructor body.
    Expect.equals(x, _x + 1);
    Expect.equals(y, _y + 1);
    Expect.isFalse(?y); // //# 01: syntax error
  }
}

class B extends A {
  var _a, _b;
  // The super call in the middle of the initializer list conceptually
  // forces two super call chains, one for initializer list and a second
  // one for the constructor bodies.
  B(a, b)
      : _a = a++,
        super(a + b++),
        _b = b++ {
    Expect.equals(a, _a + 1);
    Expect.equals(b, _b + 1);
    Expect.equals(a + (b - 2), _x);
  }
}

main() {
  var o = new B(3, 5);
  Expect.equals(3, o._a);
  Expect.equals(6, o._b);
  Expect.equals(9, o._x);
  Expect.equals(10, o._y);
  o = new A(3);
  Expect.equals(3, o._x);
  Expect.equals(10, o._y);
}
