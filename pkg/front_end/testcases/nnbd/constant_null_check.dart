// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int? a = 42;
const int b = a!;

const int? c = null;
const int? d = c!;

class Class {
  final int y;
  const Class(int? x) : y = x!;
}

const Class e = const Class(a);
const Class f = const Class(c);

main() {
  expect(42, a);
  expect(42, b);
  expect(42, e.y);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
