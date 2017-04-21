// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

constants() {
  Expect.equals(0x80000000, 0x80000000 | 0);
  Expect.equals(0x80000001, 0x80000000 | 1);
  Expect.equals(0x80000000, 0x80000000 | 0x80000000);
  Expect.equals(0xFFFFFFFF, 0xFFFF0000 | 0xFFFF);
  Expect.equals(0x80000000, 0x80000000 & 0xFFFFFFFF);
  Expect.equals(0x80000000, 0x80000000 & 0x80000000);
  Expect.equals(0x80000000, 0x80000000 & 0xF0000000);
  Expect.equals(0x80000000, 0xFFFFFFFF & 0x80000000);
  Expect.equals(0x80000000, 0x80000000 ^ 0);
  Expect.equals(0xFFFFFFFF, 0x80000000 ^ 0x7FFFFFFF);
  Expect.equals(0xFFFFFFFF, 0x7FFFFFFF ^ 0x80000000);
  Expect.equals(0xF0000000, 0x70000000 ^ 0x80000000);
  Expect.equals(0x80000000, 1 << 31);
  Expect.equals(0xFFFFFFF0, 0xFFFFFFF << 4);
  Expect.equals(0x7FFFFFFF, 0xFFFFFFFF >> 1);
  Expect.equals(
      0xFFFFFFFC,
      ((((((0xFFFFFFF << 4) // 0xFFFFFFF0
                          >>
                          1) // 0x7FFFFFF8
                      |
                      0x80000000) // 0xFFFFFFF8
                  >>
                  2) // 0x3FFFFFFE
              ^
              0x40000000) // 0x7FFFFFFE
          <<
          1));
}

foo(i) {
  if (i != 0) {
    y--;
    foo(i - 1);
    y++;
  }
}

var y;

// id returns [x] in a way that should be difficult to predict statically.
id(x) {
  y = x;
  foo(10);
  return y;
}

interceptors() {
  Expect.equals(0x80000000, id(0x80000000) | id(0));
  Expect.equals(0x80000001, id(0x80000000) | id(1));
  Expect.equals(0x80000000, id(0x80000000) | id(0x80000000));
  Expect.equals(0xFFFFFFFF, id(0xFFFF0000) | id(0xFFFF));
  Expect.equals(0x80000000, id(0x80000000) & id(0xFFFFFFFF));
  Expect.equals(0x80000000, id(0x80000000) & id(0x80000000));
  Expect.equals(0x80000000, id(0x80000000) & id(0xF0000000));
  Expect.equals(0x80000000, id(0xFFFFFFFF) & id(0x80000000));
  Expect.equals(0x80000000, id(0x80000000) ^ id(0));
  Expect.equals(0xFFFFFFFF, id(0x80000000) ^ id(0x7FFFFFFF));
  Expect.equals(0xFFFFFFFF, id(0x7FFFFFFF) ^ id(0x80000000));
  Expect.equals(0xF0000000, id(0x70000000) ^ id(0x80000000));
  Expect.equals(0x80000000, id(1) << id(31));
  Expect.equals(0xFFFFFFF0, id(0xFFFFFFF) << id(4));
  Expect.equals(0x7FFFFFFF, id(0xFFFFFFFF) >> id(1));
  Expect.equals(
      0xFFFFFFFC,
      ((((((id(0xFFFFFFF) << 4) // 0xFFFFFFF0
                          >>
                          1) // 0x7FFFFFF8
                      |
                      0x80000000) // 0xFFFFFFF8
                  >>
                  2) // 0x3FFFFFFE
              ^
              0x40000000) // 0x7FFFFFFE
          <<
          1));
}

speculative() {
  var a = id(0x80000000);
  var b = id(0);
  var c = id(1);
  var d = id(0xFFFF0000);
  var e = id(0xFFFF);
  var f = id(0xFFFFFFFF);
  var g = id(0xF0000000);
  var h = id(0x7FFFFFFF);
  var j = id(0x70000000);
  var k = id(31);
  var l = id(4);
  var m = id(0xFFFFFFF);
  for (int i = 0; i < 1; i++) {
    Expect.equals(0x80000000, a | b);
    Expect.equals(0x80000001, a | c);
    Expect.equals(0x80000000, a | a);
    Expect.equals(0xFFFFFFFF, d | e);
    Expect.equals(0x80000000, a & f);
    Expect.equals(0x80000000, a & a);
    Expect.equals(0x80000000, a & g);
    Expect.equals(0x80000000, f & a);
    Expect.equals(0x80000000, a ^ b);
    Expect.equals(0xFFFFFFFF, a ^ h);
    Expect.equals(0xFFFFFFFF, h ^ a);
    Expect.equals(0xF0000000, j ^ a);
    Expect.equals(0x80000000, c << k);
    Expect.equals(0xFFFFFFF0, m << l);
    Expect.equals(0x7FFFFFFF, f >> c);
    Expect.equals(
        0xFFFFFFFC,
        ((((((m << 4) // 0xFFFFFFF0
                            >>
                            1) // 0x7FFFFFF8
                        |
                        0x80000000) // 0xFFFFFFF8
                    >>
                    2) // 0x3FFFFFFE
                ^
                0x40000000) // 0x7FFFFFFE
            <<
            1));
  }
}

// Due to bad precedence rules this example was broken in Dart2Js.
precedence() {
  Expect.equals(0x80000000, -1 & 0x80000000);
  Expect.equals(0x80000000, id(-1) & 0x80000000);
  Expect.equals(0x80000000, ~(~(0x80000000)));
  Expect.equals(0x80000000, ~(~(id(0x80000000))));
}

main() {
  constants();
  interceptors();
  speculative();
  precedence();
}
