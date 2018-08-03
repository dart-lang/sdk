// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

class A extends B {
  A(x, y)
      : a = x,
        super(y) {}

  var a;
}

class B {
  var b;

  B(x) : b = x {}

  B.namedB(var x) : b = x {}
}

// Test the order of initialization: first the instance variable then
// the super constructor.
abstract class Alpha {
  Alpha(v) {
    this.foo(v);
  }
  foo(v) => throw 'Alpha.foo should never be called.';
}

class Beta extends Alpha {
  Beta(v)
      : b = 1,
        super(v) {}

  foo(v) {
    // Check that 'b' was initialized.
    Expect.equals(1, b);
    b = v;
  }

  var b;
}

class ConstructorTest {
  static testMain() {
    var o = new A(10, 2);
    Expect.equals(10, o.a);
    Expect.equals(2, o.b);

    var o1 = new B.namedB(10);
    Expect.equals(10, o1.b);

    Expect.equals(22, o.a + o.b + o1.b);

    var beta = new Beta(3);
    Expect.equals(3, beta.b);
  }
}

main() {
  ConstructorTest.testMain();
}
