// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
      case "mister string":
        return 300;
      case 4:
      default: {
        x = 400; break;
      }
    }
    return x;
  }

  test2 (val) {
    switch (val) {
      case true: return 100;
      case 1:    return 200;
      case "1":  return 300;
      default:   return 400;
    }
  }

  test3(val) {
    final int temp = 5;
    switch (true) {
      case temp == val:
        return true;
    }
    return false;
  }
}


class SwitchTest {
  static testMain() {
    Switcher s = new Switcher();
    Expect.equals(100, s.test1(1));
    Expect.equals(200, s.test1(2));
    Expect.equals(200, s.test1(3));
    Expect.equals(300, s.test1("mister string"));
    Expect.equals(400, s.test1(4));
    Expect.equals(400, s.test1(5));

    Expect.equals(200, s.test2(1));
    Expect.equals(300, s.test2("1"));

    Expect.equals(true, s.test3(5));
    Expect.equals(false, s.test3(6));
  }
}

main() {
  SwitchTest.testMain();
}
