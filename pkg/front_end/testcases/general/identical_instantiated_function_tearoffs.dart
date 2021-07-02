// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;

int Function(int) implicitInstantiation = id;
const int Function(int) implicitConstInstantiation = id;

T Function(T) create<T>() => id;

main() {
  expect(true, identical(implicitInstantiation, implicitInstantiation));
  expect(true, identical(implicitInstantiation, implicitConstInstantiation));
  expect(false, identical(implicitInstantiation, create<int>()));

  expect(true, identical(implicitConstInstantiation, implicitInstantiation));
  expect(
      true, identical(implicitConstInstantiation, implicitConstInstantiation));
  expect(false, identical(implicitConstInstantiation, create<int>()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
