// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  if (x case [int a] when a > 0) {
    return a;
  }
  return 0;
}

main() {
  expectEquals(1, test([1]));
  expectEquals(0, test([0]));
  expectEquals(0, test([-1]));
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
