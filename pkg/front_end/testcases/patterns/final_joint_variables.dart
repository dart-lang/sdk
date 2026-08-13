// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  switch (x) {
    case [final int a]:
    case final int a:
      return a;
    case [final String a] || final String a:
      return a;
    default:
      return null;
  }
}

main() {
  expectEquals(test(0), 0);
  expectEquals(test([0]), 0);
  expectEquals(test("foo"), "foo");
  expectEquals(test(["foo"]), "foo");
  expectEquals(test(3.14), null);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${x}'.";
  }
}
