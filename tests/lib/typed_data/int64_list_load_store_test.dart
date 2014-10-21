// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

// Test that the compiler's load elimination phase sees interfering writes to
// the array's buffer.

import "dart:typed_data";
import 'package:expect/expect.dart';

void testStoreLoad(l, z) {
  l[0] = 9223372036854775807;
  l[1] = 9223372036854775806;
  l[2] = l[0];
  l[3] = z;
  Expect.equals(l[0], 9223372036854775807);
  Expect.equals(l[1], 9223372036854775806);
  Expect.isTrue(l[1] < l[0]);
  Expect.equals(l[2], l[0]);
  Expect.equals(l[3], z);
}

main() {
  var l = new Int64List(4);
  var zGood = 9223372036854775807;
  var zBad = false;
  for (var i = 0; i < 40; i++) {
    testStoreLoad(l, zGood);
  }
  // Deopt.
  try {
    testStoreLoad(l, zBad);
  } catch (_) { }
  for (var i = 0; i < 40; i++) {
    testStoreLoad(l, zGood);
  }
}
