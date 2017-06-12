// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization caused by running code that did not collect type
// feedback before.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

testStoreIndexed() {
  test(a, i, v, flag) {
    if (flag) {
      // No type feedback in first pass
      return a[i] = v;
    } else {
      return a[i] = i;
    }
  }

  var a = new List(10);
  for (var i = 0; i < 20; i++) {
    var r = test(a, 3, 888, false);
    Expect.equals(3, r);
    Expect.equals(3, a[3]);
  }
  // Deopt.
  var r = test(a, 3, 888, true);
  Expect.equals(888, r);
  Expect.equals(888, a[3]);
}

testIncrLocal() {
  test(a, flag) {
    if (flag) {
      a++;
      return a;
    } else {
      return -1;
    }
  }

  for (var i = 0; i < 20; i++) {
    var r = test(10, false);
    Expect.equals(-1, r);
  }
  // Deopt.
  var r = test(10, true);
  Expect.equals(11, r);
}

main() {
  for (var i = 0; i < 20; i++) {}
  testStoreIndexed();
  testIncrLocal();
}
