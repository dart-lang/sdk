// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compares on 64-bit integers.


compareTest() {
  Expect.isFalse(4294967296 < 6);
  Expect.isFalse(4294967296 < 4294967296);
  Expect.isFalse(4294967296 <= 6);
  Expect.isTrue(4294967296 <= 4294967296);
  Expect.isFalse(4294967296 < 4294967295);

  Expect.isTrue(-4294967296 < 6);
  Expect.isTrue(-4294967296 < 4294967296);
  Expect.isTrue(-4294967296 <= 6);
  Expect.isTrue(-4294967296 <= 4294967296);
  Expect.isTrue(-4294967296 < 4294967295);

  Expect.isFalse(4294967296 < -6);
  Expect.isFalse(4294967296 <= -6);
  Expect.isFalse(4294967296 < -4294967295);

  Expect.isTrue(-4294967296 < -6);
  Expect.isTrue(-4294967296 <= -6);
  Expect.isTrue(-4294967296 < -4294967295);

  Expect.isTrue(4294967296 > 6);
  Expect.isFalse(4294967296 > 4294967296);
  Expect.isTrue(4294967296 >= 6);
  Expect.isTrue(4294967296 >= 4294967296);
  Expect.isTrue(4294967296 > 4294967295);

  Expect.isFalse(-4294967296 > 6);
  Expect.isFalse(-4294967296 > 4294967296);
  Expect.isFalse(-4294967296 >= 6);
  Expect.isFalse(-4294967296 >= 4294967296);
  Expect.isFalse(-4294967296 > 4294967295);

  Expect.isTrue(4294967296 > -6);
  Expect.isTrue(4294967296 >= -6);
  Expect.isTrue(4294967296 > -4294967295);

  Expect.isFalse(-4294967296 > -6);
  Expect.isFalse(-4294967296 >= -6);
  Expect.isFalse(-4294967296 > -4294967295);

  Expect.isTrue(4294967296 < 184467440737095516150);
  Expect.isTrue(-4294967296 < 184467440737095516150);
  Expect.isFalse(4294967296 < -184467440737095516150);
  Expect.isFalse(-4294967296 < -184467440737095516150);
}


main() {
  for (var i = 0; i < 100; i++) {
    compareTest();
  }
}
