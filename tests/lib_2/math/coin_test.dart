// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a coin toss with Random.nextBool() is fair.

// Library tag to allow Dartium to run the test.
library coin_test;

import "package:expect/expect.dart";
import 'dart:math';

main() {
  var seed = new Random().nextInt(1 << 16);
  print("coin_test seed: $seed");
  var rnd = new Random(seed);
  var heads = 0;
  var tails = 0;
  for (var i = 0; i < 10000; i++) {
    if (rnd.nextBool()) {
      heads++;
    } else {
      tails++;
    }
  }
  print("Heads: $heads\n"
      "Tails: $tails\n"
      "Ratio: ${heads/tails}\n");
  Expect.approxEquals(1.0, heads / tails, 0.1);

  heads = 0;
  tails = 0;
  for (var i = 0; i < 10000; i++) {
    rnd = new Random(i);
    if (rnd.nextBool()) {
      heads++;
    } else {
      tails++;
    }
  }
  print("Heads: $heads\n"
      "Tails: $tails\n"
      "Ratio: ${heads/tails}\n");
  Expect.approxEquals(1.0, heads / tails, 0.1);

  // A sequence of newly allocated Random number generators should have fair
  // initial tosses.
  heads = 0;
  tails = 0;
  for (var i = 0; i < 10000; i++) {
    rnd = new Random();
    if (rnd.nextBool()) {
      heads++;
    } else {
      tails++;
    }
  }
  print("Heads: $heads\n"
      "Tails: $tails\n"
      "Ratio: ${heads/tails}\n");
  Expect.approxEquals(1.0, heads / tails, 0.1);
}
