// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionTypeNullable(String? s) {}

extension type ExtensionTypeNum(num n) {}

extension type ExtensionTypeBool(bool b) {}

sealed class S {}
class A extends S {}
class B extends S {}

extension type ExtensionTypeSealed(S s) {}

methodNull1(ExtensionTypeNullable o) => switch (o) {
    null => 0,
    String s => 1,
  };

methodNull2(ExtensionTypeNullable o) => switch (o) {
    ExtensionTypeNullable() => 2,
  };

methodNull3(String? o) => switch (o) {
    ExtensionTypeNullable s => 3,
  };

methodNum1(ExtensionTypeNum o) => switch (o) {
    int() => 0,
    double() => 1,
  };

methodNum2(ExtensionTypeNum o) => switch (o) {
    ExtensionTypeNum() => 2,
  };

methodNum3(num o) => switch (o) {
    ExtensionTypeNum() => 3,
  };

methodBool1(ExtensionTypeBool o) => switch (o) {
    true => 0,
    false => 1,
  };

methodBool2(ExtensionTypeBool o) => switch (o) {
    ExtensionTypeBool() => 2,
  };

methodBool3(bool o) => switch (o) {
    ExtensionTypeBool() => 3,
  };

methodSealed1(ExtensionTypeSealed o) => switch (o) {
    A() => 0,
    B() => 1,
  };

methodSealed2(ExtensionTypeSealed o) => switch (o) {
    ExtensionTypeSealed() => 2,
  };

methodSealed3(S o) => switch (o) {
    ExtensionTypeSealed() => 3,
  };

main() {
  expect(0, methodNull1(ExtensionTypeNullable(null)));
  expect(1, methodNull1(ExtensionTypeNullable('foo')));

  expect(2, methodNull2(ExtensionTypeNullable(null)));
  expect(2, methodNull2(ExtensionTypeNullable('foo')));

  expect(3, methodNull3(null));
  expect(3, methodNull3('foo'));

  expect(0, methodNum1(ExtensionTypeNum(42)));
  expect(1, methodNum1(ExtensionTypeNum(3.14)));

  expect(2, methodNum2(ExtensionTypeNum(42)));
  expect(2, methodNum2(ExtensionTypeNum(3.14)));

  expect(3, methodNum3(42));
  expect(3, methodNum3(3.14));

  expect(0, methodBool1(ExtensionTypeBool(true)));
  expect(1, methodBool1(ExtensionTypeBool(false)));

  expect(2, methodBool2(ExtensionTypeBool(true)));
  expect(2, methodBool2(ExtensionTypeBool(false)));

  expect(3, methodBool3(true));
  expect(3, methodBool3(false));

  expect(0, methodSealed1(ExtensionTypeSealed(A())));
  expect(1, methodSealed1(ExtensionTypeSealed(B())));

  expect(2, methodSealed2(ExtensionTypeSealed(A())));
  expect(2, methodSealed2(ExtensionTypeSealed(B())));

  expect(3, methodSealed3(A()));
  expect(3, methodSealed3(B()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
