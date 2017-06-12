// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test Parameter Intializer.

class ParameterInitializer2Test {
  static testMain() {
    var a = new A(123);
    Expect.equals(123, a.x);

    var b = new B(123);
    Expect.equals(123, b.x);

    var c = new C(123);
    Expect.equals(123, c.x);

    var d = new D(123);
    Expect.equals(123, d.x);

    var e = new E(1);
    Expect.equals(4, e.x);

    var f = new F(1, 2, 3, 4);
    Expect.equals(4, f.z);
  }
}

// untyped
class A {
  A(this.x) {}
  int x;
}

// typed
class B {
  B(int this.x) {}
  int x;
}

// const typed
class C {
  const C(int this.x);
  final int x;
}

// const untyped
class D {
  const D(this.x);
  final x;
}

// make sure this.<X> references work properly in the constructor scope.
class E {
  E(this.x) {
    var myVar = this.x * 2;
    this.x = myVar + 1;
    x = myVar + 2;
    var foo = x + 1;
  }
  int x;
}

// mixed
class F {
  F(x, this.y_, int w, int this.z)
      : x_ = x,
        w_ = w {}
  F.foobar(this.z, int this.x_, int this.az_) {}
  int x_;
  int y_;
  int w_;
  int z;
  int az_;
}

main() {
  ParameterInitializer2Test.testMain();
}
