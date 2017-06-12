// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.isTrue(null is Object);
  Expect.isTrue(null is Null);
  Expect.isFalse(null is int);
  Expect.isFalse(null is bool);
  Expect.isFalse(null is num);
  Expect.isFalse(null is String);
  Expect.isFalse(null is List);
  Expect.isFalse(null is Expect);

  test(null);

  Expect.isFalse(1 is Null);
  Expect.isFalse("1" is Null);
  Expect.isFalse(true is Null);
  Expect.isFalse(false is Null);
  Expect.isFalse(new Object() is Null);

  testNegative(1);
  testNegative("1");
  testNegative(true);
  testNegative(false);
  testNegative(new Object());
}

test(n) {
  // Test where the argument is not a compile-time constant.
  Expect.isTrue(n is Object);
  Expect.isTrue(n is Null);
  Expect.isFalse(n is int);
  Expect.isFalse(n is bool);
  Expect.isFalse(n is num);
  Expect.isFalse(n is String);
  Expect.isFalse(n is List);
  Expect.isFalse(n is Expect);
}

testNegative(n) {
  Expect.isFalse(n is Null);
}
