// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ParameterInitializerTest {
  static testMain() {
    var obj = new Foo.untyped(1);
    Expect.equals(1, obj.x);

    obj = new Foo.supertype(9);
    Expect.equals(9, obj.x);

    obj = new Foo.subtype(7);
    Expect.equals(7, obj.x);

    obj = new Foo.optional(111);
    Expect.equals(111, obj.x);

    obj = new Foo.optional();
    Expect.equals(5, obj.x);

    obj = new Foo(1);
    Expect.equals(2, obj.x);

    obj = new SubFoo(42);
    Expect.equals(1, obj.x);

    obj = new SubSubFoo(42);
    Expect.equals(1, obj.x);
  }
}

class Foo {
  Foo(num this.x) {
    // Reference to x must resolve to the field.
    x++;
    Expect.equals(this.x, x);
  }

  Foo.untyped(this.x) {}
  Foo.supertype(Object this.x) {}
  Foo.subtype(int this.x) {}
  Foo.optional([this.x = 5]) {}

  num x;
}

class SubFoo extends Foo {
  SubFoo(num y)
      : x_ = 0,
        super(y) {
    // Subfoo.setter of x has been invoked in the Foo constructor.
    Expect.equals(x, 1);
    Expect.equals(x_, 1);

    // The super.x will resolved to the field in Foo.
    Expect.equals(super.x, y);
  }

  get x {
    return x_;
  }

  set x(num val) {
    x_ = val;
  }

  num x_;
}

class SubSubFoo extends SubFoo {
  SubSubFoo(num y) : super(y) {
    // Subfoo.setter of x has been invoked in the Foo constructor.
    Expect.equals(x, 1);
    Expect.equals(x_, 1);

    // There is no way to get to the field in Foo.
    Expect.equals(super.x, 1);
  }
}

main() {
  ParameterInitializerTest.testMain();
}
