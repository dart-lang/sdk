// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  switch (x) {
    case int x when x > 0:
    case String x when x.startsWith("f"):
      return 1;
    default:
      return 0;
  }
}

main() {
  expectEquals(test(0), 0);
  expectEquals(test(1), 1);
  expectEquals(test(2), 1);
  expectEquals(test("foo"), 1);
  expectEquals(test("bar"), 0);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
  }
}
