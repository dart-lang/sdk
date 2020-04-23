// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  late int field1;
  late int field2;
  late final int field3;
  late final int field4;
}

class SubClass extends Class {
  late int field1;
  late int field2 = 0;
  late final int field3;
  late final int field4 = 0;

  int get directField1 => super.field1;

  void set directField1(int value) {
    super.field1 = value;
  }

  int get directField2 => super.field2;

  void set directField2(int value) {
    super.field2 = value;
  }

  int get directField3 => super.field3;

  // TODO(johnniwinther): Enable this when super access of late final fields
  //  without initializers is supported.
  /*void set directField3(int value) {
    super.field3 = value;
  }*/

  int get directField4 => super.field4;

// TODO(johnniwinther): Enable this when super access of late final fields
//  without initializers is supported.
  /*void set directField4(int value) {
    super.field4 = value;
  }*/
}

main() {
  SubClass sc = new SubClass();
  Class c = sc;

  throws(() => c.field1, 'Read value from uninitialized SubClass.field1');
  throws(() => sc.directField1, 'Read value from uninitialized Class.field1');
  expect(42, c.field1 = 42);
  expect(42, c.field1);
  throws(() => sc.directField1, 'Read value from uninitialized Class.field1');
  expect(87, sc.directField1 = 87);
  expect(87, sc.directField1);

  expect(0, c.field2);
  throws(() => sc.directField2, 'Read value from uninitialized Class.field2');
  expect(42, c.field2 = 42);
  expect(42, c.field2);
  throws(() => sc.directField2, 'Read value from uninitialized Class.field2');
  expect(87, sc.directField2 = 87);
  expect(87, sc.directField2);

  throws(() => c.field3, 'Read value from uninitialized SubClass.field3');
  throws(() => sc.directField3, 'Read value from uninitialized Class.field3');
  expect(42, c.field3 = 42);
  expect(42, c.field3);
  throws(() => sc.directField3, 'Read value from uninitialized Class.field3');
  //expect(87, sc.directField3 = 87);
  //expect(87, sc.directField3);
  throws(() => c.field3 = 87, 'Write value to initialized SubClass.field3');
  //throws(() => c.directField3 = 123, 'Write value to initialized Class.field3');

  expect(0, c.field4);
  throws(() => sc.directField4, 'Read value from uninitialized Class.field4');
  expect(42, c.field4 = 42);
  expect(0, c.field4);
  expect(42, sc.directField4);
  throws(() => c.field4 = 87, 'Write value to initialized SubClass.field4');
  //throws(() => c.directField4 = 87, 'Write value to initialized Class.field4');
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
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
