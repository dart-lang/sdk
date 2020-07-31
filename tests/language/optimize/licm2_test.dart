// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a loop invariant code motion optimization does not try to
// hoist instructions that may throw.

import "package:expect/expect.dart";

var a = 42;
var b;

main() {
  Expect.throws(() {
    while (true) {
      a = 54;
      b.length;
    }
  });
  b = [];
  Expect.equals(54, a);
}
