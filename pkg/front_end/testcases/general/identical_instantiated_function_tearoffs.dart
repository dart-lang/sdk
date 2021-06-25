// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.13

// This test is similar to
//
//   constructor_tearoffs/identical_instantiated_function_tearoffs.dart
//
// but verifies that before the constructor-tearoffs experiment was enabled,
// instantiations in non-constant context were not canonicalized.

T id<T>(T t) => t;

int Function(int) implicitInstantiation = id;
const int Function(int) implicitConstInstantiation = id;

T Function(T) create<T>() => id;

main() {
  expect(true, identical(implicitInstantiation, implicitInstantiation));
  expect(false, identical(implicitInstantiation, implicitConstInstantiation));
  expect(false, identical(implicitInstantiation, create<int>()));

  expect(false, identical(implicitConstInstantiation, implicitInstantiation));
  expect(
      true, identical(implicitConstInstantiation, implicitConstInstantiation));
  expect(false, identical(implicitConstInstantiation, create<int>()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
