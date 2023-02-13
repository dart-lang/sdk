// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  if (x case [int y]) {
    return y;
  } else {
    return null;
  }
}

test2(dynamic x) {
  if (x case [int y, ...]) {
    return y;
  } else {
    return null;
  }
}

test3(dynamic x) {
  if (x case [..., int y]) {
    return y;
  } else {
    return null;
  }
}

main() {
  expectEquals(test1([1]), 1);
  expectEquals(test1([1, 2, 3]), null);
  expectEquals(test1([]), null);
  expectEquals(test1("foo"), null);

  expectEquals(test2([1]), 1);
  expectEquals(test2([1, 2, 3]), 1);
  expectEquals(test2([]), null);
  expectEquals(test2("foo"), null);

  expectEquals(test3([1]), 1);
  expectEquals(test3([1, 2, 3]), 3);
  expectEquals(test3([]), null);
  expectEquals(test3("foo"), null);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
