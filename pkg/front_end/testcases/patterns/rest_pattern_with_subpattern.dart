// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(o, [expectedRest]) {
  switch (o) {
    case [0, 1, ...]:
      return 0;
    case [0, ..., 1]:
      return 1;
    case [0, 2, ... var rest]:
      expect(expectedRest, rest);
      return 2;
    case [0, ... var rest, 2]:
      expect(expectedRest, rest);
      return 3;
    case [0, 4, ... var rest, 2, 3]:
      expect(expectedRest, rest);
      return 4;
    case [0, 5, ... [1, ... var rest, 2], 2, 3]:
      expect(expectedRest, rest);
      return 5;
  }
}

main() {
  expect(0, test([0, 1]));
  expect(0, test([0, 1, 2]));
  expect(1, test([0, 2, 1]));
  expect(1, test([0, 2, 3, 1]));
  expect(2, test([0, 2], []));
  expect(2, test([0, 2, 2], [2]));
  expect(2, test([0, 2, 3], [3]));
  expect(2, test([0, 2, 3, 4], [3, 4]));
  expect(3, test([0, 3, 4, 2], [3, 4]));
  expect(3, test([0, 3, 4, 5, 2], [3, 4, 5]));
  expect(4, test([0, 4, 2, 3], []));
  expect(4, test([0, 4, 2, 2, 3], [2]));
  expect(4, test([0, 4, 2, 3, 2, 3], [2, 3]));
  expect(null, test([0, 5, 3, 2, 3]));
  expect(null, test([0, 5, [], 2, 3]));
  expect(null, test([0, 5, [0, 1], 2, 3]));
  expect(5, test([0, 5, 1, 2, 2, 3], []));
  expect(5, test([0, 5, 1, 3, 2, 2, 3], [3]));
}

expect(expected, actual) {
  if (expected is List && actual is List) {
    if (expected.length == actual.length) {
      for (int i = 0; i < expected.length; i++) {
        if (expected[i] != actual[i]) {
          throw 'Expected ${expected[i]}, actual ${actual[i]} @ index $i';
        }
      }
      return;
    }
  }
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
