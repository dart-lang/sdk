// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  noSuchMethod(Invocation i) => 123;
}

extension ClassExtension on Class {
  int method() => 42;
}

extension Extension on dynamic {
  int method() => 87;
}

main() {
  dynamic c0 = new Class();
  Object c1 = new Class();
  Class c2 = new Class();

  expect(123, c0.method());
  expect(87, c1.method());
  expect(42, c2.method());
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
