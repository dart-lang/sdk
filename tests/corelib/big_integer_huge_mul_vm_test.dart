// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify

library big_integer_test;
import "package:expect/expect.dart";

testBigintHugeMul() {
  var bits = 65536;
  var a = 1 << bits;
  var a1 = a - 1;  // all 1's
  var p1 = a1 * a1;
  var p2 = a * a - a - a + 1;
  // Use isTrue instead of equals to avoid trying to print such big numbers.
  Expect.isTrue(p1 == p2, 'products do not match');
}

main() {
  testBigintHugeMul();
}
