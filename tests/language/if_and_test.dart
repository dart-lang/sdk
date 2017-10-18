// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// The "if (negative) res2 |= 3" below can be emitted as negative && (res2 |= 3)
// in JavaScript. Dart2js produced the wrong output.

_shiftRight(x, y) => x;
int64_bits(x) => x;

class A {
  opshr(int n, a2) {
    int res2;
    bool negative = a2 == 496;

    res2 = _shiftRight(a2, n);
    if (negative) {
      res2 |= 3;
    }
    return int64_bits(res2);
  }
}

main() {
  var a = new A();
  var t;
  for (int i = 0; i < 3; i++) {
    t = a.opshr(99, 496);
  }
  Expect.equals(499, t);
}
