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
      try {
        a = 8;
        return false;
      } finally {
        b = 8 == a;
        entered = true;
        continue;
      }
    } finally {
      continue;
    }
  }
}

main() {
  for (var i = 0; i < 20; i++) {
    a = 0;
    Expect.isTrue(foo1());
  }
}
