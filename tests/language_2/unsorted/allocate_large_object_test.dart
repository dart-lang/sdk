// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int a;
  double d1;
  double d2;
  double d3;
  double d4;
  double d5;
  double d6;
  double d7;
  double d8;
  double d9;
  double d10;
  double d11;
  double d12;
  double d13;
  double d14;
  static var s;

  static foo() {
    return s;
  }

  A(this.a) {}

  value() {
    return a + foo();
  }
}

class AllocateLargeObject {
  static testMain() {
    var a = new A(1);
    A.s = 4;
    Expect.equals(5, a.value());
  }
}

main() {
  AllocateLargeObject.testMain();
}
