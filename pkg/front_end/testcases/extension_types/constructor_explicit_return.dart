// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  final a = A();
  final v = View.a(a);
  expect(0, v.a.value);
}

class A {
  static int counter = 0;

  final int value;

  A() : value = counter++;
}

extension type View(A a) {
  View.a(this.a) {
    assert(() {
      return true;
    }());
    return;
  }
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
