// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  method0([a]) => a;
  method1([a = 42]) => a;
  method2({b = 87}) => b;
  method3({c = staticMethod}) => c();
  static staticMethod() => 123;
}

main() {
  Class c = new Class();
  var tearOff0 = c.method0;
  expect(0, tearOff0(0));
  expect(null, tearOff0());
  var tearOff1 = c.method1;
  expect(0, tearOff1(0));
  expect(42, tearOff1());
  var tearOff2 = c.method2;
  expect(0, tearOff2(b: 0));
  expect(87, tearOff2());
  var tearOff3 = c.method3;
  expect(0, tearOff3(c: () => 0));
  expect(123, tearOff3());
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
