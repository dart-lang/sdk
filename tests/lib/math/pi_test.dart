// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the default PRNG does converge towards Pi when doing a Monte Carlo
// simulation.

// Library tag to allow Dartium to run the test.
#library("pi_test.dart");

#import("dart:math");

void main() {
  var seed = new Random().nextInt((1<<32) - 1);
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
  Expect.isTrue((3.14 < pie) && (pie < 3.15));
}
