// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I {}

class A implements I {}

extension on A {
  int get member => 87;
}

extension on I {
  int get member => 42;
}

method(A a) => switch (a) {
      I(:var member) => member,
    };

main() {
  expect(42, method(new A()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
