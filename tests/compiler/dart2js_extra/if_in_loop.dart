// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for bug in code generation of if-with-aborting-branch-inside-loop.

foo(p, q) {
  var w = 10;
  do {
    if (p) {
      w = 20;
    } else {
      w = 30;
      return w;
    }
  } while (q);
  return w;
}

main() {
  Expect.equals(30, foo(false, true));
  Expect.equals(30, foo(false, false));
  Expect.equals(20, foo(true, false));
}