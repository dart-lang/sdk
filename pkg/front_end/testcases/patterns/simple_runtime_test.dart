// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  if (x case [String y]) {
    return y;
  } else {
    return null;
  }
}

main() {
  expectEquals(test(["one", "two", "three"]), "one");
  expectEquals(test([1, 2, 3]), null);
  expectEquals(test([true, false]), null);
  expectEquals(test([]), null);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected $x to be equal to $y.";
  }
}
