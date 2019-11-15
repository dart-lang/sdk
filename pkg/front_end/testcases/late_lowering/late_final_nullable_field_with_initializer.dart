// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? lateTopLevelField1Init;
int? initLateTopLevelField1(int value) {
  return lateTopLevelField1Init = value;
}

late final int? lateTopLevelField1 = initLateTopLevelField1(123);

class Class {
  static int? lateStaticField1Init;
  static int? initLateStaticField1(int value) {
    return lateStaticField1Init = value;
  }

  static late final int? lateStaticField1 = initLateStaticField1(87);

  static int? lateStaticField2Init;
  static int? initLateStaticField2(int value) {
    return lateStaticField2Init = value;
  }

  static late final int? lateStaticField2 = initLateStaticField2(42);

  static staticMethod() {
    expect(null, lateStaticField2Init);
    expect(42, lateStaticField2);
    expect(42, lateStaticField2Init);
  }

  int? lateInstanceFieldInit;
  int? initLateInstanceField(int value) {
    return lateInstanceFieldInit = value;
  }

  late final int? lateInstanceField = initLateInstanceField(16);

  instanceMethod() {
    expect(null, lateInstanceFieldInit);
    expect(16, lateInstanceField);
    expect(16, lateInstanceFieldInit);
  }
}

main() {
  expect(null, lateTopLevelField1Init);
  expect(123, lateTopLevelField1);
  expect(123, lateTopLevelField1Init);

  expect(null, Class.lateStaticField1Init);
  expect(87, Class.lateStaticField1);
  expect(87, Class.lateStaticField1Init);

  Class.staticMethod();
  new Class().instanceMethod();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
