// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test switch statement.

// VMOptions=
// VMOptions=--force-switch-dispatch-type=0
// VMOptions=--force-switch-dispatch-type=1
// VMOptions=--force-switch-dispatch-type=2

import "package:expect/expect.dart";

class Switcher {
  Switcher() {}

  test1(val) {
    var x = 0;
    switch (val) {
      case 1:
        x = 100;
        break;
      case 2:
      case 3:
        x = 200;
        break;
      case 4:
      default:
        {
          x = 400;
          break;
        }
    }
    return x;
  }

  test2(val) {
    switch (val) {
      case 1:
        return 200;
      default:
        return 400;
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

class Enum {
  static const Enum e1 = const Enum(1);
  static const Enum e2 = const Enum(2);
  static const Enum e3 = const Enum(3);
  final int id;
  const Enum(this.id);
}

void testSwitchEnum(Enum? input, int expect) {
  int? result = null;
  switch (input) {
    case Enum.e1:
      result = 10;
      break;
    case Enum.e2:
      result = 20;
      break;
    case Enum.e3:
      result = 30;
      break;
    default:
      result = 40;
  }
  Expect.equals(expect, result);
}

void testSwitchBool(bool input, int expect) {
  int? result = null;
  switch (input) {
    case true:
      result = 12;
      break;
    case false:
      result = 22;
  }
  Expect.equals(expect, result);
}

void testSwitchString(String? input, int? expect) {
  int? result = null;
  switch (input) {
    case 'one':
      result = 1;
      break;
    case 'two':
      result = 2;
      break;
  }
  Expect.equals(expect, result);
}

switchConstString() {
  const c = 'a';
  switch (c) {
    case 'a':
      return 'aa';
    case 'b':
      return 'bb';
    case 'c':
      return 'cc';
    case 'd':
      return 'dd';
    case 'e':
      return 'ee';
    case 'f':
      return 'ff';
  }
}

main() {
  SwitchTest.testMain();

  testSwitchEnum(Enum.e1, 10);
  testSwitchEnum(Enum.e2, 20);
  testSwitchEnum(Enum.e3, 30);
  testSwitchEnum(null, 40);

  testSwitchBool(true, 12);
  testSwitchBool(false, 22);

  testSwitchString(null, null);
  testSwitchString('one', 1);
  testSwitchString('two', 2);
  testSwitchString('three', null);

  Expect.equals('aa', switchConstString());
}
