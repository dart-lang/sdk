// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that our SSA graph does have the try body a predecessor of a
// try/finally.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

var a;

foo1() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      a = 8;
      return false;
    } finally {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

doThrow() {
  throw 2;
}

foo2() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      a = 8;
      doThrow();
      return false;
    } catch (e) {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo3() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      doThrow();
    } catch (e) {
      a = 8;
      entered = true;
      return false;
    } finally {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo4() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      a = 8;
      break;
    } finally {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo5() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      a = 8;
      doThrow();
      break;
    } catch (e) {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo6() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      doThrow();
    } catch (e) {
      a = 8;
      entered = true;
      break;
    } finally {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo7() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      a = 8;
      continue;
    } finally {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo8() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      a = 8;
      doThrow();
      continue;
    } catch (e) {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

foo9() {
  var b = false;
  var entered = false;
  while (true) {
    if (entered) return b;
    b = 8 == a; // This expression should not be GVN'ed.
    try {
      doThrow();
    } catch (e) {
      a = 8;
      entered = true;
      continue;
    } finally {
      b = 8 == a;
      entered = true;
      continue;
    }
  }
}

main_test() {
  a = 0;
  Expect.isTrue(foo1());
  a = 0;
  Expect.isTrue(foo2());
  a = 0;
  Expect.isTrue(foo3());
  a = 0;
  Expect.isTrue(foo4());
  a = 0;
  Expect.isTrue(foo5());
  a = 0;
  Expect.isTrue(foo6());
  a = 0;
  Expect.isTrue(foo7());
  a = 0;
  Expect.isTrue(foo8());
  a = 0;
  Expect.isTrue(foo9());
}

main() {
  for (var i = 0; i < 20; i++) {
    main_test();
  }
}
