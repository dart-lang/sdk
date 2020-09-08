// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic lastInit;

T init<T>(T value) {
  lastInit = value;
  return value;
}

const int constTopLevelField = 324;

int? topLevelFieldWithoutInitializer;

int nonNullableTopLevelFieldWithInitializer1 = init(42);
int? nullableTopLevelFieldWithInitializer = init(123);

int nonNullableTopLevelFieldWithInitializer2 = init(42);
int? nullableTopLevelFieldWithInitializer2 = init(123);

final int nonNullableFinalTopLevelFieldWithInitializer1 = init(87);
final int? nullableFinalTopLevelFieldWithInitializer1 = init(32);

int nonNullableFinalTopLevelFieldWithInitializer2Init = 0;
final int nonNullableFinalTopLevelFieldWithInitializer2 =
    nonNullableFinalTopLevelFieldWithInitializer2Init++ == 0
        ? nonNullableFinalTopLevelFieldWithInitializer2 + 1
        : 87;
int nullableFinalTopLevelFieldWithInitializer2Init = 0;
final int? nullableFinalTopLevelFieldWithInitializer2 =
    nullableFinalTopLevelFieldWithInitializer2Init++ == 0
        ? nullableFinalTopLevelFieldWithInitializer2! + 1
        : 32;

class Class {
  static const int staticConstField = 123;

  static int? staticFieldWithoutInitializer;

  int nonNullableInstanceFieldWithInitializer = init(55);
  int? nullableInstanceFieldWithInitializer = init(17);

  static int nonNullableStaticFieldWithInitializer1 = init(55);
  static int? nullableStaticFieldWithInitializer1 = init(17);

  static int nonNullableStaticFieldWithInitializer2 = init(55);
  static int? nullableStaticFieldWithInitializer2 = init(17);

  static final int nonNullableStaticFinalFieldWithInitializer1 = init(73);
  static final int? nullableStaticFinalFieldWithInitializer1 = init(19);

  static int nonNullableStaticFinalFieldWithInitializer2Init = 0;
  static final int nonNullableStaticFinalFieldWithInitializer2 =
      nonNullableStaticFinalFieldWithInitializer2Init++ == 0
          ? nonNullableStaticFinalFieldWithInitializer2 + 1
          : 87;
  static int nullableStaticFinalFieldWithInitializer2Init = 0;
  static final int? nullableStaticFinalFieldWithInitializer2 =
      nullableStaticFinalFieldWithInitializer2Init++ == 0
          ? nullableStaticFinalFieldWithInitializer2! + 1
          : 32;
}

main() {
  expect(null, lastInit);
  expect(null, topLevelFieldWithoutInitializer);
  expect(324, constTopLevelField);
  expect(null, Class.staticFieldWithoutInitializer);
  expect(123, Class.staticConstField);

  expect(42, nonNullableTopLevelFieldWithInitializer1);
  expect(42, lastInit);

  expect(123, nullableTopLevelFieldWithInitializer);
  expect(123, lastInit);

  nonNullableTopLevelFieldWithInitializer2 = 56;
  expect(123, lastInit);
  expect(56, nonNullableTopLevelFieldWithInitializer2);
  expect(123, lastInit);

  nullableTopLevelFieldWithInitializer2 = 7;
  expect(123, lastInit);
  expect(7, nullableTopLevelFieldWithInitializer2);
  expect(123, lastInit);

  expect(87, nonNullableFinalTopLevelFieldWithInitializer1);
  expect(87, lastInit);

  expect(32, nullableFinalTopLevelFieldWithInitializer1);
  expect(32, lastInit);

  throws(() => nonNullableFinalTopLevelFieldWithInitializer2,
      'Read nonNullableFinalTopLevelFieldWithInitializer2');

  throws(() => nullableFinalTopLevelFieldWithInitializer2,
      'Read nullableFinalTopLevelFieldWithInitializer2');

  expect(55, Class.nonNullableStaticFieldWithInitializer1);
  expect(55, lastInit);

  expect(17, Class.nullableStaticFieldWithInitializer1);
  expect(17, lastInit);

  Class.nonNullableStaticFieldWithInitializer2 = 63;
  expect(17, lastInit);
  expect(63, Class.nonNullableStaticFieldWithInitializer2);
  expect(17, lastInit);

  Class.nullableStaticFieldWithInitializer2 = 89;
  expect(17, lastInit);
  expect(89, Class.nullableStaticFieldWithInitializer2);
  expect(17, lastInit);

  expect(73, Class.nonNullableStaticFinalFieldWithInitializer1);
  expect(73, lastInit);

  expect(19, Class.nullableStaticFinalFieldWithInitializer1);
  expect(19, lastInit);

  throws(() => Class.nonNullableStaticFinalFieldWithInitializer2,
      'Read nonNullableStaticFinalFieldWithInitializer2');

  throws(() => Class.nullableStaticFinalFieldWithInitializer2,
      'Read nullableStaticFinalFieldWithInitializer2');

  var c = new Class();
  expect(17, lastInit);
  expect(55, c.nonNullableInstanceFieldWithInitializer);
  expect(17, c.nullableInstanceFieldWithInitializer);
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
