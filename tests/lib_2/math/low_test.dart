// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the default PRNG does uniformly distribute values when not using
// a power of 2.

// Library tag to allow Dartium to run the test.
library low_test;

import "package:expect/expect.dart";
import 'dart:math';

void main() {
  var n = (2 * (1 << 32)) ~/ 3;
  var n2 = n ~/ 2;

  var iterations = 200000;

  var seed = new Random().nextInt(1 << 16);
  print("low_test seed: $seed");
  var prng = new Random(seed);

  var low = 0;
  for (var i = 0; i < iterations; i++) {
    if (prng.nextInt(n) < n2) {
      low++;
    }
  }

  var diff = (low - (iterations ~/ 2)).abs();
  print("$low, $diff");
  Expect.isTrue(diff < (iterations ~/ 20));
}
