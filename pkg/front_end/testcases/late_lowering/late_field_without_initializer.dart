// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late int lateTopLevelField;

class Class {
  static late int lateStaticField1;
  static late int lateStaticField2;

  static staticMethod() {
    throws(() => lateStaticField2,
        'Read value from uninitialized Class.lateStaticField2');
    lateStaticField2 = 42;
    expect(42, lateStaticField2);
  }

  late int lateInstanceField;

  instanceMethod() {
    throws(() => lateInstanceField,
        'Read value from uninitialized Class.lateInstanceField');
    lateInstanceField = 16;
    expect(16, lateInstanceField);
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
  new Class().instanceMethod();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
