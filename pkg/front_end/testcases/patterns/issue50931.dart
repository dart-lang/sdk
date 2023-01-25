// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  switch (x) {
    case int y:
      continue ret0;
    ret0:
    case "foo":
      return 0;
    default:
      return 1;
  }
}

main() {
  expectEquals(test(0), 0);
  expectEquals(test(1), 0);
  expectEquals(test(2), 0);
  expectEquals(test("foo"), 0);
  expectEquals(test("bar"), 1);
  expectEquals(test(null), 1);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
