// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late int? lateTopLevelField;

class Class<T> {
  static late int? lateStaticField1;
  static late int? lateStaticField2;

  static staticMethod() {
    throws(() => lateStaticField2,
        'Read value from uninitialized Class.lateStaticField2');
    lateStaticField2 = 42;
    expect(42, lateStaticField2);
  }

  late int? lateInstanceField;

  late T? lateGenericInstanceField;

  instanceMethod(T? value) {
    throws(() => lateInstanceField,
        'Read value from uninitialized Class.lateInstanceField');
    lateInstanceField = 16;
    expect(16, lateInstanceField);

    throws(() => lateGenericInstanceField,
        'Read value from uninitialized Class.lateGenericInstanceField');
    lateGenericInstanceField = value;
    expect(value, lateGenericInstanceField);
  }
}

extension Extension<T> on Class<T> {
  static late int? lateExtensionField1;
  static late int? lateExtensionField2;

  static staticMethod() {
    throws(() => lateExtensionField2,
        'Read value from uninitialized Class.lateExtensionField2');
    lateExtensionField2 = 42;
    expect(42, lateExtensionField2);
  }
}

main() {
  throws(() => lateTopLevelField,
      'Read value from uninitialized lateTopLevelField');
  lateTopLevelField = 123;
  expect(123, lateTopLevelField);

  throws(() => Class.lateStaticField1,
      'Read value from uninitialized Class.lateStaticField1');
  Class.lateStaticField1 = 87;
  expect(87, Class.lateStaticField1);

  Class.staticMethod();

  throws(() => Extension.lateExtensionField1,
      'Read value from uninitialized Extension.lateExtensionField1');
  Extension.lateExtensionField1 = 87;
  expect(87, Extension.lateExtensionField1);

  Extension.staticMethod();

  new Class<int?>().instanceMethod(null);
  new Class<int?>().instanceMethod(0);
  new Class<int>().instanceMethod(null);
  new Class<int>().instanceMethod(0);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } on LateInitializationError catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
