// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  late int lateLocal = 123;

  expect(123, lateLocal);
  expect(124, lateLocal = 124);
  expect(124, lateLocal);

  local<T>(T value1, T value2) {
    late T lateGenericLocal = value1;

    expect(value1, lateGenericLocal);
    expect(value2, lateGenericLocal = value2);
    expect(value2, lateGenericLocal);
  }

  local<int?>(null, 0);
  local<int?>(0, null);
  local<int>(0, 42);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
