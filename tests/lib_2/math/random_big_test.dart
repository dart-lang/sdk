// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that Random can deal with a seed outside 64-bit range.

// Library tag to allow Dartium to run the test.
library random_big;

import "package:expect/expect.dart";
import 'dart:math';

main() {
  var results = [];
  for (var i = 60; i < 64; i++) {
    var rng = new Random(1 << i);
    var val = rng.nextInt(100000);
    print("$i: $val");
    Expect.isFalse(results.contains(val));
    results.add(val);
  }
}
