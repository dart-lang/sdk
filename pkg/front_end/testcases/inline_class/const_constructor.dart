// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class Class {
  final int i;

  const Class(this.i);
}

main() {
  expect(42, const Class(42));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
