// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a coin toss with Random.nextBool() is fair.

// Library tag to allow Dartium to run the test.
library random_test;

import "package:expect/expect.dart";
import 'dart:math';

main() {
  var rnd = new Random(20130307);
  // Make sure we do not break the random number generation.
  var i = 0;
  Expect.equals(         1, rnd.nextInt(1 << ++i));
  Expect.equals(         1, rnd.nextInt(1 << ++i));
  Expect.equals(         7, rnd.nextInt(1 << ++i));
  Expect.equals(         6, rnd.nextInt(1 << ++i));
  Expect.equals(         6, rnd.nextInt(1 << ++i));
  Expect.equals(        59, rnd.nextInt(1 << ++i));
  Expect.equals(        11, rnd.nextInt(1 << ++i));
  Expect.equals(       212, rnd.nextInt(1 << ++i));
  Expect.equals(        17, rnd.nextInt(1 << ++i));
  Expect.equals(       507, rnd.nextInt(1 << ++i));
  Expect.equals(      1060, rnd.nextInt(1 << ++i));
  Expect.equals(       891, rnd.nextInt(1 << ++i));
  Expect.equals(      1534, rnd.nextInt(1 << ++i));
  Expect.equals(      8404, rnd.nextInt(1 << ++i));
  Expect.equals(     13839, rnd.nextInt(1 << ++i));
  Expect.equals(     23298, rnd.nextInt(1 << ++i));
  Expect.equals(     53622, rnd.nextInt(1 << ++i));
  Expect.equals(    205997, rnd.nextInt(1 << ++i));
  Expect.equals(    393823, rnd.nextInt(1 << ++i));
  Expect.equals(    514614, rnd.nextInt(1 << ++i));
  Expect.equals(    233715, rnd.nextInt(1 << ++i));
  Expect.equals(    895357, rnd.nextInt(1 << ++i));
  Expect.equals(   4726185, rnd.nextInt(1 << ++i));
  Expect.equals(   7976427, rnd.nextInt(1 << ++i));
  Expect.equals(  31792146, rnd.nextInt(1 << ++i));
  Expect.equals(  35563210, rnd.nextInt(1 << ++i));
  Expect.equals( 113261265, rnd.nextInt(1 << ++i));
  Expect.equals( 205117298, rnd.nextInt(1 << ++i));
  Expect.equals( 447729735, rnd.nextInt(1 << ++i));
  Expect.equals(1072507596, rnd.nextInt(1 << ++i));
  Expect.equals(2134030067, rnd.nextInt(1 << ++i));
  Expect.equals(721180690, rnd.nextInt(1 << ++i));
  Expect.equals(32, i);
  // If max is too large expect an ArgumentError.
  Expect.throws(() => rnd.nextInt((1 << i)+1), (e) => e is ArgumentError);

  rnd = new Random(6790);
  Expect.approxEquals(0.7360144236, rnd.nextDouble());
  Expect.approxEquals(0.3292339731, rnd.nextDouble());
  Expect.approxEquals(0.3489622548, rnd.nextDouble());
  Expect.approxEquals(0.9815975892, rnd.nextDouble());
}
