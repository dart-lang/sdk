// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test a new statement by itself.
// VMOptions=--optimization-counter-threshold=4 --no-background-compilation

import 'dart:typed_data';

import "package:expect/expect.dart";

double createOtherNAN() {
  var buffer = new Uint8List(8).buffer;
  var bdata = new ByteData.view(buffer);
  bdata.setFloat64(0, double.NAN);
  bdata.setInt8(7, bdata.getInt8(7) ^ 1); // Flip bit 0, big endian.
  double result = bdata.getFloat64(0);
  Expect.isTrue(result.isNaN);
  return result;
}

main() {
  var otherNAN = createOtherNAN();
  for (int i = 0; i < 100; i++) {
    Expect.isFalse(checkIdentical(double.NAN, -double.NAN));
    Expect.isTrue(checkIdentical(double.NAN, double.NAN));
    Expect.isTrue(checkIdentical(-double.NAN, -double.NAN));

    Expect.isFalse(checkIdentical(otherNAN, -otherNAN));
    Expect.isTrue(checkIdentical(otherNAN, otherNAN));
    Expect.isTrue(checkIdentical(-otherNAN, -otherNAN));

    var a = otherNAN;
    var b = double.NAN;
    Expect.isFalse(checkIdentical(a, b));
    Expect.isFalse(checkIdentical(-a, -b));
    Expect.isFalse(checkIdentical(-a, b));
    Expect.isFalse(checkIdentical(a, -b));

    a = -a;
    Expect.isFalse(checkIdentical(a, b));
    Expect.isFalse(checkIdentical(-a, -b));
    Expect.isFalse(checkIdentical(-a, b));
    Expect.isFalse(checkIdentical(a, -b));

    Expect.isTrue(checkIdentical(-(-a), a));
    Expect.isTrue(checkIdentical(-(-b), b));
  }
}

checkIdentical(a, b) => identical(a, b);
