// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Mixin {}

class Base {
  final int x;
  const Base(this.x);
}

class Application = Base with Mixin;

main() {
  expect(42, const Application(42).x);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
