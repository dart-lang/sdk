// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test a new statement by itself.
// VMOptions=--optimization-counter-threshold=4 --no-use-osr

import 'dart:typed_data';

import "package:expect/expect.dart";

double uint64toDouble(int i) {
  var buffer = new Uint8List(8).buffer;
  var bdata = new ByteData.view(buffer);
  bdata.setUint64(0, i);
  return bdata.getFloat64(0);
}

double createOtherNAN() {
  return uint64toDouble((1 << 64) - 2);
}

main() {
  if (webNumbers) {
    // (1) The web compilers elect to generate smaller, faster code for
    // `identical` using `===`, with the result that `identical(NaN, NaN)` is
    // false.
    //
    // (2) In JavaScript different NaN values are treated the same by
    // `Object.is`, and can only be distinguished by writing the bits into typed
    // data, making it costly to compare NaN values.

    // Validate current behaviour so we will be alerted if (1) changes.
    Expect.isFalse(checkIdentical(double.nan, -double.nan));
    Expect.isFalse(checkIdentical(double.nan, double.nan));
    Expect.isFalse(checkIdentical(-double.nan, -double.nan));
    return;
  }

  var otherNAN = createOtherNAN();
  for (int i = 0; i < 100; i++) {
    Expect.isFalse(checkIdentical(double.nan, -double.nan));
    Expect.isTrue(checkIdentical(double.nan, double.nan));
    Expect.isTrue(checkIdentical(-double.nan, -double.nan));

    Expect.isFalse(checkIdentical(otherNAN, -otherNAN));
    Expect.isTrue(checkIdentical(otherNAN, otherNAN));
    Expect.isTrue(checkIdentical(-otherNAN, -otherNAN));

    var a = otherNAN;
    var b = double.nan;
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
