// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test(Symbol value) {
  switch (value) {
    case #foo:
      return "foo";
    default:
      return "default";
  }
}

main() {
  expect("foo", test(Symbol("foo")));
  expect("foo", test(const Symbol("foo")));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
