// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<E> {
  final E field;

  Class(this.field);

  E returnTypeVariable() {
    late E result = field;
    return result;
  }
}

int returnNonNullable(int value) {
  late int result = value;
  return result;
}

int? returnNullable(int? value) {
  late int? result = value;
  return result;
}

main() {
  expect(42, new Class<int>(42).returnTypeVariable());
  expect(87, new Class<int?>(87).returnTypeVariable());
  expect(null, new Class<int?>(null).returnTypeVariable());
  expect(42, returnNonNullable(42));
  expect(87, returnNullable(87));
  expect(null, returnNullable(null));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
