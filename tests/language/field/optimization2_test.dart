// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program to test type-based optimization on fields.

class A {
  var x;
  A() : x = new B();
  foo() {
    x++;
  }
}

class B {
  operator +(other) => 498;
}

main() {
  var a = new A();
  a.foo();
  a.foo();
  Expect.equals(499, a.x);
}
