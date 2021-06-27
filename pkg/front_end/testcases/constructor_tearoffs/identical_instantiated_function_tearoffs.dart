// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;

int Function(int) implicitInstantiation = id;
var explicitInstantiation = id<int>;
const int Function(int) implicitConstInstantiation = id;
const explicitConstInstantiation = id<int>;

T Function(T) create<T>() => id<T>;

main() {
  expect(true, identical(implicitInstantiation, implicitInstantiation));
  expect(true, identical(implicitInstantiation, explicitInstantiation));
  expect(true, identical(implicitInstantiation, implicitConstInstantiation));
  expect(true, identical(implicitInstantiation, explicitConstInstantiation));
  expect(true, identical(implicitInstantiation, id<int>));
  expect(false, identical(implicitInstantiation, id<String>));
  expect(false, identical(implicitInstantiation, create<int>()));

  expect(true, identical(explicitInstantiation, implicitInstantiation));
  expect(true, identical(explicitInstantiation, explicitInstantiation));
  expect(true, identical(explicitInstantiation, implicitConstInstantiation));
  expect(true, identical(explicitInstantiation, explicitConstInstantiation));
  expect(true, identical(explicitInstantiation, id<int>));
  expect(false, identical(explicitInstantiation, id<String>));
  expect(false, identical(explicitInstantiation, create<int>()));

  expect(true, identical(implicitConstInstantiation, implicitInstantiation));
  expect(true, identical(implicitConstInstantiation, explicitInstantiation));
  expect(true, identical(implicitConstInstantiation,
      implicitConstInstantiation));
  expect(true, identical(implicitConstInstantiation,
      explicitConstInstantiation));
  expect(true, identical(implicitConstInstantiation, id<int>));
  expect(false, identical(implicitConstInstantiation, id<String>));
  expect(false, identical(implicitConstInstantiation, create<int>()));

  expect(true, identical(explicitConstInstantiation, implicitInstantiation));
  expect(true, identical(explicitConstInstantiation, explicitInstantiation));
  expect(true, identical(explicitConstInstantiation,
      implicitConstInstantiation));
  expect(true, identical(explicitConstInstantiation,
      explicitConstInstantiation));
  expect(true, identical(explicitConstInstantiation, id<int>));
  expect(false, identical(explicitConstInstantiation, id<String>));
  expect(false, identical(explicitConstInstantiation, create<int>()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}