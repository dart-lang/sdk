// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int foo;
  int get bar => throw 'Bye';
  A(this.foo);
}

void main() {
  A obj = A(42);
  int f = -1;
  int b = -1;
  try {
    A(foo: f, bar: b) = obj;
  } catch (_) {}
  expect(-1, f);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
