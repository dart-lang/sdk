// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing try/catch statement without any exceptions
// being thrown.
// VMOptions=--optimization-counter-threshold=100 --no-background-compilation

// Test local variables updated inside try-catch.

import "package:expect/expect.dart";

@pragma('vm:never-inline')
m1(int b) {
  if (b == 1) throw 123;
}

@pragma('vm:never-inline')
m2(int b) {
  if (b == 2) throw 456;
}

@pragma('vm:never-inline')
test(b) {
  var state = 0;
  try {
    state++;
    m1(b);
    state++;
    m2(b);
    state++;
  } catch (e, s) {
    if (b == 1 && state != 1) throw "fail1";
    if (b == 2 && state != 2) throw "fail2";
    if (b == 3 && state != 3) throw "fail3";
    return e;
  }
  return "no throw";
}

main() {
  for (var i = 0; i < 300; i++) {
    Expect.equals("no throw", test(0));
  }
  Expect.equals("no throw", test(0));
  Expect.equals(123, test(1));
  Expect.equals(456, test(2));
}
