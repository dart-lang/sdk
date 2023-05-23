// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class Id {
  Id(int id) : _id = id;
  final int _id;
}

test() {
  var c = Id(2);
  print(c.unresolved); // Error
}

main() {
  var c = Id(2);
  expect(int, c.runtimeType);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
