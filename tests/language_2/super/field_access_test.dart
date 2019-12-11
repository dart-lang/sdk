// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int foo;
  A(this.foo);

  raw$foo() => foo;
  this$foo() => this.foo;
}

class B extends A {
  int foo;
  B.b1(x, this.foo) : super(x);
  B.b2(x, y)
      : this.foo = y,
        super(x);
  B.b3(x, y)
      : this.foo = y,
        super(x);

  super$foo() => super.foo;
  sum() => foo + super.foo;
}

test(b) {
  Expect.equals(10, b.foo);
  Expect.equals(10, b.raw$foo());
  Expect.equals(10, b.this$foo());
  Expect.equals(100, b.super$foo());
  Expect.equals(110, b.sum());
}

main() {
  test(new B.b1(100, 10));
  test(new B.b2(100, 10));
  test(new B.b3(100, 10));
}
