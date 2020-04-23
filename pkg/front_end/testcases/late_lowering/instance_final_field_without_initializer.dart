// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  late final int field;

  Class.constructor1();
  Class.constructor2(this.field);
  Class.constructor3(int value) : this.field = value + 1;
  Class.constructor4([this.field = 42]);
}

class Subclass extends Class {
  Subclass.constructor1() : super.constructor1();
  Subclass.constructor2(int value) : super.constructor2(value);
  Subclass.constructor3(int value) : super.constructor3(value);
  Subclass.constructor4([int value = 87]) : super.constructor4(value);
}

test1() {
  var c1 = new Class.constructor1();
  throws(() => c1.field, 'Read value from uninitialized Class.field');
  c1.field = 16;
  expect(16, c1.field);
  throws(() => c1.field = 17, 'Write value to initialized Class.field');

  var c2 = new Class.constructor2(42);
  expect(42, c2.field);
  throws(() => c2.field = 43, 'Write value to initialized Class.field');

  var c3 = new Class.constructor3(87);
  expect(88, c3.field);
  throws(() => c3.field = 89, 'Write value to initialized Class.field');

  var c4 = new Class.constructor4();
  expect(42, c4.field);
  throws(() => c4.field = 43, 'Write value to initialized Class.field');

  var c5 = new Class.constructor4(123);
  expect(123, c5.field);
  throws(() => c5.field = 124, 'Write value to initialized Class.field');

  var c6 = new Class.constructor1();
  c6.field = 32;
  expect(32, c6.field);
  throws(() => c6.field = 32, 'Write value to initialized Class.field');
}

test2() {
  var c1 = new Subclass.constructor1();
  throws(() => c1.field, 'Read value from uninitialized Class1.field');
  c1.field = 16;
  expect(16, c1.field);
  throws(() => c1.field = 17, 'Write value to initialized Class.field');

  var c2 = new Subclass.constructor2(42);
  expect(42, c2.field);
  throws(() => c2.field = 43, 'Write value to initialized Class.field');

  var c3 = new Subclass.constructor3(87);
  expect(88, c3.field);
  throws(() => c3.field = 89, 'Write value to initialized Class.field');

  var c4 = new Subclass.constructor4();
  expect(87, c4.field);
  throws(() => c4.field = 88, 'Write value to initialized Class.field');

  var c5 = new Subclass.constructor4(123);
  expect(123, c5.field);
  throws(() => c5.field = 124, 'Write value to initialized Class.field');

  var c6 = new Subclass.constructor1();
  c6.field = 32;
  expect(32, c6.field);
  throws(() => c6.field = 32, 'Write value to initialized Class.field');
}

main() {
  test1();
  test2();
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
