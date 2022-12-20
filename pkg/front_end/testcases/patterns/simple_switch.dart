// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  switch (x) {
    case int y:
      return y;
    case [double z]:
      return z;
    default:
      return null;
  }
}

main() {
  expectEquals(test(0), 0);
  expectEquals(test([3.14]), 3.14);
  expectEquals(test("foo"), null);
  expectEquals(test(null), null);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
