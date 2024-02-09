// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

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
  Expect.equals(0, methodNull1(ExtensionTypeNullable(null)));
  Expect.equals(1, methodNull1(ExtensionTypeNullable('foo')));

  Expect.equals(2, methodNull2(ExtensionTypeNullable(null)));
  Expect.equals(2, methodNull2(ExtensionTypeNullable('foo')));

  Expect.equals(3, methodNull3(null));
  Expect.equals(3, methodNull3('foo'));

  Expect.equals(0, methodNum1(ExtensionTypeNum(42)));
  Expect.equals(1, methodNum1(ExtensionTypeNum(3.14)));

  Expect.equals(2, methodNum2(ExtensionTypeNum(42)));
  Expect.equals(2, methodNum2(ExtensionTypeNum(3.14)));

  Expect.equals(3, methodNum3(42));
  Expect.equals(3, methodNum3(3.14));

  Expect.equals(0, methodBool1(ExtensionTypeBool(true)));
  Expect.equals(1, methodBool1(ExtensionTypeBool(false)));

  Expect.equals(2, methodBool2(ExtensionTypeBool(true)));
  Expect.equals(2, methodBool2(ExtensionTypeBool(false)));

  Expect.equals(3, methodBool3(true));
  Expect.equals(3, methodBool3(false));

  Expect.equals(0, methodSealed1(ExtensionTypeSealed(A())));
  Expect.equals(1, methodSealed1(ExtensionTypeSealed(B())));

  Expect.equals(2, methodSealed2(ExtensionTypeSealed(A())));
  Expect.equals(2, methodSealed2(ExtensionTypeSealed(B())));

  Expect.equals(3, methodSealed3(A()));
  Expect.equals(3, methodSealed3(B()));
}
