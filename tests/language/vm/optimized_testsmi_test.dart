// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

// Test branch optimization for TestSmiInstr

import "package:expect/expect.dart";

test1(a, bool b) {
  if (b) {
    a++;
  } else {
    a += 2;
  }
  if (a & 1 == 0) {
    return "even";
  }
  return "odd";
}

test2(a, bool b) {
  if (b) {
    a++;
  } else {
    a += 2;
  }
  if (a & 1 == 1) {
    return "odd";
  }
  return "even";
}

test3(a, bool b) {
  return test1(0, b);
}

test4(a, bool b) {
  return test2(0, b);
}

run(test) {
  Expect.equals("odd", test(0, true));
  Expect.equals("even", test(0, false));
  for (var i = 0; i < 20; i++) test(0, false);
  Expect.equals("odd", test(0, true));
  Expect.equals("even", test(0, false));
}

main() {
  run(test1);
  run(test2);
  run(test3);
  run(test4);
}
