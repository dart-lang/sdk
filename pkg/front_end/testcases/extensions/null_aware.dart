// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;
}

extension Extension on Class {
  int get property => field;
  void set property(int value) {
    field = value;
  }
  int method() => field;
}

main() {
  Class c;
  expect(null, c?.property);
  expect(null, c?.method);
  expect(null, c?.method());
  expect(null, c?.property = 42);
  c = new Class();
  expect(null, c?.property);
  expect(null, c?.method());
  var tearOff = c?.method;
  expect(null, tearOff());
  expect(42, c?.property = 42);
  expect(42, tearOff());
  expect(null, c?.property = null);
  expect(42, c.property ??= 42);
  expect(42, c.property ??= 87);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}