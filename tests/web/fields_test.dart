// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  A() {}
  int? x;

  foo() {
    x = 42;
    Expect.equals(42, x);
    x = 0;
    Expect.equals(0, x);
  }
}

class B extends A {}

main() {
  A a = new A();
  a.foo();
  Expect.equals(0, a.x);
  a.x = 4;
  Expect.equals(4, a.x);
  a.x = a.x! + 1;
  Expect.equals(5, a.x);

  B b = new B();
  b.foo();
  Expect.equals(0, b.x);
}
