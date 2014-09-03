// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_test;
import "package:expect/expect.dart";
import 'dart:math';
import 'package:math/math.dart';

void testPowmod() {
  Expect.equals(1, powmod(2, 0, 7));
  Expect.equals(2, powmod(2, 1, 7));
  Expect.equals(4, powmod(2, 2, 7));
  Expect.equals(1, powmod(2, 3, 7));
  Expect.equals(2, powmod(2, 4, 7));

  Expect.equals(1, powmod(2, 0, 13));
  Expect.equals(1, powmod(-5, 0, 7));
  Expect.equals(1, powmod(2, 0, -9));

  // Negative base
  Expect.equals(1, powmod(-2, 0, 7));
  Expect.equals(5, powmod(-2, 1, 7));
  Expect.equals(6, powmod(-2, 3, 7));

  // Negative power (inverse modulo)
  Expect.equals(4, powmod(2, -1, 7));
  Expect.equals(2, powmod(2, -2, 7));
  Expect.equals(1, powmod(2, -3, 7));

  // Negative modulus (should behave like % operator)
  Expect.equals(1, powmod(2, 0, -7));
  Expect.equals(2, powmod(2, 1, -7));
  Expect.equals(4, powmod(2, 2, -7));

  Expect.throws(() => powmod(0, null, 0), (e) => e is ArgumentError);
  Expect.throws(() => powmod(null, 0, 0), (e) => e is ArgumentError);
  Expect.throws(() => powmod(0, 0, null), (e) => e is ArgumentError);

  // Medium int (mint) arguments smaller than 94906266.
  // 67108879 is the first prime after 2^26.
  Expect.equals(1048576, powmod(pow(2, 20), 1, 67108879));
  Expect.equals(66863119, powmod(pow(2, 20), 2, 67108879));
  Expect.equals(57600, powmod(pow(2, 20), 3, 67108879));
  Expect.equals(67095379, powmod(pow(2, 20), 4, 67108879));
  Expect.equals(4197469, powmod(pow(2, 20), 5, 67108879));
}

main() {
  testPowmod();
}
