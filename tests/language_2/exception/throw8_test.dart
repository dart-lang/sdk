// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

var finallyExecutionCount = 0;
bar() {
  try {
    try {
      return 499;
    } catch (e, st) {
      rethrow;
    }
  } finally {
    finallyExecutionCount++;
    throw "quit finally with throw";
  }
}

main() {
  bool hasThrown = false;
  try {
    bar();
  } catch (x) {
    hasThrown = true;
    Expect.equals(1, finallyExecutionCount);
  }
  Expect.isTrue(hasThrown);
}
