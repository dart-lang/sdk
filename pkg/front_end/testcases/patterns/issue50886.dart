// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1() {
  Map x = {1: 1};
  if (x case <int, int>{1: 1}) {
    return 1;
  } else {
    return 0;
  }
}

test2() {
  Map<dynamic, dynamic> x = <int, int>{1: 1, 2: 2};
  if (x case <int, int>{1: 1}) {
    return 0;
  } else {
    return 1;
  }
}

main() {
  expectEquals(0, test1());
  expectEquals(0, test2());
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
