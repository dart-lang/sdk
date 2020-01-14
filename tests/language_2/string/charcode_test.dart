// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 20; i++) {
    Expect.isTrue(moo("x"));
    Expect.isFalse(moo("X"));
    Expect.isFalse(moo("xx"));
    Expect.isTrue(mooRev("x"));
    Expect.isFalse(mooRev("X"));
    Expect.isFalse(mooRev("xx"));
    Expect.isTrue(goo("Hello", "e"));
    Expect.isFalse(goo("Hello", "E"));
    Expect.isFalse(goo("Hello", "ee"));
    Expect.isTrue(gooRev("Hello", "e"));
    Expect.isFalse(gooRev("Hello", "E"));
    Expect.isFalse(gooRev("Hello", "ee"));
    Expect.isTrue(hoo("HH"));
    Expect.isFalse(hoo("Ha"));
    Expect.isTrue(hooRev("HH"));
    Expect.isFalse(hooRev("Ha"));
  }
  Expect.isFalse(moo(12));
  Expect.isFalse(mooRev(12));
  Expect.isTrue(goo([1, 2], 2));
  Expect.isTrue(gooRev([1, 2], 2));
  Expect.throwsRangeError(() => hoo("H"));
  Expect.throwsRangeError(() => hooRev("H"));
}

moo(j) {
  return "x" == j;
}

goo(a, j) {
  return a[1] == j;
}

// Check constant folding.
hoo(a) {
  return a[1] == ("Hello")[0];
}

mooRev(j) {
  return j == "x";
}

gooRev(a, j) {
  return j == a[1];
}

// Check constant folding.
hooRev(a) {
  return ("Hello")[0] == a[1];
}
