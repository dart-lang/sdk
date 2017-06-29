// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

@NoInline()
switcher3(val) {
  switch (val) {
    case 1:
    default:
      incrementX();
  }
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

  badswitches(42);
}
