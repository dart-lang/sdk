// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test cascades.

class A {
  int x;
  int y;

  A(this.x, this.y);

  A setX(int x) {
    this.x = x;
    return this;
  }

  void setY(int y) {
    this.y = y;
  }

  Function swap() {
    int tmp = x;
    x = y;
    y = tmp;
    return this.swap;
  }

  void check(int x, int y) {
    Expect.equals(x, this.x);
    Expect.equals(y, this.y);
  }

  operator [](var i) {
    if (i == 0) return x;
    if (i == 1) return y;
    if (i == "swap") return this.swap;
    return null;
  }

  int operator []=(int i, int value) {
    if (i == 0) {
      x = value;
    } else if (i == 1) {
      y = value;
    }
  }

  /**
   * A pseudo-keyword.
   */
  import() {
    x++;
  }
}

main() {
  A a = new A(1, 2);
  a
    ..check(1, 2)
    ..swap()
    ..check(2, 1)
    ..x = 4
    ..y = 9
    ..check(4, 9)
    ..setX(10)
    ..check(10, 9)
    ..y = 5
    ..check(10, 5)
    ..swap()()()
    ..check(5, 10)
    ..[0] = 2
    ..check(2, 10)
    ..setX(10).setY(3)
    ..check(10, 3)
    ..setX(7)["swap"]()
    ..check(3, 7)
    ..import()
    ..check(4, 7)
    ..["swap"]()()()
    ..check(7, 4);
  a.check(7, 4);
  a..(42); // //# 01: syntax error
  a..37; // //# 02: syntax error
  a.."foo"; // //# 03: syntax error
}
