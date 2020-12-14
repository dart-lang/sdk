// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that Random can deal with a seed at upper end of 64-bit range.

import "package:expect/expect.dart";
import 'dart:math';

main() {
  var results = [];
  for (var i = 60; i < 64; i++) {
    var rng = new Random(pow(2, i) as int);
    var val = rng.nextInt(100000);
    print("$i: $val");
    Expect.isFalse(results.contains(val));
    results.add(val);
  }
}
