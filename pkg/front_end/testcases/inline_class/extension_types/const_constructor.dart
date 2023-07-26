// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type const Class(int i) {
  Class.named(this.i);

  const factory Class.redirect(int i) = Class;

  factory Class.fact(int i) => Class(i);

  factory Class.redirect2(int i) = Class;
}

test() {
  const Class.named(42); // Error
  const Class.fact(87); // Error
  const Class.redirect2(87); // Error
}

main() {
  expect(42, const Class(42));
  expect(87, const Class.redirect(87));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
