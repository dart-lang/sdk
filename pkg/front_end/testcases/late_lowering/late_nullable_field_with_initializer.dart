// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? lateTopLevelField1Init() => 123;
late int? lateTopLevelField1 = lateTopLevelField1Init();

class Class {
  static int? lateStaticField1Init() => 87;
  static late int? lateStaticField1 = lateStaticField1Init();
  static int? lateStaticField2Init() => 42;
  static late int? lateStaticField2 = lateStaticField2Init();

  static staticMethod() {
    expect(42, lateStaticField2);
    lateStaticField2 = 43;
    expect(43, lateStaticField2);
  }

  int? lateInstanceFieldInit() => 16;
  late int? lateInstanceField = lateInstanceFieldInit();

  instanceMethod() {
    expect(16, lateInstanceField);
    lateInstanceField = 17;
    expect(17, lateInstanceField);
  }
}

main() {
  expect(123, lateTopLevelField1);
  lateTopLevelField1 = 124;
  expect(124, lateTopLevelField1);

  expect(87, Class.lateStaticField1);
  Class.lateStaticField1 = 88;
  expect(88, Class.lateStaticField1);

  Class.staticMethod();
  new Class().instanceMethod();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
