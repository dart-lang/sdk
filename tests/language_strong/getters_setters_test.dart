// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:meta/meta.dart" show virtual;

class GettersSettersTest {
  static int foo;

  static testMain() {
    A a = new A();
    a.x = 2;
    Expect.equals(2, a.x);
    Expect.equals(2, a.x_);

    // Test inheritance.
    a = new B();
    a.x = 4;
    Expect.equals(4, a.x);
    Expect.equals(4, a.x_);

    // Test overriding.
    C c = new C();
    c.x = 8;
    Expect.equals(8, c.x);
    Expect.equals(0, c.x_);
    Expect.equals(8, c.y_);

    // Test keyed getters and setters.
    a.x_ = 0;
    Expect.equals(2, a[2]);
    a[2] = 4;
    Expect.equals(6, a[0]);

    // Test assignment operators.
    a.x_ = 0;
    a[2] += 8;
    Expect.equals(12, a[0]);

    // Test calling a function that internally uses getters.
    Expect.equals(true, a.isXPositive());

    // Test static fields.
    foo = 42;
    Expect.equals(42, foo);
    A.foo = 43;
    Expect.equals(43, A.foo);

    new D().test();

    OverrideField of = new OverrideField();
    Expect.equals(27, of.getX_());

    ReferenceField rf = new ReferenceField();
    rf.x_ = 1;
    Expect.equals(1, rf.getIt());
    rf.setIt(2);
    Expect.equals(2, rf.x_);
  }
}

class A {
  @virtual
  int x_;
  static int foo;

  static get bar {
    return foo;
  }

  static set bar(newValue) {
    foo = newValue;
  }

  int get x {
    return x_;
  }

  void set x(int value) {
    x_ = value;
  }

  bool isXPositive() {
    return x > 0;
  }

  int operator [](int index) {
    return x_ + index;
  }

  void operator []=(int index, int value) {
    x_ = index + value;
  }

  int getX_() {
    return x_;
  }
}

class B extends A {}

class C extends A {
  int y_;

  C() : super() {
    this.x_ = 0;
  }

  int get x {
    return y_;
  }

  void set x(int value) {
    y_ = value;
  }
}

class D extends A {
  var x2_;

  set x(new_x) {
    x2_ = new_x;
  }

  test() {
    x = 87;
    Expect.equals(87, x2_);
    x = 42;
    Expect.equals(42, x2_);
  }
}

class OverrideField extends A {
  int get x_ {
    return 27;
  }
}

class ReferenceField extends A {
  setIt(a) {
    super.x_ = a;
  }

  int getIt() {
    return super.x_;
  }
}

main() {
  GettersSettersTest.testMain();
}
