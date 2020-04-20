// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  var t;
  A() : t = (() => new List<T>());
}

class B<T> {
  var t;
  B() : t = (() => T);
}

expect(result, expected) {
  if (result != expected) {
    throw 'Expected $expected, got $result';
  }
}

main() {
  expect(new A<int>().t() is List<int>, true);
  expect(new A<String>().t() is List<int>, false);
  expect(new B<int>().t() is Type, true);
  expect(new B<int>().t(), int);
}
