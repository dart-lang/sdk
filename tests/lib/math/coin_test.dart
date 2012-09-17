// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the default PRNG does converge towards Pi when doing a Monte Carlo
// simulation.

// Library tag to allow Dartium to run the test.
#library("coin_test");

#import("dart:math");

main() {
  var seed = new Random().nextInt((1<<32) - 1);
  print("coin_test seed: $seed");
  var rnd = new Random();
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
  Expect.approxEquals(1.0, heads/tails, tolerance:0.1);
}