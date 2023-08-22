// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type I._(int i) {
  factory I() => 0 as I;
}

extension type J._(int i) {
  factory J(int i) => J._(i);
}

extension type K<T>._(T i) {
  factory K(T i) => K._(i);
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
