// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 20; i++) testNumberIdentity();
}

testNumberIdentity() {
  const int smi = 8;
  const int mint = 9223372036854775806;
  const int bigint = 22107138293752210713829375;
  const double dbl = 8.0;

  var a = smi;
  var b = a + 0;
  Expect.isTrue(identical(a, b));
  Expect.isFalse(identical(b, mint));
  Expect.isFalse(identical(b, bigint));

  a = mint;
  b = a + 0;
  Expect.isTrue(identical(a, b));
  Expect.isFalse(identical(b, smi));
  Expect.isFalse(identical(b, bigint));
  Expect.isFalse(identical(b, dbl));

  a = bigint;
  b = a + 0;
  Expect.isTrue(identical(a, b));
  Expect.isFalse(identical(b, smi));
  Expect.isFalse(identical(b, mint));
  Expect.isFalse(identical(b, dbl));

  var a2 = dbl;
  var b2 = a2 + 0.0;
  Expect.isTrue(identical(a2, b2));
  Expect.isFalse(identical(b2, mint));
  Expect.isFalse(identical(b2, bigint));
}
