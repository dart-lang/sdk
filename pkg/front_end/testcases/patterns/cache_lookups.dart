// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'cache_lookups_lib.dart';

int counter = 0;

class Class {
  int get field {
    counter++;
    return 42;
  }
}

test(o) {
  switch (o) {
    case Class(field: 0) || Class(field: 1):
      print('Class');
    case [int a, 1] || [int a, 2]:
      print('List');
  }
}

main() {
  expect(0, counter);
  test(null);
  expect(0, counter);
  test(new Class());
  expect(1, counter);
  test(new CustomList([0, 1]));
  expect(2, counter);
  test(new CustomList([0, 2]));
  expect(3, counter);
  test(new CustomList([0, 3]));
  expect(4, counter);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}