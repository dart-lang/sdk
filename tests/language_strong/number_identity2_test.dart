// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.
//
// Contains test that is failing on dart2js. Merge this test with
// 'number_identity_test.dart' once fixed.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";
import 'dart:typed_data';

double uint64toDouble(int i) {
  var buffer = new Uint8List(8).buffer;
  var bdata = new ByteData.view(buffer);
  bdata.setUint64(0, i);
  return bdata.getFloat64(0);
}

testNumberIdentity() {
  var a = double.NAN;
  var b = a + 0.0;
  Expect.isTrue(identical(a, b));

  a = uint64toDouble((1 << 64) - 1);
  b = uint64toDouble((1 << 64) - 2);
  Expect.isFalse(identical(a, b));

  a = 0.0 / 0.0;
  b = 1.0 / 0.0;
  Expect.isFalse(identical(a, b));
}

main() {
  for (int i = 0; i < 20; i++) {
    testNumberIdentity();
  }
}
