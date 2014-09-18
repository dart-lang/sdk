// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the default PRNG does converge towards Pi when doing a Monte Carlo
// simulation.

// Library tag to allow Dartium to run the test.
library pi_test;

import "package:expect/expect.dart";
import 'dart:math';

var known_bad_seeds = const [
  50051,
  55597,
  59208
];

void main(args) {
  // Select a seed either from the argument passed in or
  // otherwise a random seed.
  var seed = -1;
  if ((args != null) && (args.length > 0)) {
    seed = int.parse(args[0]);
  } else {
    var seed_prng = new Random();
    while (seed == -1) {
      seed = seed_prng.nextInt(1<<16);
      if (known_bad_seeds.contains(seed)) {
        // Reset seed and try again.
        seed = -1;
      }
    }
  }
  
  // Setup the PRNG for the Monte Carlo simulation.
  print("pi_test seed: $seed");
  var prng = new Random(seed);

  var outside = 0;
  var inside = 0;
  for (var i = 0; i < 600000; i++) {
    var x = prng.nextDouble();
    var y = prng.nextDouble();
    if ((x*x) + (y*y) < 1.0) {
      inside++;
    } else {
      outside++;
    }
  }
  // Mmmmh, Pie!
  var pie = 4.0 * (inside/(inside + outside));
  print("$pie");
  Expect.isTrue(((PI - 0.009) < pie) && (pie < (PI + 0.009)));
}
