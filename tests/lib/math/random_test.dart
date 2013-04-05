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
  Expect.equals(         0, rnd.nextInt(1 << ++i));
  Expect.equals(         2, rnd.nextInt(1 << ++i));
  Expect.equals(         7, rnd.nextInt(1 << ++i));
  Expect.equals(         8, rnd.nextInt(1 << ++i));
  Expect.equals(         1, rnd.nextInt(1 << ++i));
  Expect.equals(        61, rnd.nextInt(1 << ++i));
  Expect.equals(        31, rnd.nextInt(1 << ++i));
  Expect.equals(       230, rnd.nextInt(1 << ++i));
  Expect.equals(       390, rnd.nextInt(1 << ++i));
  Expect.equals(       443, rnd.nextInt(1 << ++i));
  Expect.equals(      1931, rnd.nextInt(1 << ++i));
  Expect.equals(      3028, rnd.nextInt(1 << ++i));
  Expect.equals(      5649, rnd.nextInt(1 << ++i));
  Expect.equals(      4603, rnd.nextInt(1 << ++i));
  Expect.equals(     27684, rnd.nextInt(1 << ++i));
  Expect.equals(     54139, rnd.nextInt(1 << ++i));
  Expect.equals(     83454, rnd.nextInt(1 << ++i));
  Expect.equals(    106708, rnd.nextInt(1 << ++i));
  Expect.equals(    112143, rnd.nextInt(1 << ++i));
  Expect.equals(    875266, rnd.nextInt(1 << ++i));
  Expect.equals(    971126, rnd.nextInt(1 << ++i));
  Expect.equals(   1254573, rnd.nextInt(1 << ++i));
  Expect.equals(   4063839, rnd.nextInt(1 << ++i));
  Expect.equals(   7854646, rnd.nextInt(1 << ++i));
  Expect.equals(  29593843, rnd.nextInt(1 << ++i));
  Expect.equals(  17672573, rnd.nextInt(1 << ++i));
  Expect.equals(  80223657, rnd.nextInt(1 << ++i));
  Expect.equals( 142194155, rnd.nextInt(1 << ++i));
  Expect.equals(  31792146, rnd.nextInt(1 << ++i));
  Expect.equals(1042196170, rnd.nextInt(1 << ++i));
  Expect.equals(1589656273, rnd.nextInt(1 << ++i));
  Expect.equals(1547294578, rnd.nextInt(1 << ++i));
  Expect.equals(32, i);
  // If max is too large expect an ArgumentError. 
  Expect.throws(() => rnd.nextInt((1 << i)+1), (e) => e is ArgumentError);
}
