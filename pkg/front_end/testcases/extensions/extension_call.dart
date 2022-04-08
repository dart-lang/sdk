// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  T method(T a) => a;
}

extension Extension<T> on Class<T> {
  T call(T a) => method(a);
}

main() {
  Class<int> c = new Class<int>();
  expect(42, c(42));
  expect(87, Extension(c)(87));
  expect(123, Extension<int>(c)(123));
  expect(42, c.call(42));
  expect(87, Extension(c).call(87));
  expect(123, Extension<int>(c).call(123));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}