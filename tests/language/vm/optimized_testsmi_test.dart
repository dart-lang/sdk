// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10

// Test branch optimization for TestSmiInstr

import "package:expect/expect.dart";

test(bool b) {
  var a = 0;
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

main() {
  Expect.equals("odd", test(true));
  Expect.equals("even", test(false));
  for (var i=0; i<20; i++) test(false);
  Expect.equals("odd", test(true));
  Expect.equals("even", test(false));
}

