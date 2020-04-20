// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;
}

extension on Class {
  int get property1 => property2;
  void set property1(int value) => field = value;
}

extension on Class {
  int get property2 => field;
  void set property2(int value) => property1 = value;
}

main() {
  var c = new Class();
  expect(null, c.property1);
  expect(null, c.property2);
  expect(42, c.property1 = 42);
  expect(42, c.property2);
  expect(87, c.property2 = 87);
  expect(87, c.property1);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}