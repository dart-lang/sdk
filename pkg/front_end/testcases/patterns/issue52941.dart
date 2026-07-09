// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  switch ([1, 2, 3]) {
    case [6, ...var rest]:
      expect(null, rest);
    case [...var all]:
      expect([1, 2, 3], all);
  }
  switch ([1, 2, 3]) {
    case [...var all]:
      expect([1, 2, 3], all);
    case [6, ...var rest]:
      expect(null, rest);
  }
  switch ([1, 2, 3]) {
    case [6, 7, ...var rest]:
      expect(null, rest);
    case [_, ...var all]:
      expect([2, 3], all);
  }
  switch ([1, 2, 3]) {
    case [_, ...var all]:
      expect([2, 3], all);
    case [6, 7, ...var rest]:
      expect(null, rest);
  }
}

expect(List? expected, List actual) {
  if (expected == null) {
    if (actual != null) {
      throw 'Unexpected $actual';
    }
    return;
  }
  if (expected.length != actual.length) {
    throw 'Expected $expected, actual $actual';
  }
  for (int i = 0; i < expected.length; i++) {
    if (expected[i] != actual[i]) {
      throw 'Expected $expected, actual $actual';
    }
  }
}
