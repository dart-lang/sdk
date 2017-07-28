// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing assign operators.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

class AssignOpTest {
  AssignOpTest() {}

  static testMain() {
    var b = 0;
    b += 1;
    Expect.equals(1, b);
    b *= 5;
    Expect.equals(5, b);
    b -= 1;
    Expect.equals(4, b);
    b ~/= 2;
    Expect.equals(2, b);

    f = 0;
    f += 1;
    Expect.equals(1, f);
    f *= 5;
    Expect.equals(5, f);
    f -= 1;
    Expect.equals(4, f);
    f ~/= 2;
    Expect.equals(2, f);
    f /= 4;
    Expect.equals(.5, f);

    AssignOpTest.f = 0;
    AssignOpTest.f += 1;
    Expect.equals(1, AssignOpTest.f);
    AssignOpTest.f *= 5;
    Expect.equals(5, AssignOpTest.f);
    AssignOpTest.f -= 1;
    Expect.equals(4, AssignOpTest.f);
    AssignOpTest.f ~/= 2;
    Expect.equals(2, AssignOpTest.f);
    AssignOpTest.f /= 4;
    Expect.equals(.5, f);

    var o = new AssignOpTest();
    o.instf = 0;
    o.instf += 1;
    Expect.equals(1, o.instf);
    o.instf *= 5;
    Expect.equals(5, o.instf);
    o.instf -= 1;
    Expect.equals(4, o.instf);
    o.instf ~/= 2;
    Expect.equals(2, o.instf);
    o.instf /= 4;
    Expect.equals(.5, o.instf);

    var x = 0xFF;
    x >>= 3;
    Expect.equals(0x1F, x);
    x <<= 3;
    Expect.equals(0xF8, x);
    x |= 0xF00;
    Expect.equals(0xFF8, x);
    x &= 0xF0;
    Expect.equals(0xF0, x);
    x ^= 0x11;
    Expect.equals(0xE1, x);

    var y = 100;
    y += 1 << 3;
    Expect.equals(108, y);
    y *= 2 + 1;
    Expect.equals(324, y);
    y -= 3 - 2;
    Expect.equals(323, y);
    y += 3 * 4;
    Expect.equals(335, y);

    var a = [1, 2, 3];
    var ix = 0;
    a[ix] |= 12;
    Expect.equals(13, a[ix]);
  }

  static var f;
  var instf;
}

main() {
  for (int i = 0; i < 20; i++) {
    AssignOpTest.testMain();
  }
}
