// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.
//
// Tests 'identical' for cases that not supported in dart2js (bigint,
// disambiguation int/double).

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 1000; i++) testNumberIdentity();
}

testNumberIdentity() {
  const int smi = 8;
  const int bigint = 22107138293752210713829375;
  const double dbl = 8.0;
  // No int/double differences in dart2js.
  var a = smi + 0;
  Expect.isFalse(identical(a, dbl));
  var c = dbl + 0.0;
  Expect.isFalse(identical(c, smi));

  a = bigint;
  var b = a + 0;
  Expect.isTrue(identical(a, b));
  b = a + 1;
  Expect.isFalse(identical(a, b)); // Fails with dart2js.
}
