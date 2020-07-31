// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that phi type computation in the Dart2Js compiler does the
// correct thing.

import "package:expect/expect.dart";

bar() => 490;
bar2() => 0;

foo(b) {
  var x = bar();
  var x2 = x;
  if (b) x2 = bar2();
  var x3 = 9 + x; // Guarantees that x is a number. Dart2js propagated the
  // type information back to the phi (for x2).
  return x2 + x3;
}

main() {
  Expect.equals(499, foo(true));
}
