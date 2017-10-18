// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test break out of try-finally.

import "package:expect/expect.dart";

var count = 0;

test() {
  L:
  while (true) {
    try {
      break L;
    } finally {
      count++;
    }
  }
  throw "ex";
}

main() {
  bool caught = false;
  try {
    test();
  } catch (e) {
    caught = true;
    Expect.equals(e, "ex");
  }
  Expect.isTrue(caught);
  Expect.equals(1, count);
}
