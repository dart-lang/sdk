// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

dynamic lastInit;

T init<T>(T value) {
  lastInit = value;
  return value;
}

const int constTopLevelField = 324;

int topLevelFieldWithoutInitializer;

int topLevelFieldWithInitializer1 = init(42);

int topLevelFieldWithInitializer2 = init(42);

final int finalTopLevelFieldWithInitializer1 = init(87);

int finalTopLevelFieldWithInitializer2Init = 0;
final int finalTopLevelFieldWithInitializer2 =
    finalTopLevelFieldWithInitializer2Init++ == 0
        ? finalTopLevelFieldWithInitializer2 + 1
        : 87;

class Class {
  static const int staticConstField = 123;

  int instanceFieldWithInitializer = init(55);

  static int staticFieldWithoutInitializer;

  static int staticFieldWithInitializer1 = init(55);

  static int staticFieldWithInitializer2 = init(55);

  static final int staticFinalFieldWithInitializer1 = init(73);

  static int staticFinalFieldWithInitializer2Init = 0;
  static final int staticFinalFieldWithInitializer2 =
      staticFinalFieldWithInitializer2Init++ == 0
          ? staticFinalFieldWithInitializer2 + 1
          : 87;
}

main() {
  expect(null, lastInit);
  expect(null, topLevelFieldWithoutInitializer);
  expect(324, constTopLevelField);
  expect(null, Class.staticFieldWithoutInitializer);
  expect(123, Class.staticConstField);

  expect(42, topLevelFieldWithInitializer1);
  expect(42, lastInit);

  topLevelFieldWithInitializer2 = 56;
  expect(42, lastInit);
  expect(56, topLevelFieldWithInitializer2);
  expect(42, lastInit);

  expect(87, finalTopLevelFieldWithInitializer1);
  expect(87, lastInit);

  throws(() => finalTopLevelFieldWithInitializer2,
      'Read finalTopLevelFieldWithInitializer2');

  expect(55, Class.staticFieldWithInitializer1);
  expect(55, lastInit);

  Class.staticFieldWithInitializer2 = 63;
  expect(55, lastInit);
  expect(63, Class.staticFieldWithInitializer2);
  expect(55, lastInit);

  expect(73, Class.staticFinalFieldWithInitializer1);
  expect(73, lastInit);

  throws(() => Class.staticFinalFieldWithInitializer2,
      'Read staticFinalFieldWithInitializer2');

  var c = new Class();
  expect(55, lastInit);
  expect(55, c.instanceFieldWithInitializer);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } on LateInitializationError catch (e) {
    throw '$message: Unexpected LateInitializationError: $e';
  } catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
