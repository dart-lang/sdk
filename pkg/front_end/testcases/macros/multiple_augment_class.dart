// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'multiple_augment_class_lib1.dart';
import augment 'multiple_augment_class_lib2.dart';

class Class {
  external int method1();
  external int method2();
  external int method3();
}

main() {
  Class c = new Class();
  expect(42, c.method1());
  expect(87, c.method2());
  expect(123, c.method3());
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
