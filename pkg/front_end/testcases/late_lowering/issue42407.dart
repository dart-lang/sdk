// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  late T x;
}

class B<T> {
  T? _y;
  T? get y => _y;
  set y(T? val) {
    _y = val;
  }
}

main() {
  A<num> a = new A<int>();
  expect(42, a.x = 42);
  throws(() => a.x = 0.5);

  B<num> b = new B<int>();
  expect(42, b.y = 42);
  throws(() => b.y = 0.5);
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw "Expected exception";
}
