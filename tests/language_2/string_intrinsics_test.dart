// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Replace with shared test once interface issues clarified.
// Test various String intrinsics
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

main() {
  var oneByte = "Hello world";
  var empty = "";
  for (int i = 0; i < 20; i++) {
    Expect.equals(11, testLength(oneByte));
    Expect.equals(0, testLength(empty));
    Expect.isFalse(testIsEmpty(oneByte));
    Expect.isTrue(testIsEmpty(empty));
  }
}

testLength(s) {
  return s.length;
}

testIsEmpty(s) {
  return s.isEmpty;
}
