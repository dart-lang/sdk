// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(o) {
  switch (o) {
    case int a:
      return 1;
  }
  switch (o) {
    case String a:
      return 2;
  }
  return 0;
}

main() {
  expect(1, test(0));
  expect(2, test('foo'));
  expect(0, test(true));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}