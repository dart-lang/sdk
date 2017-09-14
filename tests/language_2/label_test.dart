// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test check that we can parse labels.

import "package:expect/expect.dart";

class Helper {
  static int ticks;

  // Helper function to prevent endless loops in case labels or
  // break/continue is broken.
  static doAgain() {
    ++ticks;
    if (ticks > 300) {
      // obfuscating man's assert(false)
      Expect.equals(true, false);
    }
    return true;
  }

  static test1() {
    var i = 1;
    while (doAgain()) {
      if (i > 0) break;
      return 0;
    }
    return 111;
  }

  static test2() {
    // Make sure we break out to default label.
    var i = 1;
    L:
    while (doAgain()) {
      // unused label
      if (i > 0) break;
      return 0;
    }
    return 111;
  }

  static test3() {
    // Make sure we break out of outer loop.
    var i = 1;
    L:
    while (doAgain()) {
      while (doAgain()) {
        if (i > 0) break L;
        return 0;
      }
      return 1;
    }
    return 111;
  }

  static test4() {
    // Make sure we break out of inner loop.
    var i = 100;
    L:
    while (doAgain()) {
      // unused label
      while (doAgain()) {
        if (i > 0) break;
        return 0;
      }
      return 111;
    }
    return 1;
  }

  static test5() {
    // Make sure we jump to loop condition.
    var i = 10;
    while (i > 0) {
      i--;
      if (true) continue; // without the if the following return is dead code.
      return 0;
    }
    return 111;
  }

  static test6() {
    // Make sure we jump to loop condition.
    L:
    for (int i = 10; i > 0; i--) {
      // unreferenced label, should warn
      if (true) continue; // without the if the following return is dead code.
      return 0;
    }
    // Make sure this L does not conflict with previous L.
    var k = 20;
    L:
    while (doAgain()) {
      L0:
      while (doAgain()) break L; // unreferenced label L0, should warn
      return 1;
    }
    return 111;
  }

  static test7() {
    // Just weird stuff.
    var i = 10;
    L:
    do {
      L:
      while (doAgain()) {
        if (true) break L; // without the if the following line is dead code.
        continue L;
      }
      i = 0;
      continue L;
    } while (i == 10 && doAgain());
    return 111;
  }

  static test8() {
    L:
    while (false) {
      var L = 33; // OK, shouldn't collide with label.
      if (true) break L;
    }
    return 111;
  }

  static test9() {
    var i = 111;
    L1:
    if (i == 0) {
      // unreferenced label, should warn
      return 0;
    }

    L2:
    while (i == 0) {
      // unreferenced label, should warn
      return 0;
    }

    L3: // useless label, should warn
    return i;
  }

  // Labels should be allowed on block/if/for/switch/while/do stmts.
  static test10() {
    int i = 111;
    // block
    while (doAgain()) {
      L:
      {
        while (doAgain()) {
          break L;
        }
        i--;
      }
      break;
    }
    Expect.equals(111, i);

    while (doAgain()) {
      L:
      if (doAgain()) {
        while (doAgain()) {
          break L;
        }
        i--;
      }
      break;
    }
    Expect.equals(111, i);

    while (doAgain()) {
      L:
      for (; doAgain();) {
        while (doAgain()) {
          break L;
        }
        i--;
      }
      break;
    }
    Expect.equals(111, i);

    L:
    for (i in [111]) {
      while (doAgain()) {
        break L;
      }
      i--;
      break;
    }
    Expect.equals(111, i);

    L:
    for (var j in [111]) {
      while (doAgain()) {
        break L;
      }
      i--;
      break;
    }
    Expect.equals(111, i);

    while (doAgain()) {
      L:
      switch (i) {
        case 111:
          while (doAgain()) {
            break L;
          }
          i--;
          break;
        default:
          i--;
      }
      break;
    }
    Expect.equals(111, i);

    while (doAgain()) {
      L:
      do {
        while (doAgain()) {
          break L;
        }
        i--;
      } while (doAgain());
      break;
    }
    Expect.equals(111, i);

    while (doAgain()) {
      L:
      try {
        while (doAgain()) {
          break L;
        }
        i--;
      } finally {}
      break;
    }
    Expect.equals(111, i);

    return i;
  }

  static test11() {
    // Kind of odd, but is valid and shouldn't be flagged as useless either.
    L:
    break L;
    return 111;
  }

  static test12() {
    int i = 111;

    // label the inner block on compound stmts
    if (true)
      L:
      {
        while (doAgain()) {
          break L;
        }
        i--;
      }
    Expect.equals(111, i);

    // loop will execute each time, but won't execute code below the break
    var forCount = 0;
    for (forCount = 0; forCount < 2; forCount++)
      L:
      {
        while (doAgain()) {
          break L;
        }
        i--;
        break;
      }
    Expect.equals(111, i);
    Expect.equals(forCount, 2);

    for (i in [111])
      L:
      {
        while (doAgain()) {
          break L;
        }
        i--;
        break;
      }
    Expect.equals(111, i);

    for (var j in [111])
      L:
      {
        while (doAgain()) {
          break L;
        }
        i--;
        break;
      }
    Expect.equals(111, i);

    if (false) {} else
      L:
      {
        while (doAgain()) {
          break L;
        }
        i--;
      }
    Expect.equals(111, i);

    int whileCount = 0;
    while (whileCount < 2)
      L:
      {
        whileCount++;
        while (doAgain()) {
          break L;
        }
        i--;
        break;
      }
    Expect.equals(111, i);
    Expect.equals(2, whileCount);

    return i;
  }
}

class LabelTest {
  static testMain() {
    Helper.ticks = 0;
    Expect.equals(111, Helper.test1());
    Expect.equals(111, Helper.test2());
    Expect.equals(111, Helper.test3());
    Expect.equals(111, Helper.test4());
    Expect.equals(111, Helper.test5());
    Expect.equals(111, Helper.test6());
    Expect.equals(111, Helper.test7());
    Expect.equals(111, Helper.test8());
    Expect.equals(111, Helper.test9());
    Expect.equals(111, Helper.test10());
    Expect.equals(111, Helper.test11());
    Expect.equals(111, Helper.test12());
  }
}

main() {
  LabelTest.testMain();
}
