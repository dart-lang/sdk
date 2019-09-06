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
  // We don't specify the exact exception type here, that is covered in
  // truncdiv_zero_test. The correct answer is IntegerDivisionByZeroException,
  // but the web platform has only one num type and can't distinguish between
  // int and double, so it throws UnsupportedError (the behaviour for double).
  Expect.throws(() => foo2(0));
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
