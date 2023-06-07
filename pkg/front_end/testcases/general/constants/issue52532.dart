// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const bool b = true;
const double d = 3.5;
const int i = 42;
const Null n = null;
const String s = 'foo';
const String e = const String.fromEnvironment('foo', defaultValue: 'bar');

main() {
  expect('<true>', '<${b}>');
  expect('<3.5>', '<${d}>');
  expect('<42>', '<${i}>');
  expect('<null>', '<${n}>');
  expect('<foo>', '<${s}>');
  expect('<bar>', '<${e}>');

  expect('<true>', '<${true}>');
  expect('<3.5>', '<${3.5}>');
  expect('<42>', '<${42}>');
  expect('<null>', '<${null}>');
  expect('<foo>', '<${'foo'}>');
}

expect(expected, actual) {
  if (!identical(expected, actual)) {
    throw 'Expected ${expected} to identical to ${actual}';
  }
}
