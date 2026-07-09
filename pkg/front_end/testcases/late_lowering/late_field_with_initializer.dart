// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late int lateTopLevelField1 = 123;

class Class<T> {
  static late int lateStaticField1 = 87;
  static late int lateStaticField2 = 42;

  static staticMethod() {
    expect(42, lateStaticField2);
    lateStaticField2 = 43;
    expect(43, lateStaticField2);
  }

  late int lateInstanceField = 16;
  final T field;
  late T lateGenericField1 = field;
  late T lateGenericField2 = field;

  Class(this.field);

  instanceMethod(T value) {
    expect(16, lateInstanceField);
    lateInstanceField = 17;
    expect(17, lateInstanceField);

    expect(field, lateGenericField1);
    lateGenericField1 = value;
    expect(value, lateGenericField1);

    lateGenericField2 = value;
    expect(value, lateGenericField2);
  }
}

extension Extension<T> on Class<T> {
  static late int lateExtensionField1 = 87;
  static late int lateExtensionField2 = 42;

  static staticMethod() {
    expect(42, lateExtensionField2);
    lateExtensionField2 = 43;
    expect(43, lateExtensionField2);
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
  new Class<int>(0).instanceMethod(42);

  expect(87, Extension.lateExtensionField1);
  Extension.lateExtensionField1 = 88;
  expect(88, Extension.lateExtensionField1);

  Extension.staticMethod();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
