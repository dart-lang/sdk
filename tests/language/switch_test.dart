// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test switch statement.

class Switcher {

  Switcher() { }

  test1 (val) {
    var x = 0;
    switch (val) {
      case 1:
        x = 100; break;
      case 2:
      case 3:
        x = 200; break;
      case 4:
      default: {
        x = 400; break;
      }
    }
    return x;
  }

  test2 (val) {
    switch (val) {
      case 1:    return 200;
      default:   return 400;
    }
  }
}


class SwitchTest {
  static testMain() {
    Switcher s = new Switcher();
    Expect.equals(100, s.test1(1));
    Expect.equals(200, s.test1(2));
    Expect.equals(200, s.test1(3));
    Expect.equals(400, s.test1(4));
    Expect.equals(400, s.test1(5));

    Expect.equals(200, s.test2(1));
    Expect.equals(400, s.test2(2));
  }
}

main() {
  SwitchTest.testMain();
}
