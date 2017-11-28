// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test optimization of modulo operator on Smi.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

main() {
  for (int i = -30; i < 30; i++) {
    Expect.equals(i % 9, foo(i, 9));
    // Zero test is done outside the loop.
    if (i < 0) {
      Expect.equals(i ~/ -i, foo2(i));
    } else if (i > 0) {
      Expect.equals(i ~/ i, foo2(i));
    }
  }
  Expect.throws(() => foo(12, 0), (e) => e is IntegerDivisionByZeroException);
  Expect.throws(() => foo2(0), (e) => e is IntegerDivisionByZeroException);
}

foo(i, x) => i % x;

foo2(i) {
  // Make sure x has a range computed.
  var x = 0;
  if (i < 0) {
    x = -i;
  } else {
    x = i;
  }
  return i ~/ x;
}
