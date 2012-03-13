// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program for testing named parameters in type tests.

class NamedParametersTypeTest {
  static int testMain() {
    int result = 0;
    Function anyFunction;
    void acceptFunNumOptBool(void funNumOptBool(num num, [bool b])) { };
    void funNum(num num) { };
    void funNumBool(num num, bool b) { };
    void funNumOptBool(num num, [bool b = true]) { };
    void funNumOptBoolX(num num, [bool x = true]) { };
    anyFunction = funNum;  // No error.
    anyFunction = funNumBool;  // No error.
    anyFunction = funNumOptBool;  // No error.
    anyFunction = funNumOptBoolX;  // No error.
    acceptFunNumOptBool(funNumOptBool);  // No error.
    try {
      acceptFunNumOptBool(funNum);  // No static type warning.
    } catch (TypeError error) {
      result += 1;
      Expect.stringEquals("(num, [b: bool]) => void", error.dstType);
      Expect.stringEquals("(num) => void", error.srcType);
    }
    try {
      acceptFunNumOptBool(funNumBool);  /// static type warning
    } catch (TypeError error) {
      result += 10;
      Expect.stringEquals("(num, [b: bool]) => void", error.dstType);
      Expect.stringEquals("(num, bool) => void", error.srcType);
    }
    try {
      acceptFunNumOptBool(funNumOptBoolX);  /// static type warning
    } catch (TypeError error) {
      result += 100;
      Expect.stringEquals("(num, [b: bool]) => void", error.dstType);
      Expect.stringEquals("(num, [x: bool]) => void", error.srcType);
    }
    return result;
  }
}

main() {
  Expect.equals(111, NamedParametersTypeTest.testMain());
}
