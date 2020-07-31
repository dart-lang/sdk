// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

switcher(val) {
  var x = 0;
  switch (val) {
    case 1:
      x = 100;
      break;
    case 2:
      x = 200;
      break;
    case 3:
      x = 300;
      break;
    default:
      return 400;
      break; // Intentional dead code (regression test for crash).
  }
  return x;
}

// Check unambiguated grammar allowing multiple labels per case/default.
switcher2(val) {
  var x = 0;
  switch (val) {
    foo:
    bar:
    case 1:
    baz:
    case 2:
      fez:
      {
        x = 100;
        break fez;
      }
      break;
    hest:
    fisk:
    case 3:
    case 4:
    svin:
    default:
      barber:
      {
        if (val > 2) {
          x = 200;
          break;
        } else {
          // Enable when continue to switch-case is implemented.
          continue hest;
        }
      }
  }
  return x;
}

var x = 0;

@pragma('dart2js:noInline')
switcher3(val) {
  switch (val) {
    case 1:
    default:
      incrementX();
  }
}

// Tests that switch cases work when there is a case that calls a function
// that always throws, and there is no break in the switch statement.
switcher4(val) {
  switch (val) {
    case 1:
      return 100;
    case 2: _throw(); //# 00: compile-time error
    case 3:
      _throw();
      break;
    default:
      return 300;
  }
}

_throw() {
  throw 'exception';
}

// Tests that we generate a break after the last case if it isn't default.
switcher5(val) {
  var x = 0;
  switch(val) {
    case 1:
      return 100;
    case 2:
      return 200;
    case 3:
      x = 300;
  }
  return x;
}

incrementX() {
  x++;
}

badswitches(val) {
  // Test some badly formed switch bodies.
  // 01 - a label/statement without a following case/default.
  // 02 - a label without a following case/default or statement.
  switch (val) {
    foo: break; //    //# 01: compile-time error
    case 2: //        //# 02: compile-time error
    foo: //           //# 02: continued
  }
}

main() {
  Expect.equals(100, switcher(1));
  Expect.equals(200, switcher(2));
  Expect.equals(300, switcher(3));
  Expect.equals(400, switcher(4));

  Expect.equals(100, switcher2(1));
  Expect.equals(100, switcher2(2));
  Expect.equals(200, switcher2(3));
  Expect.equals(200, switcher2(4));
  Expect.equals(200, switcher2(5));


  switcher3(1);
  Expect.equals(1, x);

  Expect.equals(100, switcher4(1));

  Expect.equals(100, switcher5(1));
  Expect.equals(200, switcher5(2));
  Expect.equals(300, switcher5(3));

  badswitches(42);
}
