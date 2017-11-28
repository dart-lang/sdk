// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing order of constructor invocation.

import "package:expect/expect.dart";

var trace = "";

int rec(int i) {
  trace += "$i ";
  return i;
}

class A {
  A(int x) : x = rec(2) {
    Expect.equals(1, x); // Parameter x
    Expect.equals(2, this.x);
    rec(5);
  }
  final int x;
}

class B extends A {
  B(this.a, int y, int z)
      : z = rec(3),
        y = rec(4),
        super(rec(1)) {
    rec(6);
  }
  int a;
  int y;
  int z;
}

main() {
  var test = new B(rec(0), 0, 0);
  Expect.equals(0, test.a);
  Expect.equals(2, test.x);
  Expect.equals(4, test.y);
  Expect.equals(3, test.z);
  Expect.equals("0 1 2 3 4 5 6 ", trace);
}
