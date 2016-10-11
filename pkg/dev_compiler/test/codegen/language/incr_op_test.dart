// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing increment operator.

import "package:expect/expect.dart";

class A {
  static var yy;
  static set y(v) {
    yy = v;
  }

  static get y {
    return yy;
  }
}

class IncrOpTest {
  var x;
  static var y;

  IncrOpTest() {}

  static testMain() {
    var a = 3;
    var c = a++ + 1;
    Expect.equals(4, c);
    Expect.equals(4, a);
    c = a-- + 1;
    Expect.equals(5, c);
    Expect.equals(3, a);

    c = --a + 1;
    Expect.equals(3, c);
    Expect.equals(2, a);

    c = 2 + ++a;
    Expect.equals(5, c);
    Expect.equals(3, a);

    var obj = new IncrOpTest();
    obj.x = 100;
    Expect.equals(100, obj.x);
    obj.x++;
    Expect.equals(101, obj.x);
    Expect.equals(102, ++obj.x);
    Expect.equals(102, obj.x++);
    Expect.equals(103, obj.x);

    A.y = 55;
    Expect.equals(55, A.y++);
    Expect.equals(56, A.y);
    Expect.equals(57, ++A.y);
    Expect.equals(57, A.y);
    Expect.equals(56, --A.y);

    IncrOpTest.y = 55;
    Expect.equals(55, IncrOpTest.y++);
    Expect.equals(56, IncrOpTest.y);
    Expect.equals(57, ++IncrOpTest.y);
    Expect.equals(57, IncrOpTest.y);
    Expect.equals(56, --IncrOpTest.y);

    var list = new List(4);
    for (int i = 0; i < list.length; i++) {
      list[i] = i;
    }
    for (int i = 0; i < list.length; i++) {
      list[i]++;
    }
    for (int i = 0; i < list.length; i++) {
      Expect.equals(i + 1, list[i]);
      ++list[i];
    }
    Expect.equals(1 + 2, list[1]);
    Expect.equals(1 + 2, list[1]--);
    Expect.equals(1 + 1, list[1]);
    Expect.equals(1 + 0, --list[1]);
  }
}

main() {
  IncrOpTest.testMain();
}
