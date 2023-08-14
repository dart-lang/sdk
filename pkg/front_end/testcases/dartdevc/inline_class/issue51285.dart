// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class I {
  final int i = 0;

  factory I() => 0 as I;
}

inline class J {
  final int i;
  factory J(int i) => J._(i);
  J._(this.i);
}

inline class K<T> {
  final T i;
  factory K(T i) => K._(i);
  K._(this.i);
}

main() {
  expect(0, I());
  expect(0, (I.new)());
  expect(42, J(42));
  expect(87, J(87));
  expect(123, (J.new)(123));
  expect("foo", K("foo"));
  expect("bar", K<String>("bar"));
  expect("baz", (K.new)("baz"));
  expect("boz", (K<String>.new)("boz"));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
