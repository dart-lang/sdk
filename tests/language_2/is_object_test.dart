// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for the "is" type test operator.

import "package:expect/expect.dart";

testTryCatch(x) {
  try {
    throw x;
    Expect.fail("Exception '$x' should've been thrown");
  } on Object catch (obj) {
    Expect.equals(obj, x);
  }
}

main() {
  var evalCount = 0;
  testEval(x) {
    evalCount++;
    return x;
  }

  // Test that types that match JS primitive types compare correctly to Object
  var x = 1;
  Expect.isTrue(x is Object);
  var x2 = 'hi';
  Expect.isTrue(x2 is Object);
  var x3 = true;
  Expect.isTrue(x3 is Object);
  var x4 = null;
  Expect.isTrue(x4 is Object);
  var y;
  Expect.isTrue(y is Object);

  // Verify that operand is evaluated
  Expect.isTrue(testEval(123) is Object);
  Expect.equals(1, evalCount);
  Expect.isTrue(testEval('world') is Object);
  Expect.equals(2, evalCount);
  Expect.isTrue(testEval(false) is Object);
  Expect.equals(3, evalCount);
  Expect.isTrue(testEval(null) is Object);
  Expect.equals(4, evalCount);

  // Verify that these objects are catchable
  testTryCatch(444);
  testTryCatch('abc');
  testTryCatch(true);
}
