// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? lateTopLevelField1Init;
int? initLateTopLevelField1(int value) {
  return lateTopLevelField1Init = value;
}

late final int? lateTopLevelField1 = initLateTopLevelField1(123);

class Class<T> {
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

  T? lateGenericInstanceFieldInit;
  T? initLateGenericInstanceField(T? value) {
    return lateGenericInstanceFieldInit = value;
  }

  final T? field;
  late final T? lateGenericInstanceField = initLateGenericInstanceField(field);

  Class(this.field);

  instanceMethod() {
    expect(null, lateInstanceFieldInit);
    expect(16, lateInstanceField);
    expect(16, lateInstanceFieldInit);

    expect(null, lateGenericInstanceFieldInit);
    expect(field, lateGenericInstanceField);
    expect(field, lateGenericInstanceFieldInit);
  }
}

extension Extension<T> on Class<T> {
  static int? lateExtensionField1Init;
  static int? initLateExtensionField1(int value) {
    return lateExtensionField1Init = value;
  }

  static late final int? lateExtensionField1 = initLateExtensionField1(87);

  static int? lateExtensionField2Init;
  static int? initLateExtensionField2(int value) {
    return lateExtensionField2Init = value;
  }

  static late final int? lateExtensionField2 = initLateExtensionField2(42);

  static staticMethod() {
    expect(null, lateExtensionField2Init);
    expect(42, lateExtensionField2);
    expect(42, lateExtensionField2Init);
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
  new Class<int?>(null).instanceMethod();
  new Class<int?>(0).instanceMethod();
  new Class<int>(0).instanceMethod();

  expect(null, Extension.lateExtensionField1Init);
  expect(87, Extension.lateExtensionField1);
  expect(87, Extension.lateExtensionField1Init);

  Extension.staticMethod();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
