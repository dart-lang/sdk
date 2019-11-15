// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late final int lateTopLevelField;

class Class {
  static late final int lateStaticField1;
  static late final int lateStaticField2;

  static staticMethod() {
    throws(() => lateStaticField2,
        'Read value from uninitialized Class.lateStaticField2');
    lateStaticField2 = 42;
    expect(42, lateStaticField2);
    throws(() => lateStaticField2 = 43,
        'Write value to initialized Class.lateStaticField2');
  }
}

main() {
  throws(() => lateTopLevelField,
      'Read value from uninitialized lateTopLevelField');
  lateTopLevelField = 123;
  expect(123, lateTopLevelField);
  throws(() => lateTopLevelField = 124,
      'Write value to initialized lateTopLevelField');

  throws(() => Class.lateStaticField1,
      'Read value from uninitialized Class.lateStaticField1');
  Class.lateStaticField1 = 87;
  expect(87, Class.lateStaticField1);
  throws(() => Class.lateStaticField1 = 88,
      'Write value to initialized Class.lateStaticField1');

  Class.staticMethod();
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
