// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program to test type-based optimization on fields.

class A {
  var x;
  A() : x = 0;
  foo() {
    x++;
  }

  toto() {
    x = 99;
  }

  bar(y) {
    x = y;
  }
}

class B {
  operator +(other) => "ok";
}

main() {
  var a = new A();
  a.foo();
  a.toto();
  a.bar("str");
  a.bar(new B());
  a.foo();
  Expect.equals("ok", a.x);
}
