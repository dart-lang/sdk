// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the secure random generator does not systematically generates
// duplicates. Note that this test is flaky by definition, since duplicates
// can occur. They should be extremely rare, though.

// Library tag to allow Dartium to run the test.
library random_secure;

import "package:expect/expect.dart";
import 'dart:math';

main() {
  var results;
  var rng0;
  var rng1;
  var checkInt = (max) {
    var intVal0 = rng0.nextInt(max);
    var intVal1 = rng1.nextInt(max);
    if (max > (1 << 28)) {
      Expect.isFalse(results.contains(intVal0));
      results.add(intVal0);
      Expect.isFalse(results.contains(intVal1));
      results.add(intVal1);
    }
  };
  results = [];
  rng0 = new Random.secure();
  for (var i = 0; i <= 32; i++) {
    rng1 = new Random.secure();
    checkInt(pow(2, 32));
    checkInt(pow(2, 32 - i));
    checkInt(1000000000);
  }
  var checkDouble = () {
    var doubleVal0 = rng0.nextDouble();
    var doubleVal1 = rng1.nextDouble();
    Expect.isFalse(results.contains(doubleVal0));
    results.add(doubleVal0);
    Expect.isFalse(results.contains(doubleVal1));
    results.add(doubleVal1);
  };
  results = [];
  rng0 = new Random.secure();
  for (var i = 0; i < 32; i++) {
    rng1 = new Random.secure();
    checkDouble();
  }
  var cnt0 = 0;
  var cnt1 = 0;
  rng0 = new Random.secure();
  for (var i = 0; i < 32; i++) {
    rng1 = new Random.secure();
    cnt0 += rng0.nextBool() ? 1 : 0;
    cnt1 += rng1.nextBool() ? 1 : 0;
  }
  Expect.isTrue((cnt0 > 0) && (cnt0 < 32));
  Expect.isTrue((cnt1 > 0) && (cnt1 < 32));
}
