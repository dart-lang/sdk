// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test(Object? o) {
  String toReturn = "";
  switch (o) {
    case [1, 2]:
      toReturn = "list";
    case {"key1": _}:
      toReturn = "map";
    default:
      toReturn = "default";
  }
  return toReturn;
}

main() {
  expect("list", test([1, 2]));
  expect("map", test({"key1": 1}));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
