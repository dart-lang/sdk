// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'dart:math' show pow;

main() {
  // Test integers.
  testInt(0);
  for (int i = 0; i < 63; i++) {
    var n = pow(2, i);
    testInt(-n - 1);
    testInt(-n);
    testInt(-n + 1);
    testInt(n - 1);
    testInt(n);
    testInt(n + 1);
  }
  testInt(-0x8000000000000000);

  // Test doubles.
  testDouble(0.0);
  testDouble(-0.0, 0.0);
  for (double d in [
    1.0,
    2.0,
    pow(2.0, 30) - 1,
    pow(2.0, 30),
    pow(2.0, 31) - 1,
    pow(2.0, 31),
    pow(2.0, 31) + 1,
    pow(2.0, 32) - 1,
    pow(2.0, 32),
    pow(2.0, 32) + 1,
    pow(2.0, 52) - 1,
    pow(2.0, 52),
    pow(2.0, 52) + 1,
    pow(2.0, 53) - 1,
    pow(2.0, 53),
  ]) {
    for (int p = 0; p < 1024; p++) {
      var value = d * pow(2.0, p); // Valid integer value.
      if (!value.isFinite) break;
      testDouble(-value);
      testDouble(value);
    }
  }
  Expect.equals(BigInt.zero, new BigInt.from(0.5));
  Expect.equals(BigInt.one, new BigInt.from(1.5));

  Expect.throws(() => new BigInt.from(double.infinity));
  Expect.throws(() => new BigInt.from(-double.infinity));
  Expect.throws(() => new BigInt.from(double.nan));
}

testInt(int n) {
  var bigint = new BigInt.from(n);
  Expect.equals(n, bigint.toInt());
  Expect.equals("$n", "$bigint");
}

testDouble(double input, [double expectation]) {
  var bigint = new BigInt.from(input);
  Expect.equals(expectation ?? input, bigint.toDouble());
}
