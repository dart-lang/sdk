// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program for testing optional named parameters in type tests.

import "package:expect/expect.dart";

class NamedParametersTypeTest {
  static int testMain() {
    int result = 0;
    Function anyFunction;
    void acceptFunNumOptBool(void funNumOptBool(num n, {bool b})) { };
    void funNum(num n) { };
    void funNumBool(num n, bool b) { };
    void funNumOptBool(num n, {bool b: true}) { };
    void funNumOptBoolX(num n, {bool x: true}) { };
    anyFunction = funNum;  // No error.
    anyFunction = funNumBool;  // No error.
    anyFunction = funNumOptBool;  // No error.
    anyFunction = funNumOptBoolX;  // No error.
    acceptFunNumOptBool(funNumOptBool);  // No error.
    try {
      acceptFunNumOptBool(funNum);  // No static type warning.
    } on TypeError catch (error) {
      result += 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("(num, {b: bool}) => void"));  // dstType
      Expect.isTrue(msg.contains("(num) => void"));  // srcType
    }
    try {
      acceptFunNumOptBool(funNumBool);  /// static type warning
    } on TypeError catch (error) {
      result += 10;
      var msg = error.toString();
      Expect.isTrue(msg.contains("(num, {b: bool}) => void"));  // dstType
      Expect.isTrue(msg.contains("(num, bool) => void"));  // srcType
    }
    try {
      acceptFunNumOptBool(funNumOptBoolX);  /// static type warning
    } on TypeError catch (error) {
      result += 100;
      var msg = error.toString();
      Expect.isTrue(msg.contains("(num, {b: bool}) => void"));  // dstType
      Expect.isTrue(msg.contains("(num, {x: bool}) => void"));  // srcType
    }
    return result;
  }
}

main() {
  Expect.equals(111, NamedParametersTypeTest.testMain());
}
